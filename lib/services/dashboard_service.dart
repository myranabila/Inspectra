import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;

class DashboardService {
  // Get monthly statistics
  static Future<Map<String, dynamic>> getStats({String period = "all"}) async {
    final token = await AuthService.getToken();

    final response = await ApiService.get(
      url: '${ApiConfig.baseUrl}/dashboard/stats?period=$period',
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
      print('[DEBUG] getMyTasks response: $response');
      return response;
    } catch (e) {
      print('[ERROR] getMyTasks failed: $e');
      throw Exception('Failed to load tasks: $e');
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

  // Get all inspections for inspector
  static Future<List<dynamic>> getAllInspections() async {
    final token = await AuthService.getToken();

    try {
      final response = await ApiService.getList(
        url: '${ApiConfig.baseUrl}/dashboard/inspections/all',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to load all inspections: $e');
    }
  }

  // Get completed inspections (Reports Generated)
  static Future<List<dynamic>> getCompletedInspections() async {
    final token = await AuthService.getToken();

    try {
      final response = await ApiService.getList(
        url: '${ApiConfig.baseUrl}/dashboard/inspections/completed',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to load completed inspections: $e');
    }
  }

  // Get pending review inspections
  static Future<List<dynamic>> getPendingReviewInspections() async {
    final token = await AuthService.getToken();

    try {
      final response = await ApiService.getList(
        url: '${ApiConfig.baseUrl}/dashboard/inspections/pending-review',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to load pending review inspections: $e');
    }
  }

  // Get inspections completed this month
  static Future<List<dynamic>> getCompletedThisMonth() async {
    final token = await AuthService.getToken();

    try {
      final response = await ApiService.getList(
        url: '${ApiConfig.baseUrl}/dashboard/inspections/completed-this-month',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to load completed this month: $e');
    }
  }

  // Get inspections that are in progress or scheduled
  static Future<List<dynamic>> getInProgressScheduled() async {
    final token = await AuthService.getToken();

    try {
      final response = await ApiService.getList(
        url: '${ApiConfig.baseUrl}/dashboard/inspections/scheduled',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to load in progress/scheduled: $e');
    }
  }

  // Submit inspection report
  static Future<void> submitInspectionReport({
    required int inspectionId,
    required String findings,
    required String recommendations,
    String? notes,
    List<int>? pdfBytes,
  }) async {
    final token = await AuthService.getToken();

    try {
      if (pdfBytes != null) {
        // Use multipart/form-data for file upload
        final uri = Uri.parse('${ApiConfig.baseUrl}/dashboard/inspections/$inspectionId/submit');
        final request = http.MultipartRequest('POST', uri);
        
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['findings'] = findings;
        request.fields['recommendations'] = recommendations;
        if (notes != null) request.fields['notes'] = notes;
        
        // Add PDF file
        request.files.add(http.MultipartFile.fromBytes(
          'pdf_file',
          pdfBytes,
          filename: 'inspection_$inspectionId.pdf',
        ));
        
        final response = await request.send();
        if (response.statusCode != 200) {
          final responseBody = await response.stream.bytesToString();
          throw Exception('Server returned ${response.statusCode}: $responseBody');
        }
      } else {
        // Regular JSON submission without PDF
        await ApiService.post(
          url: '${ApiConfig.baseUrl}/dashboard/inspections/$inspectionId/submit',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: {
            'findings': findings,
            'recommendations': recommendations,
            if (notes != null) 'notes': notes,
          },
        );
      }
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }
}
