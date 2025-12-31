import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'widgets/collapsible_sidebar.dart';

class InspectionsListPage extends StatefulWidget {
  final String title;
  final Future<List<dynamic>> Function() fetchFunction;
  final Color headerColor;

  const InspectionsListPage({
    super.key,
    required this.title,
    required this.fetchFunction,
    this.headerColor = AppTheme.inspectorPrimary,
  });

  @override
  State<InspectionsListPage> createState() => _InspectionsListPageState();
}

class _InspectionsListPageState extends State<InspectionsListPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _inspections = [];
  String? _error;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _loadInspections();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInspections() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final inspections = await widget.fetchFunction();
      setState(() { _inspections = inspections; _isLoading = false; });
      _animationController.forward();
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
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
                  child: _isLoading ? _buildLoading() : _error != null ? _buildError() : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return const CollapsibleSidebar(
      currentPage: 'inspections',
      isMainPage: false, // This is a filtered view/sub-page
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: widget.headerColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.assignment_rounded, color: widget.headerColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(widget.title, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(width: 12),
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: widget.headerColor, borderRadius: BorderRadius.circular(10)),
                        child: Text('${_inspections.length}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('View and manage inspections', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadInspections, tooltip: 'Refresh', color: AppTheme.primaryRed),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primaryRed)),
          const SizedBox(height: 24),
          Text('Loading inspections...', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 24),
          Text('Failed to load inspections', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(_error!, style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadInspections,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_inspections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24)),
              child: Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text('No inspections found', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(32),
        itemCount: _inspections.length,
        itemBuilder: (context, index) => _buildInspectionCard(_inspections[index]),
      ),
    );
  }

  Widget _buildInspectionCard(dynamic inspection) {
    final status = inspection['status'] as String? ?? 'scheduled';
    final statusColor = AppTheme.getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to inspection detail
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(AppTheme.getStatusIcon(status), color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inspection['title'] ?? 'Untitled',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(inspection['location'] ?? 'N/A', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(_formatDate(inspection['scheduled_date']), style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                AppTheme.statusBadge(status),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
