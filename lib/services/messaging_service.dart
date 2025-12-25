import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;

class MessagingService {
  static final String baseUrl = '${ApiConfig.baseUrl}/messaging';

  // Get conversation threads
  static Future<List<dynamic>> getThreads() async {
    final token = await AuthService.getToken();
    try {
      return await ApiService.getList(
        url: '$baseUrl/threads',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print('[ERROR] Failed to load threads: $e');
      return [];
    }
  }

  // Get messages for a specific thread
  static Future<List<dynamic>> getThreadMessages(String threadId) async {
    final token = await AuthService.getToken();
    try {
      return await ApiService.getList(
        url: '$baseUrl/thread/$threadId',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print('[ERROR] Failed to load thread messages: $e');
      throw Exception('Failed to load messages');
    }
  }

  // Get all users for starting a chat
  static Future<List<dynamic>> getAllUsers() async {
    final token = await AuthService.getToken();
    return await ApiService.getList(
      url: '$baseUrl/users',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // Send message (supports file attachment)
  static Future<Map<String, dynamic>> sendMessage({
    required int receiverId,
    required String content,
    String? subject,
    int? replyToId,
    int? inspectionId,
    List<int>? attachmentBytes,
    String? attachmentName,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/send');
    
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    
    request.fields['receiver_id'] = receiverId.toString();
    request.fields['content'] = content;
    
    if (subject != null) request.fields['subject'] = subject;
    if (replyToId != null) request.fields['reply_to_id'] = replyToId.toString();
    if (inspectionId != null) request.fields['inspection_id'] = inspectionId.toString();
    
    if (attachmentBytes != null && attachmentName != null) {
      // Determine content type based on extension just in case, though usually optional
      request.files.add(http.MultipartFile.fromBytes(
        'attachment',
        attachmentBytes,
        filename: attachmentName,
      ));
    }

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        // Successful
        return {}; // Could return decoded JSON if needed
      } else {
        throw Exception('Failed to send message: ${response.statusCode} - $respStr');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get unread count
  static Future<int> getUnreadCount() async {
    final token = await AuthService.getToken();
    try {
      final response = await ApiService.get(
        url: '$baseUrl/unread-count',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response['unread_count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Create reminder
  static Future<Map<String, dynamic>> createReminder({
    required int inspectionId,
    required String title,
    String? message,
    required DateTime remindAt,
  }) async {
    final token = await AuthService.getToken();
    try {
      return await ApiService.post(
        url: '$baseUrl/reminder/create',
        body: {
          'inspection_id': inspectionId,
          'title': title,
          'message': message,
          'remind_at': remindAt.toIso8601String(),
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to set reminder: $e');
    }
  }

  // Get pending reminders
  static Future<List<dynamic>> getPendingReminders() async {
    final token = await AuthService.getToken();
    try {
      return await ApiService.getList(
        url: '$baseUrl/reminder/pending',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      return [];
    }
  }

  // Dismiss reminder
  static Future<void> dismissReminder(int reminderId) async {
    final token = await AuthService.getToken();
    try {
      await ApiService.post(
        url: '$baseUrl/reminder/dismiss/$reminderId',
        body: {},
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // Ignore
    }
  }
}
