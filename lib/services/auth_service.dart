import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  // Login method
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await ApiService.post(
      url: ApiConfig.loginUrl,
      body: {'username': username, 'password': password},
    );

    // Save token to local storage
    if (response['access_token'] != null) {
      await _saveToken(response['access_token']);
    }

    return response;
  }

  // Get current user profile
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await ApiService.get( // Should point to /profile/me
      url: '${ApiConfig.baseUrl}/profile/me',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response;
  }

  // Save token to local storage
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);

    // Also fetch and save user role
    try {
      final user = await getCurrentUser();
      if (user['role'] != null) {
        await prefs.setString('user_role', user['role']);
        await prefs.setString('user_name', user['username']);
      }
    } catch (e) {
      // Failed to fetch user role
    }
  }

  /// Fetches the current user's data and updates local storage.
  /// This is useful for refreshing the UI after a profile update.
  static Future<void> refreshUserData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final user = await getCurrentUser();
      await prefs.setString('user_role', user['role']);
      await prefs.setString('user_name', user['username']);
    } catch (e) {
      print("Failed to refresh user data: $e");
    }
  }

  // Get token from local storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get user role from local storage
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  // Get user name from local storage
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Logout (clear token)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
  }

  // Check backend health
  static Future<bool> checkBackendHealth() async {
    try {
      final response = await ApiService.get(url: ApiConfig.healthUrl);
      return response['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }
}
