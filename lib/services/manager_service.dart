import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ManagerService {
  static final String baseUrl = '${ApiConfig.baseUrl}/manager';

  // Assign task to inspector
  static Future<Map<String, dynamic>> assignTask({
    required int inspectorId,
    required String title,
    required String location,
    String? scheduledDate,
    String? notes,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        url: '$baseUrl/assign-task',
        body: {
          'inspector_id': inspectorId,
          'title': title,
          'location': location,
          'scheduled_date': scheduledDate,
          'notes': notes,
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to assign task: $e');
    }
  }

  // Get all inspections (for viewing and approval)
  static Future<List<dynamic>> getAllInspections() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getList(
        url: '$baseUrl/inspections',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to load inspections: $e');
    }
  }

  // Get pending inspections for approval
  static Future<List<dynamic>> getPendingInspections() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getList(
        url: '$baseUrl/pending/inspections',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to load pending inspections: $e');
    }
  }

  // Get pending reports for approval
  static Future<List<dynamic>> getPendingReports() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getList(
        url: '$baseUrl/pending/reports',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to load pending reports: $e');
    }
  }

  // Approve or reject inspection
  static Future<Map<String, dynamic>> approveInspection(
    int inspectionId,
    String action, {
    String? notes,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        url: '$baseUrl/approve/inspection',
        body: {'inspection_id': inspectionId, 'action': action, 'notes': notes},
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to $action inspection: $e');
    }
  }

  // Approve or reject report
  static Future<Map<String, dynamic>> approveReport(
    int reportId,
    String action, {
    String? notes,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        url: '$baseUrl/approve/report',
        body: {'report_id': reportId, 'action': action, 'notes': notes},
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to $action report: $e');
    }
  }

  // Get all inspectors
  static Future<List<dynamic>> getInspectors() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getList(
        url: '$baseUrl/inspectors',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to load inspectors: $e');
    }
  }

  // Get inspector statistics
  static Future<Map<String, dynamic>> getInspectorStats(int inspectorId) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get(
        url: '$baseUrl/inspector/$inspectorId/stats',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to load inspector stats: $e');
    }
  }
}
