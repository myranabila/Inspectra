import 'package:flutter/material.dart';
import 'services/dashboard_service.dart';
import 'services/messaging_service.dart';
import 'theme/app_theme.dart';
import 'inspection_workflow_page.dart';

class MyTasksPage extends StatefulWidget {
  final TaskFilterUrgency? initialUrgencyFilter;
  final Set<String>? initialStatusFilter;
  final bool showAllInspections;
  
  const MyTasksPage({
    super.key,
    this.initialUrgencyFilter,
    this.initialStatusFilter,
    this.showAllInspections = false,
  });

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

enum TaskSortBy { date, priority, status, location }
enum TaskFilterUrgency { all, overdue, today, thisWeek, later }

class _MyTasksPageState extends State<MyTasksPage> {
  bool _isLoading = true;
  List<dynamic> _tasks = [];
  List<dynamic> _filteredTasks = [];
  String? _error;
  
  // Filter states
  String _searchQuery = '';
  Set<String> _selectedStatuses = {};
  TaskFilterUrgency _urgencyFilter = TaskFilterUrgency.all;
  TaskSortBy _sortBy = TaskSortBy.date;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Set initial filters from widget parameters
    if (widget.initialUrgencyFilter != null) {
      _urgencyFilter = widget.initialUrgencyFilter!;
      _showFilters = true; // Show filters if preset
    }
    if (widget.initialStatusFilter != null) {
      _selectedStatuses = widget.initialStatusFilter!;
      _showFilters = true; // Show filters if preset
    }
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await DashboardService.getMyTasks();

