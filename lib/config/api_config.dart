class ApiConfig {
  // Base URL for the backend API
  // Change this to your backend server address
  static const String baseUrl = 'http://127.0.0.1:8000';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String healthEndpoint = '/health';

  // Full URLs
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get registerUrl => '$baseUrl$registerEndpoint';
  static String get healthUrl => '$baseUrl$healthEndpoint';
}
