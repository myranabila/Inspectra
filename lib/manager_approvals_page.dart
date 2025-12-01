import 'package:flutter/material.dart';
import 'services/manager_service.dart';
import 'services/messaging_service.dart';
import 'theme/app_theme.dart';

class ManagerApprovalsPage extends StatefulWidget {
  const ManagerApprovalsPage({super.key});

  @override
  State<ManagerApprovalsPage> createState() => _ManagerApprovalsPageState();
}

class _ManagerApprovalsPageState extends State<ManagerApprovalsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _allInspections = [];
  List<dynamic> _pendingInspections = [];
  List<dynamic> _pendingReports = [];
  bool _isLoadingAll = true;
  bool _isLoadingInspections = true;
  bool _isLoadingReports = true;
  String? _errorAll;
  String? _errorInspections;
  String? _errorReports;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPendingItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingItems() async {
    await Future.wait([
      _loadAllInspections(),
      _loadPendingInspections(),
      _loadPendingReports(),
    ]);
  }

  Future<void> _loadAllInspections() async {
    setState(() {
      _isLoadingAll = true;
      _errorAll = null;
    });

    try {
      final inspections = await ManagerService.getAllInspections();
      setState(() {
        _allInspections = inspections;
        _isLoadingAll = false;
      });
    } catch (e) {
      setState(() {
        _errorAll = e.toString();
        _isLoadingAll = false;
      });
    }
  }

  Future<void> _loadPendingInspections() async {
    setState(() {
      _isLoadingInspections = true;
      _errorInspections = null;
    });

    try {
      final inspections = await ManagerService.getPendingInspections();
      setState(() {
        _pendingInspections = inspections;
        _isLoadingInspections = false;
      });
    } catch (e) {
      setState(() {
        _errorInspections = e.toString();
        _isLoadingInspections = false;
      });
    }
  }

  Future<void> _loadPendingReports() async {
    setState(() {
      _isLoadingReports = true;
      _errorReports = null;
    });

    try {
      final reports = await ManagerService.getPendingReports();
      setState(() {
        _pendingReports = reports;
        _isLoadingReports = false;
      });
    } catch (e) {
      setState(() {
        _errorReports = e.toString();
        _isLoadingReports = false;
      });
    }
  }

  Future<void> _handleInspectionAction(int inspectionId, String action) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          action == "approve" ? "Approve Inspection" : "Reject Inspection",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to $action this inspection?'),
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
              backgroundColor: action == "approve" ? Colors.green : Colors.red,
            ),
            child: Text(action == "approve" ? "Approve" : "Reject"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ManagerService.approveInspection(
          inspectionId,
          action,
          notes: notesController.text.isNotEmpty ? notesController.text : null,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inspection ${action}d successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _loadPendingInspections();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action inspection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReportAction(int reportId, String action) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == "approve" ? "Approve Report" : "Reject Report"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to $action this report?'),
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
              backgroundColor: action == "approve" ? Colors.green : Colors.red,
            ),
            child: Text(action == "approve" ? "Approve" : "Reject"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ManagerService.approveReport(
          reportId,
          action,
          notes: notesController.text.isNotEmpty ? notesController.text : null,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report ${action}d successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _loadPendingReports();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage(
    int inspectionId,
    int inspectorId,
    String inspectionTitle,
  ) async {
    final subjectController = TextEditingController();
    final contentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send message about: $inspectionTitle'),
            const SizedBox(height: 16),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
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
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (contentController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a message'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        await MessagingService.sendMessage(
          inspectionId: inspectionId,
          receiverId: inspectorId,
          subject: subjectController.text.isNotEmpty
              ? subjectController.text
              : null,
          content: contentController.text,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
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
          'Task Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppTheme.managerPrimary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.list_alt),
              text: 'All Tasks (${_allInspections.length})',
            ),
            Tab(
              icon: const Icon(Icons.pending_actions),
              text: 'Pending Approval (${_pendingInspections.length})',
            ),
            Tab(
              icon: const Icon(Icons.description),
              text: 'Reports (${_pendingReports.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllInspectionsTab(),
          _buildPendingInspectionsTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildAllInspectionsTab() {
    if (_isLoadingAll) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorAll != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorAll'),
            ElevatedButton(
              onPressed: _loadAllInspections,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_allInspections.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No tasks assigned yet'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllInspections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allInspections.length,
        itemBuilder: (context, index) {
          final inspection = _allInspections[index];
          final status = inspection['status'] as String;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: AppTheme.cardBorderRadius,
              boxShadow: [AppTheme.cardShadow],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          inspection['title'] ?? 'Untitled',
                          style: AppTheme.headingSmall,
                        ),
                      ),
                      AppTheme.statusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (inspection['scheduled_date'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scheduled: ${inspection['scheduled_date']}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        inspection['inspector'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        inspection['location'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (inspection['notes'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Notes: ${inspection['notes']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                  if (status == 'pending_review') ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => _sendMessage(
                            inspection['id'],
                            inspection['inspector_id'],
                            inspection['title'] ?? 'Untitled',
                          ),
                          icon: const Icon(Icons.message, size: 18),
                          label: const Text('Message'),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _handleInspectionAction(
                                inspection['id'],
                                'reject',
                              ),
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
                  ] else ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => _sendMessage(
                            inspection['id'],
                            inspection['inspector_id'],
                            inspection['title'] ?? 'Untitled',
                          ),
                          icon: const Icon(Icons.message, size: 18),
                          label: const Text('Message'),
                        ),
                        Text(
                          status == 'scheduled'
                              ? 'Waiting for inspector to start'
                              : status == 'in_progress'
                              ? 'Inspector is working on this'
                              : status == 'completed'
                              ? 'Task completed'
                              : 'View only',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingInspectionsTab() {
    if (_isLoadingInspections) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorInspections != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorInspections'),
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
                  if (inspection['notes'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Notes: ${inspection['notes']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 12),
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

  Widget _buildReportsTab() {
    if (_isLoadingReports) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorReports != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorReports'),
            ElevatedButton(
              onPressed: _loadPendingReports,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pendingReports.isEmpty) {
      return const Center(child: Text('No pending reports'));
    }

    return RefreshIndicator(
      onRefresh: _loadPendingReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingReports.length,
        itemBuilder: (context, index) {
          final report = _pendingReports[index];
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
                          report['title'] ?? 'Untitled',
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
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PENDING',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Created by: ${report['created_by'] ?? 'N/A'}'),
                  Text('Inspection: ${report['inspection'] ?? 'N/A'}'),
                  if (report['findings'] != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Findings:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(report['findings']),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _handleReportAction(report['id'], 'reject'),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _handleReportAction(report['id'], 'approve'),
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
}
