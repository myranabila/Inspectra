import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/manager_service.dart';
import 'theme/app_theme.dart';
import 'widgets/collapsible_sidebar.dart';

class InspectorManagementPage extends StatefulWidget {
  const InspectorManagementPage({super.key});

  @override
  State<InspectorManagementPage> createState() => _InspectorManagementPageState();
}

class _InspectorManagementPageState extends State<InspectorManagementPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _inspectors = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'name';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadInspectors();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      _animationController.forward();
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
    if (rate >= 80) return AppTheme.statusCompleted;
    if (rate >= 60) return AppTheme.accentYellow;
    return AppTheme.statusRejected;
  }

  IconData _getPerformanceIcon(double rate) {
    if (rate >= 80) return Icons.trending_up_rounded;
    if (rate >= 60) return Icons.trending_flat_rounded;
    return Icons.trending_down_rounded;
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
                      ? _buildLoading()
                      : _error != null
                          ? _buildError()
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
    return const CollapsibleSidebar(currentPage: 'inspector_management');
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                  AppTheme.primaryRed.withOpacity(0.15),
                  AppTheme.primaryRed.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryRed.withOpacity(0.1),
              ),
            ),
            child: Icon(
              Icons.people_alt_rounded,
              color: AppTheme.primaryRed,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Inspector Management',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 14),
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryRed,
                              AppTheme.primaryRed.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryRed.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${_inspectors.length}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Monitor inspector performance and workload',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons with modern styling
          _buildActionButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh Data',
            onPressed: _loadInspectors,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: AppTheme.primaryRed,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
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
            'Loading inspectors...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Failed to load inspectors',
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInspectors,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_inspectors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 56,
                color: AppTheme.primaryRed.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No inspectors found',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inspectors will appear here once registered',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildSortSection(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
              itemCount: _inspectors.length,
              itemBuilder: (context, index) => _buildInspectorCard(_inspectors[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.divider.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sort_rounded,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Sort by:',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                {'key': 'name', 'label': 'Name', 'icon': Icons.person_rounded},
                {'key': 'total_tasks', 'label': 'Total Tasks', 'icon': Icons.assignment_rounded},
                {'key': 'completion_rate', 'label': 'Completion', 'icon': Icons.check_circle_rounded},
                {'key': 'approval_rate', 'label': 'Approval', 'icon': Icons.verified_rounded},
              ].map((item) {
                final isSelected = _sortBy == item['key'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _sortBy = item['key'] as String;
                      _sortInspectors();
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryRed
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryRed
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorCard(Map<String, dynamic> inspector, int index) {
    final completionRate = (inspector['completion_rate'] as num).toDouble();
    final approvalRate = (inspector['approval_rate'] as num).toDouble();
    final totalTasks = inspector['total_tasks'] as int;
    final completedTasks = inspector['completed_tasks'] as int;
    final pendingReview = inspector['pending_review'] as int;
    final scheduled = inspector['scheduled'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.divider.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Future: Navigate to inspector detail page
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header Row
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryRed,
                            AppTheme.primaryRed.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryRed.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          inspector['username'][0].toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name & Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inspector['username'],
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inspector['email'],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Performance Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getPerformanceColor(completionRate).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getPerformanceColor(completionRate).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPerformanceIcon(completionRate),
                            size: 16,
                            color: _getPerformanceColor(completionRate),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${completionRate.toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              color: _getPerformanceColor(completionRate),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Stats Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildStatItem(
                        Icons.assignment_rounded,
                        'Total',
                        totalTasks.toString(),
                        AppTheme.textPrimary,
                      ),
                      _buildStatItem(
                        Icons.check_circle_rounded,
                        'Completed',
                        completedTasks.toString(),
                        AppTheme.statusCompleted,
                      ),
                      _buildStatItem(
                        Icons.hourglass_top_rounded,
                        'Review',
                        pendingReview.toString(),
                        AppTheme.statusPendingReview,
                      ),
                      _buildStatItem(
                        Icons.schedule_rounded,
                        'Scheduled',
                        scheduled.toString(),
                        AppTheme.statusScheduled,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Progress Bars
                Row(
                  children: [
                    Expanded(
                      child: _buildProgressIndicator(
                        'Completion',
                        completionRate,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildProgressIndicator(
                        'Approval',
                        approvalRate,
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

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double rate) {
    final color = _getPerformanceColor(rate);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${rate.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate / 100,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
