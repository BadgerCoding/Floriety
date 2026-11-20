FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server.py .

ENV PYTHONUNBUFFERED=1

# Data lives in Supabase, so this server needs no disk or volume.
# One worker with several threads keeps database connections within Supabase's limits.
CMD ["sh", "-c", "gunicorn server:app --bind 0.0.0.0:${PORT:-5000} --workers 1 --threads 8 --timeout 120"]
