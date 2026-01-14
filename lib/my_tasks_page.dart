import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config/api_config.dart';
import 'services/dashboard_service.dart';
import 'services/messaging_service.dart';
import 'theme/app_theme.dart';
import 'inspection_workflow_page.dart';
import 'widgets/collapsible_sidebar.dart';
import 'utils/animations_config.dart';

class MyTasksPage extends StatefulWidget {
  final TaskFilterUrgency? initialUrgencyFilter;
  final Set<String>? initialStatusFilter;
  final bool showAllInspections;
  
  const MyTasksPage({
    super.key,
    this.initialUrgencyFilter,
    this.initialStatusFilter,
    this.showAllInspections = false,
  });

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

enum TaskSortBy { date, priority, status, location }
enum TaskFilterUrgency { all, overdue, today, thisWeek, later }

class _MyTasksPageState extends State<MyTasksPage> {
  bool _isLoading = true;
  List<dynamic> _tasks = [];
  List<dynamic> _filteredTasks = [];
  String? _error;
  
  // Filter states
  String _searchQuery = '';
  Set<String> _selectedStatuses = {};
  TaskFilterUrgency _urgencyFilter = TaskFilterUrgency.all;
  TaskSortBy _sortBy = TaskSortBy.date;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrgencyFilter != null) {
      _urgencyFilter = widget.initialUrgencyFilter!;
      _showFilters = true;
    }
    if (widget.initialStatusFilter != null) {
      _selectedStatuses = widget.initialStatusFilter!;
      _showFilters = true;
    }
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await DashboardService.getMyTasks();
      setState(() {
        _tasks = tasks;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<dynamic> filtered = List.from(_tasks);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        final title = (task['title'] ?? '').toString().toLowerCase();
        final location = (task['location'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || location.contains(query);
      }).toList();
    }

    if (_selectedStatuses.isNotEmpty) {
      filtered = filtered.where((task) => _selectedStatuses.contains(task['status'])).toList();
    }

    // STRICT REQUIREMENT: Pending tasks show items that need inspector action (scheduled + rejected)
    // Exclude pending_review (awaiting manager) and completed (approved, goes to history)
    if (!widget.showAllInspections) {
      filtered = filtered.where((task) {
        final status = task['status'];
        return status == 'scheduled' || status == 'rejected';
      }).toList();
    }

    if (_urgencyFilter != TaskFilterUrgency.all) {
      filtered = filtered.where((task) {
        final dueDate = _parseDate(task['scheduled_date']);
        if (dueDate == null) return _urgencyFilter == TaskFilterUrgency.later;
        
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekEnd = today.add(const Duration(days: 7));

        switch (_urgencyFilter) {
          case TaskFilterUrgency.overdue:
            return dueDate.isBefore(today);
          case TaskFilterUrgency.today:
            return dueDate.isAtSameMomentAs(today);
          case TaskFilterUrgency.thisWeek:
            return dueDate.isAfter(today) && dueDate.isBefore(weekEnd);
          case TaskFilterUrgency.later:
            return dueDate.isAfter(weekEnd) || dueDate.isAtSameMomentAs(weekEnd);
          default:
            return true;
        }
      }).toList();
    }

    switch (_sortBy) {
      case TaskSortBy.date:
        filtered.sort((a, b) {
          final dateA = _parseDate(a['scheduled_date']);
          final dateB = _parseDate(b['scheduled_date']);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB);
        });
        break;
      case TaskSortBy.priority:
        filtered.sort((a, b) => _getUrgencyLevel(b).compareTo(_getUrgencyLevel(a)));
        break;
      case TaskSortBy.status:
        filtered.sort((a, b) {
          final statusOrder = {'scheduled': 0, 'pending_review': 1, 'rejected': 2, 'completed': 3};
          return (statusOrder[a['status']] ?? 4).compareTo(statusOrder[b['status']] ?? 4);
        });
        break;
      case TaskSortBy.location:
        filtered.sort((a, b) => (a['location'] ?? '').toString().compareTo((b['location'] ?? '').toString()));
        break;
    }

