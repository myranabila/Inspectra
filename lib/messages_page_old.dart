import 'package:flutter/material.dart';
import 'services/messaging_service.dart';
import 'theme/app_theme.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await MessagingService.getMyMessages();
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showMessageDetail(Map<String, dynamic> message) async {
    // Mark as read if unread
    if (!message['is_sender'] && message['status'] == 'unread') {
      await MessagingService.markAsRead(message['id']);
      _loadMessages();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message['subject'] ?? 'Message', style: AppTheme.headingSmall),
            const SizedBox(height: 4),
            if (message['inspection_title'] != null)
              Text(
                'Re: ${message['inspection_title']}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.managerPrimary,
                ),
              )
            else
              Text(
                'General Message',
                style: AppTheme.bodySmall.copyWith(color: Colors.grey),
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'From: ${message['sender_name']}',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    message['created_at'].substring(0, 16).replaceAll('T', ' '),
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(message['content'], style: AppTheme.bodyLarge),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!message['is_sender'])
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _replyToMessage(message);
              },
              icon: const Icon(Icons.reply, size: 18),
              label: const Text('Reply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.managerPrimary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _replyToMessage(Map<String, dynamic> originalMessage) async {
    final subjectController = TextEditingController(
      text: originalMessage['subject']?.startsWith('Re:') == true
          ? originalMessage['subject']
          : 'Re: ${originalMessage['subject'] ?? 'Message'}',
    );
    final contentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.reply, color: AppTheme.managerPrimary),
            const SizedBox(width: 8),
            Text('Reply to ${originalMessage['sender_name']}',
                style: AppTheme.headingSmall),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show original message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original message:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      originalMessage['content'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration:
                    AppTheme.inputDecoration('Subject', icon: Icons.subject),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration:
                    AppTheme.inputDecoration('Your reply', icon: Icons.message),
                maxLines: 5,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send Reply'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.managerPrimary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (contentController.text.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your reply'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final result = await MessagingService.sendMessage(
          receiverId: originalMessage['sender_id'],
          replyToId: originalMessage['id'],
          subject:
              subjectController.text.isNotEmpty ? subjectController.text : null,
          content: contentController.text,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reply sent to ${result['sent_to'] ?? 'recipient'}'),
            backgroundColor: Colors.green,
          ),
        );

        _loadMessages();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reply: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _composeNewMessage() async {
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

      int? selectedUserId;
      final subjectController = TextEditingController();
      final contentController = TextEditingController();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('New Message', style: AppTheme.headingSmall),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Send to:', style: AppTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        hint: const Text('Select user'),
                        value: selectedUserId,
                        items: users.map<DropdownMenuItem<int>>((user) {
                          // Ensure ID is integer
                          final userId = user['id'] is int
                              ? user['id']
                              : int.parse(user['id'].toString());
                          return DropdownMenuItem<int>(
                            value: userId,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: user['role'] == 'manager'
                                        ? AppTheme.managerPrimary.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppTheme.inspectorPrimary.withValues(
                                            alpha: 0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user['role'].toString().toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: user['role'] == 'manager'
                                          ? AppTheme.managerPrimary
                                          : AppTheme.inspectorPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['full_name'] ?? user['username'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        user['email'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedUserId = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: subjectController,
                    decoration: AppTheme.inputDecoration(
                      'Subject',
                      icon: Icons.subject,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    decoration: AppTheme.inputDecoration(
                      'Message',
                      icon: Icons.message,
                    ),
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Send'),
                style: AppTheme.primaryButton.copyWith(
                  backgroundColor: WidgetStateProperty.all(
                    AppTheme.managerPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (confirmed == true) {
        if (selectedUserId == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a recipient'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (contentController.text.trim().isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a message'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final result = await MessagingService.sendMessage(
          receiverId: selectedUserId!,
          subject: subjectController.text.isNotEmpty
              ? subjectController.text
              : null,
          content: contentController.text,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Message sent to ${result['sent_to'] ?? 'recipient'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadMessages();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppTheme.managerPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh messages',
            onPressed: _loadMessages,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _composeNewMessage,
        backgroundColor: AppTheme.managerPrimary,
        icon: const Icon(Icons.edit),
        label: const Text('New Message'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: $_error', style: AppTheme.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadMessages,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: AppTheme.primaryButton,
                  ),
                ],
              ),
            )
          : _messages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text('No messages yet', style: AppTheme.headingSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Messages about tasks will appear here',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMessages,
              color: AppTheme.managerPrimary,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUnread =
                      !message['is_sender'] && message['status'] == 'unread';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isUnread ? Colors.blue.shade50 : Colors.white,
                      borderRadius: AppTheme.cardBorderRadius,
                      boxShadow: [AppTheme.cardShadow],
                      border: isUnread
                          ? Border.all(
                              color: AppTheme.managerPrimary.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            )
                          : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message['is_sender']
                              ? AppTheme.inspectorPrimary.withValues(alpha: 0.1)
                              : AppTheme.managerPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          message['is_sender'] ? Icons.send : Icons.inbox,
                          color: message['is_sender']
                              ? AppTheme.inspectorPrimary
                              : AppTheme.managerPrimary,
                        ),
                      ),
                      title: Row(
                        children: [
                          if (message['reply_to_id'] != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.reply,
                                  size: 16, color: Colors.grey.shade600),
                            ),
                          Expanded(
                            child: Text(
                              message['subject'] ?? 'No subject',
                              style: AppTheme.headingSmall.copyWith(
                                fontSize: 16,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.managerPrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            message['is_sender']
                                ? 'To: ${message['receiver_name']}'
                                : 'From: ${message['sender_name']}',
                            style: AppTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          if (message['inspection_title'] != null)
                            Text(
                              'Re: ${message['inspection_title']}',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.managerPrimary,
                              ),
                            )
                          else
                            Text(
                              'General Message',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            message['created_at']
                                .substring(0, 16)
                                .replaceAll('T', ' '),
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                      onTap: () => _showMessageDetail(message),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
