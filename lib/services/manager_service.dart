import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ManagerService {
  static final String baseUrl = '${ApiConfig.baseUrl}/manager';

  // Assign task to inspector with manager-defined title and sections
  static Future<Map<String, dynamic>> assignTask({
    required int inspectorId,
    required String inspectionTitle, // Manager-defined inspection title
    required String inspectionType,
    required String equipmentTag,
    String? doshRegistration,  // DOSH Registration Number (optional)
    required String location,
    required String dueDate,
    required bool requireExternal,
    required bool requireWeld,
    required bool requireInternal,
    required bool requireThickness,
    List<String> initialConditions = const [],
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        url: '$baseUrl/assign-task',
        body: {
          'inspector_id': inspectorId,
          'title': inspectionTitle, // Manager-defined title
          'inspection_type': inspectionType,
          'equipment_tag': equipmentTag,
          'dosh_registration': doshRegistration,  // DOSH Registration Number
          'location': location,
          'due_date': dueDate,
          'require_external': requireExternal,
          'require_weld': requireWeld,
          'require_internal': requireInternal,
          'require_thickness': requireThickness,
          'initial_conditions': initialConditions.join(','),
          'status': 'scheduled',
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

  // Approve inspection
  static Future<Map<String, dynamic>> approveInspection(
    int inspectionId, {
    String? notes,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        url: '$baseUrl/approve/inspection?inspection_id=$inspectionId',
        body: {
          'notes': notes,
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to approve inspection: $e');
    }
  }

  // Reject inspection with detailed reason
  static Future<Map<String, dynamic>> rejectInspection(
    int inspectionId,
    String rejectionReason, {
    String? feedback,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        url: '$baseUrl/reject/inspection?inspection_id=$inspectionId',
        body: {
          'rejection_reason': rejectionReason,
          'rejection_feedback': feedback,
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to reject inspection: $e');
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

  // Reassign a rejected inspection to same or different inspector
  static Future<Map<String, dynamic>> reassignInspection(
    int inspectionId,
    int inspectorId, {
    String? notes,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        url: '$baseUrl/reassign/inspection?inspection_id=$inspectionId',
        body: {
          'inspector_id': inspectorId,
          'notes': notes,
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to reassign inspection: $e');
    }
  }

  // Update inspection details (Area and Equipment Type)
  static Future<Map<String, dynamic>> updateInspectionDetails({
    required int inspectionId,
    required String area,
    required String equipmentType,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        url: '$baseUrl/update/inspection?inspection_id=$inspectionId',
        body: {
          'location': area,
          'inspection_type': equipmentType,
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to update inspection: $e');
    }
  }

  // Get list of locations
  static Future<List<dynamic>> getLocations() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getList(
        url: '${ApiConfig.baseUrl}/api/locations',  // Correct endpoint for locations
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to load locations: $e');
    }
  }
  // Delete inspection
  static Future<void> deleteInspection(int inspectionId) async {
    try {
      final token = await AuthService.getToken();
      await ApiService.delete(
        url: '$baseUrl/delete/inspection/$inspectionId',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to delete inspection: $e');
    }
  }
}
