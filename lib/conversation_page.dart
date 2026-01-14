import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'widgets/collapsible_sidebar.dart';
import 'package:file_picker/file_picker.dart';
// import 'dart:io'; // REMOVED for Web compatibility
import 'services/messaging_service.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/manager_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config/api_config.dart';
import 'config/api_config.dart';

class ConversationPage extends StatefulWidget {
  final String? threadId;
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
  String? _currentThreadId;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _selectedTaskToShare; // Inspection ID to link
  String? _selectedTaskTitle;

  @override
  void initState() {
    super.initState();
    _currentThreadId = widget.threadId; // string in backend
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (_currentThreadId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final msgs = await MessagingService.getThreadMessages(_currentThreadId!);
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error cleanly
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<dynamic> _groupMessagesByDate(List<dynamic> messages) {
    // ... same logic usually ...
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
    if (text.isEmpty && _selectedFile == null && _selectedTaskToShare == null) return;
    
    // Construct content with embedded task link if selected
    String finalContent = text;
    if (_selectedTaskToShare != null) {
      finalContent = '$finalContent\n[TASK:$_selectedTaskToShare:$_selectedTaskTitle]'.trim();
    }

    // Optimistic UI Update (optional, but tricky with real BE id needed for linking)
    setState(() => _isLoading = true);

    try {
      // Prepare file bytes
      List<int>? fileBytes;
      if (_selectedFile != null) {
        if (_selectedFile!.bytes != null) {
          fileBytes = _selectedFile!.bytes;
        }
        // NOTE: For Web, we rely on bytes. For Native without bytes, we would need dart:io but we removed it.
        // FilePicker withData: true ensures bytes are present.
      }

      await MessagingService.sendMessage(
        receiverId: widget.otherUserId,
        content: finalContent.isEmpty ? 'Sent an attachment' : finalContent,
        subject: widget.subject,
        inspectionId: null, // Keep in current thread, do not fork to inspection thread
        attachmentBytes: fileBytes,
        attachmentName: _selectedFile?.name,
      );

      _controller.clear();
      setState(() {
        _selectedFile = null;
        _selectedTaskToShare = null;
        _selectedTaskTitle = null;
      });

      // Reload messages
      if (_currentThreadId != null) {
        await _loadMessages();
      } else {
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      setState(() => _isLoading = false);
    }
  }
// ...
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true, // Crucial for Web to get bytes
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );
      
      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _shareTask() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share a Task'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<dynamic>>(
            future: DashboardService.getAllInspections(), // Changed to allow Managers to see tasks
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Error loading tasks: ${snapshot.error}');
              }
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return const Text('No tasks found.');
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text(task['title'] ?? 'Inspection #${task['id']}'),
                    subtitle: Text(task['location'] ?? 'No location'),
                    onTap: () {
                      setState(() {
                        _selectedTaskToShare = task['id'];
                        _selectedTaskTitle = task['title'] ?? 'Inspection #${task['id']}';
                      });
                      Navigator.pop(context);
                    },
                  );
                },
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
  }

  Future<void> _handleTaskClick(int inspectionId) async {
    try {
      // Fetch inspection details
      final inspectionDetails = await DashboardService.getInspectionDetails(inspectionId);
      
      final pdfPath = inspectionDetails['pdf_report_path']; // Correct key
      
      if (pdfPath == null || pdfPath.toString().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF not available for this inspection'))
          );
        }
        return;
      }

      // Open PDF in new browser tab
      // Ensure path is URL-friendly
      final cleanPath = pdfPath.toString().replaceAll('\\', '/');
      final pdfUrl = '${ApiConfig.baseUrl}/$cleanPath'; // Ensure slash separator
      
      if (await canLaunchUrl(Uri.parse(pdfUrl))) {
        await launchUrl(
          Uri.parse(pdfUrl),
          mode: LaunchMode.platformDefault,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open PDF'))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: $e'))
        );
      }
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      
      // Optimistic update: remove from list immediately
      setState(() {
         // Create new list to avoid modifying reference if needed, though setState handles rebuild
         // But finding index is better.
      });

      try {
        await MessagingService.deleteMessage(messageId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message deleted'), duration: Duration(seconds: 2)),
          );
          _loadMessages(); // Refresh to ensure sync
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Widget _buildMessages() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
    }

    final groupedMessages = _groupMessagesByDate(_messages);
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      itemCount: groupedMessages.length,
      itemBuilder: (context, index) {
        final item = groupedMessages[index];
        if (item is Map && item.containsKey('_dateLabel')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppTheme.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(item['_dateLabel'], style: GoogleFonts.inter(color: AppTheme.textMuted, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                Expanded(child: Divider(color: AppTheme.divider)),
              ],
            ),
          );
        }
        
        final msg = item;
        final isMe = msg['is_sender'] == true;
        
        // Parse embedded task link
        String content = msg['content'] ?? '';
        String? linkedTaskId;
        String? linkedTaskTitle;
        final taskMatch = RegExp(r'\[TASK:(\d+):(.+?)\]').firstMatch(content);
        if (taskMatch != null) {
          linkedTaskId = taskMatch.group(1);
          linkedTaskTitle = taskMatch.group(2);
          content = content.replaceAll(taskMatch.group(0)!, '').trim();
        }
        
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: isMe ? () => _deleteMessage(msg['id']) : null,
            onSecondaryTap: isMe ? () => _deleteMessage(msg['id']) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryRed : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Linked Task from Content Embedding OR DB
                if (linkedTaskId != null || msg['inspection_id'] != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      onTap: () => _handleTaskClick(int.tryParse(linkedTaskId ?? msg['inspection_id'].toString())!),
                      borderRadius: BorderRadius.circular(10),
                      hoverColor: isMe ? Colors.white.withValues(alpha: 0.1) : AppTheme.primaryRed.withValues(alpha: 0.05),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: isMe ? null : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Icon(Icons.assignment_rounded, size: 20, color: isMe ? Colors.white : AppTheme.primaryRed),
                             const SizedBox(width: 10),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     'Linked Task',
                                     style: GoogleFonts.inter(fontSize: 10, color: isMe ? Colors.white70 : AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                   ),
                                   Text(
                                     linkedTaskTitle ?? msg['inspection_title'] ?? 'Inspection #${linkedTaskId ?? msg['inspection_id']}',
                                     style: GoogleFonts.inter(fontSize: 14, color: isMe ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600),
                                   ),
                                 ],
                               ),
                             )
                          ],
                        ),
                      ),
                    ),
                  ),

                // Image Attachment
                if (msg['attachment_url'] != null && (msg['attachment_type'] == 'image')) ...[
                   Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        msg['attachment_url'].startsWith('http') ? msg['attachment_url'] : '${ApiConfig.baseUrl}/${msg['attachment_url']}',
                        width: 200, 
                        height: 150, 
                        fit: BoxFit.cover,
                        errorBuilder: (c,e,s) => Container(width: 200, height: 100, color: Colors.grey[300], child: Icon(Icons.broken_image)),
                      ),
                    ),
                  )
                ] else if (msg['attachment_url'] != null) ...[
                  // File Attachment
                   Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isMe ? Colors.white : AppTheme.backgroundGrey).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insert_drive_file_rounded, size: 20, color: isMe ? Colors.white70 : AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Flexible(child: Text(msg['attachment_name'] ?? 'File', style: GoogleFonts.inter(fontSize: 12, color: isMe ? Colors.white70 : AppTheme.textSecondary))),
                      ],
                    ),
                  )
                ],

                if (content.isNotEmpty)
                  Text(
                    content,
                    style: GoogleFonts.inter(fontSize: 14, color: isMe ? Colors.white : AppTheme.textPrimary, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.parse(iso).toLocal();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          // Selected Attachment Indicator
          if (_selectedFile != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file_rounded, color: AppTheme.primaryRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_selectedFile!.name, style: GoogleFonts.inter(fontSize: 13), overflow: TextOverflow.ellipsis)),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                    onPressed: () => setState(() => _selectedFile = null),
                  ),
                ],
              ),
            ),
            
          // Selected Task Indicator
          if (_selectedTaskToShare != null)
             Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentYellow),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_rounded, color: AppTheme.accentYellow, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Sharing: $_selectedTaskTitle', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                    onPressed: () => setState(() { _selectedTaskToShare = null; _selectedTaskTitle = null; }),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              // Attach File
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.attach_file_rounded, color: AppTheme.textSecondary),
                  onPressed: _pickFile,
                  tooltip: 'Attach File',
                ),
              ),
              const SizedBox(width: 8),
              
              // Share Task
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.assignment_add, color: AppTheme.textSecondary),
                  onPressed: _shareTask,
                  tooltip: 'Share Task',
                ),
              ),
              
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.coloredShadow(AppTheme.primaryRed),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return const CollapsibleSidebar(
      currentPage: 'messages',
      isMainPage: false, // Conversation is a sub-page of Messages
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryRed, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subject.isNotEmpty ? widget.subject : 'Conversation',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chat with ${widget.otherUserName}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildMessages()),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
