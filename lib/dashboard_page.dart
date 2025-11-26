import 'package:flutter/material.dart';

class DashboardModule extends StatelessWidget {
  const DashboardModule({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        "title": "Total Inspections",
        "value": "156",
        "change": "+12%",
        "icon": Icons.assignment_turned_in,
        "color": Colors.blue,
        "bg": Colors.blueAccent.withOpacity(0.15),
      },
      {
        "title": "Reports Generated",
        "value": "89",
        "change": "+8%",
        "icon": Icons.description,
        "color": Colors.green,
        "bg": Colors.greenAccent.withOpacity(0.15),
      },
      {
        "title": "Pending Review",
        "value": "23",
        "change": "+5",
        "icon": Icons.warning_amber_rounded,
        "color": Colors.orange,
        "bg": Colors.orangeAccent.withOpacity(0.15),
      },
      {
        "title": "Completed This Month",
        "value": "67",
        "change": "+15%",
        "icon": Icons.check_circle,
        "color": Colors.green,
        "bg": Colors.greenAccent.withOpacity(0.15),
      }
    ];

    final recentInspections = [
      {"name": "Building A Inspection", "status": "In Progress", "progress": 75},
      {"name": "Office Safety Audit", "status": "Pending Review", "progress": 100},
      {"name": "Electrical Inspection", "status": "Scheduled", "progress": 0},
    ];

    final upcomingTasks = [
      {"title": "Monthly Report Review", "date": "Nov 10, 2025", "priority": "High"},
      {"title": "HVAC Inspection", "date": "Nov 12, 2025", "priority": "Medium"},
      {"title": "Cleanliness Audit", "date": "Nov 15, 2025", "priority": "Low"},
    ];

    return Scaffold(
      body: Row(
        children: [
          // -----------------------
          // LEFT SIDEBAR NAVIGATION
          // -----------------------
          Container(
            width: 240,
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Inspection",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                navItem(
                  icon: Icons.dashboard,
                  label: "Dashboard",
                  selected: true,
                  route: "/dashboard",
                  context: context,
                ),
                navItem(
                  icon: Icons.work,
                  label: "Job Management",
                  route: "/jobs",
                  context: context,
                ),
                navItem(
                  icon: Icons.rate_review,
                  label: "Report Review",
                  route: "/review",
                  context: context,
                ),
                navItem(
                  icon: Icons.folder,
                  label: "Report Repository",
                  route: "/repository",
                  context: context,
                ),
                navItem(
                  icon: Icons.settings,
                  label: "Maintenance Tasks",
                  route: "/maintenance",
                  context: context,
                ),
                navItem(
                  icon: Icons.bar_chart,
                  label: "Analytics & Reports",
                  route: "/analytics",
                  context: context,
                ),
                navItem(
                  icon: Icons.notifications,
                  label: "Notifications",
                  route: "/notifications",
                  context: context,
                ),

                const Spacer(),

                navItem(
                  icon: Icons.logout,
                  label: "Logout",
                  route: "/logout",
                  context: context,
                ),
              ],
            ),
          ),

          // ---------------------------------
          // MAIN DASHBOARD CONTENT AREA (RIGHT)
          // ---------------------------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Dashboard",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    "Welcome back! Here's a summary of your activities.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    physics: const NeverScrollableScrollPhysics(),
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
                                  Text(stat["title"].toString(),
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.grey)),
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
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                stat["value"].toString(),
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.trending_up,
                                      size: 14, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${stat["change"]} from last month",
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.green),
                                  )
                                ],
                              )
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Recent Inspections",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    ...recentInspections.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        item["name"].toString(),
                                                        style: const TextStyle(
                                                            fontSize: 14)),
                                                    Text(
                                                        item["status"]
                                                            .toString(),
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey)),
                                                  ],
                                                ),
                                                Text(
                                                    "${item["progress"]}%",
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            Colors.black54)),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            LinearProgressIndicator(
                                              value: (item["progress"] as int) /
                                                  100.0,
                                              minHeight: 6,
                                            )
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
                              height: isWide ? 0 : 16),

                          Expanded(
                            child: Card(
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Upcoming Tasks",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
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
                                            vertical: 6),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today,
                                                    size: 20,
                                                    color: Colors.grey),
                                                const SizedBox(width: 10),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        task["title"]
                                                            .toString(),
                                                        style: const TextStyle(
                                                            fontSize: 14)),
                                                    Text(
                                                        task["date"]
                                                            .toString(),
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                Colors.grey)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: bg,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                  task["priority"].toString(),
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: text)),
                                            )
                                          ],
                                        ),
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------
  // REUSABLE SIDEBAR ITEM WITH NAVIGATION
  // --------------------------------------
  Widget navItem({
    required IconData icon,
    required String label,
    required String route,
    required BuildContext context,
    bool selected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(icon,
            color: selected ? Colors.blueAccent : Colors.black54),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.blueAccent : Colors.black87,
          ),
        ),
        tileColor: selected ? Colors.blue.shade50 : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
