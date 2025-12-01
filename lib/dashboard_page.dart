import 'package:flutter/material.dart';
import 'services/dashboard_service.dart';
import 'services/auth_service.dart';
import 'manager_approvals_page.dart';
import 'create_inspection_page.dart';
import 'assign_task_page.dart';
import 'my_tasks_page.dart';
import 'messages_page.dart';
import 'reminders_page.dart';
import 'theme/app_theme.dart';

class DashboardModule extends StatefulWidget {
  const DashboardModule({super.key});

  @override
  State<DashboardModule> createState() => _DashboardModuleState();
}

class _DashboardModuleState extends State<DashboardModule> {
  bool _loading = true;
  String? _error;
  String? _userRole;
  String? _userName;

  Map<String, dynamic>? _statsData;
  List<dynamic> _recentInspections = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadDashboardData();
  }

  Future<void> _loadUserInfo() async {
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
      final stats = await DashboardService.getMonthlyStats();
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
              "value": "${_statsData!['total_inspections'] ?? 0}",
              "change": _statsData!['inspections_change'] ?? "0%",
              "icon": Icons.assignment_turned_in,
              "color": Colors.blue,
              "bg": Colors.blueAccent.withValues(alpha: 0.15),
            },
            {
              "title": "Reports Generated",
              "value": "${_statsData!['total_reports'] ?? 0}",
              "change": _statsData!['reports_change'] ?? "0%",
              "icon": Icons.description,
              "color": Colors.green,
              "bg": Colors.greenAccent.withValues(alpha: 0.15),
            },
            {
              "title": "Pending Review",
              "value": "${_statsData!['pending_review'] ?? 0}",
              "change": "+${_statsData!['pending_review_inspections'] ?? 0}",
              "icon": Icons.warning_amber_rounded,
              "color": Colors.orange,
              "bg": Colors.orangeAccent.withValues(alpha: 0.15),
            },
            {
              "title": "Completed This Month",
              "value": "${_statsData!['completed_this_month'] ?? 0}",
              "change": _statsData!['completed_change'] ?? "0%",
              "icon": Icons.check_circle,
              "color": Colors.green,
              "bg": Colors.greenAccent.withValues(alpha: 0.15),
            },
          ]
        : [
            {
              "title": "Total Inspections",
              "value": "0",
              "change": "0%",
              "icon": Icons.assignment_turned_in,
              "color": Colors.blue,
              "bg": Colors.blueAccent.withValues(alpha: 0.15),
            },
            {
              "title": "Reports Generated",
              "value": "0",
              "change": "0%",
              "icon": Icons.description,
              "color": Colors.green,
              "bg": Colors.greenAccent.withValues(alpha: 0.15),
            },
            {
              "title": "Pending Review",
              "value": "0",
              "change": "0",
              "icon": Icons.warning_amber_rounded,
              "color": Colors.orange,
              "bg": Colors.orangeAccent.withValues(alpha: 0.15),
            },
            {
              "title": "Completed This Month",
              "value": "0",
              "change": "0%",
              "icon": Icons.check_circle,
              "color": Colors.green,
              "bg": Colors.greenAccent.withValues(alpha: 0.15),
            },
          ];

    final upcomingTasks = [
      {
        "title": "Monthly Report Review",
        "date": "Dec 10, 2025",
        "priority": "High",
      },
      {
        "title": "HVAC Inspection",
        "date": "Dec 12, 2025",
        "priority": "Medium",
      },
      {"title": "Cleanliness Audit", "date": "Dec 15, 2025", "priority": "Low"},
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
                  'Inspectra',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Text(
              _userName ?? 'User',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        backgroundColor: _userRole == 'manager'
            ? AppTheme.managerPrimary
            : AppTheme.inspectorPrimary,
        foregroundColor: Colors.white,
        actions: _userRole == 'manager'
            ? [
                IconButton(
                  icon: const Icon(Icons.assignment_ind),
                  tooltip: 'Assign Task',
                  onPressed: () async {
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
                IconButton(
                  icon: const Icon(Icons.pending_actions),
                  tooltip: 'Pending Approvals',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManagerApprovalsPage(),
                      ),
                    );
                  },
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
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.add_task),
                  tooltip: 'Create Inspection',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateInspectionPage(),
                      ),
                    );
                    if (result == true) {
                      _loadDashboardData(); // Refresh dashboard
                    }
                  },
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: _userRole == 'manager' ? Colors.blue : Colors.green,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _userRole == 'manager'
                        ? Icons.admin_panel_settings
                        : Icons.assignment_ind,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName ??
                        (_userRole == 'manager' ? 'Manager' : 'Inspector'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _userRole == 'manager'
                        ? 'Manager Account'
                        : 'Inspector Account',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
            if (_userRole == 'manager') ...[
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inspector Management coming soon'),
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
                      builder: (context) => const MessagesPage(),
                    ),
                  );
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.add_task),
                title: const Text('Create Inspection'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateInspectionPage(),
                    ),
                  );
                  if (result == true) {
                    _loadDashboardData(); // Refresh dashboard
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Submit Report'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Submit Report coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text('My Tasks'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyTasksPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('My Reports'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('My Reports coming soon')),
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
                      builder: (context) => const MessagesPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Reminders'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RemindersPage(),
                    ),
                  );
                },
              ),
            ],
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
      ),
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
              color: _userRole == 'manager'
                  ? AppTheme.managerPrimary
                  : AppTheme.inspectorPrimary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTheme.sectionHeader(
                      'Dashboard Overview',
                      _userRole == 'manager'
                          ? AppTheme.managerPrimary
                          : AppTheme.inspectorPrimary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Welcome back! Here's a summary of your activities.",
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: MediaQuery.of(context).size.width > 900
                          ? 4
                          : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: stats.map((stat) {
                        return Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      stat["title"].toString(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: stat["bg"] as Color,
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
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.trending_up,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${stat["change"]} from last month",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Two column layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isWide = constraints.maxWidth > 700;

                        return Flex(
                          direction: isWide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _error!,
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                      if (!_loading &&
                                          _error == null &&
                                          _recentInspections.isEmpty)
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Text(
                                              "No recent inspections found",
                                            ),
                                          ),
                                        ),
                                      ..._recentInspections.map((item) {
                                        final statusColors = {
                                          'scheduled': Colors.blue,
                                          'in_progress': Colors.orange,
                                          'pending_review': Colors.amber,
                                          'completed': Colors.green,
                                        };
                                        final status =
                                            item['status']?.toString() ??
                                            'scheduled';
                                        final color =
                                            statusColors[status] ?? Colors.grey;

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          item["title"]
                                                                  ?.toString() ??
                                                              'Untitled',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          item["location"]
                                                                  ?.toString() ??
                                                              'No location',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: color.withValues(
                                                        alpha: 0.1,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      status
                                                          .replaceAll('_', ' ')
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: color,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              LinearProgressIndicator(
                                                value: status == 'completed'
                                                    ? 1.0
                                                    : status == 'in_progress'
                                                    ? 0.5
                                                    : 0.1,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                color: color,
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(
                              width: isWide ? 16 : 0,
                              height: isWide ? 0 : 16,
                            ),

                            Expanded(
                              child: Card(
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Upcoming Tasks",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...upcomingTasks.map((task) {
                                        Color bg;
                                        Color text;

                                        switch (task["priority"]) {
                                          case "High":
                                            bg = Colors.red.shade100;
                                            text = Colors.red.shade800;
                                            break;
                                          case "Medium":
                                            bg = Colors.yellow.shade100;
                                            text = Colors.yellow.shade800;
                                            break;
                                          default:
                                            bg = Colors.grey.shade200;
                                            text = Colors.grey.shade800;
                                        }

                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_today,
                                                    size: 20,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        task["title"]
                                                            .toString(),
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      Text(
                                                        task["date"].toString(),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: bg,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  task["priority"].toString(),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: text,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
