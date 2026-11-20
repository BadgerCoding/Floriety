"""
Floriety Backend — Flask REST API + Supabase (Postgres database + file storage)

Local test:   python server.py
Production:   gunicorn server:app   (see Dockerfile)

Environment variables (set these on your hosting service, never in code):
  DATABASE_URL         Supabase Postgres connection string (Session pooler, port 5432)
  GROQ_API_KEY         your Groq key (the mobile app does not hold it)
  ADMIN_KEY            long random string; required by the admin dashboard
  SUPABASE_URL         e.g. https://abcdxyz.supabase.co
  SUPABASE_SECRET_KEY  Supabase secret key (sb_secret_...) or legacy service_role key
  SUPABASE_BUCKET      public bucket name (default: flower-images)
  PORT                 set automatically by most hosts (default 5000)

The database tables are created by floriety.sql (run it once in the
Supabase SQL Editor).
"""

import os
import re
import hashlib
import json
import base64
import uuid
import secrets
import threading
import time
from collections import defaultdict, deque
from datetime import timezone
from functools import wraps

import requests
import psycopg2
import psycopg2.errors
import psycopg2.pool
from psycopg2.extras import RealDictCursor, Json
from flask import Flask, request, jsonify, g
from flask_cors import CORS
from werkzeug.exceptions import HTTPException
from werkzeug.security import generate_password_hash, check_password_hash

# Load a local .env file if python-dotenv is installed (harmless on hosts that
# already inject real environment variables).
try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env'))
except ImportError:
    pass

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 8 * 1024 * 1024  # 8 MB (flower photos)
CORS(app)

def _env(name, default=''):
    return os.environ.get(name, default).strip().strip('"').strip("'")


DATABASE_URL = _env('DATABASE_URL')
DB_SSLMODE = os.environ.get('DB_SSLMODE', 'require')
DB_POOL_MAX = int(os.environ.get('DB_POOL_MAX', '8'))

GROQ_API_KEY = _env('GROQ_API_KEY')
ADMIN_KEY = _env('ADMIN_KEY')

SUPABASE_URL = _env('SUPABASE_URL').rstrip('/')
SUPABASE_KEY = _env('SUPABASE_SECRET_KEY')
SUPABASE_BUCKET = _env('SUPABASE_BUCKET', 'flower-images')
MAX_IMAGE_BYTES = 5 * 1024 * 1024

GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions'
TEXT_MODEL = _env('GROQ_TEXT_MODEL', 'openai/gpt-oss-120b')
VISION_MODEL = _env('GROQ_VISION_MODEL', 'qwen/qwen3.8-27b')


# ─── Database (Supabase Postgres) ────────────────────────────────────

_pool = None
_pool_lock = threading.Lock()


def _get_pool():
    global _pool
    if _pool is None:
        with _pool_lock:
            if _pool is None:
                if not DATABASE_URL:
                    raise RuntimeError('DATABASE_URL is not set on the server')
                _pool = psycopg2.pool.ThreadedConnectionPool(
                    1, DB_POOL_MAX,
                    dsn=DATABASE_URL,
                    sslmode=DB_SSLMODE,
                    connect_timeout=10,
                    keepalives=1,
                    keepalives_idle=30,
                    keepalives_interval=10,
                    keepalives_count=5,
                )
    return _pool


class DB:
    """Small wrapper so queries read like: db.execute(sql, params).fetchone()"""

    def __init__(self, conn):
        self.conn = conn

    def execute(self, sql, params=None):
        cur = self.conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(sql, params)
        return cur

    def commit(self):
        self.conn.commit()

    def rollback(self):
        self.conn.rollback()


def get_db():
    if 'db' not in g:
        pool = _get_pool()
        conn = None
        for _ in range(3):
            candidate = pool.getconn()
            try:
                # Pooled connections can go stale while idle; make sure it still works.
                cur = candidate.cursor()
                cur.execute('SELECT 1')
                cur.close()
                conn = candidate
                break
            except Exception:
                try:
                    pool.putconn(candidate, close=True)
                except Exception:
                    pass
        if conn is None:
            raise psycopg2.OperationalError('Could not connect to the database')
        g.db = DB(conn)
    return g.db


@app.teardown_appcontext
def close_db(exception):
    db = g.pop('db', None)
    if db is None:
        return
    pool = _get_pool()
    try:
        db.conn.rollback()  # discard anything that was never committed
        pool.putconn(db.conn)
    except Exception:
        try:
            pool.putconn(db.conn, close=True)
        except Exception:
            pass


def _ts(value):
    """Timestamps go to the app as 'YYYY-MM-DD HH:MM:SS' (UTC)."""
    if value is None:
        return ''
    if isinstance(value, str):
        return value
    if value.tzinfo is not None:
        value = value.astimezone(timezone.utc)
    return value.strftime('%Y-%m-%d %H:%M:%S')


