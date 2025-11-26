import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart'; 
// Note: You need these imports for the helper functions to work
// ignore: unused_import
import 'package:provider/provider.dart'; 

// --- Global Constant for Fallback/Dummy User -------------------------------
const String fallbackUid = 'debug-inspector-uid-001'; 
// --------------------------------------------------------------------------

// --- Data Models ----------------------------------------------------------
class MenuItem {
  final String title;
  final IconData icon;
  final String route;
  const MenuItem(this.title, this.icon, this.route);
}

const List<MenuItem> menuItems = [
  MenuItem('Dashboard', Icons.dashboard, '/'),
  MenuItem('Inspection Jobs', Icons.work, '/jobs'), 
  MenuItem('Report Drafting', Icons.edit_note, '/draft'),
  MenuItem('Report Generation', Icons.assessment, '/generate'),
  MenuItem('Report Review', Icons.rate_review, '/review'),
  MenuItem('Report Repository', Icons.folder, '/repository'),
  MenuItem('Maintenance Tasks', Icons.build, '/maintenance'),
  MenuItem('Analytics & Reports', Icons.analytics, '/analytics'),
  MenuItem('Media Manager', Icons.camera_roll, '/upload'),
  MenuItem('Notifications', Icons.notifications, '/notifications'),
  MenuItem('Export & Integration', Icons.cloud_upload, '/export'),
  MenuItem('User Management', Icons.people, '/users'),
];

