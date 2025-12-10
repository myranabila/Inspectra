import 'package:flutter/material.dart';
import 'services/profile_service.dart';
import 'widgets/time_filter.dart';
import 'theme/app_theme.dart';

class ManagerPerformanceDashboard extends StatefulWidget {
  const ManagerPerformanceDashboard({super.key});

  @override
  State<ManagerPerformanceDashboard> createState() =>
      _ManagerPerformanceDashboardState();
}

class _ManagerPerformanceDashboardState extends State<ManagerPerformanceDashboard> {
  TimeFilterPeriod _selectedPeriod = TimeFilterPeriod.all;
  List<dynamic> _inspectorStats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInspectorStats();
  }

  Future<void> _fetchInspectorStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ProfileService.getInspectorsWithStats(
        period: _selectedPeriod.toShortString(),
      );
      setState(() {
        _inspectorStats = data;
        _isLoading = false;
      });
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
      appBar: AppBar(
        title: const Text('Inspector Performance'),
        backgroundColor: AppTheme.managerPrimary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // The TimeFilter widget is integrated here
          Container(
            color: Colors.white,
            child: TimeFilter(
              selectedPeriod: _selectedPeriod,
              onPeriodSelected: (period) {
                setState(() {
                  _selectedPeriod = period;
                });
                _fetchInspectorStats(); // Re-fetch data when the filter changes
              },
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Failed to load data: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_inspectorStats.isEmpty) {
      return const Center(
        child: Text('No inspector data available for the selected period.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInspectorStats,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _inspectorStats.length,
        itemBuilder: (context, index) {
          final inspector = _inspectorStats[index];
          return _buildInspectorCard(inspector);
        },
      ),
    );
  }

  Widget _buildInspectorCard(Map<String, dynamic> inspector) {
    final completionRate = inspector['completion_rate'] ?? 0.0;
    final approvalRate = inspector['approval_rate'] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inspector['username'] ?? 'Unknown Inspector',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.managerPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              inspector['email'] ?? 'No email',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Tasks', inspector['total_tasks']?.toString() ?? '0'),
                _buildStatColumn('Completed', inspector['completed_tasks']?.toString() ?? '0'),
                _buildStatColumn('Pending', inspector['pending_review']?.toString() ?? '0'),
              ],
            ),
            const SizedBox(height: 16),
            _buildRateIndicator('Completion Rate', completionRate, Colors.blue),
            const SizedBox(height: 8),
            _buildRateIndicator('Approval Rate', approvalRate, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRateIndicator(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}