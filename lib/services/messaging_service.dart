import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MessagingService {
    static Future<List<Map<String, dynamic>>> getMyMessages() async {
      final token = await AuthService.getToken();
      // Mock implementation for UI testing
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        {
          'id': 1,
          'sender_id': 2,
          'sender_name': 'Manager',
          'subject': 'Welcome',
          'content': 'Welcome to Inspectra!',
          'created_at': DateTime.now().toIso8601String(),
          'status': 'unread',
          'is_sender': false,
        },
      ];
    }

    static Future<void> markAsRead(int messageId) async {
      final token = await AuthService.getToken();
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 200));
      return;
    }
  static final String baseUrl = '${ApiConfig.baseUrl}/messaging';

  static Future<List<dynamic>> getThreads() async {
    final token = await AuthService.getToken();
    // Mocking response for UI testing as backend endpoint might not exist yet
    return []; 
    /* 
    // Real implementation:
    return await ApiService.getList(
      url: '$baseUrl/threads',
      headers: {'Authorization': 'Bearer $token'},
    );
    */
  }

  static Future<List<dynamic>> getAllUsers() async {
    final token = await AuthService.getToken();
    final response = await ApiService.getList(
      url: '$baseUrl/users',
      headers: {'Authorization': 'Bearer $token'},
    );
    return response;
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int receiverId,
    required String content,
    String? subject,
    int? replyToId,
    int? inspectionId,
  }) async {
    final token = await AuthService.getToken();
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'sent_to': receiverId,
      'subject': subject,
      'reply_to': replyToId,
    };
    /*
    final result = await ApiService.post(
      url: '$baseUrl/send',
      headers: {'Authorization': 'Bearer $token'},
      body: {
        'receiver_id': receiverId,
        'content': content,
        'subject': subject,
        'reply_to_id': replyToId,
        'inspection_id': inspectionId,
      },
    );
    return result;
    */
  }

  static Future<void> createReminder({
    required int inspectionId,
    required String title,
    String? message,
    required DateTime remindAt,
  }) async {
    final token = await AuthService.getToken();
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    /*
    await ApiService.post(
      url: '$baseUrl/reminders',
      headers: {'Authorization': 'Bearer $token'},
      body: {
        'inspection_id': inspectionId,
        'title': title,
        'message': message,
        'remind_at': remindAt.toIso8601String(),
      },
    );
    */
  }
}