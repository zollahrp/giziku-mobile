class ApiConfig {
  // API Base URL - Change this to your actual API endpoint
  // For development, you might use a local server:
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator accessing localhost
  // static const String baseUrl = 'http://localhost:8000/api'; // iOS simulator
  static const String baseUrl =
      'https://kqt1clq7-8000.asse.devtunnels.ms'; // Development

  // Auth Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String googleAuthEndpoint = '/auth/google';

  // User Endpoints
  static const String userProfileEndpoint = '/users/me';
  static const String updateUserProfileEndpoint = '/users/me';
  static const String changePasswordEndpoint = '/users/password';

  // Nutrition Tracking Endpoints
  static const String nutritionLogsEndpoint = '/nutrition';
  static const String waterIntakeEndpoint = '/water-intake';
  static const String foodSearchEndpoint = '/food/search';
  static const String recentFoodsEndpoint = '/food/recent';

  // Health Data Endpoints
  static const String healthMetricsEndpoint = '/health/metrics';
  static const String weightHistoryEndpoint = '/health/weight-history';

  // Goals Endpoints
  static const String nutritionGoalsEndpoint = '/goals/nutrition';
  static const String activityGoalsEndpoint = '/goals/activity';

  // Network configuration
  static const int connectionTimeout = 15000; // 15 seconds
  static const int receiveTimeout = 15000; // 15 seconds
  static const int sendTimeout = 15000; // 15 seconds

  // Pagination defaults
  static const int defaultPageSize = 20;

  // Header keys
  static const String authHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String apiKeyHeader = 'X-API-Key';
}
