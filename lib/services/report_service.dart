import '../config/api_config.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportService {
  static final String baseUrl = '${ApiConfig.baseUrl}/report';

  static Future<Map<String, dynamic>> submitReport(int inspectionId, Map<String, dynamic> reportData) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/submit/$inspectionId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(reportData),
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> approveReport(int reportId) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/approve/$reportId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> rejectReport(int reportId, String reason) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/reject/$reportId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'reason': reason}),
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> resubmitReport(int reportId, Map<String, dynamic> reportData) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/resubmit/$reportId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(reportData),
    );
    return json.decode(response.body);
  }
}