def startup_check():
    """Prints a clear message at boot; never crashes the server."""
    try:
        pool = _get_pool()
        conn = pool.getconn()
        try:
            cur = conn.cursor()
            cur.execute("SELECT to_regclass('public.users')")
            exists = cur.fetchone()[0] is not None
            conn.rollback()
        finally:
            pool.putconn(conn)
        if exists:
            print('✓ Connected to the Supabase database')
        else:
            print('⚠️  Connected, but the tables are missing. Run floriety.sql in the '
                  'Supabase SQL Editor.')
    except Exception as e:
        print(f'⚠️  Cannot connect to the database: {e}')


def config_report():
    """Which settings are present (never prints secret values)."""
    return {
        'DATABASE_URL': bool(DATABASE_URL),
        'GROQ_API_KEY': bool(GROQ_API_KEY),
        'ADMIN_KEY': bool(ADMIN_KEY),
        'SUPABASE_URL': bool(SUPABASE_URL),
        'SUPABASE_SECRET_KEY': bool(SUPABASE_KEY),
    }


def _print_config():
    missing = [k for k, ok in config_report().items() if not ok]
    if missing:
        print('⚠️  Missing settings: ' + ', '.join(missing) +
              '  (set them as environment variables or in a .env file next to server.py)')
    else:
        print('✓ All server settings are present')


_print_config()
startup_check()


@app.errorhandler(Exception)
def handle_error(e):
    if isinstance(e, HTTPException):
        return jsonify({'error': e.description}), e.code
    app.logger.exception('Unhandled error')
    if isinstance(e, psycopg2.OperationalError):
        return jsonify({'error': 'Database is temporarily unavailable. Please try again.'}), 503
    return jsonify({'error': 'Something went wrong on the server. Please try again.'}), 500


# ─── Security helpers ────────────────────────────────────────────────

def _hash_password(password):
    return generate_password_hash(password)


def _verify_password(stored_hash, password):
    """Supports new (werkzeug) hashes and old unsalted SHA-256 hashes."""
    if stored_hash.startswith(('scrypt:', 'pbkdf2:')):
        return check_password_hash(stored_hash, password)
    legacy = hashlib.sha256(password.encode()).hexdigest()
    return secrets.compare_digest(stored_hash, legacy)


def _is_legacy_hash(stored_hash):
    return not stored_hash.startswith(('scrypt:', 'pbkdf2:'))


def _token_hash(token):
    return hashlib.sha256(token.encode()).hexdigest()


def _create_session(db, user_id):
    token = secrets.token_hex(32)
    db.execute(
        'INSERT INTO sessions (user_id, token_hash) VALUES (%s, %s)',
        (user_id, _token_hash(token))
    )
    # Keep at most 10 devices per user.
    db.execute(
        '''DELETE FROM sessions WHERE user_id = %s AND id NOT IN
           (SELECT id FROM sessions WHERE user_id = %s ORDER BY id DESC LIMIT 10)''',
        (user_id, user_id)
    )
    return token


# Simple in-memory rate limiter (per IP). Good enough for one server.
_hits = defaultdict(deque)