      setState(() {
        _tasks = tasks;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<dynamic> filtered = List.from(_tasks);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        final title = (task['title'] ?? '').toString().toLowerCase();
        final location = (task['location'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || location.contains(query);
      }).toList();
    }

    // Status filter
    if (_selectedStatuses.isNotEmpty) {
      filtered = filtered.where((task) {
        return _selectedStatuses.contains(task['status']);
      }).toList();
    }

    // Urgency filter
    if (_urgencyFilter != TaskFilterUrgency.all) {
      filtered = filtered.where((task) {
        final dueDate = _parseDate(task['scheduled_date']);
        if (dueDate == null) return _urgencyFilter == TaskFilterUrgency.later;
        
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekEnd = today.add(const Duration(days: 7));

        switch (_urgencyFilter) {
          case TaskFilterUrgency.overdue:
            return dueDate.isBefore(today);
          case TaskFilterUrgency.today:
            return dueDate.isAtSameMomentAs(today);
          case TaskFilterUrgency.thisWeek:
            return dueDate.isAfter(today) && dueDate.isBefore(weekEnd);
          case TaskFilterUrgency.later:
            return dueDate.isAfter(weekEnd) || dueDate.isAtSameMomentAs(weekEnd);
          default:
            return true;
        }
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case TaskSortBy.date:
        filtered.sort((a, b) {
          final dateA = _parseDate(a['scheduled_date']);
          final dateB = _parseDate(b['scheduled_date']);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB);
        });
        break;
      case TaskSortBy.priority:
        // Priority based on urgency
        filtered.sort((a, b) {
          final urgencyA = _getUrgencyLevel(a);
          final urgencyB = _getUrgencyLevel(b);
          return urgencyB.compareTo(urgencyA); // Higher urgency first
        });
        break;
      case TaskSortBy.status:
        filtered.sort((a, b) {
          final statusOrder = {
            'scheduled': 0,
            'pending_review': 1,
            'rejected': 2,
            'completed': 3,
          };
          return (statusOrder[a['status']] ?? 4)
              .compareTo(statusOrder[b['status']] ?? 4);
        });
        break;
      case TaskSortBy.location:
        filtered.sort((a, b) {
          return (a['location'] ?? '').toString().compareTo(
              (b['location'] ?? '').toString());
        });
        break;
    }

    setState(() {
      _filteredTasks = filtered;
    });
  }

  DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr.toString());
    } catch (e) {
      return null;
    }
  }

  int _getUrgencyLevel(dynamic task) {
    final dueDate = _parseDate(task['scheduled_date']);
    if (dueDate == null) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = dueDate.difference(today).inDays;

    if (diff < 0) return 5; // Overdue - highest priority
    if (diff == 0) return 4; // Today
    if (diff == 1) return 3; // Tomorrow
    if (diff <= 7) return 2; // This week
    return 1; // Later
  }

  Map<String, List<dynamic>> _groupTasksByDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    final Map<String, List<dynamic>> grouped = {
      'Overdue': [],
      'Today': [],
      'Tomorrow': [],
      'This Week': [],
      'Later': [],
      'No Due Date': [],
    };

    for (var task in _filteredTasks) {
      final dueDate = _parseDate(task['scheduled_date']);
      
      if (dueDate == null) {
        grouped['No Due Date']!.add(task);
      } else if (dueDate.isBefore(today)) {
        grouped['Overdue']!.add(task);
      } else if (dueDate.isAtSameMomentAs(today)) {
        grouped['Today']!.add(task);
      } else if (dueDate.isAtSameMomentAs(tomorrow)) {
        grouped['Tomorrow']!.add(task);
      } else if (dueDate.isBefore(weekEnd)) {
        grouped['This Week']!.add(task);
      } else {
        grouped['Later']!.add(task);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    
    return grouped;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'pending_review':
        return Colors.purple;
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
        return Icons.edit_note;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Future<void> _setReminder(int inspectionId, String title) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'For task: $title',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Reminder Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select Date',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          selectedTime != null
                              ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                              : 'Select Time',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (titleController.text.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a reminder title'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (selectedDate == null || selectedTime == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select date and time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final remindAt = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      try {
        await MessagingService.createReminder(
          inspectionId: inspectionId,
          title: titleController.text,
          message: messageController.text.isNotEmpty
              ? messageController.text
              : null,
          remindAt: remindAt,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder set successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedTasks = _groupTasksByDate();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.inspectorPrimary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.assignment_turned_in, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Inspector Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('My Tasks'),
              selected: true,
              selectedTileColor: Colors.blue.shade50,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/history');
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Messages'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/messages');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'My Tasks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppTheme.inspectorPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Filters',
          ),
          PopupMenuButton<TaskSortBy>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TaskSortBy.date,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18),
                    SizedBox(width: 12),
                    Text('Due Date'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TaskSortBy.priority,
                child: Row(
                  children: [
                    Icon(Icons.priority_high, size: 18),
                    SizedBox(width: 12),
                    Text('Priority'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TaskSortBy.status,
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18),
                    SizedBox(width: 12),
                    Text('Status'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TaskSortBy.location,
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 18),
                    SizedBox(width: 12),
                    Text('Location'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _applyFilters();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                isDense: true,
              ),
            ),
          ),
          
          // Filter chips
          if (_showFilters)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Urgency filter
                  const Text(
                    'Urgency',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _urgencyFilter == TaskFilterUrgency.all,
                        onSelected: (selected) {
                          setState(() {
                            _urgencyFilter = TaskFilterUrgency.all;
                            _applyFilters();
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Overdue'),
                        selected: _urgencyFilter == TaskFilterUrgency.overdue,
                        onSelected: (selected) {
                          setState(() {
                            _urgencyFilter = TaskFilterUrgency.overdue;
                            _applyFilters();
                          });
                        },
                        avatar: const Icon(Icons.warning, size: 16),
                      ),
                      FilterChip(
                        label: const Text('Today'),
                        selected: _urgencyFilter == TaskFilterUrgency.today,
                        onSelected: (selected) {
                          setState(() {
                            _urgencyFilter = TaskFilterUrgency.today;
                            _applyFilters();
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('This Week'),
                        selected: _urgencyFilter == TaskFilterUrgency.thisWeek,
                        onSelected: (selected) {
                          setState(() {
                            _urgencyFilter = TaskFilterUrgency.thisWeek;
                            _applyFilters();
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Later'),
                        selected: _urgencyFilter == TaskFilterUrgency.later,
                        onSelected: (selected) {
                          setState(() {
                            _urgencyFilter = TaskFilterUrgency.later;
                            _applyFilters();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Status filter
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Scheduled'),
                        selected: _selectedStatuses.contains('scheduled'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedStatuses.add('scheduled');
                            } else {
                              _selectedStatuses.remove('scheduled');
                            }
                            _applyFilters();
                          });
                        },
                        avatar: const Icon(Icons.schedule, size: 16),
                      ),
                      FilterChip(
                        label: const Text('Pending Review'),
                        selected: _selectedStatuses.contains('pending_review'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedStatuses.add('pending_review');
                            } else {
                              _selectedStatuses.remove('pending_review');
                            }
                            _applyFilters();
                          });
                        },
                        avatar: const Icon(Icons.pending, size: 16),
                      ),
                      FilterChip(
                        label: const Text('Rejected'),
                        selected: _selectedStatuses.contains('rejected'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedStatuses.add('rejected');
                            } else {
                              _selectedStatuses.remove('rejected');
                            }
                            _applyFilters();
                          });
                        },
                        avatar: const Icon(Icons.cancel, size: 16),
                      ),
                      FilterChip(
                        label: const Text('Completed'),
                        selected: _selectedStatuses.contains('completed'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedStatuses.add('completed');
                            } else {
                              _selectedStatuses.remove('completed');
                            }
                            _applyFilters();
                          });
                        },
                        avatar: const Icon(Icons.check_circle, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Clear filters button
                  if (_selectedStatuses.isNotEmpty ||
                      _urgencyFilter != TaskFilterUrgency.all ||
                      _searchQuery.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedStatuses.clear();
                          _urgencyFilter = TaskFilterUrgency.all;
                          _searchQuery = '';
                          _applyFilters();
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear All Filters'),
                    ),
                ],
              ),
            ),
          
          // Task list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTasks,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks assigned yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your manager will assign tasks to you',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : _filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_alt_off,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks match your filters',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedTasks.entries.length,
                      itemBuilder: (context, index) {
                        final entry = groupedTasks.entries.elementAt(index);
                        final groupName = entry.key;
                        final groupTasks = entry.value;
                        
                        return _buildTaskGroup(groupName, groupTasks);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskGroup(String groupName, List<dynamic> tasks) {
    Color groupColor;
    IconData groupIcon;
    
    switch (groupName) {
      case 'Overdue':
        groupColor = Colors.red;
        groupIcon = Icons.warning;
        break;
      case 'Today':
        groupColor = Colors.orange;
        groupIcon = Icons.today;
        break;
      case 'Tomorrow':
        groupColor = Colors.blue;
        groupIcon = Icons.event;
        break;
      case 'This Week':
        groupColor = Colors.green;
        groupIcon = Icons.date_range;
        break;
      default:
        groupColor = Colors.grey;
        groupIcon = Icons.schedule;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(groupIcon, size: 18, color: groupColor),
              ),
              const SizedBox(width: 12),
              Text(
                '$groupName (${tasks.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: groupColor,
                ),
              ),
            ],
          ),
        ),
        
        // Group tasks
        ...tasks.map((task) => _buildTaskCard(task)),
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final status = task['status'] ?? 'scheduled';
    final color = _getStatusColor(status);
    final isRejected = status == 'rejected';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: isRejected
          ? RoundedRectangleBorder(
              side: BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: InkWell(
        onTap: () {
          // Navigate to inspection workflow for scheduled or rejected tasks
          if (status == 'scheduled' || status == 'rejected') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InspectionWorkflowPage(
                  inspection: task,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rejection banner
              if (isRejected) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚠️ REVISION REQUIRED',
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (task['rejection_reason'] != null) ...[
                              SizedBox(height: 4),
                              Text(
                                'Reason: ${task['rejection_reason']}',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (task['rejection_feedback'] != null) ...[
                              SizedBox(height: 4),
                              Text(
                                '${task['rejection_feedback']}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
              ],
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                task['location'] ?? 'No location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (task['equipment_id'] != null || task['equipment_type'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${task['equipment_id'] ?? 'N/A'} - ${task['equipment_type'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isRejected ? 'NEEDS REVISION' : status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (task['scheduled_date'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${task['scheduled_date']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
              if (task['notes'] != null &&
                  task['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task['notes'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _setReminder(
                      task['id'],
                      task['title'] ?? 'Untitled',
                    ),
                    icon: const Icon(
                      Icons.notifications_outlined,
                      size: 18,
                    ),
                    label: const Text('Reminder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.inspectorPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  if (status == 'scheduled')
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Start inspection
                      },
                      icon: const Icon(
                        Icons.play_arrow,
                        size: 18,
                      ),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  if (status == 'pending_review')
                    ElevatedButton.icon(
                      onPressed: () {
                        // View submitted inspection
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  if (status == 'pending_review')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pending,
                            size: 16,
                            color: Colors.purple.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Waiting for approval',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (status == 'completed')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
