import 'package:flutter/material.dart';
import 'services/manager_service.dart';
import 'theme/app_theme.dart';

class InspectorManagementPage extends StatefulWidget {
  const InspectorManagementPage({super.key});

  @override
  State<InspectorManagementPage> createState() => _InspectorManagementPageState();
}

class _InspectorManagementPageState extends State<InspectorManagementPage> {
  List<Map<String, dynamic>> _inspectors = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'name'; // name, total_tasks, completion_rate, approval_rate

  @override
  void initState() {
    super.initState();
    _loadInspectors();
  }

  Future<void> _loadInspectors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ManagerService.getInspectors();
      setState(() {
        _inspectors = List<Map<String, dynamic>>.from(data);
        _sortInspectors();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _sortInspectors() {
    switch (_sortBy) {
      case 'name':
        _inspectors.sort((a, b) => a['username'].toString().compareTo(b['username'].toString()));
        break;
      case 'total_tasks':
        _inspectors.sort((a, b) => (b['total_tasks'] as int).compareTo(a['total_tasks'] as int));
        break;
      case 'completion_rate':
        _inspectors.sort((a, b) => (b['completion_rate'] as num).compareTo(a['completion_rate'] as num));
        break;
      case 'approval_rate':
        _inspectors.sort((a, b) => (b['approval_rate'] as num).compareTo(a['approval_rate'] as num));
        break;
    }
  }

  Color _getPerformanceColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspector Management'),
        backgroundColor: AppTheme.managerPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInspectors,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInspectors,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Sort options
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _sortBy,
                            items: const [
                              DropdownMenuItem(value: 'name', child: Text('Name')),
                              DropdownMenuItem(value: 'total_tasks', child: Text('Total Tasks')),
                              DropdownMenuItem(value: 'completion_rate', child: Text('Completion Rate')),
                              DropdownMenuItem(value: 'approval_rate', child: Text('Approval Rate')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _sortBy = value;
                                  _sortInspectors();
                                });
                              }
                            },
                          ),
                          const Spacer(),
                          Text(
                            '${_inspectors.length} Inspectors',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Inspector list
                    Expanded(
                      child: _inspectors.isEmpty
                          ? const Center(
                              child: Text(
                                'No inspectors found',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _inspectors.length,
                              itemBuilder: (context, index) {
                                final inspector = _inspectors[index];
                                return _buildInspectorCard(inspector);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInspectorCard(Map<String, dynamic> inspector) {
    final completionRate = inspector['completion_rate'] as num;
    final approvalRate = inspector['approval_rate'] as num;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.managerPrimary,
                  child: Text(
                  inspector['username'].toString()[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inspector['username'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        inspector['email'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Performance indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPerformanceColor(completionRate.toDouble()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getPerformanceColor(completionRate.toDouble()),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: _getPerformanceColor(completionRate.toDouble()),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${completionRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getPerformanceColor(completionRate.toDouble()),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Task Statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Tasks',
                    inspector['total_tasks'].toString(),
                    Icons.assignment,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    inspector['completed_tasks'].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    inspector['pending_review'].toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Scheduled',
                    inspector['scheduled'].toString(),
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Performance Metrics
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Completion Rate',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          Text(
                            '${completionRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _getPerformanceColor(completionRate.toDouble()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: completionRate / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          _getPerformanceColor(completionRate.toDouble()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Approval Rate',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          Text(
                            '${approvalRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _getPerformanceColor(approvalRate.toDouble()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: approvalRate / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          _getPerformanceColor(approvalRate.toDouble()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Reports info
            Text(
              'Reports: ${inspector['approved_reports']}/${inspector['total_reports']} approved',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
