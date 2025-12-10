import 'package:flutter/material.dart';
import 'services/messaging_service.dart';
import 'conversation_page.dart';
import 'theme/app_theme.dart';

class ThreadsListPage extends StatefulWidget {
  const ThreadsListPage({super.key});

  @override
  State<ThreadsListPage> createState() => _ThreadsListPageState();
}

class _ThreadsListPageState extends State<ThreadsListPage> {
  List<dynamic> _threads = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final threads = await MessagingService.getThreads();
      setState(() {
        _threads = threads;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openConversation(Map<String, dynamic> thread) async {
    // Navigate to conversation page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationPage(
          threadId: thread['thread_id'],
          otherUserName: thread['participant_name'],
          otherUserId: thread['participant_id'],
          subject: thread['subject'] ?? '',
        ),
      ),
    );

    // Reload threads when coming back (to update unread count, last message, etc.)
    _loadThreads();
  }

  Future<void> _startNewConversation() async {
    try {
      // Load all users
      final users = await MessagingService.getAllUsers();

      if (!mounted) return;

      if (users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No users available for messaging'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show user selection dialog
      final selectedUser = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start Conversation'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.managerPrimary,
                    child: Text( // Use username for initial
                      user['username'][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user['username']),
                  subtitle: Text(user['role']),
                  onTap: () => Navigator.pop(context, user),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedUser != null && mounted) {
        // Create a temporary thread_id for new conversation
        // Backend will handle actual thread_id generation
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationPage(
              threadId: null, // New conversation
              otherUserName: selectedUser['username'],
              otherUserId: selectedUser['id'],
              subject: '',
            ),
          ),
        );

        // Reload threads
        _loadThreads();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppTheme.managerPrimary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadThreads,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _threads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a new conversation',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadThreads,
                      child: ListView.builder(
                        itemCount: _threads.length,
                        itemBuilder: (context, index) {
                          final thread = _threads[index];
                          final hasUnread =
                              thread['unread_count'] != null &&
                                  thread['unread_count'] > 0;

                          return InkWell(
                            onTap: () => _openConversation(thread),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                color: hasUnread
                                    ? Colors.blue.shade50
                                    : Colors.white,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppTheme.managerPrimary,
                                  child: Text(
                                    thread['participant_name'][0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        thread['participant_name'],
                                        style: TextStyle(
                                          fontWeight: hasUnread
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTime(thread['last_message_time']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: hasUnread
                                            ? AppTheme.managerPrimary
                                            : Colors.grey.shade600,
                                        fontWeight: hasUnread
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        thread['last_message_preview'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: hasUnread
                                              ? Colors.black87
                                              : Colors.grey.shade600,
                                          fontWeight: hasUnread
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (hasUnread) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.managerPrimary,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${thread['unread_count']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewConversation,
        backgroundColor: AppTheme.managerPrimary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } catch (e) {
      return '';
    }
  }
}