def rate_limit(max_calls, per_seconds):
    def wrapper(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            ip = request.headers.get('X-Forwarded-For', request.remote_addr or 'unknown')
            ip = ip.split(',')[0].strip()
            key = (f.__name__, ip)
            now = time.time()
            q = _hits[key]
            while q and now - q[0] > per_seconds:
                q.popleft()
            if len(q) >= max_calls:
                return jsonify({'error': 'Too many requests. Please wait a moment.'}), 429
            q.append(now)
            return f(*args, **kwargs)
        return decorated
    return wrapper


def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization', '').replace('Bearer ', '').strip()
        if not token:
            return jsonify({'error': 'No token provided'}), 401
        db = get_db()
        user = db.execute(
            '''SELECT u.* FROM users u
               JOIN sessions s ON s.user_id = u.id
               WHERE s.token_hash = %s''',
            (_token_hash(token),)
        ).fetchone()
        if not user:
            return jsonify({'error': 'Invalid token'}), 401
        g.user = dict(user)
        return f(*args, **kwargs)
    return decorated


def require_admin(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        provided = request.headers.get('X-Admin-Key', '')
        if not ADMIN_KEY or not secrets.compare_digest(provided, ADMIN_KEY):
            return jsonify({'error': 'Admin access denied'}), 403
        return f(*args, **kwargs)
    return decorated


# ─── Supabase Storage helpers (files live in the cloud) ──────────────

def storage_enabled():
    return bool(SUPABASE_URL and SUPABASE_KEY)


def _storage_headers(content_type=None):
    headers = {'apikey': SUPABASE_KEY}
    # New-style sb_secret_ keys are not JWTs and go ONLY in the apikey header.
    # Legacy service_role keys are JWTs and also go in Authorization.
    if not SUPABASE_KEY.startswith(('sb_secret_', 'sb_publishable_')):
        headers['Authorization'] = f'Bearer {SUPABASE_KEY}'
    if content_type:
        headers['Content-Type'] = content_type
    return headers


def _public_prefix():
    return f'{SUPABASE_URL}/storage/v1/object/public/{SUPABASE_BUCKET}/'


def _public_url(path):
    return _public_prefix() + path


def _path_from_url(url):
    if SUPABASE_URL and url and url.startswith(_public_prefix()):
        return url[len(_public_prefix()):]
    return None


def _safe_image_url(user_id, url):
    """Only accept image URLs that point at THIS user's folder in our bucket."""
    path = _path_from_url(url or '')
    if path and path.startswith(f'{user_id}/') and '..' not in path:
        return url
    return ''


def _sniff_image(data):
    """Returns (extension, mime) from the file's real bytes, or None."""
    if data[:3] == b'\xff\xd8\xff':
        return 'jpg', 'image/jpeg'
    if data[:8] == b'\x89PNG\r\n\x1a\n':
        return 'png', 'image/png'
    if data[:4] == b'RIFF' and data[8:12] == b'WEBP':
        return 'webp', 'image/webp'
    return None


def _delete_storage_files(urls, user_id=None):
    """Best-effort cleanup; a storage hiccup must never break the main request."""
    if not storage_enabled():
        return
    paths = []
    for url in urls:
        path = _path_from_url(url or '')
        if not path or '..' in path:
            continue
        if user_id is not None and not path.startswith(f'{user_id}/'):
            continue
        paths.append(path)
    if not paths:
        return
    try:
        requests.delete(
            f'{SUPABASE_URL}/storage/v1/object/{SUPABASE_BUCKET}',
            headers=_storage_headers('application/json'),
            json={'prefixes': paths},
            timeout=20,
        )
    except Exception as e:
        app.logger.warning('Storage cleanup failed: %s', e)


def _user_image_urls(db, user_id):
    rows = db.execute(
        "SELECT image_url FROM scan_history WHERE user_id = %s AND image_url <> ''",
        (user_id,)
    ).fetchall()
    return [r['image_url'] for r in rows]


@app.route('/', methods=['GET'])
@app.route('/health', methods=['GET'])
def health():
    database_ok = False
    try:
        get_db().execute('SELECT 1').fetchone()
        database_ok = True
    except Exception:
        pass
    return jsonify({
        'status': 'ok' if database_ok else 'degraded',
        'service': 'floriety-api',
        'database': database_ok,
        'storage': storage_enabled(),
        'ai': bool(GROQ_API_KEY),
    }), 200


# ─── Auth endpoints ──────────────────────────────────────────────────

@app.route('/api/register', methods=['POST'])
@rate_limit(10, 3600)
def register():
    data = request.get_json(silent=True) or {}
    email = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''

    if not email or not password:
        return jsonify({'error': 'Email and password are required'}), 400
    if '@' not in email or '.' not in email.split('@')[-1]:
        return jsonify({'error': 'Please enter a valid email address'}), 400
    if len(password) < 8:
        return jsonify({'error': 'Password must be at least 8 characters'}), 400

    db = get_db()
    if db.execute('SELECT id FROM users WHERE email = %s', (email,)).fetchone():
        return jsonify({'error': 'Email already registered'}), 409

    try:
        user_id = db.execute(
            'INSERT INTO users (email, password_hash) VALUES (%s, %s) RETURNING id',
            (email, _hash_password(password))
        ).fetchone()['id']
    except psycopg2.errors.UniqueViolation:
        db.rollback()
        return jsonify({'error': 'Email already registered'}), 409

    name = email.split('@')[0].title()
    db.execute(
        'INSERT INTO profiles (user_id, name, nickname, description, avatar_index, is_dark) '
        'VALUES (%s, %s, %s, %s, %s, %s)',
        (user_id, name, '', '', 1, True)
    )
    token = _create_session(db, user_id)
    db.commit()

    return jsonify({
        'token': token,
        'user_id': user_id,
        'email': email,
        'name': name,
    }), 201


@app.route('/api/login', methods=['POST'])
@rate_limit(20, 600)
def login():
    data = request.get_json(silent=True) or {}
    email = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''

    if not email or not password:
        return jsonify({'error': 'Email and password are required'}), 400

    db = get_db()
    user = db.execute('SELECT * FROM users WHERE email = %s', (email,)).fetchone()
    if not user or not _verify_password(user['password_hash'], password):
        return jsonify({'error': 'Invalid email or password'}), 401

    # Silently upgrade old SHA-256 hashes to a salted hash.
    if _is_legacy_hash(user['password_hash']):
        db.execute('UPDATE users SET password_hash = %s WHERE id = %s',
                   (_hash_password(password), user['id']))

    token = _create_session(db, user['id'])
    db.commit()

    profile = db.execute('SELECT * FROM profiles WHERE user_id = %s', (user['id'],)).fetchone()
    result = {'token': token, 'user_id': user['id'], 'email': user['email']}
    if profile:
        result.update({
            'name': profile['name'],
            'nickname': profile['nickname'],
            'description': profile['description'],
            'avatar_index': profile['avatar_index'],
            'is_dark': bool(profile['is_dark']),
        })
    else:
        result.update({
            'name': email.split('@')[0].title(),
            'nickname': '',
            'description': '',
            'avatar_index': 1,
            'is_dark': True,
        })
    return jsonify(result), 200


@app.route('/api/logout', methods=['POST'])
@require_auth
def logout():
    token = request.headers.get('Authorization', '').replace('Bearer ', '').strip()
    db = get_db()
    db.execute('DELETE FROM sessions WHERE token_hash = %s', (_token_hash(token),))
    db.commit()
    return jsonify({'message': 'Logged out'}), 200


@app.route('/api/account', methods=['DELETE'])
@require_auth
def delete_account():
    """Lets customers delete their own account (required by Google Play / App Store)."""
    db = get_db()
    urls = _user_image_urls(db, g.user['id'])
    db.execute('DELETE FROM users WHERE id = %s', (g.user['id'],))
    db.commit()
    _delete_storage_files(urls, user_id=g.user['id'])
    return jsonify({'message': 'Account deleted'}), 200


# ─── Profile endpoints ──────────────────────────────────────────────

@app.route('/api/profile', methods=['GET'])
@require_auth
def get_profile():
    db = get_db()
    profile = db.execute('SELECT * FROM profiles WHERE user_id = %s', (g.user['id'],)).fetchone()
    if not profile:
        return jsonify({'name': '', 'nickname': '', 'description': '',
                        'avatar_index': 1, 'is_dark': True}), 200
    return jsonify({
        'name': profile['name'],
        'nickname': profile['nickname'],
        'description': profile['description'],
        'avatar_index': profile['avatar_index'],
        'is_dark': bool(profile['is_dark']),
    }), 200


@app.route('/api/profile', methods=['PUT'])
@require_auth
def update_profile():
    data = request.get_json(silent=True) or {}
    name = (data.get('name') or '').strip()[:100]
    nickname = (data.get('nickname') or '').strip()[:100]
    description = (data.get('description') or '').strip()[:500]
    try:
        avatar_index = int(data.get('avatar_index') or 1)
    except (TypeError, ValueError):
        avatar_index = 1
    avatar_index = max(1, avatar_index)
    is_dark = bool(data.get('is_dark', True))

    db = get_db()
    updated = db.execute(
        'UPDATE profiles SET name = %s, nickname = %s, description = %s, avatar_index = %s, '
        'is_dark = %s WHERE user_id = %s RETURNING id',
        (name, nickname, description, avatar_index, is_dark, g.user['id'])
    ).fetchone()
    if not updated:
        db.execute(
            'INSERT INTO profiles (user_id, name, nickname, description, avatar_index, is_dark) '
            'VALUES (%s, %s, %s, %s, %s, %s)',
            (g.user['id'], name or g.user['email'].split('@')[0].title(),
             nickname, description, avatar_index, is_dark)
        )
    db.commit()
    return jsonify({'message': 'Profile updated'}), 200


# ─── History endpoints ───────────────────────────────────────────────

@app.route('/api/history', methods=['GET'])
@require_auth
def get_history():
    db = get_db()
    rows = db.execute(
        'SELECT * FROM scan_history WHERE user_id = %s ORDER BY created_at DESC, id DESC',
        (g.user['id'],)
    ).fetchall()
    items = []
    for r in rows:
        items.append({
            'id': r['id'],
            'flower_name': r['flower_name'],
            'scientific': r['scientific'],
            'family': r['family'],
            'variety_appearance': r['variety_appearance'],
            'origin': r['origin'],
            'habitat': r['habitat'],
            'allergen': r['allergen'],
            'disease': r['disease'],
            'care_list': r['care_list'],
            'description': r['description'],
            'image_url': r['image_url'],
            'is_favorite': bool(r['is_favorite']),
            'created_at': _ts(r['created_at']),
        })
    return jsonify(items), 200


@app.route('/api/history', methods=['POST'])
@require_auth
def add_history():
    data = request.get_json(silent=True) or {}
    db = get_db()
    flower_name = data.get('flower_name', data.get('name', ''))

    db.execute(
        '''INSERT INTO scan_history
           (user_id, flower_name, scientific, family, variety_appearance,
            origin, habitat, allergen, disease, care_list, description, image_url)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)''',
        (
            g.user['id'],
            flower_name,
            data.get('scientific', ''),
            data.get('family', ''),
            data.get('variety_appearance', ''),
            data.get('origin', ''),
            data.get('habitat', ''),
            data.get('allergen', ''),
            data.get('disease', ''),
            data.get('care_list', ''),
            data.get('description', ''),
            _safe_image_url(g.user['id'], data.get('image_url', '')),
        )
    )
    db.commit()
    return jsonify({'message': 'History saved'}), 201


@app.route('/api/history/<int:history_id>/favorite', methods=['PUT'])
@require_auth
def toggle_favorite(history_id):
    db = get_db()
    row = db.execute(
        'UPDATE scan_history SET is_favorite = NOT is_favorite '
        'WHERE id = %s AND user_id = %s RETURNING is_favorite',
        (history_id, g.user['id'])
    ).fetchone()
    if not row:
        return jsonify({'error': 'Item not found'}), 404
    db.commit()
    return jsonify({'is_favorite': bool(row['is_favorite'])}), 200


@app.route('/api/history/<int:history_id>', methods=['DELETE'])
@require_auth
def delete_history(history_id):
    db = get_db()
    row = db.execute(
        'DELETE FROM scan_history WHERE id = %s AND user_id = %s RETURNING image_url',
        (history_id, g.user['id'])
    ).fetchone()
    if not row:
        return jsonify({'error': 'Item not found'}), 404
    db.commit()
    _delete_storage_files([row['image_url']], user_id=g.user['id'])
    return jsonify({'message': 'Deleted'}), 200


# ─── Feedback endpoints ─────────────────────────────────────────────

@app.route('/api/feedback', methods=['POST'])
@require_auth
def submit_feedback():
    data = request.get_json(silent=True) or {}
    gmail = (data.get('gmail') or '').strip()[:200]
    subject = (data.get('subject') or '').strip()[:200]
    message = (data.get('message') or '').strip()[:5000]

    if not subject or not message:
        return jsonify({'error': 'Subject and message are required'}), 400

    db = get_db()
    db.execute(
        'INSERT INTO feedback (user_id, gmail, subject, message) VALUES (%s, %s, %s, %s)',
        (g.user['id'], gmail, subject, message)
    )
    db.commit()
    return jsonify({'message': 'Feedback submitted'}), 201


@app.route('/api/feedback', methods=['GET'])
@require_admin
def get_all_feedback():
    db = get_db()
    rows = db.execute('''
        SELECT f.*, u.email AS user_email
        FROM feedback f
        JOIN users u ON f.user_id = u.id
        ORDER BY f.created_at DESC
    ''').fetchall()
    return jsonify([{
        'id': r['id'],
        'user_email': r['user_email'],
        'gmail': r['gmail'],
        'subject': r['subject'],
        'message': r['message'],
        'created_at': _ts(r['created_at']),
    } for r in rows]), 200


# ─── Chatbot history endpoints ───────────────────────────────────────

@app.route('/api/chat/history', methods=['GET'])
@require_auth
def get_chat_history():
    db = get_db()
    rows = db.execute(
        'SELECT id, title, created_at, updated_at FROM chat_history '
        'WHERE user_id = %s ORDER BY updated_at DESC',
        (g.user['id'],)
    ).fetchall()
    return jsonify([{
        'id': r['id'],
        'title': r['title'],
        'created_at': _ts(r['created_at']),
        'updated_at': _ts(r['updated_at']),
    } for r in rows]), 200


@app.route('/api/chat/history/<int:history_id>', methods=['GET'])
@require_auth
def get_chat_history_item(history_id):
    db = get_db()
    row = db.execute(
        'SELECT * FROM chat_history WHERE id = %s AND user_id = %s',
        (history_id, g.user['id'])
    ).fetchone()
    if not row:
        return jsonify({'error': 'Chat history not found'}), 404
    messages = row['messages']
    if isinstance(messages, str):
        messages = json.loads(messages or '[]')
    return jsonify({
        'id': row['id'],
        'title': row['title'],
        'messages': messages or [],
        'created_at': _ts(row['created_at']),
        'updated_at': _ts(row['updated_at']),
    }), 200


@app.route('/api/chat/history', methods=['POST'])
@require_auth
def save_chat_history():
    data = request.get_json(silent=True) or {}
    title = (data.get('title') or '').strip()
    messages = data.get('messages', [])
    if not isinstance(messages, list) or len(messages) == 0:
        return jsonify({'error': 'Messages are required'}), 400

    if not title:
        first_user = next((m for m in messages if m.get('role') == 'user'), None)
        title = (first_user.get('content', 'Floriety Chat')[:48] if first_user else 'Floriety Chat')

    db = get_db()
    existing_id = data.get('id')

    if existing_id is not None:
        try:
            existing_id = int(existing_id)
        except (TypeError, ValueError):
            return jsonify({'error': 'Chat history not found'}), 404
        row = db.execute(
            'UPDATE chat_history SET title = %s, messages = %s, updated_at = now() '
            'WHERE id = %s AND user_id = %s RETURNING id',
            (title, Json(messages), existing_id, g.user['id'])
        ).fetchone()
        if not row:
            return jsonify({'error': 'Chat history not found'}), 404
    else:
        existing_id = db.execute(
            'INSERT INTO chat_history (user_id, title, messages) VALUES (%s, %s, %s) RETURNING id',
            (g.user['id'], title, Json(messages))
        ).fetchone()['id']

    # Keep only the latest 5 chat sessions per user.
    db.execute(
        '''DELETE FROM chat_history WHERE user_id = %s AND id NOT IN
           (SELECT id FROM chat_history WHERE user_id = %s
            ORDER BY updated_at DESC, id DESC LIMIT 5)''',
        (g.user['id'], g.user['id'])
    )

    db.commit()
    return jsonify({'id': existing_id, 'message': 'Chat history saved'}), 200


# ─── File upload → Supabase Storage ──────────────────────────────────

@app.route('/api/upload', methods=['POST'])
@require_auth
@rate_limit(60, 3600)
def upload_image():
    """Body: {"image_base64": "..."}  →  {"url": "https://....supabase.co/..."}"""
    if not storage_enabled():
        return jsonify({'error': 'File storage is not configured on the server'}), 503

    data = request.get_json(silent=True) or {}
    raw = data.get('image_base64') or ''
    try:
        image_bytes = base64.b64decode(raw, validate=False)
    except Exception:
        return jsonify({'error': 'Invalid image data'}), 400
    if not image_bytes:
        return jsonify({'error': 'image_base64 is required'}), 400
    if len(image_bytes) > MAX_IMAGE_BYTES:
        return jsonify({'error': 'Image is too large (max 5 MB)'}), 413

    kind = _sniff_image(image_bytes)
    if not kind:
        return jsonify({'error': 'Only JPG, PNG or WEBP images are allowed'}), 400
    ext, mime = kind

    path = f"{g.user['id']}/{uuid.uuid4().hex}.{ext}"
    try:
        resp = requests.post(
            f'{SUPABASE_URL}/storage/v1/object/{SUPABASE_BUCKET}/{path}',
            headers={**_storage_headers(mime), 'x-upsert': 'false'},
            data=image_bytes,
            timeout=30,
        )
    except requests.RequestException as e:
        app.logger.error('Supabase upload failed: %s', e)
        return jsonify({'error': 'Could not reach file storage. Try again.'}), 502
    if resp.status_code not in (200, 201):
        app.logger.error('Supabase upload error %s: %s', resp.status_code, resp.text[:300])
        return jsonify({'error': 'File storage rejected the upload'}), 502

    return jsonify({'url': _public_url(path)}), 201


# ─── AI proxy (Groq key stays on the server) ─────────────────────────

class AIError(RuntimeError):
    def __init__(self, message, status=502):
        super().__init__(message)
        self.status = status


def _groq(payload):
    if not GROQ_API_KEY:
        raise AIError('AI service is not configured on the server (GROQ_API_KEY is missing)', 503)
    try:
        resp = requests.post(
            GROQ_URL,
            headers={'Authorization': f'Bearer {GROQ_API_KEY}', 'Content-Type': 'application/json'},
            json=payload,
            timeout=60,
        )
    except requests.RequestException as e:
        app.logger.error('Groq request failed: %s', e)
        raise AIError('Could not reach the AI service. Please try again.')
    if resp.status_code != 200:
        app.logger.error('Groq error %s: %s', resp.status_code, resp.text[:500])
        if resp.status_code in (401, 403):
            raise AIError('The AI service key on the server is invalid or expired.', 503)
        if resp.status_code == 429:
            raise AIError('The AI service is busy right now. Please wait a moment and try again.', 429)
        if resp.status_code in (400, 404):
            try:
                detail = resp.json().get('error', {}).get('message', '')
            except ValueError:
                detail = ''
            raise AIError(
                'The AI request was rejected' + (f': {detail[:200]}' if detail else '.') +
                ' (check GROQ_VISION_MODEL / GROQ_TEXT_MODEL on the server)', 502)
        raise AIError('The AI service is busy. Please try again.')
    try:
        content = resp.json()['choices'][0]['message']['content'] or ''
    except (KeyError, IndexError, ValueError):
        raise AIError('The AI service returned an unexpected answer. Please try again.')
    # Reasoning models may include their thinking; users only need the answer.
    content = re.sub(r'<think>.*?</think>', '', content, flags=re.DOTALL).strip()
    if not content:
        raise AIError('The AI did not produce an answer. Please try again.')
    return content


def _ai_error(e):
    if isinstance(e, AIError):
        return jsonify({'error': str(e)}), e.status
    app.logger.exception('Unexpected AI error')
    return jsonify({'error': 'The AI service had a problem. Please try again.'}), 502


SCAN_PROMPT = '''You are a professional botanist. Carefully examine this image.

IMPORTANT: Analyze ALL visible botanical features for maximum accuracy:
- Petal shape, color, count, and arrangement
- Leaf shape, margin (serrated/smooth), venation pattern, and attachment
- Stem structure and color
- Overall plant habit and growth form
- Any visible reproductive structures (stamens, pistils, sepals)

Based on this holistic analysis of both flower AND leaves/stems, identify the plant species with high confidence.

If the image does NOT contain a flower or plant at all, respond with isFlower set to "false".

Respond ONLY with a valid JSON object (no markdown, no extra text):
{
  "isFlower": "true",
  "name": "Most accurate common name of the flower",
  "scientific": "Scientific/Latin name (Genus species)",
  "family": "Botanical family name (e.g. Asteraceae, Rosaceae)",
  "variety_appearance": "Description of variety, cultivar, and visual appearance (color, size, petal form)",
  "origin": "Geographic origin or native region",
  "habitat": "Typical environment where this flower grows (e.g. tropical rainforest, alpine meadow, coastal dunes)",
  "allergen": "Allergen information (pollen type, severity)",
  "disease": "Disease or health condition observed on this specimen — if healthy say None detected",
  "care_list": "1. [care step]\\n2. [care step]\\n3. [care step] (list all crucial care steps specific to this flower — watering, sunlight, soil, pruning, fertilizer, repotting, humidity, etc. Include as many as needed)",
  "description": "2-3 sentence poetic yet informative description of this flower"
}

If this is NOT a flower/plant, respond with:
{
  "isFlower": "false",
  "name": "No Flower Detected",
  "scientific": "",
  "family": "",
  "variety_appearance": "",
  "origin": "",
  "habitat": "",
  "allergen": "",
  "disease": "",
  "care_list": "",
  "description": ""
}'''

CHAT_SYSTEM = (
    'You are Floriety AI, a friendly and knowledgeable botanical assistant. '
    'You specialize in flowers, plants, their care, history, and identification. '
    'Keep responses concise, helpful and engaging. Use occasional botanical terminology.'
)


@app.route('/api/ai/scan', methods=['POST'])
@require_auth
@rate_limit(30, 3600)
def ai_scan():
    data = request.get_json(silent=True) or {}
    image_b64 = data.get('image_base64') or ''
    mime = data.get('mime_type') or 'image/jpeg'
    if not image_b64:
        return jsonify({'error': 'image_base64 is required'}), 400
    if mime not in ('image/jpeg', 'image/png', 'image/webp'):
        return jsonify({'error': 'Unsupported image type'}), 400
    try:
        content = _groq({
            'model': VISION_MODEL,
            'messages': [{
                'role': 'user',
                'content': [
                    {'type': 'image_url',
                     'image_url': {'url': f'data:{mime};base64,{image_b64}'}},
                    {'type': 'text', 'text': SCAN_PROMPT},
                ],
            }],
            'max_tokens': 4000,
        })
    except Exception as e:
        return _ai_error(e)
    return jsonify({'content': content}), 200


@app.route('/api/ai/chat', methods=['POST'])
@require_auth
@rate_limit(120, 3600)
def ai_chat():
    data = request.get_json(silent=True) or {}
    messages = data.get('messages') or []
    if not isinstance(messages, list) or not messages:
        return jsonify({'error': 'messages are required'}), 400
    clean = []
    for m in messages[-30:]:
        role = m.get('role')
        content = str(m.get('content', ''))[:4000]
        if role in ('user', 'assistant') and content:
            clean.append({'role': role, 'content': content})
    if not clean:
        return jsonify({'error': 'messages are required'}), 400
    try:
        content = _groq({
            'model': TEXT_MODEL,
            'messages': [{'role': 'system', 'content': CHAT_SYSTEM}] + clean,
            'max_tokens': 2048,
        })
    except Exception as e:
        return _ai_error(e)
    return jsonify({'content': content}), 200


@app.route('/api/ai/identify', methods=['POST'])
@require_auth
@rate_limit(60, 3600)
def ai_identify():
    data = request.get_json(silent=True) or {}
    description = str(data.get('description') or '').strip()[:1000]
    if not description:
        return jsonify({'error': 'description is required'}), 400
    try:
        content = _groq({
            'model': TEXT_MODEL,
            'messages': [
                {'role': 'system', 'content':
                    'You are a botanical expert. When given a description of a flower, identify '
                    'the best matching real flower and respond ONLY with a valid JSON object '
                    '(no markdown, no explanation).'},
                {'role': 'user', 'content':
                    f'''Based on this description: "{description}"
Identify the best matching real flower and respond with ONLY a JSON object:
{{
  "name": "Common name",
  "scientific": "Scientific name",
  "imagePrompt": "A beautiful high-quality photo of <flower name>, botanical illustration style",
  "description": "2-3 sentence description of this flower"
}}'''},
            ],
            'max_tokens': 2048,
        })
    except Exception as e:
        return _ai_error(e)
    return jsonify({'content': content}), 200


@app.route('/api/ai/care-guide', methods=['POST'])
@require_auth
@rate_limit(60, 3600)
def ai_care_guide():
    data = request.get_json(silent=True) or {}
    name = str(data.get('name') or 'this flower')[:120]
    scientific = str(data.get('scientific') or '')[:120]
    origin = str(data.get('origin') or '')[:120]
    extra_sci = f' ({scientific})' if scientific else ''
    extra_origin = f', originally from {origin}' if origin else ''
    try:
        content = _groq({
            'model': TEXT_MODEL,
            'messages': [
                {'role': 'system', 'content':
                    'You are a professional botanist and horticulturist. Generate detailed, '
                    'well-structured flower care guides.'},
                {'role': 'user', 'content':
                    f'''Generate a comprehensive care guide for {name}{extra_sci}{extra_origin}.

Include these sections with emoji headers:
🌱 **Planting & Soil**
☀️ **Sunlight Requirements**
💧 **Watering Schedule**
🌡️ **Temperature & Humidity**
✂️ **Pruning & Maintenance**
🐛 **Common Pests & Diseases**
🌸 **Blooming Season**
💡 **Pro Tips**

Keep each section to 2-3 sentences. Be specific and practical.'''},
            ],
            'max_tokens': 3000,
        })
    except Exception as e:
        return _ai_error(e)
    return jsonify({'content': content}), 200


# ─── Admin endpoints (require X-Admin-Key header) ───────────────────

@app.route('/api/admin/users', methods=['GET'])
@require_admin
def admin_get_users():
    db = get_db()
    rows = db.execute('SELECT id, email, created_at FROM users ORDER BY created_at DESC').fetchall()
    return jsonify([{'id': r['id'], 'email': r['email'], 'created_at': _ts(r['created_at'])}
                    for r in rows]), 200


@app.route('/api/admin/users/<int:user_id>', methods=['PUT'])
@require_admin
def admin_update_user(user_id):
    data = request.get_json(silent=True) or {}
    db = get_db()
    if not db.execute('SELECT id FROM users WHERE id = %s', (user_id,)).fetchone():
        return jsonify({'error': 'User not found'}), 404

    if data.get('email'):
        try:
            db.execute('UPDATE users SET email = %s WHERE id = %s',
                       (data['email'].strip().lower(), user_id))
        except psycopg2.errors.UniqueViolation:
            db.rollback()
            return jsonify({'error': 'Email already in use'}), 409

    if data.get('password'):
        if len(data['password']) < 8:
            db.rollback()
            return jsonify({'error': 'Password must be at least 8 characters'}), 400
        db.execute('UPDATE users SET password_hash = %s WHERE id = %s',
                   (_hash_password(data['password']), user_id))
        db.execute('DELETE FROM sessions WHERE user_id = %s', (user_id,))

    db.commit()
    return jsonify({'message': 'User updated'}), 200


@app.route('/api/admin/users/<int:user_id>', methods=['DELETE'])
@require_admin
def admin_delete_user(user_id):
    db = get_db()
    if not db.execute('SELECT id FROM users WHERE id = %s', (user_id,)).fetchone():
        return jsonify({'error': 'User not found'}), 404
    urls = _user_image_urls(db, user_id)
    db.execute('DELETE FROM users WHERE id = %s', (user_id,))
    db.commit()
    _delete_storage_files(urls, user_id=user_id)
    return jsonify({'message': 'User deleted'}), 200


@app.route('/api/admin/analytics', methods=['GET'])
@require_admin
def admin_analytics():
    db = get_db()
    total_users = db.execute('SELECT COUNT(*) AS c FROM users').fetchone()['c']
    total_scans = db.execute('SELECT COUNT(*) AS c FROM scan_history').fetchone()['c']
    total_feedbacks = db.execute('SELECT COUNT(*) AS c FROM feedback').fetchone()['c']
    total_favorites = db.execute(
        'SELECT COUNT(*) AS c FROM scan_history WHERE is_favorite = true').fetchone()['c']

    monthly_users = db.execute('''
        SELECT to_char(created_at, 'YYYY-MM') AS month, COUNT(*) AS count
        FROM users GROUP BY month ORDER BY month DESC LIMIT 12
    ''').fetchall()
    monthly_scans = db.execute('''
        SELECT to_char(created_at, 'YYYY-MM') AS month, COUNT(*) AS count
        FROM scan_history GROUP BY month ORDER BY month DESC LIMIT 12
    ''').fetchall()
    top_flowers = db.execute('''
        SELECT flower_name, COUNT(*) AS count FROM scan_history
        WHERE flower_name <> '' GROUP BY flower_name ORDER BY count DESC LIMIT 10
    ''').fetchall()

    return jsonify({
        'total_users': total_users,
        'total_scans': total_scans,
        'total_feedbacks': total_feedbacks,
        'total_favorites': total_favorites,
        'monthly_users': [{'month': r['month'], 'count': r['count']} for r in monthly_users],
        'monthly_scans': [{'month': r['month'], 'count': r['count']} for r in monthly_scans],
        'top_flowers': [{'name': r['flower_name'], 'count': r['count']} for r in top_flowers],
    }), 200


@app.route('/api/admin/diagnostics', methods=['GET'])
@require_admin
def admin_diagnostics():
    """Shows which database/storage/AI this server is really using (no secrets)."""
    info = {'settings_present': config_report(), 'ai_models': {'text': TEXT_MODEL, 'vision': VISION_MODEL}}
    try:
        db = get_db()
        row = db.execute('SELECT current_database() AS db, inet_server_addr()::text AS addr').fetchone()
        info['database'] = {'connected': True, 'name': row['db']}
        tables = {}
        for t in ('users', 'profiles', 'sessions', 'scan_history', 'feedback', 'chat_history'):
            if db.execute('SELECT to_regclass(%s) AS r', (f'public.{t}',)).fetchone()['r']:
                tables[t] = db.execute(f'SELECT COUNT(*) AS c FROM public.{t}').fetchone()['c']
            else:
                tables[t] = 'MISSING (run floriety.sql)'
        info['tables'] = tables
        # Host part of the connection string only (helps spot "wrong Supabase project").
        host = DATABASE_URL.rsplit('@', 1)[-1].split('/')[0] if DATABASE_URL else ''
        info['database']['host'] = host
    except Exception as e:
        info['database'] = {'connected': False, 'error': str(e)[:200]}
    info['storage'] = {'configured': storage_enabled(), 'bucket': SUPABASE_BUCKET}
    return jsonify(info), 200


# ─── Main (local testing only; production uses gunicorn) ────────────

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"✿ Floriety API running on http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
