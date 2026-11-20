Floriety — Claude analysis bundle

This bundle contains the current Flutter app, Android build configuration,
Flask API/admin dashboard, backend container files, and HTML design prototypes.

Project layout
- server.py: Flask API using Supabase Postgres and Supabase Storage.
- admin.py: Streamlit admin dashboard.
- requirements.txt and Dockerfile: backend Python dependencies and container entry point.
- floriety/lib: Flutter app screens, routes, services, and theme.
- floriety/android: Android app and Gradle configuration.
- floriety/assets: app assets, except large profile avatar images.
- floriety_nocturnal and the top-level screen folders: design references.

Important context
- The Android Gradle configuration was updated for the installed Flutter 3.50
  toolchain (Gradle 9.5.0, Android Gradle Plugin 9.3.1, Kotlin 2.4.20).
- Backend credentials are read from environment variables, not included in
  this bundle: DATABASE_URL, GROQ_API_KEY, ADMIN_KEY, SUPABASE_URL, and
  SUPABASE_SECRET_KEY. SUPABASE_BUCKET and PORT are optional.
- The app reads API_BASE_URL at build time. Its default is a placeholder;
  Android emulator testing uses http://10.0.2.2:5000, while USB testing with
  `adb reverse tcp:5000 tcp:5000` uses
  `--dart-define=API_BASE_URL=http://127.0.0.1:5000`.
- server.py's header says the Supabase schema is created by `floriety.sql`,
  but no SQL file is present in the scanned project.
- The old floriety.db file is not used by the current Supabase-backed server
  and is intentionally not included.
- local.properties, generated build/cache files, virtual environments, and
  any local secrets are intentionally not included.
- Large floriety/assets/profile_avatar images are omitted to keep the bundle
  manageable. Other app assets and UI mockup screenshots are included.
- *.original service files are included as historical context, not as the
  currently active implementation.

To run locally
- Backend: install `requirements.txt`, provide the required Supabase and
  service credentials, then run `python server.py` from the project root.
- Production backend: `Dockerfile` starts Gunicorn and binds to PORT (default
  5000).
- Flutter: run `flutter pub get`, then `flutter run` from `floriety/`, passing
  API_BASE_URL for the chosen emulator/device.
- The database and machine-specific Android SDK settings are not bundled.
