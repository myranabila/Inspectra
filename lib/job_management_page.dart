import 'package:flutter/material.dart';

class InspectionJobModule extends StatefulWidget {
  const InspectionJobModule({super.key});

  @override
  State<InspectionJobModule> createState() => _InspectionJobModuleState();
}

class _InspectionJobModuleState extends State<InspectionJobModule> {
  String searchTerm = "";

  final inspections = [
    {
      'id': 'INS-001',
      'title': 'Building A Inspection - Floor 3',
      'location': 'Block A, Floor 3',
      'inspector': 'Ahmad Abdullah',
      'scheduledDate': '2025-11-08',
      'status': 'Scheduled',
      'priority': 'High'
    },
    {
      'id': 'INS-002',
      'title': 'Fire Safety Audit',
      'location': 'Entire Premises',
      'inspector': 'Siti Nurhaliza',
      'scheduledDate': '2025-11-10',
      'status': 'In Progress',
      'priority': 'Critical'
    },
    {
      'id': 'INS-003',
      'title': 'Electrical System Inspection',
      'location': 'Block B',
      'inspector': 'Muhammad Ali',
      'scheduledDate': '2025-11-12',
      'status': 'Completed',
      'priority': 'Medium'
    },
    {
      'id': 'INS-004',
      'title': 'HVAC Inspection',
      'location': 'Block C, Floor 1-5',
      'inspector': 'Ahmad Abdullah',
      'scheduledDate': '2025-11-15',
      'status': 'Scheduled',
      'priority': 'Medium'
    },
  ];

  Color statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade100;
      case 'In Progress':
        return Colors.blue.shade100;
      case 'Scheduled':
        return Colors.yellow.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color statusTextColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade800;
      case 'In Progress':
        return Colors.blue.shade800;
      case 'Scheduled':
        return Colors.yellow.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  Color priorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red.shade100;
      case 'High':
        return Colors.orange.shade100;
      case 'Medium':
        return Colors.yellow.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color priorityTextColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red.shade800;
      case 'High':
        return Colors.orange.shade800;
      case 'Medium':
        return Colors.yellow.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // Prevents overlap + follows your reference UI
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───────────────────────────────────────────
            // TOP BAR (Back button + Title + Add Job)
            // ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 26),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/dashboard');
                      },
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Inspection Jobs",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Add Job button (matches the image)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text("Add Job"),
                ),
              ],
            ),

            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.only(left: 56),
              child: Text(
                "Manage and schedule inspection jobs",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 26),

            // ───────────────────────────────────────────
            // WHITE CARD CONTAINER
            // ───────────────────────────────────────────
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 1.5,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Search bar row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Inspection List",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              // Search bar
                              SizedBox(
                                width: 260,
                                child: TextField(
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search),
                                    hintText: "Search inspections...",
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    setState(() => searchTerm = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),

                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                                onPressed: () {},
                                child: const Icon(Icons.filter_list),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ───────────────────────────────────────────
                      // TABLE AREA (Scrollable & Expandable)
                      // ───────────────────────────────────────────
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  Colors.grey.shade200,
                                ),
                                columnSpacing: 32,
                                dataRowHeight: 58,
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('Title')),
                                  DataColumn(label: Text('Location')),
                                  DataColumn(label: Text('Inspector')),
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Priority')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: inspections
                                    .where((i) => i['title']!
                                        .toLowerCase()
                                        .contains(searchTerm.toLowerCase()))
                                    .map((inspection) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(inspection['id']!)),
                                      DataCell(Text(inspection['title']!)),
                                      DataCell(Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(inspection['location']!),
                                        ],
                                      )),
                                      DataCell(Row(
                                        children: [
                                          const Icon(Icons.person,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(inspection['inspector']!),
                                        ],
                                      )),
                                      DataCell(Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(inspection['scheduledDate']!),
                                        ],
                                      )),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: statusColor(
                                                inspection['status']!),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            inspection['status']!,
                                            style: TextStyle(
                                              color: statusTextColor(
                                                  inspection['status']!),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: priorityColor(
                                                inspection['priority']!),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            inspection['priority']!,
                                            style: TextStyle(
                                              color: priorityTextColor(
                                                  inspection['priority']!),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        TextButton(
                                          onPressed: () {},
                                          child: const Text("View"),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