    setState(() {
      _filteredTasks = filtered;
    });
  }

  DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr.toString());
    } catch (e) {
      return null;
    }
  }

  int _getUrgencyLevel(dynamic task) {
    final dueDate = _parseDate(task['scheduled_date']);
    if (dueDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = dueDate.difference(today).inDays;
    if (diff < 0) return 5;
    if (diff == 0) return 4;
    if (diff == 1) return 3;
    if (diff <= 7) return 2;
    return 1;
  }

  Map<String, List<dynamic>> _groupTasksByDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    final Map<String, List<dynamic>> grouped = {
      'Overdue': [],
      'Today': [],
      'Tomorrow': [],
      'This Week': [],
      'Later': [],
      'No Due Date': [],
    };

    for (var task in _filteredTasks) {
      final dueDate = _parseDate(task['scheduled_date']);
      if (dueDate == null) {
        grouped['No Due Date']!.add(task);
      } else if (dueDate.isBefore(today)) {
        grouped['Overdue']!.add(task);
      } else if (dueDate.isAtSameMomentAs(today)) {
        grouped['Today']!.add(task);
      } else if (dueDate.isAtSameMomentAs(tomorrow)) {
        grouped['Tomorrow']!.add(task);
      } else if (dueDate.isBefore(weekEnd)) {
        grouped['This Week']!.add(task);
      } else {
        grouped['Later']!.add(task);
      }
    }
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
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
                Expanded(
                  child: _isLoading 
                      ? _buildLoadingState() 
                      : _error != null 
                          ? _buildErrorState() 
                          : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return const CollapsibleSidebar(currentPage: 'my_tasks');
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Icon with gradient background
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.inspectorPrimary.withOpacity(0.15), AppTheme.inspectorPrimary.withOpacity(0.05)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.inspectorPrimary.withOpacity(0.1)),
            ),
            child: Icon(Icons.task_alt_rounded, color: AppTheme.inspectorPrimary, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Pending Task', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5)),
                    const SizedBox(width: 14),
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.inspectorPrimary, AppTheme.inspectorPrimary.withOpacity(0.8)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: AppTheme.inspectorPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Text('${_filteredTasks.length}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('View and manage your pending inspection tasks', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Action buttons with modern styling
          _buildActionButton(
            icon: _showFilters ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
            tooltip: 'Toggle Filters',
            isActive: _showFilters,
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<TaskSortBy>(
            icon: Icon(Icons.sort_rounded, color: AppTheme.textSecondary),
            tooltip: 'Sort by',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            offset: const Offset(0, 48),
            onSelected: (value) => setState(() { _sortBy = value; _applyFilters(); }),
            itemBuilder: (context) => [
              PopupMenuItem(value: TaskSortBy.date, child: _buildSortItem(Icons.calendar_today_rounded, 'Due Date', _sortBy == TaskSortBy.date)),
              PopupMenuItem(value: TaskSortBy.priority, child: _buildSortItem(Icons.priority_high_rounded, 'Priority', _sortBy == TaskSortBy.priority)),
              PopupMenuItem(value: TaskSortBy.status, child: _buildSortItem(Icons.check_circle_outline_rounded, 'Status', _sortBy == TaskSortBy.status)),
              PopupMenuItem(value: TaskSortBy.location, child: _buildSortItem(Icons.location_on_rounded, 'Location', _sortBy == TaskSortBy.location)),
            ],
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh Tasks',
            onPressed: _loadTasks,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String tooltip, required VoidCallback onPressed, bool isActive = false, bool isPrimary = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? AppTheme.primaryRed.withOpacity(0.1) : (isActive ? AppTheme.primaryRed.withOpacity(0.1) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPrimary || isActive ? AppTheme.primaryRed.withOpacity(0.2) : Colors.grey.shade200),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        color: isPrimary || isActive ? AppTheme.primaryRed : AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildSortItem(IconData icon, String label, bool isSelected) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isSelected ? AppTheme.primaryRed : AppTheme.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: isSelected ? AppTheme.primaryRed : AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
        if (isSelected) ...[const Spacer(), Icon(Icons.check_rounded, size: 16, color: AppTheme.primaryRed)],
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primaryRed.withOpacity(0.1), AppTheme.primaryRed.withOpacity(0.05)]),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primaryRed, strokeCap: StrokeCap.round),
            ),
          ),
          const SizedBox(height: 28),
          Text('Loading your tasks...', style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Please wait while we fetch your assignments', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFFFEE2E2), const Color(0xFFFECACA)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 28),
            Text('Unable to load tasks', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            Text(_error ?? 'Unknown error', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_tasks.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(48),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.grey.shade100, Colors.grey.shade50]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(Icons.assignment_rounded, size: 52, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 28),
              Text('No tasks assigned yet', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              Text('Tasks from your manager will appear here', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: AppTheme.primaryRed.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primaryRed),
                  const SizedBox(width: 8),
                  Text('Check back later for new assignments', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primaryRed, fontWeight: FontWeight.w500)),
                ]),
              ),
            ],
          ),
        ),
      );
    }

    final groupedTasks = _groupTasksByDate();

    return Column(
      children: [
        // Enhanced search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  onChanged: (value) { setState(() { _searchQuery = value; _applyFilters(); }); },
                  decoration: InputDecoration(
                    hintText: 'Search tasks by title or location...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(icon: Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 20), onPressed: () { setState(() { _searchQuery = ''; _applyFilters(); }); })
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              if (_showFilters) ...[const SizedBox(height: 20), _buildFilterChips()],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTasks,
            color: AppTheme.primaryRed,
            child: ListView.builder(
              padding: const EdgeInsets.all(36),
              itemCount: groupedTasks.length,
              itemBuilder: (context, index) {
                final groupName = groupedTasks.keys.elementAt(index);
                return _buildTaskGroup(groupName, groupedTasks[groupName]!);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Urgency:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TaskFilterUrgency.values.map((u) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(u.name[0].toUpperCase() + u.name.substring(1)),
                      selected: _urgencyFilter == u,
                      onSelected: (val) { setState(() { _urgencyFilter = u; _applyFilters(); }); },
                      selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryRed,
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
        if (widget.showAllInspections) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Status:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['scheduled', 'pending_review', 'rejected', 'completed'].map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s.replaceAll('_', ' ').toUpperCase()),
                        selected: _selectedStatuses.contains(s),
                        onSelected: (val) {
                          setState(() { 
                            if (val) {
                              _selectedStatuses.add(s);
                            } else {
                              _selectedStatuses.remove(s);
                            }
                            _applyFilters();
                          });
                        },
                        selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryRed,
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTaskGroup(String groupName, List<dynamic> tasks) {
    IconData groupIcon;
    Color groupColor;
    switch (groupName) {
      case 'Overdue': groupIcon = Icons.warning_rounded; groupColor = AppTheme.statusRejected; break;
      case 'Today': groupIcon = Icons.today_rounded; groupColor = AppTheme.primaryRed; break;
      case 'Tomorrow': groupIcon = Icons.next_plan_rounded; groupColor = AppTheme.accentYellow; break;
      case 'This Week': groupIcon = Icons.date_range_rounded; groupColor = AppTheme.statusScheduled; break;
      default: groupIcon = Icons.calendar_month_rounded; groupColor = AppTheme.textMuted;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 20, top: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [groupColor.withOpacity(0.15), groupColor.withOpacity(0.05)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: groupColor.withOpacity(0.15)),
                ),
                child: Icon(groupIcon, size: 20, color: groupColor),
              ),
              const SizedBox(width: 16),
              Text(groupName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: groupColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${tasks.length}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: groupColor)),
              ),
            ],
          ),
        ),
        ...tasks.map((task) => _buildTaskCard(task)),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final status = task['status'] ?? 'scheduled';
    final statusColor = AppTheme.getStatusColor(status);
    final isRejected = status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: statusColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
        ],
        border: isRejected 
            ? Border.all(color: AppTheme.statusRejected.withOpacity(0.35), width: 1.5) 
            : Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            if (status == 'scheduled' || status == 'rejected') {
              Navigator.push(context, SlidePageRoute(page: InspectionWorkflowPage(inspection: task)));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRejected) _buildRejectionBanner(task),
                Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [statusColor.withOpacity(0.15), statusColor.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withOpacity(0.1)),
                      ),
                      child: Icon(AppTheme.getStatusIcon(status), color: statusColor, size: 26),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task['title'] ?? 'Untitled Inspection', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: -0.2)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                              child: Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(task['location'] ?? 'No Location', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    AppTheme.statusBadge(status),
                  ],
                ),
                const SizedBox(height: 22),
                Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.grey.shade200, Colors.transparent]))),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _buildTaskInfoChip(Icons.precision_manufacturing_outlined, 'Equipment Tag Number', '${task['equipment_id'] ?? 'N/A'}'),
                    const SizedBox(width: 16),
                    _buildTaskInfoChip(Icons.precision_manufacturing_outlined, 'Equipment Type', '${task['equipment_type'] ?? 'N/A'}'),
                    const SizedBox(width: 16),
                    _buildTaskInfoChip(Icons.calendar_today_outlined, 'Due Date', _formatDate(task['scheduled_date'])),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.primaryRed, AppTheme.primaryRed.withOpacity(0.85)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        onPressed: () {
                          if (status == 'scheduled' || status == 'rejected') {
                            Navigator.push(context, SlidePageRoute(page: InspectionWorkflowPage(inspection: task)));
                          }
                        },
                        tooltip: 'Start Inspection',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _viewPdfReport(int inspectionId) async {
    try {
      final url = '${ApiConfig.baseUrl}/dashboard/inspections/$inspectionId/pdf';
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        throw Exception('Could not open PDF viewer');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open PDF: $e'),
          backgroundColor: AppTheme.statusRejected,
        ),
      );
    }
  }



  Widget _buildTaskInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  Widget _buildRejectionBanner(dynamic task) {
    final rejectionReason = task['rejection_reason'];
    final rejectionFeedback = task['rejection_feedback'];
    final rejectionCount = task['rejection_count'] ?? 1;
    
    if (rejectionReason == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.statusRejected.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.statusRejected.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.statusRejected,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rejected by Manager',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.statusRejected,
                      ),
                    ),
                    if (rejectionCount > 1)
                      Text(
                        'Revision #$rejectionCount',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.statusRejected.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.statusRejected.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.statusRejected),
                    const SizedBox(width: 6),
                    Text(
                      'Reason:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  rejectionReason,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
                ),
                if (rejectionFeedback != null && rejectionFeedback.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manager Feedback:',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rejectionFeedback,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