// --- Dashboard Screen -----------------------------------------------------
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: !isLargeScreen
          ? AppBar(
              title: const Text('Inspection'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              actions: [_buildProfileHeader(context)],
            )
          : null,
      drawer: !isLargeScreen ? _buildSidebar(context) : null,
      backgroundColor: Colors.grey.shade100,
      body: Row(
        children: [
          if (isLargeScreen) _buildSidebar(context),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (isLargeScreen)
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    toolbarHeight: 70,
                    pinned: true,
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        // Align profile header to the right
                        mainAxisAlignment: MainAxisAlignment.end, 
                        children: [
                          // REMOVED: Welcome back! text is gone
                          _buildProfileHeader(context),
                        ],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.all(32),
                  sliver: _buildDashboardContent(context, isLargeScreen), 
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ----------  Sidebar  ---------- */
  Widget _buildSidebar(BuildContext context) {
    const double sidebarWidth = 250;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: sidebarWidth,
      child: Material( 
        color: Colors.white,
        child: Column(
          children: [
            // --- HEADER ROW (Title, Logo, Arrow all REMOVED) ---
            Container(
              height: 70,
              padding: const EdgeInsets.only(left: 20, top: 10),
              alignment: Alignment.centerLeft,
              child: const Row(
                // Only includes the fixed arrow for visual structure, or is empty.
                children: [
                  Spacer(), // Push content right
                  // Arrow icon removed
                  // Icon(Icons.keyboard_arrow_left, color: Colors.grey),
                  SizedBox(width: 10), 
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.grey),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  
                  // FIX: Only apply selection style if the route is NOT the Dashboard ('/')
                  final bool isSelected = item.route == currentRoute && item.route != '/';
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      // Color is only applied if isSelected is true
                      color: isSelected ? primaryColor.withValues(alpha: 20) : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: Icon(
                        item.icon,
                        // Icon color is only primary if isSelected is true
                        color: isSelected ? primaryColor : Colors.grey.shade700,
                        size: 22,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          // Text color is only primary if isSelected is true
                          color: isSelected ? primaryColor : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        if (item.route == '/' ||
                            item.route == '/profile' ||
                            item.route == '/upload' || 
                            item.route == '/jobs' 
                            ) {
                          context.go(item.route); // Use GoRouter
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Route not yet defined for: ${item.title}')),
                          );
                        }
                        if (MediaQuery.of(context).size.width < 800) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.grey),
              title: const Text('Log Out'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /* ----------  Profile Header  ---------- */
  Widget _buildProfileHeader(BuildContext context) {
    return Row(
      children: [
        // Stack MUST be dynamic (non-const) because it contains the IconButton
        Stack(
          children: [
            // Notification Bell (Badge removed)
            IconButton(
              icon: const Icon(Icons.notifications_none,
                  size: 28, color: Color(0xFF757575)), 
              onPressed: () {},
            ),
            // The Positioned badge element is REMOVED.
          ],
        ),
        const SizedBox(width: 16),
        InkWell(
          // FIX: Use context.go() for GoRouter navigation
          onTap: () => context.go('/profile'), 
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: Text('A',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Abu',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold)),
                  Text('Administrator',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down,
                  size: 20, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  /* ----------  Dashboard Content  ---------- */
  Widget _buildDashboardContent(BuildContext context, bool isLargeScreen) {
    // NOTE: Requires InspectorProvider to be available via context
    // final provider = context.watch<InspectorProvider>(); 
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? fallbackUid; 

    final crossAxisCount = isLargeScreen
        ? 4
        : (MediaQuery.of(context).size.width > 600 ? 2 : 1);

    return SliverList(
      delegate: SliverChildListDelegate.fixed([
        // =========  LIVE STAT CARDS  =========
        FutureBuilder<Map<String, int>>(
          future: _fetchDashboardStats(uid),
          builder: (_, statsSnap) {
            if (statsSnap.connectionState == ConnectionState.waiting) {
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 0, 
                mainAxisSpacing: 20,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: List.generate(4, (_) => const Card(child: Center(child: CircularProgressIndicator.adaptive()))), 
              );
            }

            final stats = statsSnap.data ?? {};
            final total = stats['total'] ?? 0;
            final completed = stats['completed'] ?? 0;
            final pending = stats['pending'] ?? 0;
            
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 0, 
              mainAxisSpacing: 20,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                _liveStatCard(context, 'Total Inspections', '$total', '', Colors.blue, Icons.checklist_rtl),
                _liveStatCard(context, 'Reports Generated', '$completed', '', Colors.green, Icons.description),
                _liveStatCard(context, 'Pending Review', '$pending', '', Colors.orange, Icons.access_time_filled),
                _liveStatCard(context, 'Completed This Month', 'N/A', '', Colors.teal, Icons.check_circle, showBorder: false), 
              ],
            );
          },
        ),

        const SizedBox(height: 32),

// =========  LIVE RECENT INSPECTIONS  =========
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('inspections')
              .where('userId', isEqualTo: uid)
              .orderBy('date', descending: true)
              .limit(4)
              .snapshots(),
          builder: (_, snap) {
            if (snap.hasError) {
              return const Card(
                child: ListTile(
                  leading: Icon(Icons.error_outline, color: Colors.red),
                  title: Text('Error loading inspections'),
                ),
              );
            }
            if (!snap.hasData) return const Center(child: CircularProgressIndicator.adaptive());

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.inbox_outlined),
                  title: const Text('No inspections yet for this user ID'),
                  subtitle: Text('Current ID: $uid'), 
                ),
              );
            }

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Inspections',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    ...docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return _buildInspectionProgress(
                        data['title'] ?? 'No title',
                        data['status'] ?? 'Unknown',
                        (data['progress'] ?? 0).toDouble(),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        // =========  LIVE UPCOMING TASKS  =========
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .where('userId', isEqualTo: uid)
              .where('dueDate', isGreaterThanOrEqualTo: Timestamp.now())
              .orderBy('dueDate')
              .limit(3)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final docs = snap.data!.docs;
            
            if (docs.isEmpty) {
              return const SizedBox.shrink(); 
            }

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upcoming Tasks', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    ...docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final dueDateTimestamp = data['dueDate'] as Timestamp?;
                      final due = dueDateTimestamp?.toDate();
                      return _buildTaskItem(
                        data['title'] ?? 'No title',
                        due != null ? '${due.day}/${due.month}/${due.year}' : 'N/A',
                        data['priority'] ?? 'Low',
                        _priorityColor(data['priority']),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  /* -------------------------------------------------- 
      Helper functions / widgets 
      -------------------------------------------------- */

  Future<Map<String, int>> _fetchDashboardStats(String uid) async {
    final totalFuture = _countInspections(uid);
    final completedFuture = _countCompleted(uid);

    final results = await Future.wait([totalFuture, completedFuture]);

    final total = results[0];
    final completed = results[1];

    return {
      'total': total,
      'completed': completed,
      'pending': total - completed,
    };
  }

  Future<int> _countInspections(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('inspections')
        .where('userId', isEqualTo: uid)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> _countCompleted(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('inspections')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'Completed')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Widget _liveStatCard(BuildContext context, String title, String value, String change, Color color, IconData icon, {bool showBorder = true}) {
    final borderColor = Colors.grey.shade300;

    return Container(
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                right: BorderSide(color: borderColor, width: 1.0),
              ),
            )
          : null,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(color: color.withValues(alpha: 25), borderRadius: BorderRadius.circular(8)), 
                    child: Icon(icon, color: color, size: 24)
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(value, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87)),
              if (change.isNotEmpty)
                Row(children: [Icon(Icons.arrow_upward, color: Colors.green.shade600, size: 16), const SizedBox(width: 4), Text(change, style: TextStyle(color: Colors.green.shade600, fontSize: 14))]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionProgress(String title, String status, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(status, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text('${(progress * 100).toInt()}%', style: TextStyle(color: progress == 1.0 ? Colors.teal : Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: progress == 1.0 ? Colors.teal : Colors.blue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, String date, String priority, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              Text(date, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(priority, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String? p) {
    switch (p) {
      case 'High': return Colors.red;
      case 'Medium': return Colors.amber;
      default: return Colors.blueGrey;
    }
  }
}