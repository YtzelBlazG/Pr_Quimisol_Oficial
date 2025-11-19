class Env {
  // Puedes sobreescribir con: --dart-define=API_BASE_URL=http://10.0.2.2:3005
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3005',
  );
}
