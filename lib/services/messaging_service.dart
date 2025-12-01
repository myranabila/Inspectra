import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MessagingService {
  static final String baseUrl = '${ApiConfig.baseUrl}/messaging';

  // Send message
  static Future<Map<String, dynamic>> sendMessage({
    int? inspectionId, // Made optional for general messages
    required int receiverId,
    int? replyToId, // For reply threading
    String? subject,
    required String content,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        url: '$baseUrl/send',
        body: {
          'inspection_id': inspectionId,
          'receiver_id': receiverId,
          'reply_to_id': replyToId,
          'subject': subject,
          'content': content,
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for inspection
  static Future<List<dynamic>> getInspectionMessages(int inspectionId) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getList(
        url: '$baseUrl/inspection/$inspectionId',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  // Get all user messages
  static Future<List<dynamic>> getMyMessages() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getList(
        url: '$baseUrl/my-messages',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  // Get unread count
  static Future<int> getUnreadCount() async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.get(
        url: '$baseUrl/unread-count',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response['unread_count'] as int;
    } catch (e) {
      return 0;
    }
  }

  // Mark message as read
  static Future<void> markAsRead(int messageId) async {
    try {
      final token = await AuthService.getToken();
      await ApiService.post(
        url: '$baseUrl/mark-read/$messageId',
        body: {},
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Get all users for messaging
  static Future<List<dynamic>> getAllUsers() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getList(
        url: '$baseUrl/users',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  // Get conversation threads (Gmail-style)
  static Future<List<dynamic>> getThreads() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getList(
        url: '$baseUrl/threads',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to load threads: $e');
    }
  }

  // Get messages in a thread
  static Future<List<dynamic>> getThreadMessages(String threadId) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getList(
        url: '$baseUrl/thread/$threadId',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to load thread messages: $e');
    }
  }

  // Send message in thread (simplified - receiver determined from thread)
  static Future<Map<String, dynamic>> sendMessageInThread({
    required int receiverId,
    required String content,
    int? inspectionId,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        url: '$baseUrl/send',
        body: {
          'receiver_id': receiverId,
          'content': content,
          'inspection_id': inspectionId,
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Create reminder
  static Future<Map<String, dynamic>> createReminder({
    required int inspectionId,
    required String title,
    String? message,
    required DateTime remindAt,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
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
      return response;
    } catch (e) {
      throw Exception('Failed to create reminder: $e');
    }
  }

  // Get user reminders
  static Future<List<dynamic>> getMyReminders() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getList(
        url: '$baseUrl/reminder/my-reminders',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to load reminders: $e');
    }
  }

  // Get pending reminders
  static Future<List<dynamic>> getPendingReminders() async {
    try {
      final token = await AuthService.getToken();
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
    try {
      final token = await AuthService.getToken();
      await ApiService.post(
        url: '$baseUrl/reminder/dismiss/$reminderId',
        body: {},
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Failed to dismiss reminder: $e');
    }
  }
}
