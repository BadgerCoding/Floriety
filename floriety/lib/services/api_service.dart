import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Every network call goes through here so users on ANY connection
/// (weak WiFi, mobile data, sleeping server) see a friendly message
/// instead of a raw "ClientException ... errno = 113" error.
class _Net {
  static const Duration _defaultTimeout = Duration(seconds: 75); // free hosts need up to ~60s to wake up

  static Future<http.Response> _run(
    Future<http.Response> Function() call,
    Duration timeout,
  ) async {
    try {
      return await call().timeout(timeout);
    } on TimeoutException {
      throw Exception(
        'The server is taking too long to respond. Check your internet and try again.',
      );
    } on SocketException {
      throw Exception(
        'Cannot reach Floriety. Please check your internet connection.',
      );
    } on http.ClientException {
      throw Exception(
        'Cannot reach Floriety. Please check your internet connection.',
      );
    } on HandshakeException {
      throw Exception('Secure connection failed. Check your date/time and network.');
    }
  }

  static Future<http.Response> get(Uri uri,
          {Map<String, String>? headers, Duration? timeout}) =>
      _run(() => http.get(uri, headers: headers), timeout ?? _defaultTimeout);

  static Future<http.Response> post(Uri uri,
          {Map<String, String>? headers, Object? body, Duration? timeout}) =>
      _run(() => http.post(uri, headers: headers, body: body),
          timeout ?? _defaultTimeout);

  static Future<http.Response> put(Uri uri,
          {Map<String, String>? headers, Object? body, Duration? timeout}) =>
      _run(() => http.put(uri, headers: headers, body: body),
          timeout ?? _defaultTimeout);

  static Future<http.Response> delete(Uri uri,
          {Map<String, String>? headers, Object? body, Duration? timeout}) =>
      _run(() => http.delete(uri, headers: headers, body: body),
          timeout ?? _defaultTimeout);
}

