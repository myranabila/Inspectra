import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/manager_service.dart';
import 'services/profile_service.dart'; 
import 'theme/app_theme.dart';

class InspectorManagementPage extends StatefulWidget {
  const InspectorManagementPage({super.key});

  @override
  State<InspectorManagementPage> createState() =>
      _InspectorManagementPageState();
}

class _InspectorManagementPageState extends State<InspectorManagementPage> {
  List<Map<String, dynamic>> _inspectors = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'name';

  final Color _bgColor = const Color(0xFFF5F7FA);
  final Color _cardColor = Colors.white;
  final Color _textDark = const Color(0xFF2D3436);
  final Color _textLight = const Color(0xFF636E72);

  @override
  void initState() {
    super.initState();
    _loadInspectors();
  }

  Future<void> _saveRole(String email, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role_$email', role);
  }

  Future<String?> _loadRole(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role_$email');
  }

  Future<void> _saveActiveStatus(String email, bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('active_$email', isActive);
  }

  Future<bool> _loadActiveStatus(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('active_$email') ?? true;
  }

  Future<void> _loadInspectors() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        ManagerService.getInspectors(),                 
        ProfileService.getAllUsers(includeInactive: true), 
      ]);

      final inspectorData = List<Map<String, dynamic>>.from(results[0]);
      final allUsersData = List<Map<String, dynamic>>.from(results[1]);

      _inspectors = inspectorData;

      for (var inspector in _inspectors) {
        final email = inspector['email'];

        final userMatch = allUsersData.firstWhere(
          (u) => u['email'] == email,
          orElse: () => <String, dynamic>{},
        );

        bool isUserAccountActive = userMatch.isNotEmpty ? (userMatch['is_active'] ?? true) : true;
        
        inspector['account_active'] = isUserAccountActive;

        final savedRole = await _loadRole(email);
        final isInspectorActiveLocally = await _loadActiveStatus(email);

        inspector['role'] = savedRole ?? inspector['role'] ?? 'Inspector';

        if (!isUserAccountActive) {
          inspector['is_active'] = false;
          inspector['status_label'] = 'SUSPENDED';
        } else {
          inspector['is_active'] = isInspectorActiveLocally;
          inspector['status_label'] = isInspectorActiveLocally ? 'Active' : 'On Leave';
        }
      }

      _sortInspectors();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sortInspectors() {
    _inspectors.sort((a, b) {
      switch (_sortBy) {
        case 'total_tasks':
          return (b['total_tasks'] ?? 0).compareTo(a['total_tasks'] ?? 0);
        case 'completion_rate':
          return (b['completion_rate'] ?? 0).compareTo(a['completion_rate'] ?? 0);
        case 'approval_rate':
          return (b['approval_rate'] ?? 0).compareTo(a['approval_rate'] ?? 0);
        default:
          return a['username'].toString().compareTo(b['username'].toString());
      }
    });
  }

  Color _rateColor(double rate) {
    if (rate >= 80) return Colors.green.shade600;
    if (rate >= 60) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  void _editInspector(Map<String, dynamic> inspector) {
    final nameController = TextEditingController(text: inspector['username']);
    final emailController = TextEditingController(text: inspector['email']);
    String selectedRole = inspector['role'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Inspector'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController, 
              decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController, 
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Inspector', child: Text('Inspector')),
                DropdownMenuItem(value: 'Senior Inspector', child: Text('Senior Inspector')),
              ],
              onChanged: (value) {
                selectedRole = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel')
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.managerPrimary, 
              foregroundColor: Colors.white
            ),
            onPressed: () async {
              setState(() {
                inspector['username'] = nameController.text;
                inspector['email'] = emailController.text;
                inspector['role'] = selectedRole;
              });

              await _saveRole(inspector['email'], selectedRole);
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.lock, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Inspector Management', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        backgroundColor: AppTheme.managerPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInspectors,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.managerPrimary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    _buildFilterHeader(),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _inspectors.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final inspector = _inspectors[index];
                          return _buildModernCard(inspector);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      color: _bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_inspectors.length} Staff Members',
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: _textDark
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                icon: const Icon(Icons.sort_rounded, size: 20),
                style: TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w500),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                  DropdownMenuItem(value: 'total_tasks', child: Text('Most Tasks')),
                  DropdownMenuItem(value: 'completion_rate', child: Text('Best Completion')),
                  DropdownMenuItem(value: 'approval_rate', child: Text('Best Approval')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                    _sortInspectors();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard(Map<String, dynamic> inspector) {
    final completion = (inspector['completion_rate'] as num).toDouble();
    final approval = (inspector['approval_rate'] as num).toDouble();
    
    bool isActive = inspector['is_active']; 
    bool isAccountActive = inspector['account_active']; 
    String statusLabel = inspector['status_label'];

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        border: !isAccountActive ? Border.all(color: Colors.red.withOpacity(0.3), width: 1.5) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: !isAccountActive ? Colors.grey.shade300 : AppTheme.managerPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      inspector['username'][0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: !isAccountActive ? Colors.grey.shade600 : AppTheme.managerPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inspector['username'],
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          decoration: !isAccountActive ? TextDecoration.lineThrough : null,
                          color: !isAccountActive ? Colors.grey : _textDark
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inspector['email'],
                        style: TextStyle(fontSize: 12, color: _textLight),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBadge(
                            label: inspector['role'],
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            label: statusLabel,
                            color: !isAccountActive 
                                ? Colors.red 
                                : (isActive ? Colors.green : Colors.orange), 
                            isOutlined: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: _textLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _editInspector(inspector);
                    } else if (value == 'toggle') {
                      if (!isAccountActive) {
                        _showErrorSnackbar("Cannot activate. User account is deactivated in User Management.");
                        return;
                      }

                      final newStatus = !isActive;
                      setState(() {
                        inspector['is_active'] = newStatus;
                        inspector['status_label'] = newStatus ? 'Active' : 'On Leave';
                      });
                      await _saveActiveStatus(inspector['email'], newStatus);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.grey), 
                          SizedBox(width: 8), 
                          Text('Edit Profile')
                        ]
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      enabled: isAccountActive, 
                      child: Row(
                        children: [
                          Icon(
                            !isAccountActive 
                                ? Icons.lock 
                                : (isActive ? Icons.block : Icons.check_circle), 
                            size: 18, 
                            color: !isAccountActive 
                                ? Colors.grey 
                                : (isActive ? Colors.orange : Colors.green)
                          ),
                          const SizedBox(width: 8), 
                          Text(
                            !isAccountActive 
                              ? 'Account Deactivated' 
                              : (isActive ? 'Set "On Leave"' : 'Set "Active"')
                          )
                        ]
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Opacity(
            opacity: !isAccountActive ? 0.5 : 1.0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA), 
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', inspector['total_tasks'].toString(), Colors.blueAccent),
                  _verticalDivider(),
                  _buildStatItem('Done', inspector['completed_tasks'].toString(), Colors.green),
                  _verticalDivider(),
                  _buildStatItem('Pending', inspector['pending_review'].toString(), Colors.orange),
                  _verticalDivider(),
                  _buildStatItem('Plan', inspector['scheduled'].toString(), Colors.purpleAccent),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Opacity(
             opacity: !isAccountActive ? 0.5 : 1.0,
             child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                children: [
                  _buildProgressBar('Completion Rate', completion),
                  const SizedBox(height: 10),
                  _buildProgressBar('Approval Rate', approval),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(height: 24, width: 1, color: Colors.grey.shade300);
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: _textLight, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBadge({required String label, required Color color, bool isOutlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: isOutlined ? Border.all(color: color.withOpacity(0.5)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage) {
    final color = _rateColor(percentage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: _textLight, fontWeight: FontWeight.w500)),
            Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}