import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/api_config.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/collapsible_sidebar.dart';
import 'inspection_workflow_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  List<dynamic> _inspections = [];
  int _totalCount = 0;
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all';
  
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
    _loadHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final queryParams = <String, String>{};
      if (_selectedStatus != 'all') {
        queryParams['status'] = _selectedStatus;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/dashboard/history')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _totalCount = data['total_count'];
          _inspections = data['inspections'];
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
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
                _buildFilterSection(),
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
    return const CollapsibleSidebar(currentPage: 'history');
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.statusPendingReview.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.history_rounded,
              color: AppTheme.statusPendingReview,
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
                      'Inspection History',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.statusPendingReview,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_totalCount',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'View all your past and current inspections',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadHistory,
              tooltip: 'Refresh',
              color: AppTheme.primaryRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', null),
            const SizedBox(width: 10),
            _buildFilterChip('Scheduled', 'scheduled', Icons.schedule_rounded),
            const SizedBox(width: 10),
            _buildFilterChip('Under Review', 'pending_review', Icons.hourglass_top_rounded),
            const SizedBox(width: 10),
            _buildFilterChip('Rejected', 'rejected', Icons.cancel_rounded),
            const SizedBox(width: 10),
            _buildFilterChip('Completed', 'completed', Icons.check_circle_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String status, IconData? icon) {
    final isSelected = _selectedStatus == status;
    Color chipColor = AppTheme.textSecondary;
    
    if (status == 'scheduled') chipColor = AppTheme.statusScheduled;
    if (status == 'pending_review') chipColor = AppTheme.statusPendingReview;
    if (status == 'rejected') chipColor = AppTheme.statusRejected;
    if (status == 'completed') chipColor = AppTheme.statusCompleted;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isSelected ? Colors.white : chipColor),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
        _loadHistory();
      },
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: status == 'all' ? AppTheme.primaryRed : chipColor,
      labelStyle: GoogleFonts.inter(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primaryRed),
          ),
          const SizedBox(height: 24),
          Text('Loading history...', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
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
            child: const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 24),
          Text('Failed to load history', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(_error!, style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadHistory,
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

  Widget _buildContent() {
    if (_inspections.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppTheme.primaryRed,
        child: ListView.builder(
          padding: const EdgeInsets.all(32),
          itemCount: _inspections.length,
          itemBuilder: (context, index) => _buildInspectionCard(_inspections[index]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            'No inspection history found',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionCard(Map<String, dynamic> inspection) {
    final status = inspection['status'] as String;
    final statusColor = AppTheme.getStatusColor(status);
    final isRejected = status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
        border: isRejected 
            ? Border.all(color: AppTheme.statusRejected.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InspectionWorkflowPage(inspection: inspection),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        AppTheme.getStatusIcon(status),
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inspection['title'] ?? 'Untitled',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                inspection['location'] ?? 'N/A',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppTheme.statusBadge(status),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (inspection['equipment_id'] != null || inspection['equipment_type'] != null)
                        _buildInfoRow(Icons.category_rounded, 'Equipment', 
                            '${inspection['equipment_id'] ?? 'N/A'} - ${inspection['equipment_type'] ?? 'N/A'}'),
                      if (inspection['scheduled_date'] != null) ...[
                        if (inspection['equipment_id'] != null) const SizedBox(height: 10),
                        _buildInfoRow(Icons.calendar_today_rounded, 'Scheduled', inspection['scheduled_date']),
                      ],
                      if (inspection['completion_date'] != null) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.check_circle_rounded, 'Completed', inspection['completion_date'], 
                            color: AppTheme.statusCompleted),
                      ],
                    ],
                  ),
                ),
                
                if (inspection['rejection_count'] != null && inspection['rejection_count'] > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.statusRejected.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.replay_rounded, size: 14, color: AppTheme.statusRejected),
                        const SizedBox(width: 6),
                        Text(
                          'Rejected ${inspection['rejection_count']}x',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.statusRejected,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (isRejected && (inspection['rejection_reason'] != null || inspection['rejection_feedback'] != null)) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.statusRejected.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.statusRejected.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.statusRejected),
                            const SizedBox(width: 8),
                            Text(
                              'Rejection Details',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.statusRejected,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (inspection['rejection_reason'] != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            inspection['rejection_reason'],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (inspection['rejection_feedback'] != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            inspection['rejection_feedback'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
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
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppTheme.textMuted),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
