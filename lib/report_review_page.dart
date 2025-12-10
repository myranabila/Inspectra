import 'package:flutter/material.dart';
import 'services/report_service.dart';

class ReportReviewPage extends StatelessWidget {
  const ReportReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Review',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Row(
        children: [
          // LEFT SIDEBAR -------------------------------------------------------
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Pending Reports',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  child: ListView(
                    children: List.generate(8, (i) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: Text('${i + 1}'),
                        ),
                        title: Text('Report 00${i + 1}'),
                        subtitle: const Text(
                          'Standard Report',
                          style: TextStyle(color: Colors.grey),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade600,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // RIGHT CONTENT AREA -------------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report Info Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report 001',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Submitted by: John Doe',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),

                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Full Preview'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Card ----------------------------------------------------------
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),

                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            // TAB BAR
                            const TabBar(
                              labelColor: Colors.black,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.purple,
                              tabs: [
                                Tab(text: 'Report Content'),
                                Tab(text: 'Comments'),
                                Tab(text: 'History'),
                              ],
                            ),

                            // TAB CONTENT
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // Report Content Tab
                                  SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Form ID  #F0011',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Report Summary Lorem ipsum dolor sit...',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Comments Tab
                                  SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _commentTile(
                                          'Ashley Villadestar',
                                          'Ok it seems correct...',
                                        ),
                                        const SizedBox(height: 12),
                                        _commentTile(
                                          'Joshua Blay',
                                          'Hello, please revise this section...',
                                        ),
                                      ],
                                    ),
                                  ),

                                  // History Tab
                                  SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('01/09/2024 - Submitted'),
                                        SizedBox(height: 8),
                                        Text('02/09/2024 - Reviewed'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons ------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          // TODO: Get reportId and reason from UI
                          final reportId = 1; // Replace with actual report ID
                          final reason = 'Needs revision'; // Replace with actual reason
                          final result = await ReportService.rejectReport(reportId, reason);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message'] ?? 'Revision requested')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Request Revision'),
                      ),
                      const SizedBox(width: 12),

                      ElevatedButton(
                        onPressed: () async {
                          // TODO: Get reportId from UI
                          final reportId = 1; // Replace with actual report ID
                          final result = await ReportService.approveReport(reportId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message'] ?? 'Report approved')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// COMMENT TILE WIDGET ----------------------------------------------------------
Widget _commentTile(String name, String comment) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF9F9F9),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(comment),
            ],
          ),
        ),
      ],
    ),
  );
}
