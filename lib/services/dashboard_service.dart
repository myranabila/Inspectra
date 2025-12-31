import 'dart:convert';
import 'dart:typed_data';
import '../config/api_config.dart';
import '../utils/cache_manager.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class DashboardService {
  static final _cache = CacheManager();
  
  // Get monthly statistics with caching
  static Future<Map<String, dynamic>> getStats({String period = "all", bool forceRefresh = false}) async {
    final cacheKey = 'stats_$period';
    
    // Return cached data if available and not forcing refresh
    if (!forceRefresh) {
      final cached = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) return cached;
    }
    
    final token = await AuthService.getToken();

    final response = await ApiService.get(
      url: '${ApiConfig.baseUrl}/dashboard/stats?period=$period',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // Cache the response for 3 minutes
    _cache.set(cacheKey, response, duration: const Duration(minutes: 3));
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

  // Submit API 510 Visual Inspection Report
  static Future<void> submitVisualInspectionReport({
    required int inspectionId,
    required String inspectionDate,
    required String equipmentFinding,
    required String equipmentRecommendation,
    required String externalFinding,
    required String externalRecommendation,
    required String weldFinding,
    required String weldRecommendation,
    required bool internalAccessible,
    String? internalFinding,
    String? internalRecommendation,
    required List<Map<String, String>> thicknessData,
    required String overallCondition,
    required String generalRecommendation,
    List<dynamic>? photoFiles,
    required Map<String, int> photoSections,
    Uint8List? pdfBytes,  // NEW: Accept the generated PDF bytes
  }) async {
    final token = await AuthService.getToken();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/dashboard/inspections/$inspectionId/submit-visual-report');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      
      // Metadata
      request.fields['inspection_date'] = inspectionDate;
      request.fields['report_type'] = 'API 510 Visual Inspection';
      
      // Section A: Equipment Identification
      request.fields['equipment_finding'] = equipmentFinding;
      request.fields['equipment_recommendation'] = equipmentRecommendation;
      
      // Section B: External Visual
      request.fields['external_finding'] = externalFinding;
      request.fields['external_recommendation'] = externalRecommendation;
      
      // Section C: Weld Visual
      request.fields['weld_finding'] = weldFinding;
      request.fields['weld_recommendation'] = weldRecommendation;
      
      // Section D: Internal Visual (if applicable)
      request.fields['internal_accessible'] = internalAccessible.toString();
      if (internalAccessible) {
        request.fields['internal_finding'] = internalFinding ?? 'Nil';
        request.fields['internal_recommendation'] = internalRecommendation ?? 'Nil';
      }
      
      // Section E: Thickness Measurement
      request.fields['thickness_data'] = jsonEncode(thicknessData);
      
      // Section F: Summary
      request.fields['overall_condition'] = overallCondition;
      request.fields['general_recommendation'] = generalRecommendation;
      
      // Photo sections
      request.fields['photo_sections'] = jsonEncode(photoSections);
      
      // CRITICAL: Set status to pending_review
      request.fields['status'] = 'pending_review';
      
      // NEW: Add the generated PDF file
      if (pdfBytes != null && pdfBytes.isNotEmpty) {
        print('[PDF] Attaching PDF file: ${pdfBytes.length} bytes');
        request.files.add(http.MultipartFile.fromBytes(
          'pdf_file',
          pdfBytes,
          filename: 'inspection_${inspectionId}_report.pdf',
          contentType: MediaType('application', 'pdf'),
        ));
        print('[PDF] PDF file attached successfully');
      } else {
        print('[PDF] WARNING: No PDF bytes to attach!');
      }
      
      // Add photo files
      if (photoFiles != null) {
        for (int i = 0; i < photoFiles.length; i++) {
          final file = photoFiles[i];
          if (file.path != null) {
            final bytes = await file.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
              'photos',
              bytes,
              filename: 'photo_${i + 1}.jpg',
            ));
          }
        }
      }
      
      final response = await request.send();
      if (response.statusCode != 200 && response.statusCode != 201) {
        final responseBody = await response.stream.bytesToString();
        throw Exception('Server returned ${response.statusCode}: $responseBody');
      }
      
      print('[SUCCESS] Visual Inspection Report submitted with PDF, status: pending_review');
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  // Get strict dashboard metrics with role-based scoping and filtering
  static Future<Map<String, dynamic>> getDashboardMetrics({String period = 'all'}) async {
    try {
      List<dynamic> inspections = [];
      
      // 1. Determine Scope based on Role
      final role = await AuthService.getUserRole();
      if (role?.toLowerCase() == 'manager') {
        inspections = await getAllInspections(); 
      } else {
        inspections = await getMyTasks(); 
      }

      final now = DateTime.now();
      DateTime? startDate;
      
      if (period == 'year') {
        startDate = DateTime(now.year, 1, 1);
      } else if (period == 'month') {
        startDate = DateTime(now.year, now.month, 1);
      } else if (period == 'week') {
         // Assuming Monday start. weekday 1=Mon.
         startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      } else if (period == 'today') {
         startDate = DateTime(now.year, now.month, now.day);
      }
      
      int total = 0;
      int scheduled = 0;
      int pendingReview = 0;
      int completed = 0;
      int rejected = 0;
      int overdue = 0;
      
      for (var inspection in inspections) {
        // Filter by Date
        final dateStr = inspection['scheduled_date'] ?? inspection['created_at'];
        if (startDate != null && dateStr != null) {
            final date = DateTime.tryParse(dateStr);
            if (date == null || date.isBefore(startDate)) continue; 
        }

        total++;
        
        final rawStatus = inspection['status']?.toString().toLowerCase() ?? '';
        final status = rawStatus.trim();
        
        if (status == 'scheduled') {
          scheduled++;
        } else if (status == 'pending review' || status == 'pending_review' || status == 'pending-review') {
          pendingReview++;
        } else if (status == 'completed') {
          completed++;
        } else if (status == 'rejected') {
          rejected++;
        }
        
        if (status != 'completed' && dateStr != null) {
          final dueDate = DateTime.tryParse(dateStr);
          if (dueDate != null && dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
             overdue++;
          }
        }
      }
      
      return {
        'total': total,
        'scheduled': scheduled,
        'pending_review': pendingReview,
        'completed': completed,
        'rejected': rejected,
        'overdue': overdue,
      };
    } catch (e) {
      print('[ERROR] getDashboardMetrics failed: $e');
      return {
        'total': 0, 'scheduled': 0, 'pending_review': 0, 
        'completed': 0, 'rejected': 0, 'overdue': 0
      };
    }
  }

  // Get upcoming inspections (Next closest scheduled task)
  static Future<Map<String, dynamic>?> getUpcomingInspection() async {
    try {
      final scheduled = await getInProgressScheduled();
      if (scheduled.isEmpty) return null;
      
      // Sort by date ascending
      scheduled.sort((a, b) {
        final dateA = DateTime.tryParse(a['scheduled_date'] ?? '') ?? DateTime.now().add(const Duration(days: 365));
        final dateB = DateTime.tryParse(b['scheduled_date'] ?? '') ?? DateTime.now().add(const Duration(days: 365));
        return dateA.compareTo(dateB);
      });
      
      return scheduled.first;
    } catch (e) {
      print('[ERROR] getUpcomingInspection failed: $e');
      return null;
    }
  }

  // Get recent activities (Using recent inspections as proxy)
  static Future<List<dynamic>> getRecentActivities() async {
    try {
      // Fetch inspections and map them to activity format
      // In a real app, this would be a dedicated activity log endpoint
      final recentInspections = await getRecentInspections(limit: 10);
      
      return recentInspections.map((inspection) {
        final status = inspection['status'] ?? 'updated';
        String action = 'updated inspection';
        if (status == 'completed') action = 'completed inspection';
        if (status == 'scheduled') action = 'scheduled inspection';
        
        return {
          'id': inspection['id'],
          'type': 'inspection',
          'action': action,
          'title': inspection['client_name'] ?? 'Unknown Client',
          'subtitle': inspection['site_location'] ?? 'Unknown Location',
          'timestamp': inspection['updated_at'] ?? inspection['created_at'],
          'status': status,
        };
      }).toList();
    } catch (e) {
       print('[ERROR] getRecentActivities failed: $e');
      return [];
    }
  }
}
