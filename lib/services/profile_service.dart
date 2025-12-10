import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

class ProfileService {
  static const String baseUrl = ApiConfig.baseUrl;

  // ==================== Common Profile Methods ====================

  static Future<Map<String, dynamic>> getMyProfile() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/profile/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> updateMyProfile({
    String? username,
    String? email,
    String? phone,
    int? yearsExperience,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (yearsExperience != null) body['years_experience'] = yearsExperience;

    final response = await http.put(
      Uri.parse('$baseUrl/profile/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      // After a successful update, refresh the locally stored user data
      // to ensure the UI reflects the changes immediately.
      await AuthService.refreshUserData();

      return json.decode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> updateMyPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$baseUrl/profile/me/password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update password');
    }
  }

  // ==================== Manager-Only Methods ====================

  static Future<List<Map<String, dynamic>>> getAllUsers({bool includeInactive = false}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/profile/users?include_inactive=$includeInactive'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('[DEBUG] getAllUsers response: status=${response.statusCode}, body=${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // The backend returns a map {'users': [...]}, so we extract the list.
      if (data['users'] is List) {
        return List<Map<String, dynamic>>.from(data['users']);
      } else {
        throw Exception('Failed to parse users list from response');
      }
    } else {
      throw Exception('Failed to load users: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getUser(int userId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/profile/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> createUser({
    required String username,
    String? password,
    required String email,
    required String role,
    String? phone,
    int? yearsExperience,
    bool generateTempPassword = false,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = {
      'username': username,
      'email': email,
      'role': role,
      'generate_temp_password': generateTempPassword,
    };

    if (password != null) body['password'] = password;
    if (phone != null) body['phone'] = phone;
    if (yearsExperience != null) body['years_experience'] = yearsExperience;

    final response = await http.post(
      Uri.parse('$baseUrl/profile/users'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to create user');
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? username,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
    int? yearsExperience,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (role != null) body['role'] = role;
    if (isActive != null) body['is_active'] = isActive;
    if (yearsExperience != null) body['years_experience'] = yearsExperience;

    final response = await http.put(
      Uri.parse('$baseUrl/profile/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update user');
    }
  }

  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('$baseUrl/profile/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to delete user');
    }
  }

  static Future<Map<String, dynamic>> deactivateUser(int userId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$baseUrl/profile/users/$userId/deactivate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to deactivate user');
    }
  }

  static Future<Map<String, dynamic>> activateUser(int userId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$baseUrl/profile/users/$userId/activate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to activate user');
    }
  }

  static Future<Map<String, dynamic>> resetUserPassword({
    required int userId,
    String? newPassword,
    bool generateTempPassword = false,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = {
      'user_id': userId,
      'generate_temp_password': generateTempPassword,
    };

    if (newPassword != null) body['new_password'] = newPassword;

    final response = await http.post(
      Uri.parse('$baseUrl/profile/users/$userId/reset-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to reset password');
    }
  }

  static Future<List<dynamic>> getInspectorsWithStats({String period = "all"}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      // Note: This endpoint is in manager.py, but we are keeping user-related services here for now.
      // In a larger app, this might move to a dedicated ManagerService.
      Uri.parse('$baseUrl/inspectors?period=$period'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // The backend returns a direct list for this endpoint
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load inspector stats');
    }
  }
}
