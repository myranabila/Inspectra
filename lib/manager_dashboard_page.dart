import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/dashboard_service.dart';
import 'services/auth_service.dart';
import 'services/manager_service.dart';
import 'assign_task_page.dart';
import 'manager_approvals_page.dart';
import 'inspector_management_page.dart';
import 'manager_user_management_page.dart';
import 'threads_list_page.dart';
import 'inspections_list_page.dart';
import 'inspector_profile_page.dart';
import 'widgets/collapsible_sidebar.dart';
import 'theme/app_theme.dart';
import 'utils/sidebar_state.dart';
import 'widgets/time_filter.dart';
import 'widgets/dashboard_chart_widgets.dart';
import 'utils/animations_config.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  String? _userName;

  Map<String, dynamic>? _statsData;

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



  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    await AuthService.refreshUserData(); // Fetch latest data from backend
    final name = await AuthService.getUserName();
    setState(() {
      _userName = name;
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Fetch strict metrics
      final metrics = await DashboardService.getDashboardMetrics(period: _selectedPeriod.toShortString());

      setState(() {
        _statsData = metrics; // Now strict metrics
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
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
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
  
  // Sidebar and TopBar methods condensed or extracted...
  
  Widget _buildDashboardContent() {
    final overdueCount = _statsData?['overdue'] as int? ?? 0;

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
              // 1. Overdue Alert - REMOVED AS REQUESTED
              // if (overdueCount > 0) ...[
              //   _buildOverdueAlert(overdueCount),
              //   const SizedBox(height: 24),
              // ],

              // 2. Strict Metrics Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                      'Team Overview',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TimeFilter(
                      selectedPeriod: _selectedPeriod,
                      onPeriodSelected: (period) {
                        setState(() => _selectedPeriod = period);
                        _loadDashboardData();
                      },
                    ),
                ],
              ),
                const SizedBox(height: 16),
              _buildStrictStatsGrid(),
              const SizedBox(height: 32),
              
              // 3. Status Pie Chart - REMOVED AS REQUESTED
              // _buildStatusPieChart(),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverdueAlert(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Light Red
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.group_off_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Attention Required',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF991B1B),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$count overdue inspection${count > 1 ? 's' : ''} in your team.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB91C1C),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrictStatsGrid() {
    final total = _statsData?['total'] ?? 0;
    final scheduled = _statsData?['scheduled'] ?? 0;
    final pending = _statsData?['pending_review'] ?? 0;
    final completed = _statsData?['completed'] ?? 0;
    final rejected = _statsData?['rejected'] ?? 0;

    void navTo(String title, String? status) {
      Navigator.push(
        context,
        FadePageRoute(
          page: InspectionsListPage(
            title: title,
            fetchFunction: () async {
              final all = await ManagerService.getAllInspections();
              if (status == null) return all;
              return all.where((i) => i['status'] == status).toList();
            },
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
        onTap: () => navTo('Pending Inspections', 'pending_review'),
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
        Colors.red,
        Colors.red.withValues(alpha: 0.1),
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

  Widget _buildStatusPieChart() {
    // Re-use logic for pie chart
     final completed = _statsData?['completed'] as int? ?? 0;
     final pending = _statsData?['pending_review'] as int? ?? 0;
     final scheduled = _statsData?['scheduled'] as int? ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Distribution', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: StatusPieChart(completed: completed, pending: pending, scheduled: scheduled),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white, // Card background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: data.onTap, // Enable hover and navigation
          hoverColor: data.color.withValues(alpha: 0.05), // Subtle hover tint
          splashColor: data.color.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(data.title, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500))),
                    Icon(data.icon, size: 20, color: data.color),
                  ],
                ),
                Text(data.value.toString(), style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return const CollapsibleSidebar(currentPage: 'dashboard');
  }

  Widget _buildTopBar() {
     return _ManagerTopBar(userName: _userName, onRefresh: _loadDashboardData);
  }
}

class _StatCardData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  _StatCardData(this.title, this.value, this.icon, this.color, this.bgColor, {this.onTap});
}



class _ManagerTopBar extends StatelessWidget {
  final String? userName;
  final VoidCallback onRefresh;
  const _ManagerTopBar({this.userName, required this.onRefresh});
  
  @override
  Widget build(BuildContext context) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
       color: Colors.white,
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Row(
             children: [
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
               Column(
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
             ],
           ),
           Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onRefresh,
              tooltip: 'Refresh',
              color: AppTheme.primaryRed,
            ),
           ),
         ],
       ),
     );
  }
}

// Extension methods for ManagerDashboardPageState
extension _ManagerDashboardWidgets on _ManagerDashboardPageState {
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
              // Stats Grid
              _buildStatsGrid(),
              const SizedBox(height: 32),
              
