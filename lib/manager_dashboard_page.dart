import 'package:flutter/material.dart';
import 'services/dashboard_service.dart';
import 'services/auth_service.dart';
import 'assign_task_page.dart';
import 'manager_approvals_page.dart';
import 'inspector_management_page.dart';
import 'manager_user_management_page.dart';
import 'threads_list_page.dart';
import 'inspections_list_page.dart';
import 'theme/app_theme.dart';
import 'widgets/time_filter.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  bool _loading = true;
  String? _error;
  String? _userName;

  Map<String, dynamic>? _statsData;
  List<dynamic> _recentInspections = [];
  TimeFilterPeriod _selectedPeriod = TimeFilterPeriod.all;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadDashboardData();
  }

  Future<void> _loadUserInfo() async {
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
      final stats =
          await DashboardService.getStats(period: _selectedPeriod.toShortString());
      final inspections = await DashboardService.getRecentInspections(limit: 5);

      setState(() {
        _statsData = stats;
        _recentInspections = inspections;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build stats cards from API data
    final stats = _statsData != null
        ? [
            {
              "title": "Total Inspections",
              "value": _statsData!['total_inspections']?.toString() ?? '0',
              "icon": Icons.assignment_turned_in,
              "color": Colors.blue,
            },
            {
              "title": "Reports Generated",
              "value": _statsData!['reports_generated']?.toString() ?? '0',
              "icon": Icons.description,
              "color": Colors.green,
            },
            {
              "title": "Pending Review",
              "value": _statsData!['pending_review']?.toString() ?? '0',
              "icon": Icons.warning_amber_rounded,
              "color": Colors.orange,
            },
            {
              "title": "Completed",
              "value": _statsData!['completed']?.toString() ?? '0',
              "icon": Icons.check_circle,
              "color": Colors.green,
            },
            {
              "title": "Scheduled",
              "value": _statsData!['scheduled']?.toString() ?? '0',
              "icon": Icons.schedule,
              "color": Colors.blue,
            },
          ]
        : [
            {
              "title": "Total Inspections",
              "value": "0",
              "icon": Icons.assignment_turned_in,
              "color": Colors.blue,
            },
            {
              "title": "Reports Generated",
              "value": "0",
              "icon": Icons.description,
              "color": Colors.green,
            },
            {
              "title": "Pending Review",
              "value": "0",
              "icon": Icons.warning_amber_rounded,
              "color": Colors.orange,
            },
            {
              "title": "Completed",
              "value": "0",
              "icon": Icons.check_circle,
              "color": Colors.green,
            },
            {
              "title": "Scheduled",
              "value": "0",
              "icon": Icons.schedule,
              "color": Colors.blue,
            },
          ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard_rounded, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Manager Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Text(
              _userName ?? 'Manager',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _loading
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
                      Text('Error loading dashboard', style: AppTheme.headingSmall),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: AppTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadDashboardData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: AppTheme.primaryButton,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  color: Colors.blue.shade700,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TimeFilter(
                          selectedPeriod: _selectedPeriod,
                          onPeriodSelected: (period) {
                            setState(() {
                              _selectedPeriod = period;
                            });
                            _loadDashboardData();
                          },
                        ),
                        const SizedBox(height: 24),
                        AppTheme.sectionHeader(
                          'Manager Dashboard Overview',
                          Colors.blue.shade700,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Welcome back! Here's a summary of all inspectors' activities.",
                          style: AppTheme.bodyMedium,
                        ),
                        if (_selectedPeriod != TimeFilterPeriod.all)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Showing data for this ${_selectedPeriod.toShortString()}',
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Stats Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: MediaQuery.of(context).size.width > 1200
                              ? 5
                              : MediaQuery.of(context).size.width > 600
                                  ? 3
                                  : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          children: stats.map((stat) {
                            return Card(
                              elevation: 1,
                              child: InkWell(
                                onTap: () => _navigateToStatDetail(stat["title"].toString()),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              stat["title"].toString(),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            height: 40,
                                            width: 40,
                                            decoration: BoxDecoration(
                                              color: (stat["color"] as Color)
                                                  .withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              stat["icon"] as IconData,
                                              size: 20,
                                              color: stat["color"] as Color,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        stat["value"].toString(),
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Recent Inspections
                        Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Recent Inspections",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_loading)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_error != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  )
                                else if (_recentInspections.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text(
                                        "No recent inspections",
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: _recentInspections
                                        .map((inspection) => _buildInspectionCard(inspection))
                                        .toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  void _navigateToStatDetail(String title) {
    if (title == "Total Inspections") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InspectionsListPage(
            title: 'Total Inspections',
            fetchFunction: DashboardService.getAllInspections,
            headerColor: Colors.blue.shade700,
          ),
        ),
      );
    } else if (title == "Reports Generated") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InspectionsListPage(
            title: 'Reports Generated',
            fetchFunction: DashboardService.getCompletedInspections,
            headerColor: Colors.green,
          ),
        ),
      );
    } else if (title == "Pending Review") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManagerApprovalsPage(),
        ),
      );
    } else if (title == "Completed") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InspectionsListPage(
            title: 'Completed Inspections',
            fetchFunction: DashboardService.getCompletedInspections,
            headerColor: Colors.green,
          ),
        ),
      );
    } else if (title == "Scheduled") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InspectionsListPage(
            title: 'Scheduled Inspections',
            fetchFunction: DashboardService.getInProgressScheduled,
            headerColor: Colors.purple,
          ),
        ),
      );
    }
  }

  Widget _buildInspectionCard(Map<String, dynamic> inspection) {
    final status = inspection['status'] ?? 'unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.grey.shade50,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.2),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 20,
          ),
        ),
        title: Text(
          inspection['title'] ?? 'No Title',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          inspection['location'] ?? 'No Location',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: AppTheme.statusBadge(status),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'pending_review':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled':
        return Icons.schedule;
      case 'pending_review':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  _userName ?? 'Manager',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Manager Account',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.assignment_ind),
            title: const Text('Assign Task'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AssignTaskPage(),
                ),
              );
              if (result == true) {
                _loadDashboardData();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.pending_actions),
            title: const Text('Pending Approvals'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManagerApprovalsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Inspector Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InspectorManagementPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('User Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManagerUserManagementPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThreadsListPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
