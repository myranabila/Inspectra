import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

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

class _InspectionsListPageState extends State<InspectionsListPage> {
  bool _isLoading = true;
  List<dynamic> _inspections = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final inspections = await widget.fetchFunction();
      setState(() {
        _inspections = inspections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending_review':
        return Colors.purple;
      case 'rejected':
        return Colors.red;
      case 'scheduled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'pending_review':
        return 'Pending Review';
      case 'rejected':
        return 'Rejected';
      case 'scheduled':
        return 'Scheduled';
      default:
        return status;
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
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!_isLoading && _error == null)
              Text(
                '${_inspections.length} ${_inspections.length == 1 ? 'record' : 'records'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        backgroundColor: widget.headerColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
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
                      Text('Error loading data', style: AppTheme.headingSmall),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: AppTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadInspections,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: AppTheme.primaryButton,
                      ),
                    ],
                  ),
                )
              : _inspections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No records found',
                            style: AppTheme.headingSmall.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'There are no inspections in this category',
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadInspections,
                      color: widget.headerColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _inspections.length,
                        itemBuilder: (context, index) {
                          final inspection = _inspections[index];

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                // TODO: Navigate to inspection details
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title + status chip
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            inspection['title'] ?? 'Untitled',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              inspection['status'] ?? '',
                                            ).withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getStatusColor(
                                                inspection['status'] ?? '',
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            _formatStatus(
                                              inspection['status'] ?? '',
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _getStatusColor(
                                                inspection['status'] ?? '',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // Location
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            inspection['location'] ??
                                                'No location',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    // Dates
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Scheduled: ${_formatDate(inspection['scheduled_date'])}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (inspection['completion_date'] !=
                                            null) ...[
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 16,
                                            color: Colors.green.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Completed: ${_formatDate(inspection['completion_date'])}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.green.shade600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),

                                    // Notes (optional)
                                    if (inspection['notes'] != null &&
                                        inspection['notes']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.note_outlined,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                inspection['notes'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700,
                                                ),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // View PDF button (optional)
                                    if (inspection['status'] ==
                                            'pending_review' ||
                                        inspection['status'] == 'completed')
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          icon: const Icon(
                                            Icons.picture_as_pdf,
                                            color: Colors.red,
                                          ),
                                          label: const Text('View PDF'),
                                          onPressed: () async {
                                            // TODO: Implement PDF viewing with url_launcher
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
