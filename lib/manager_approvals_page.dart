import 'package:flutter/material.dart';
import 'services/manager_service.dart';
import 'services/messaging_service.dart';
import 'services/auth_service.dart';
import 'config/api_config.dart';
import 'theme/app_theme.dart';
import 'dart:html' as html;

class ManagerApprovalsPage extends StatefulWidget {
  final int? initialTab;
  
  const ManagerApprovalsPage({super.key, this.initialTab});

  @override
  State<ManagerApprovalsPage> createState() => _ManagerApprovalsPageState();
}

enum SortBy { date, inspector, priority }

class _ManagerApprovalsPageState extends State<ManagerApprovalsPage> {
  List<dynamic> _pendingInspections = [];
  bool _isLoading = true;
  String? _error;
  
  // Sorting
  SortBy _sortBy = SortBy.date;

  @override
  void initState() {
    super.initState();
    _loadPendingInspections();
  }
  
  void _applySorting(List<dynamic> list) {
    switch (_sortBy) {
      case SortBy.date:
        list.sort((a, b) {
          final dateA = DateTime.tryParse(a['scheduled_date'] ?? '');
          final dateB = DateTime.tryParse(b['scheduled_date'] ?? '');
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB);
        });
        break;
      case SortBy.inspector:
        list.sort((a, b) {
          return (a['inspector'] ?? '').toString().compareTo(
              (b['inspector'] ?? '').toString());
        });
        break;
      case SortBy.priority:
        list.sort((a, b) {
          final priorityA = _getPriorityLevel(a);
          final priorityB = _getPriorityLevel(b);
          return priorityB.compareTo(priorityA);
        });
        break;
    }
  }
  
  int _getPriorityLevel(dynamic item) {
    final scheduledDate = DateTime.tryParse(item['scheduled_date'] ?? '');
    if (scheduledDate == null) return 0;
    
    final now = DateTime.now();
    final diff = scheduledDate.difference(now).inDays;
    
    if (diff < 0) return 4; // Overdue
    if (diff == 0) return 3; // Today
    if (diff == 1) return 3; // Tomorrow
    if (diff <= 7) return 2; // This week
    return 1; // Later
  }
  
  Future<void> _loadPendingInspections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final inspections = await ManagerService.getPendingInspections();
      _applySorting(inspections);
      setState(() {
        _pendingInspections = inspections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleInspectionAction(int inspectionId, String action) async {
    if (action == 'reject') {
      await _handleInspectionRejection(inspectionId);
      return;
    }
    
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Approve Inspection"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to approve this inspection?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text("Approve"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await ManagerService.approveInspection(
        inspectionId,
        notes: notesController.text.trim().isNotEmpty ? notesController.text : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Inspection approved and marked as completed'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _loadPendingInspections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleInspectionRejection(int inspectionId) async {
    final reasonController = TextEditingController();
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text("Reject Inspection"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please provide the reason for rejection:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText: 'e.g., Incomplete data, Does not meet standards',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.error_outline),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (optional)',
                  hintText: 'Any other information for the inspector',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await ManagerService.rejectInspection(
        inspectionId,
        reasonController.text,
        feedback: notesController.text.trim().isNotEmpty ? notesController.text : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Inspection rejected and sent back for revision'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        _loadPendingInspections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage(
    int inspectionId,
    int recipientId,
    String inspectionTitle,
  ) async {
    final messageController = TextEditingController();

    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Message: $inspectionTitle"),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (sent != true || messageController.text.trim().isEmpty) return;

    try {
      await MessagingService.sendMessage(
        receiverId: recipientId,
        content: messageController.text.trim(),
        inspectionId: inspectionId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Pending Approvals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppTheme.managerPrimary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _applySorting(_pendingInspections);
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortBy.date,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18),
                    SizedBox(width: 12),
                    Text('Date'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortBy.inspector,
                child: Row(
                  children: [
                    Icon(Icons.person, size: 18),
                    SizedBox(width: 12),
                    Text('Inspector'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortBy.priority,
                child: Row(
                  children: [
                    Icon(Icons.priority_high, size: 18),
                    SizedBox(width: 12),
                    Text('Priority'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildPendingInspectionsView(),
    );
  }

  Widget _buildPendingInspectionsView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPendingInspections,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pendingInspections.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending_actions, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No inspections pending approval'),
            SizedBox(height: 8),
            Text(
              'Tasks will appear here when inspectors submit them for review',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingInspections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingInspections.length,
        itemBuilder: (context, index) {
          final inspection = _pendingInspections[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          inspection['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PENDING REVIEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (inspection['scheduled_date'] != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Scheduled: ${inspection['scheduled_date']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text('Inspector: ${inspection['inspector'] ?? 'N/A'}'),
                  Text('Location: ${inspection['location'] ?? 'N/A'}'),
                  if (inspection['notes'] != null && inspection['notes'] != '') ...[
                    const SizedBox(height: 4),
                    Text(
                      'Notes: ${inspection['notes']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // View Full Details Button
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewInspectionDetails(inspection),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Full Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple,
                        side: const BorderSide(color: Colors.purple),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _handleInspectionAction(inspection['id'], 'reject'),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _handleInspectionAction(
                          inspection['id'],
                          'approve',
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _viewInspectionDetails(Map<String, dynamic> inspection) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.75,
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inspection['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PENDING REVIEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.person,
                        'Inspector',
                        inspection['inspector'] ?? 'N/A',
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.location_on,
                        'Location',
                        inspection['location'] ?? 'N/A',
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      if (inspection['scheduled_date'] != null)
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Scheduled Date',
                          inspection['scheduled_date'],
                          Colors.orange,
                        ),
                      const SizedBox(height: 12),
                      if (inspection['completion_date'] != null)
                        _buildInfoRow(
                          Icons.check_circle,
                          'Completion Date',
                          inspection['completion_date'],
                          Colors.purple,
                        ),
                      if (inspection['report_findings'] != null && inspection['report_findings'] != '') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Findings:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            inspection['report_findings'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                      if (inspection['report_recommendations'] != null && inspection['report_recommendations'] != '') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Recommendations:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            inspection['report_recommendations'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                      if (inspection['notes'] != null && inspection['notes'] != '') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Notes:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            inspection['notes'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              // PDF View Button
              if (inspection['pdf_report_path'] != null && inspection['pdf_report_path'] != '') ...[
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewPdfReport(inspection['id']),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('View PDF Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleInspectionAction(inspection['id'], 'reject');
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleInspectionAction(inspection['id'], 'approve');
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _viewPdfReport(int inspectionId) async {
    try {
      final token = await AuthService.getToken();
      final url = '${ApiConfig.baseUrl}/dashboard/inspections/$inspectionId/pdf';
      
      // Open PDF in new browser tab
      html.window.open(url, '_blank');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
