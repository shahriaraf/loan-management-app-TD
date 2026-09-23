class ApiConstants {
  // Change this to your backend URL
  // For Android emulator use 10.0.2.2 instead of localhost
  // For real device use your machine's LAN IP e.g. http://192.168.1.10:8000
  static const String baseUrl = 'http://localhost:5000';

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String me = '/api/auth/me';
  static const String refresh = '/api/auth/refresh';
  static const String updateProfile = '/api/auth/profile';
  static const String generate2FA = '/api/auth/2fa/generate';
  static const String verify2FA = '/api/auth/2fa/verify';
  static const String login2FA = '/api/auth/login/verify-2fa';

  // Customers
  static const String customers = '/api/customers';

  // Groups
  static const String groups = '/api/groups';

  // Loans
  static const String loanProducts = '/api/loans/products';
  static const String loanApplications = '/api/loans/applications';

  // Settings
  static const String loanPurposes = '/api/settings/loan-purposes';
  static const String dashboardStats = '/api/settings/dashboard/stats';

  // Upload
  static const String upload = '/api/upload';

  // Health
  static const String health = '/health';
}