              // Charts Row
               LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive chart layout
                  if (constraints.maxWidth > 900) {
                     return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildInspectionStatusChart()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildQuickActions()), // Or Top Inspectors if available
                      ],
                    );
                  } else {
                     return Column(
                      children: [
                         _buildInspectionStatusChart(),
                         const SizedBox(height: 24),
                         _buildQuickActions(),
                      ],
                    );
                  }
                },
               ),
              
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInspectionStatusChart() {
     final completed = int.tryParse(_statsData?['completed']?.toString() ?? '0') ?? 0;
     final pending = int.tryParse(_statsData?['pending_review']?.toString() ?? '0') ?? 0;
     final scheduled = int.tryParse(_statsData?['scheduled']?.toString() ?? '0') ?? 0;
    
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
            'Overall Status',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Distribution of inspection statuses',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: StatusPieChart(
                completed: completed,
                pending: pending,
                scheduled: scheduled,
            ),
          ),
           const SizedBox(height: 16),
           // Legend
           Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               _buildLegendItem('Completed', AppTheme.statusCompleted),
               const SizedBox(width: 16),
               _buildLegendItem('Pending', AppTheme.statusPendingReview),
               const SizedBox(width: 16),
               _buildLegendItem('Scheduled', AppTheme.statusScheduled),
             ],
           ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
  
  Widget _buildQuickActions() {
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
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildQuickActionTile(
            title: 'Assign New Task',
            icon: Icons.add_task_rounded,
            color: AppTheme.accentYellow,
            onTap: () async {
                 final result = await Navigator.push(
                    context,
                    SlidePageRoute(page: const AssignTaskPage()),
                  );
                  if (result == true) _loadDashboardData();
            },
          ),
          _buildQuickActionTile(
            title: 'Manage Inspectors',
            icon: Icons.people_outline_rounded,
            color: Colors.purple,
             onTap: () => Navigator.push(
                context,
                SlidePageRoute(page: const InspectorManagementPage()),
              ),
          ),
          _buildQuickActionTile(
            title: 'Review Pending Reports',
            icon: Icons.rate_review_outlined,
            color: AppTheme.accentYellow,
             onTap: () => Navigator.push(
                context,
                SlidePageRoute(page: const ManagerApprovalsPage()),
              ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionTile({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: color.withValues(alpha: 0.05),
        hoverColor: color.withValues(alpha: 0.1),
        splashColor: color.withValues(alpha: 0.15),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title, 
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatItem(
        title: 'Total Inspections',
        value: _statsData?['total_inspections']?.toString() ?? '0',
        icon: Icons.assignment_turned_in_rounded,
        color: AppTheme.primaryRed,
        trend: '+12%',
        trendUp: true,
        onTap: () => _navigateToStatDetail('Total Inspections'),
      ),
      _StatItem(
        title: 'Reports Generated',
        value: _statsData?['reports_generated']?.toString() ?? '0',
        icon: Icons.description_rounded,
        color: const Color(0xFF10B981),
        trend: '+8%',
        trendUp: true,
        onTap: () => _navigateToStatDetail('Reports Generated'),
      ),
      _StatItem(
        title: 'Pending Review',
        value: _statsData?['pending_review']?.toString() ?? '0',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFF59E0B),
        isHighlight: true,
        onTap: () => _navigateToStatDetail('Pending Review'),
      ),
      _StatItem(
        title: 'Completed',
        value: _statsData?['completed']?.toString() ?? '0',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF10B981),
        onTap: () => _navigateToStatDetail('Completed'),
      ),
      _StatItem(
        title: 'Scheduled',
        value: _statsData?['scheduled']?.toString() ?? '0',
        icon: Icons.schedule_rounded,
        color: const Color(0xFF3B82F6),
        onTap: () => _navigateToStatDetail('Scheduled'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 : 
                        MediaQuery.of(context).size.width > 800 ? 3 : 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.35,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatCard(stats[index]),
    );
  }

  void _navigateToStatDetail(String title) {
    if (title == "Total Inspections") {
      Navigator.push(
        context,
        SlidePageRoute(
          page: InspectionsListPage(
            title: 'Total Inspections',
            fetchFunction: DashboardService.getAllInspections,
            headerColor: AppTheme.primaryRed,
          ),
        ),
      );
    } else if (title == "Reports Generated") {
      Navigator.push(
        context,
        SlidePageRoute(
          page: InspectionsListPage(
            title: 'Reports Generated',
            fetchFunction: DashboardService.getCompletedInspections,
            headerColor: AppTheme.primaryRed,
          ),
        ),
      );
    } else if (title == "Pending Review") {
      Navigator.push(
        context,
        SlidePageRoute(
          page: const ManagerApprovalsPage(),
        ),
      );
    } else if (title == "Completed") {
      Navigator.push(
        context,
        SlidePageRoute(
          page: InspectionsListPage(
            title: 'Completed Inspections',
            fetchFunction: DashboardService.getCompletedInspections,
            headerColor: AppTheme.primaryRed,
          ),
        ),
      );
    } else if (title == "Scheduled") {
      Navigator.push(
        context,
        SlidePageRoute(
          page: InspectionsListPage(
            title: 'Scheduled Inspections',
            fetchFunction: DashboardService.getInProgressScheduled,
            headerColor: Colors.purple,
          ),
        ),
      );
    }
  }

  Widget _buildStatCard(_StatItem stat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: stat.color.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: stat.isHighlight 
            ? Border.all(color: stat.color.withValues(alpha: 0.3), width: 2)
            : Border.all(color: Colors.grey.shade100),
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
                      width: 44,
                      height: 44,
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
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1,
                      ),
                    ),
                    if (stat.trend != null) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (stat.trendUp ? AppTheme.primaryRed : Colors.red).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                stat.trendUp ? Icons.trending_up : Icons.trending_down,
                                size: 12,
                                color: stat.trendUp ? AppTheme.primaryRed : Colors.red,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                stat.trend!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: stat.trendUp ? AppTheme.primaryRed : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool trendUp;
  final bool isHighlight;
  final VoidCallback onTap;

  _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendUp = true,
    this.isHighlight = false,
    required this.onTap,
  });
}
