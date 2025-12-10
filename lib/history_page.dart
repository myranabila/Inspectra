import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/api_config.dart';
import 'services/auth_service.dart';
import 'inspection_workflow_page.dart';
import 'my_tasks_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> _inspections = [];
  int _totalCount = 0;
  bool _isLoading = true;
  String? _error;

  // Filter state
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    print('====================================');
    print('HISTORY PAGE INITIALIZED - FILTERS SHOULD BE VISIBLE');
    print('====================================');
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    print('[HISTORY] Loading history with filter: status=$_selectedStatus');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (_selectedStatus != 'all') {
        queryParams['status'] = _selectedStatus;
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/dashboard/history',
      ).replace(queryParameters: queryParams);

      print('[HISTORY] Making request to: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[HISTORY] Response status: ${response.statusCode}');
      print('[HISTORY] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[HISTORY] Received ${data['total_count']} inspections');
        setState(() {
          _totalCount = data['total_count'];
          _inspections = data['inspections'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _loadHistory();
  }



  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'pending_review':
        return Colors.purple;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled':
        return Icons.calendar_today;
      case 'pending_review':
        return Icons.pending_actions;
      case 'rejected':
        return Icons.edit_note;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'SCHEDULED';
      case 'pending_review':
        return 'UNDER REVIEW';
      case 'rejected':
        return 'REJECTED';
      case 'completed':
        return 'COMPLETED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.assignment_turned_in,
                      size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Inspector Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('My Tasks'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyTasksPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              selected: true,
              selectedTileColor: Colors.blue.shade50,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Messages'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/messages');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'Inspection History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Quick Status Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedStatus == 'all',
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedStatus = 'all';
                        });
                        _applyFilters();
                      },
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue.shade700,
                    ),
                    FilterChip(
                      label: const Text('Scheduled'),
                      selected: _selectedStatus == 'scheduled',
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedStatus = selected ? 'scheduled' : 'all';
                        });
                        _applyFilters();
                      },
                      selectedColor: Colors.orange.shade100,
                      checkmarkColor: Colors.orange.shade700,
                    ),
                    FilterChip(
                      label: const Text('Pending Review'),
                      selected: _selectedStatus == 'pending_review',
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedStatus = selected ? 'pending_review' : 'all';
                        });
                        _applyFilters();
                      },
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue.shade700,
                    ),
                    FilterChip(
                      label: const Text('Rejected'),
                      selected: _selectedStatus == 'rejected',
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedStatus = selected ? 'rejected' : 'all';
                        });
                        _applyFilters();
                      },
                      selectedColor: Colors.red.shade100,
                      checkmarkColor: Colors.red.shade700,
                    ),
                    FilterChip(
                      label: const Text('Completed'),
                      selected: _selectedStatus == 'completed',
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedStatus = selected ? 'completed' : 'all';
                        });
                        _applyFilters();
                      },
                      selectedColor: Colors.green.shade100,
                      checkmarkColor: Colors.green.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Count section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Tasks: $_totalCount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List section
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadHistory, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_inspections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No inspection history found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _inspections.length,
      itemBuilder: (context, index) {
        final inspection = _inspections[index];
        return _buildInspectionCard(inspection);
      },
    );
  }

  Widget _buildInspectionCard(Map<String, dynamic> inspection) {
    final status = inspection['status'] as String;
    final statusColor = _getStatusColor(status);
    final isRejected = status == 'rejected';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRejected
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  InspectionWorkflowPage(inspection: inspection),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (inspection['rejection_count'] != null &&
                      inspection['rejection_count'] > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Rejected ${inspection['rejection_count']}x',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                inspection['title'] ?? 'Untitled',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      inspection['location'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              // Equipment info
              if (inspection['equipment_id'] != null ||
                  inspection['equipment_type'] != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${inspection['equipment_id'] ?? 'N/A'} - ${inspection['equipment_type'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              // Scheduled date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    inspection['scheduled_date'] != null
                        ? 'Scheduled: ${inspection['scheduled_date']}'
                        : 'Not scheduled',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
              // Completion date for completed tasks
              if (inspection['completion_date'] != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Completed: ${inspection['completion_date']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              // Rejection info
              if (isRejected &&
                  (inspection['rejection_reason'] != null ||
                      inspection['rejection_feedback'] != null)) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rejection Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (inspection['rejection_reason'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          inspection['rejection_reason'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (inspection['rejection_feedback'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          inspection['rejection_feedback'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
