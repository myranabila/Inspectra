import 'package:flutter/material.dart';
import 'services/messaging_service.dart';
import 'theme/app_theme.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<dynamic> _reminders = [];
  bool _isLoading = true;
  String? _error;

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
      final reminders = await MessagingService.getMyReminders();
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _dismissReminder(int reminderId) async {
    try {
      await MessagingService.dismissReminder(reminderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder dismissed'),
          backgroundColor: Colors.green,
        ),
      );
      _loadReminders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to dismiss reminder: $e'),
          backgroundColor: Colors.red,
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
          'My Reminders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppTheme.inspectorPrimary,
        foregroundColor: Colors.white,
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
                    onPressed: _loadReminders,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: AppTheme.primaryButton,
                  ),
                ],
              ),
            )
          : _reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text('No reminders', style: AppTheme.headingSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Set reminders for your tasks',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadReminders,
              color: AppTheme.inspectorPrimary,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final reminder = _reminders[index];
                  final status = reminder['status'] as String;
                  final remindAt = DateTime.parse(reminder['remind_at']);
                  final isPending = status == 'pending';
                  final isPast = remindAt.isBefore(DateTime.now());

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.cardBorderRadius,
                      boxShadow: [AppTheme.cardShadow],
                      border: isPending && isPast
                          ? Border.all(color: Colors.orange, width: 2)
                          : null,
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
                                  reminder['title'],
                                  style: AppTheme.headingSmall,
                                ),
                              ),
                              AppTheme.statusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.assignment,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    reminder['inspection_title'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (reminder['message'] != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              reminder['message'],
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.alarm,
                                size: 18,
                                color: isPast
                                    ? Colors.orange
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                remindAt
                                    .toString()
                                    .substring(0, 16)
                                    .replaceAll('T', ' '),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isPast
                                      ? Colors.orange
                                      : Colors.grey.shade700,
                                ),
                              ),
                              if (isPast && isPending) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'OVERDUE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (isPending) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _dismissReminder(reminder['id']),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Dismiss'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.inspectorPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppTheme.buttonBorderRadius,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
