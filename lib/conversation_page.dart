import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ConversationPage extends StatefulWidget {
  final int? threadId;
  final String otherUserName;
  final int otherUserId;
  final String subject;

  const ConversationPage({
    super.key,
    this.threadId,
    required this.otherUserName,
    required this.otherUserId,
    required this.subject,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();



}

class _ConversationPageState extends State<ConversationPage> {
    PlatformFile? _selectedFile;
  List<dynamic> _messages = [];
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    // TODO: Replace with real API call for conversation messages
    // For now, mock messages for demonstration
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _messages = [
        {
          'id': 1,
          'sender_id': widget.otherUserId,
          'sender_name': widget.otherUserName,
          'content': 'Hello! This is the start of our chat.',
          'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'is_sender': false,
        },
        {
          'id': 2,
          'sender_id': 0,
          'sender_name': 'Me',
          'content': 'Hi! Ready to discuss?',
          'created_at': DateTime.now().toIso8601String(),
          'is_sender': true,
        },
      ];
      _isLoading = false;
    });
  }

  List<dynamic> _groupMessagesByDate(List<dynamic> messages) {
    final List<dynamic> grouped = [];
    String? lastDateLabel;
    final now = DateTime.now();
    for (final msg in messages) {
      final createdAt = DateTime.tryParse(msg['created_at'] ?? '') ?? now;
      String dateLabel;
      if (createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day) {
        dateLabel = 'Today';
      } else {
        dateLabel = "${createdAt.year.toString().padLeft(4, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";
      }
      if (dateLabel != lastDateLabel) {
        grouped.add({'_dateLabel': dateLabel});
        lastDateLabel = dateLabel;
      }
      grouped.add(msg);
    }
    return grouped;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedFile == null) return;
    setState(() => _isLoading = true);
    // TODO: Replace with real sendMessage API call (with file upload)
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _messages.add({
        'id': _messages.length + 1,
        'sender_id': 0,
        'sender_name': 'Me',
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
        'is_sender': true,
        'attachment_url': _selectedFile != null ? _selectedFile!.path : null,
        'attachment_type': _selectedFile != null && _selectedFile!.extension != null && ['jpg','jpeg','png','gif'].contains(_selectedFile!.extension!.toLowerCase()) ? 'image' : 'file',
        'attachment_name': _selectedFile?.name,
      });
      _isLoading = false;
      _controller.clear();
      _selectedFile = null;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: AppTheme.managerPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: false,
                    padding: const EdgeInsets.all(16),
                    itemCount: _groupMessagesByDate(_messages).length,
                    itemBuilder: (context, index) {
                      final item = _groupMessagesByDate(_messages)[index];
                      if (item is Map && item.containsKey('_dateLabel')) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Expanded(child: Divider(thickness: 1, color: Colors.grey.shade300)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  item['_dateLabel'],
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(thickness: 1, color: Colors.grey.shade300)),
                            ],
                          ),
                        );
                      }
                      final msg = item;
                      final isMe = msg['is_sender'] == true;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (msg['attachment_url'] != null && msg['attachment_type'] == 'image')
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Image.file(
                                    File(msg['attachment_url']),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (msg['attachment_url'] != null && msg['attachment_type'] == 'file')
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.insert_drive_file, size: 20),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          msg['attachment_name'] ?? 'File',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if ((msg['content'] ?? '').isNotEmpty)
                                Text(msg['content'] ?? '', style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.blueGrey),
                  onPressed: _pickFile,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                      if (_selectedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (_selectedFile!.extension != null && ['jpg','jpeg','png','gif'].contains(_selectedFile!.extension!.toLowerCase()))
                                Image.file(
                                  File(_selectedFile!.path!),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                )
                              else
                                const Icon(Icons.insert_drive_file, size: 32),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedFile!.name,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _selectedFile = null),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