class ApiService {
  // Set your live server address in ONE place: pass it when building, e.g.
  //   flutter build apk --release --dart-define=API_BASE_URL=https://floriety-api.onrender.com
  // For local testing on the Android emulator use http://10.0.2.2:5000
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://YOUR-SERVER-URL-HERE',
  );

  /// Safe JSON decode: hosting errors (502 HTML pages, cold starts) won't crash the app.
  static dynamic _decode(http.Response r) {
    try {
      return jsonDecode(r.body);
    } catch (_) {
      return {
        'error': r.statusCode == 429
            ? 'Too many requests. Please wait a moment.'
            : 'Server is unavailable (${r.statusCode}). Please try again.'
      };
    }
  }

  static Future<Map<String, dynamic>> register(
    String email,
    String password,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/register');
    final response = await _Net.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = _decode(response);
    if (response.statusCode != 201) {
      throw Exception(body['error'] ?? 'Registration failed');
    }
    return Map<String, dynamic>.from(body);
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/login');
    final response = await _Net.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Login failed');
    }
    return Map<String, dynamic>.from(body);
  }

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final uri = Uri.parse('$_baseUrl/api/profile');
    final response = await _Net.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Failed to load profile');
    }
    return Map<String, dynamic>.from(body);
  }

  static Future<void> updateProfile(
    String token, {
    String? name,
    String? nickname,
    String? description,
    int? avatarIndex,
    bool? isDark,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/profile');
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (nickname != null) payload['nickname'] = nickname;
    if (description != null) payload['description'] = description;
    if (avatarIndex != null) payload['avatar_index'] = avatarIndex;
    if (isDark != null) payload['is_dark'] = isDark;

    final response = await _Net.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Failed to update profile');
    }
  }

  static Future<List<Map<String, dynamic>>> getHistory(String token) async {
    final uri = Uri.parse('$_baseUrl/api/history');
    final response = await _Net.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Failed to load history');
    }
    return List<Map<String, dynamic>>.from(body);
  }

  static Future<void> addHistory(
    String token,
    Map<String, String> flowerData,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/history');
    final response = await _Net.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(flowerData),
    );
    if (response.statusCode != 201) {
      final body = _decode(response);
      throw Exception(body['error'] ?? 'Failed to save history');
    }
  }

  static Future<bool> toggleFavorite(String token, int historyId) async {
    final uri = Uri.parse('$_baseUrl/api/history/$historyId/favorite');
    final response = await _Net.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Failed to update favorite');
    }
    return body['is_favorite'] as bool? ?? false;
  }

  static Future<void> deleteHistory(String token, int historyId) async {
    final uri = Uri.parse('$_baseUrl/api/history/$historyId');
    final response = await _Net.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      final body = _decode(response);
      throw Exception(body['error'] ?? 'Failed to delete history');
    }
  }

  static Future<void> submitFeedback(
    String token, {
    required String gmail,
    required String subject,
    required String message,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/feedback');
    final response = await _Net.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'gmail': gmail,
        'subject': subject,
        'message': message,
      }),
    );
    if (response.statusCode != 201) {
      final body = _decode(response);
      throw Exception(body['error'] ?? 'Failed to submit feedback');
    }
  }

  static Future<List<Map<String, dynamic>>> getChatHistory(String token) async {
    final uri = Uri.parse('$_baseUrl/api/chat/history');
    final response = await _Net.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Failed to load chat history');
    }
    return List<Map<String, dynamic>>.from(body);
  }

  static Future<Map<String, dynamic>> getChatConversation(
    String token,
    int historyId,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/chat/history/$historyId');
    final response = await _Net.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Failed to load chat conversation');
    }
    return Map<String, dynamic>.from(body);
  }

  static Future<int> saveChatConversation(
    String token, {
    int? id,
    required String title,
    required List<Map<String, String>> messages,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat/history');
    final payload = <String, dynamic>{'title': title, 'messages': messages};
    if (id != null) {
      payload['id'] = id;
    }
    final response = await _Net.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Failed to save chat conversation');
    }
    return body['id'] as int? ?? 0;
  }

  // ── Session / account ────────────────────────────────────────────

  static Future<void> logout(String token) async {
    try {
      await _Net.post(
        Uri.parse('$_baseUrl/api/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {
      // Logging out locally must still work when offline.
    }
  }

  static Future<void> deleteAccount(String token) async {
    final response = await _Net.delete(
      Uri.parse('$_baseUrl/api/account'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      final body = _decode(response);
      throw Exception(body['error'] ?? 'Failed to delete account');
    }
  }

  // ── AI (the Groq key now lives on the server) ────────────────────

  static Future<String> _aiPost(
    String token,
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await _Net
        .post(
          Uri.parse('$_baseUrl/api/ai/$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
          timeout: const Duration(seconds: 90),
        );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'AI request failed');
    }
    return (body['content'] ?? '') as String;
  }

  static Future<String> aiScan(
    String token,
    String imageBase64,
    String mimeType,
  ) =>
      _aiPost(token, 'scan', {
        'image_base64': imageBase64,
        'mime_type': mimeType,
      });

  static Future<String> aiChat(
    String token,
    List<Map<String, String>> messages,
  ) =>
      _aiPost(token, 'chat', {'messages': messages});

  static Future<String> aiIdentify(String token, String description) =>
      _aiPost(token, 'identify', {'description': description});

  static Future<String> aiCareGuide(
    String token,
    Map<String, String> flowerData,
  ) =>
      _aiPost(token, 'care-guide', {
        'name': flowerData['name'] ?? '',
        'scientific': flowerData['scientific'] ?? '',
        'origin': flowerData['origin'] ?? '',
      });

  // ── Cloud file storage (Supabase, via our server) ────────────────

  /// Uploads a photo and returns its permanent public URL.
  static Future<String> uploadImage(
    String token,
    String imageBase64,
    String mimeType,
  ) async {
    final response = await _Net.post(
      Uri.parse('$_baseUrl/api/upload'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'image_base64': imageBase64, 'mime_type': mimeType}),
      timeout: const Duration(seconds: 60),
    );
    final body = _decode(response);
    if (response.statusCode != 201) {
      throw Exception(body['error'] ?? 'Failed to upload image');
    }
    return (body['url'] ?? '') as String;
  }
}
