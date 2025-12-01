import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

class DashboardService {
  // Get monthly statistics
  static Future<Map<String, dynamic>> getMonthlyStats() async {
    final token = await AuthService.getToken();

    final response = await ApiService.get(
      url: '${ApiConfig.baseUrl}/dashboard/stats/monthly',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response;
  }

  // Get inspector's assigned tasks
  static Future<List<dynamic>> getMyTasks() async {
    final token = await AuthService.getToken();

    try {
      final response = await ApiService.getList(
        url: '${ApiConfig.baseUrl}/dashboard/my-tasks',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      // Error logged
      return [];
    }
  }

  // Get recent inspections
  static Future<List<dynamic>> getRecentInspections({int limit = 5}) async {
    final token = await AuthService.getToken();

    try {
      final response = await ApiService.getList(
        url: '${ApiConfig.baseUrl}/dashboard/inspections/recent?limit=$limit',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      // Error logged
      return [];
    }
  }

  // Get recent reports
  static Future<List<dynamic>> getRecentReports({int limit = 5}) async {
    final token = await AuthService.getToken();

    try {
      final response = await ApiService.getList(
        url: '${ApiConfig.baseUrl}/dashboard/reports/recent?limit=$limit',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      // Error logged
      return [];
    }
  }
}
