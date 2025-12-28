import 'package:flutter/material.dart';
import 'services/dashboard_service.dart';
import 'theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'inspection_workflow_page.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await DashboardService.getMyTasks();
      final reminders = _generateReminders(tasks);

      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateReminders(List<dynamic> tasks) {
    final List<Map<String, dynamic>> reminders = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var task in tasks) {
      if (task['scheduled_date'] == null) continue;
      
      try {
        final dueDate = DateTime.parse(task['scheduled_date'].toString());
        final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
        final difference = taskDate.difference(today).inDays;

        if (difference >= 1 && difference <= 5) {
          reminders.add({
            'task': task,
            'days_remaining': difference,
            'title': task['title'] ?? 'Untitled Task',
            'date': dueDate,
            'type': 'Due Date'
          });
        }
      } catch (e) {
        // Skip invalid dates
        continue;
      }
    }

    // Sort by days remaining (lowest first)
    reminders.sort((a, b) => (a['days_remaining'] as int).compareTo(b['days_remaining'] as int));
    return reminders;
  }

  Future<void> _refresh() async {
    await _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: AppTheme.inspectorPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
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
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: _reminders.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No active reminders',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Reminders will appear here when tasks \nare due within 5 days.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reminders.length,
                          itemBuilder: (context, index) {
                            final reminder = _reminders[index];
                            final days = reminder['days_remaining'] as int;
                            final date = reminder['date'] as DateTime;
                            final formattedDate = DateFormat('MMM d, y').format(date);
                            
                            Color color;
                            String label;
                            
                            if (days <= 1) {
                              color = Colors.red;
                              label = 'Due Tomorrow';
                            } else if (days <= 3) {
                              color = Colors.orange;
                              label = 'Due in $days Days';
                            } else {
                              color = Colors.blue;
                              label = 'Due in $days Days';
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: color.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  label,
                                                  style: TextStyle(
                                                    color: color,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                formattedDate,
                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            reminder['title'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Task Reminder • Please prepare for this inspection.',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                if (reminder['task'] != null) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => InspectionWorkflowPage(
                                                        inspection: reminder['task'],
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              icon: const Icon(Icons.play_arrow, size: 16),
                                              label: const Text('Start Inspection'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}