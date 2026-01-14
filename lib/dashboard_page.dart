import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/dashboard_service.dart';
import 'services/auth_service.dart';
import 'manager_approvals_page.dart';
import 'assign_task_page.dart';
import 'widgets/time_filter.dart';
import 'my_tasks_page.dart';
import 'threads_list_page.dart';
import 'reminders_page.dart';
import 'inspections_list_page.dart';
import 'inspector_management_page.dart';
import 'inspector_profile_page.dart';
import 'manager_user_management_page.dart';
import 'theme/app_theme.dart';
import 'utils/sidebar_state.dart';
import 'widgets/time_filter.dart';
import 'widgets/dashboard_chart_widgets.dart';
import 'package:intl/intl.dart';
import 'utils/animations_config.dart';
import 'inspection_workflow_page.dart';

class DashboardModule extends StatefulWidget {
  const DashboardModule({super.key});

  @override
  State<DashboardModule> createState() => _DashboardModuleState();
}

class _DashboardModuleState extends State<DashboardModule> with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  String? _userRole;
  String? _userName;

  Map<String, dynamic>? _statsData;
  Map<String, dynamic>? _weeklyStats;
  Map<String, dynamic>? _upcomingInspection;
  List<dynamic> _recentActivity = [];
  List<dynamic> _upcomingTasks = [];

  TimeFilterPeriod _selectedPeriod = TimeFilterPeriod.all;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Match navigation transitions
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // Consistent with page transitions
    );
    
    _loadUserInfo();
    _loadDashboardData();
  }

  void _toggleSidebar() {
    setState(() {
      SidebarState.toggle();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    await AuthService.refreshUserData();
    final role = await AuthService.getUserRole();
    final name = await AuthService.getUserName();
    setState(() {
      _userRole = role;
      _userName = name;
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stats = await DashboardService.getDashboardMetrics(period: _selectedPeriod.toShortString()); 
      final upcoming = await DashboardService.getUpcomingInspection();
      final recent = await DashboardService.getRecentActivities();
      
      // Load upcoming tasks for inspectors
      List<dynamic> tasks = [];
      if (_userRole == 'inspector') {
        try {
          final allTasks = await DashboardService.getMyTasks();
          tasks = allTasks.where((t) => 
            t['status'] != 'completed' && 
            t['status'] != 'pending_review'
          ).toList();
          
          // Sort by due date (most urgent first)
          tasks.sort((a, b) {
            final aDate = DateTime.tryParse(a['due_date'] ?? '') ?? DateTime.now().add(const Duration(days: 999));
            final bDate = DateTime.tryParse(b['due_date'] ?? '') ?? DateTime.now().add(const Duration(days: 999));
            return aDate.compareTo(bDate);
          });
          
          // Take top 5 most urgent
          tasks = tasks.take(5).toList();
        } catch (e) {
          // Silently fail for tasks, don't break dashboard
          tasks = [];
        }
      }

      setState(() {
        _statsData = stats;
        _upcomingInspection = upcoming;
        _recentActivity = recent;
        _upcomingTasks = tasks;
        _loading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Row(
        children: [
          // Sidebar Navigation
          _buildSidebar(),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),
                
                // Main content area
                Expanded(
                  child: _loading
                      ? _buildLoadingState()
                      : _error != null
                          ? _buildErrorState()
                          : _buildDashboardContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final isManager = _userRole == 'manager';
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: SidebarState.isCollapsed ? 70 : 260,
      decoration: BoxDecoration(
        gradient: AppTheme.sidebarGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _toggleSidebar,
                  icon: Icon(
                    SidebarState.isCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                    color: Colors.white,
                  ),
                  tooltip: SidebarState.isCollapsed ? 'Expand Menu' : 'Collapse Menu',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                if (!SidebarState.isCollapsed) ...[
                  const SizedBox(width: 8),
                  // iPETRO Logo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/ipetro_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.business_rounded,
                            color: Color(0xFFDC2626),
                            size: 28,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'i',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: 'PETRO',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Inspector Portal',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Navigation items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavSection('MAIN'),
                  _buildNavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: true,
                    onTap: () {},
                  ),
                  
                  if (isManager) ...[
                    const SizedBox(height: 24),
                    _buildNavSection('MANAGEMENT'),
                    _buildNavItem(
                      icon: Icons.assignment_ind_rounded,
                      label: 'Assign Task',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          SlidePageRoute(page: const AssignTaskPage()),
                        );
                        if (result == true) _loadDashboardData();
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pending Approvals',
                      onTap: () => Navigator.push(
                        context,
                        SlidePageRoute(page: const ManagerApprovalsPage()),
                      ),
                    ),
                    _buildNavItem(
                      icon: Icons.people_rounded,
                      label: 'Inspector Management',
                      onTap: () => Navigator.push(
                        context,
                        SlidePageRoute(page: const InspectorManagementPage()),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    _buildNavSection('TASKS'),
                    _buildNavItem(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pending Task',
                      onTap: () => Navigator.push(
                        context,
                        SlidePageRoute(page: const MyTasksPage()),
                      ),
                    ),
                    _buildNavItem(
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: () => Navigator.push(
                        context,
                        SlidePageRoute(
                          page: const MyTasksPage(
                            showAllInspections: true,
                            initialStatusFilter: {'completed'},
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  _buildNavSection('COMMUNICATION'),
                  _buildNavItem(
                    icon: Icons.message_rounded,
                    label: 'Messages',
                    onTap: () => Navigator.push(
                      context,
                      SlidePageRoute(page: const ThreadsListPage()),
                    ),
                  ),
                  if (!isManager)
                    _buildNavItem(
                      icon: Icons.notifications_rounded,
                      label: 'Reminders',
                      onTap: () => Navigator.push(
                        context,
                        SlidePageRoute(page: const RemindersPage()),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  _buildNavSection('SETTINGS'),
                  if (isManager)
                    _buildNavItem(
                      icon: Icons.manage_accounts_rounded,
                      label: 'User Management',
                      onTap: () => Navigator.push(
                        context,
                        SlidePageRoute(page: const ManagerUserManagementPage()),
                      ),
                    ),
                  _buildNavItem(
                    icon: Icons.account_circle_rounded,
                    label: 'My Profile',
                    onTap: () => Navigator.push(
                      context,
                      SlidePageRoute(page: const InspectorProfilePage()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Logout button
          Container(
            padding: const EdgeInsets.all(12),
            child: _buildNavItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              isDestructive: true,
              onTap: () async {
                await AuthService.logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavSection(String title) {
    if (SidebarState.isCollapsed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    final color = isDestructive 
        ? AppTheme.primaryRed
        : isActive 
            ? Colors.white 
            : const Color(0xFF94A3B8);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryRed.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withValues(alpha: 0.1),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SidebarState.isCollapsed ? 0 : 12, 
              vertical: 12
            ),
            child: Row(
              mainAxisAlignment: SidebarState.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: color),
                if (!SidebarState.isCollapsed) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
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
          // Icon with gradient background
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryRed.withValues(alpha: 0.15),
                  AppTheme.primaryRed.withValues(alpha: 0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.1)),
            ),
            child: Icon(Icons.dashboard_rounded, color: AppTheme.primaryRed, size: 28),
          ),
          const SizedBox(width: 20),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Overview of your inspection activities',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Time filter
          TimeFilter(
            selectedPeriod: _selectedPeriod,
            onPeriodSelected: (period) {
              setState(() => _selectedPeriod = period);
              _loadDashboardData();
            },
          ),
          
          const SizedBox(width: 16),
          
          // Refresh button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadDashboardData,
              tooltip: 'Refresh',
              color: AppTheme.primaryRed,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
            'Loading dashboard...',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
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
              'Unable to load dashboard',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {

  
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppTheme.primaryRed,
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Overview
                Text(
                  'Overview',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStrictStatsGrid(),
                const SizedBox(height: 32),
                
                // Upcoming Inspections (formerly Reminders)
                if (_userRole == 'inspector' && _upcomingTasks.isNotEmpty) ...[
                  _buildRemindersSection(),
                  const SizedBox(height: 32),
                ],

                // Recent Activity Section
                if (_recentActivity.isNotEmpty) ...[
                   _buildRecentActivitySection(),
                   const SizedBox(height: 32),
                ],
              ],
            ),
        ),
      ),
    );
  }



  Widget _buildStrictStatsGrid() {
    // Data from strict counting
    final total = _statsData?['total'] ?? 0;
    final scheduled = _statsData?['scheduled'] ?? 0;
    final pending = _statsData?['pending_review'] ?? 0;
    final completed = _statsData?['completed'] ?? 0;
    final rejected = _statsData?['rejected'] ?? 0;

    void navTo(String title, String? status) {
      Navigator.push(
        context,
        SlidePageRoute(
          page: InspectionsListPage(
            title: title,
            fetchFunction: () async {
              final all = await DashboardService.getAllInspections();
              if (status == null) return all;
              return all.where((i) => i['status'] == status).toList();
            },
            headerColor: AppTheme.primaryRed,
          ),
        ),
      );
    }

    final cards = [
      _StatCardData(
        'Total Inspections',
        total,
        Icons.copy_all_rounded,
        Colors.grey.shade700,
        Colors.white,
        onTap: () => navTo('All Inspections', null),
      ),
      _StatCardData(
        'Scheduled',
        scheduled,
        Icons.calendar_today_rounded,
        AppTheme.accentYellow,
        AppTheme.accentYellow.withValues(alpha: 0.1),
        onTap: () => navTo('Scheduled Inspections', 'scheduled'),
      ),
      _StatCardData(
        'Pending Review',
        pending,
        Icons.hourglass_top_rounded,
        AppTheme.accentYellow,
        AppTheme.accentYellow.withValues(alpha: 0.1),
        onTap: () => navTo('Pending Review', 'pending_review'),
      ),
      _StatCardData(
        'Completed',
        completed,
        Icons.check_circle_outline_rounded,
        AppTheme.primaryRed,
        AppTheme.primaryRed.withValues(alpha: 0.1),
        onTap: () => navTo('Completed Inspections', 'completed'),
      ),
      _StatCardData(
        'Rejected',
        rejected,
        Icons.cancel_outlined,
        Colors.red.shade700,
        Colors.red.shade50,
        onTap: () => navTo('Rejected Inspections', 'rejected'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 : 
                        MediaQuery.of(context).size.width > 800 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => _buildStatCard(cards[index]),
    );
  }

  Widget _buildStatCard(_StatCardData card) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: card.bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: card.iconColor.withValues(alpha: 0.2)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: card.onTap, // Enable hover effect and navigation
          hoverColor: card.iconColor.withValues(alpha: 0.1),
          splashColor: card.iconColor.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: card.iconColor,
                      ),
                    ),
                    Icon(card.icon, color: card.iconColor, size: 24),
                  ],
                ),
                Text(
                  card.value.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: card.iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final greeting = _getGreeting();
    final name = _userName?.split(' ')[0] ?? 'Inspector';
    
    final overdueCount = _upcomingTasks.where((task) {
      final dueDate = DateTime.tryParse(task['due_date'] ?? '');
      return dueDate != null && dueDate.isBefore(DateTime.now());
    }).length;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryRed,
            AppTheme.primaryRed.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              overdueCount > 0 ? Icons.notification_important_rounded : Icons.waving_hand_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $name!',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  overdueCount > 0
                      ? 'You have $overdueCount overdue task${overdueCount > 1 ? "s" : ""} - immediate action required'
                      : _upcomingTasks.isEmpty
                          ? 'All caught up! No pending tasks'
                          : 'You have ${_upcomingTasks.length} upcoming task${_upcomingTasks.length > 1 ? "s" : ""}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_upcomingTasks.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _upcomingTasks.length.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  Text(
                    'Tasks',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatsGrid() {
    final total = _statsData?['total'] ?? 0;
    final scheduled = _statsData?['scheduled'] ?? 0;
    final pending = _statsData?['pending_review'] ?? 0;
    final completed = _statsData?['completed'] ?? 0;
    final rejected = _statsData?['rejected'] ?? 0;

    void navTo(String title, String? status) {
      Navigator.push(
        context,
        SlidePageRoute(
          page: InspectionsListPage(
            title: title,
            fetchFunction: () async {
              final all = await DashboardService.getAllInspections();
              if (status == null) return all;
              return all.where((i) => i['status'] == status).toList();
            },
            headerColor: AppTheme.primaryRed,
          ),
        ),
      );
    }

    final cards = [
      _EnhancedStatCardData(
        'Total Inspections',
        total,
        Icons.assignment_rounded,
        [const Color(0xFF64748B), const Color(0xFF475569)],
        onTap: () => navTo('All Inspections', null),
      ),
      _EnhancedStatCardData(
        'Scheduled',
        scheduled,
        Icons.event_available_rounded,
        [AppTheme.accentYellow, const Color(0xFFF59E0B)],
        onTap: () => navTo('Scheduled Inspections', 'scheduled'),
      ),
      _EnhancedStatCardData(
        'Pending Review',
        pending,
        Icons.pending_actions_rounded,
        [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        onTap: () => navTo('Pending Review', 'pending_review'),
      ),
      _EnhancedStatCardData(
        'Completed',
        completed,
        Icons.check_circle_rounded,
        [AppTheme.primaryRed, const Color(0xFFB91C1C)],
        onTap: () => navTo('Completed Inspections', 'completed'),
      ),
      _EnhancedStatCardData(
        'Rejected',
        rejected,
        Icons.cancel_rounded,
        [const Color(0xFFDC2626), const Color(0xFF991B1B)],
        onTap: () => navTo('Rejected Inspections', 'rejected'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 : 
                        MediaQuery.of(context).size.width > 800 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => _buildEnhancedStatCard(cards[index]),
    );
  }

  Widget _buildEnhancedStatCard(_EnhancedStatCardData card) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: card.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: card.gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: card.onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        card.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(card.icon, color: Colors.white, size: 22),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  card.value.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentYellow, AppTheme.accentYellow.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Upcoming Deadlines',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                SlidePageRoute(page: const RemindersPage()),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryRed,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _upcomingTasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              final isLast = index == _upcomingTasks.length - 1;
              return _buildEnhancedReminderCard(task, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedReminderCard(Map<String, dynamic> task, bool isLast) {
    final dueDate = DateTime.tryParse(task['due_date'] ?? '') ?? DateTime.now();
    final title = task['title'] ?? 'Inspection Task';
    final location = task['location'] ?? '';
    
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    final isOverdue = difference.isNegative;
    
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
    
    String formatDate(DateTime dateTime) {
      final diff = dateTime.difference(now);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Tomorrow';
      if (diff.inDays == -1) return 'Yesterday';
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          try {
            final inspection = await DashboardService.getInspectionDetails(task['id']);
            if (!mounted || inspection == null) return;
            Navigator.push(
              context,
              SlidePageRoute(
                page: InspectionWorkflowPage(inspection: inspection),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              AppTheme.errorSnackBar(
                context: context,
                message: 'Failed to load inspection: $e',
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: isLast ? null : Border(
              bottom: BorderSide(color: Colors.grey.shade100),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(priorityIcon, size: 12, color: priorityColor),
                    const SizedBox(width: 6),
                    Text(
                      priorityLabel,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: priorityColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Due',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formatDate(dueDate),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isOverdue ? AppTheme.statusRejected : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivity.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) => _buildActivityItem(_recentActivity[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(dynamic activity) {
    final status = activity['status'] as String? ?? 'updated';
    final isCompleted = status == 'completed';
    final isScheduled = status == 'scheduled';
    
    final iconColor = isCompleted ? AppTheme.primaryRed : 
                      isScheduled ? AppTheme.accentYellow : Colors.blue;
    final icon = isCompleted ? Icons.check_circle_outline_rounded :
                 isScheduled ? Icons.calendar_today_rounded : Icons.edit_outlined;

    return InkWell(
      onTap: () {
        // Optional: Navigate to history/details
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                     activity['title'] ?? 'Title',
                     style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 14),
                   ),
                   const SizedBox(height: 4),
                   Row(
                     children: [
                       Expanded(
                         child: Text(
                           activity['subtitle'] ?? 'Location',
                           style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                       const SizedBox(width: 8),
                       Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                       const SizedBox(width: 8),
                       Text(
                         _getTimeAgo(activity['timestamp']),
                         style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                       ),
                     ],
                   ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.tryParse(timestamp);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Upcoming Inspections',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                SlidePageRoute(page: const RemindersPage()),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: _upcomingTasks.map((task) => _buildCompactReminderCard(task)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactReminderCard(Map<String, dynamic> task) {
    final dueDate = DateTime.tryParse(task['due_date'] ?? '') ?? DateTime.now();
    final title = task['title'] ?? 'Inspection Task';
    final location = task['location'] ?? '';
    
    // Calculate priority
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    final isOverdue = difference.isNegative;
    
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
    
    String formatDate(DateTime dateTime) {
      final difference = dateTime.difference(now);
      if (difference.inDays == 0) return 'Today';
      if (difference.inDays == 1) return 'Tomorrow';
      if (difference.inDays == -1) return 'Yesterday';
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          try {
            final inspection = await DashboardService.getInspectionDetails(task['id']);
            if (!mounted || inspection == null) return;
            Navigator.push(
              context,
              SlidePageRoute(
                page: InspectionWorkflowPage(inspection: inspection),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load inspection: $e')),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100),
            ),
          ),
          child: Row(
            children: [
              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(priorityIcon, size: 12, color: priorityColor),
                    const SizedBox(width: 6),
                    Text(
                      priorityLabel,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: priorityColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Due date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Due',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formatDate(dueDate),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isOverdue ? AppTheme.statusRejected : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildUpcomingTaskCard() {
    if (_upcomingInspection == null) {
      return Container(); // Or a placeholder "No upcoming tasks"
    }

    final inspection = _upcomingInspection!;
    final dateStr = inspection['scheduled_date'];
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final formattedDate = date != null ? DateFormat('EEEE, MMM d, yyyy').format(date) : 'TBD';
    final location = inspection['site_location'] ?? 'Unknown Location';
    final client = inspection['client_name'] ?? 'Unknown Client';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryRed, AppTheme.primaryRed.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'UPCOMING TASK',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  client,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to my tasks or details
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyTasksPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              children: const [
                Text('Start Now', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPerformanceChart() {
    final completed = _weeklyStats?['completed'] as int? ?? 0;
    final scheduled = _weeklyStats?['scheduled'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Performance',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inspections completed vs scheduled (Last 7 days)',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: PerformanceBarChart(completed: completed, scheduled: scheduled),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                   // Navigate to history or logs
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InspectionsListPage(
                            title: 'Recent Activity',
                            fetchFunction: () => DashboardService.getMyTasks(),
                            headerColor: AppTheme.primaryRed,
                          ),
                        ),
                      );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentActivity.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No recent activity',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivity.length,
              itemBuilder: (context, index) {
                return ActivityListTile(activity: _recentActivity[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _statsData != null
        ? [
            StatItem(
              title: 'Total Inspections',
              value: _statsData!['total_inspections']?.toString() ?? '0',
              icon: Icons.assignment_turned_in_rounded,
              color: AppTheme.primaryRed,
              onTap: () => _navigateToInspectionsList('Total Inspections', DashboardService.getAllInspections, AppTheme.primaryRed),
            ),
            StatItem(
              title: 'Reports Generated',
              value: _statsData!['reports_generated']?.toString() ?? '0',
              icon: Icons.description_rounded,
              color: AppTheme.statusCompleted,
              onTap: () => _navigateToInspectionsList('Reports Generated', DashboardService.getCompletedInspections, AppTheme.primaryRed),
            ),
            StatItem(
              title: 'Pending Review',
              value: _statsData!['pending_review']?.toString() ?? '0',
              icon: Icons.hourglass_top_rounded,
              color: AppTheme.statusPendingReview,
              onTap: () => _navigateToInspectionsList('Pending Review', DashboardService.getPendingReviewInspections, AppTheme.accentYellow),
            ),
            StatItem(
              title: 'Completed',
              value: _statsData!['completed']?.toString() ?? '0',
              icon: Icons.check_circle_rounded,
              color: AppTheme.statusCompleted,
              onTap: () => _navigateToInspectionsList('Completed', DashboardService.getCompletedInspections, AppTheme.primaryRed),
            ),
            StatItem(
              title: 'Scheduled',
              value: _statsData!['scheduled']?.toString() ?? '0',
              icon: Icons.schedule_rounded,
              color: AppTheme.statusScheduled,
              onTap: () => _navigateToInspectionsList('Scheduled', DashboardService.getInProgressScheduled, Colors.purple),
            ),
          ]
        : [];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 : 
                        MediaQuery.of(context).size.width > 800 ? 3 : 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.4,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatCard(stats[index]),
    );
  }

  void _navigateToInspectionsList(String title, Future<List<dynamic>> Function() fetchFunction, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionsListPage(
          title: title,
          fetchFunction: fetchFunction,
          headerColor: color,
        ),
      ),
    );
  }

  Widget _buildStatItemCard(StatItem stat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: stat.color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: stat.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        stat.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            stat.color.withValues(alpha: 0.15),
                            stat.color.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(stat.icon, size: 22, color: stat.color),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      stat.value,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: stat.color,
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
}

class StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _StatCardData {
  final String title;
  final int value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback? onTap;

  _StatCardData(this.title, this.value, this.icon, this.iconColor, this.bgColor, {this.onTap});
}

class _EnhancedStatCardData {
  final String title;
  final int value;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  _EnhancedStatCardData(
    this.title,
    this.value,
    this.icon,
    this.gradientColors,
    {this.onTap}
  );
}


