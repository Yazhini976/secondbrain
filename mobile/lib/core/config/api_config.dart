/// Centralized API Configuration for Second Brain backend.
class ApiConfig {
  /// Production / build-time API URL passed via:
  /// `flutter run --dart-define=API_URL=https://your-api.com/api/v1` or
  /// `flutter build apk --dart-define=API_URL=https://your-api.com/api/v1`
  static const String _envApiUrl = String.fromEnvironment('API_URL');

  /// Base URL for backend REST API.
  /// Uses `--dart-define=API_URL` if configured, otherwise defaults to production Render backend.
  static String baseUrl = _envApiUrl.isNotEmpty
      ? _envApiUrl
      : 'https://secondbrain-api-hjfb.onrender.com/api/v1';

  /// Candidate URLs for automatic fallback when running on physical device,
  /// cloud production, USB ADB reverse port forwarding, or Android emulator.
  static List<String> get candidateUrls => [
    if (_envApiUrl.isNotEmpty) _envApiUrl,
    'https://secondbrain-api-hjfb.onrender.com/api/v1',
    'http://127.0.0.1:8000/api/v1',
    'http://10.35.94.190:8000/api/v1',
    'http://10.0.2.2:8000/api/v1',
  ];

  /// Auth token provider callback.
  /// Returns current Firebase ID token or test token.
  static Future<String?> Function()? authTokenProvider;
}

