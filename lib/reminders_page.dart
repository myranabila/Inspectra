import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'theme/app_theme.dart';
import 'widgets/collapsible_sidebar.dart';
import 'services/dashboard_service.dart';
import 'inspection_workflow_page.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> with SingleTickerProviderStateMixin {
  List<dynamic> _activeTasks = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  bool _showLegend = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    
    // Auto-refresh every 30 seconds to update countdown timers
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadTasks();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await DashboardService.getMyTasks();
      
      if (mounted) {
        setState(() {
          // Only get active tasks (exclude completed and pending_review)
          _activeTasks = tasks.where((t) => 
            t['status'] != 'completed' && 
            t['status'] != 'pending_review'
          ).toList();
          
          // Sort active tasks by due date (most urgent first)
          _activeTasks.sort((a, b) {
            final aDate = DateTime.tryParse(a['scheduled_date'] ?? '') ?? DateTime.now().add(const Duration(days: 999));
            final bDate = DateTime.tryParse(b['scheduled_date'] ?? '') ?? DateTime.now().add(const Duration(days: 999));
            return aDate.compareTo(bDate);
          });
          
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _viewInspection(Map<String, dynamic> task) async {
    try {
      final inspectionId = task['id'];
      final inspection = await DashboardService.getInspectionDetails(inspectionId);
      
      if (mounted && inspection != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionWorkflowPage(
              inspection: inspection,
            ),
          ),
        ).then((_) => _loadTasks()); // Refresh when returning
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(
            context: context,
            message: 'Failed to load inspection: $e',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Row(
        children: [
          const CollapsibleSidebar(currentPage: 'reminders'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                if (_showLegend) _buildStatusLegend(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _error != null
                          ? _buildErrorState()
                          : _buildTasksList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final overdueCount = _activeTasks.where((task) {
      final dueDate = DateTime.tryParse(task['scheduled_date'] ?? '');
      return dueDate != null && dueDate.isBefore(DateTime.now());
    }).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: overdueCount > 0 
                  ? AppTheme.statusRejected.withValues(alpha: 0.1)
                  : AppTheme.accentYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              overdueCount > 0 
                  ? Icons.notification_important_rounded
                  : Icons.notifications_active_rounded,
              color: overdueCount > 0 ? AppTheme.statusRejected : AppTheme.accentYellow,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Task Reminders',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Automatically tracked from assigned tasks',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _showLegend 
                  ? AppTheme.primaryRed.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showLegend 
                    ? AppTheme.primaryRed.withValues(alpha: 0.2)
                    : Colors.grey.shade200,
              ),
            ),
            child: IconButton(
              icon: Icon(
                _showLegend ? Icons.visibility_off_rounded : Icons.info_outline_rounded,
                color: _showLegend ? AppTheme.primaryRed : AppTheme.textSecondary,
              ),
              onPressed: () => setState(() => _showLegend = !_showLegend),
              tooltip: _showLegend ? 'Hide Priority Guide' : 'Show Priority Guide',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadTasks,
              tooltip: 'Refresh',
              color: AppTheme.primaryRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegend() {
    return Container(
      margin: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.primaryRed),
              const SizedBox(width: 8),
              Text(
                'Priority Status Guide',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                onPressed: () => setState(() => _showLegend = false),
                tooltip: 'Hide guide',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildLegendItem(
                Icons.error_rounded,
                'OVERDUE',
                'Past the due date - Immediate action required',
                AppTheme.statusRejected,
              ),
              _buildLegendItem(
                Icons.warning_rounded,
                'URGENT',
                'Less than 24 hours remaining - High priority',
                AppTheme.primaryRed,
              ),
              _buildLegendItem(
                Icons.schedule_rounded,
                'SOON',
                'Due within 7 days - Plan accordingly',
                AppTheme.accentYellow,
              ),
              _buildLegendItem(
                Icons.calendar_today_rounded,
                'UPCOMING',
                'More than 7 days away - Monitor progress',
                AppTheme.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, String description, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTasksList() {
    if (_activeTasks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.task_alt_rounded,
        title: 'No active reminders',
        subtitle: 'All assigned tasks are completed. Great job!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: _activeTasks.length,
      itemBuilder: (context, index) {
        final task = _activeTasks[index];
        return _buildTaskCard(task, isActive: true);
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, {required bool isActive}) {
    final dueDate = DateTime.tryParse(task['scheduled_date'] ?? '') ?? DateTime.now();
    final title = task['title'] ?? 'Inspection Task';
    final location = task['location'] ?? '';
    final equipmentType = task['equipment_type'] ?? '';
    
    // Calculate time difference for priority
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    final isOverdue = difference.isNegative;
    
    // Determine priority color for active tasks only
    Color priorityColor;
    String priorityLabel;
    IconData priorityIcon;
    
    if (isOverdue) {
      priorityColor = AppTheme.statusRejected;
      priorityLabel = 'OVERDUE';
      priorityIcon = Icons.error_rounded;
    } else if (difference.inHours < 24) {
      priorityColor = AppTheme.primaryRed;
      priorityLabel = 'URGENT';
      priorityIcon = Icons.warning_rounded;
    } else if (difference.inDays < 7) {
      priorityColor = AppTheme.accentYellow;
      priorityLabel = 'SOON';
      priorityIcon = Icons.schedule_rounded;
    } else {
      priorityColor = AppTheme.textMuted;
      priorityLabel = 'UPCOMING';
      priorityIcon = Icons.calendar_today_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: isActive && isOverdue
            ? Border.all(color: AppTheme.statusRejected, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _viewInspection(task),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(priorityIcon, size: 14, color: priorityColor),
                          const SizedBox(width: 6),
                          Text(
                            priorityLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: priorityColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Title
                Row(
                  children: [
                    Icon(Icons.assignment_rounded, size: 20, color: AppTheme.primaryRed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Equipment Info
                if (equipmentType.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.precision_manufacturing_rounded, size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        equipmentType,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Location
                if (location.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        location,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Due Date
                Row(
                  children: [
                    Icon(Icons.event_rounded, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Due: ${_formatDateTime(dueDate)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isOverdue && isActive ? AppTheme.statusRejected : AppTheme.textSecondary,
                        fontWeight: isOverdue && isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _viewInspection(task),
                    icon: const Icon(Icons.work_outline_rounded, size: 18),
                    label: const Text('Start Inspection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownTimer(Duration difference, Color color) {
    String countdownText;
    
    if (difference.isNegative) {
      final absDiff = difference.abs();
      if (absDiff.inDays > 0) {
        countdownText = '${absDiff.inDays}d overdue';
      } else if (absDiff.inHours > 0) {
        countdownText = '${absDiff.inHours}h overdue';
      } else {
        countdownText = '${absDiff.inMinutes}m overdue';
      }
    } else {
      if (difference.inDays > 0) {
        countdownText = '${difference.inDays}d ${difference.inHours % 24}h';
      } else if (difference.inHours > 0) {
        countdownText = '${difference.inHours}h ${difference.inMinutes % 60}m';
      } else {
        countdownText = '${difference.inMinutes}m';
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        countdownText,
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 48, color: AppTheme.accentYellow),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primaryRed,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading tasks...',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Failed to load tasks',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
