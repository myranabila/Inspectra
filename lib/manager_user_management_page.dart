import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/profile_service.dart';

class ManagerUserManagementPage extends StatefulWidget {
  const ManagerUserManagementPage({super.key});

  @override
  State<ManagerUserManagementPage> createState() => _ManagerUserManagementPageState();
}

class _ManagerUserManagementPageState extends State<ManagerUserManagementPage> {
  bool _isLoading = true;
  bool _includeInactive = false;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _searchQuery = '';
  String _filterRole = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = await ProfileService.getAllUsers(includeInactive: _includeInactive);
      setState(() {
        _users = users;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      final matchesSearch = user['username'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            user['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _filterRole == 'all' || user['role'] == _filterRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  void _showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final expController = TextEditingController();
    
    String selectedRole = 'inspector';
    bool generateTempPassword = false;
    bool showPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'inspector', child: Text('Inspector')),
                      DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    ],
                    onChanged: (value) => setDialogState(() => selectedRole = value!),
                  ),
                  const SizedBox(height: 12),
                  
                  if (selectedRole == 'inspector') ...[
                    TextFormField(
                      controller: expController,
                      decoration: const InputDecoration(
                        labelText: 'Years of Experience',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  CheckboxListTile(
                    title: const Text('Generate temporary password'),
                    value: generateTempPassword,
                    onChanged: (value) => setDialogState(() {
                      generateTempPassword = value!;
                      if (generateTempPassword) passwordController.clear();
                    }),
                  ),
                  
                  if (!generateTempPassword) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setDialogState(() => showPassword = !showPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  final result = await ProfileService.createUser(
                    username: usernameController.text,
                    password: generateTempPassword ? null : passwordController.text,
                    email: emailController.text,
                    role: selectedRole,
                    phone: phoneController.text.isEmpty ? null : phoneController.text,
                    yearsExperience: expController.text.isEmpty ? null : int.tryParse(expController.text),
                    generateTempPassword: generateTempPassword,
                  );

                  if (mounted) Navigator.pop(context);
                  
                  // Show temporary password if generated
                  if (result.containsKey('temporary_password')) {
                    _showTemporaryPasswordDialog(usernameController.text, result['temporary_password']);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User created successfully!'), backgroundColor: Colors.green),
                    );
                  }
                  
                  _loadUsers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemporaryPasswordDialog(String username, String tempPassword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Temporary Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User created successfully!'),
            const SizedBox(height: 16),
            const Text('Temporary password:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SelectableText(
                      tempPassword,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tempPassword));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Please save this password! It cannot be retrieved later.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Provide this password to $username. They should change it after first login.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('I have saved the password'),
          ),
        ],
      ),
    );
  }

  void _showUserDetailsDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['username']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Username', user['username']),
              _buildDetailRow('Staff ID', user['staff_id'] ?? 'Not assigned'),
              _buildDetailRow('Email', user['email']),
              _buildDetailRow('Phone', user['phone'] ?? '-'),
              _buildDetailRow('Role', user['role'].toString().toUpperCase()),
              if (user['years_experience'] != null)
                _buildDetailRow('Experience', '${user['years_experience']} years'),
              _buildDetailRow('Status', user['is_active'] ? 'Active' : 'Inactive'),
              _buildDetailRow('Created', _formatDate(user['created_at'])),
              if (user['last_password_change'] != null)
                _buildDetailRow('Last Password Change', _formatDate(user['last_password_change'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditUserDialog(user);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(text: user['email']);
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    final expController = TextEditingController(text: user['years_experience']?.toString() ?? '');
    
    String selectedRole = user['role'];
    bool isActive = user['is_active'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${user['username']}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'inspector', child: Text('Inspector')),
                      DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    ],
                    onChanged: (value) => setDialogState(() => selectedRole = value!),
                  ),
                  const SizedBox(height: 12),
                  if (selectedRole == 'inspector') ...[
                    TextFormField(
                      controller: expController,
                      decoration: const InputDecoration(labelText: 'Years of Experience', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                  ],
                  SwitchListTile(
                    title: const Text('Account Active'),
                    value: isActive,
                    onChanged: (value) => setDialogState(() => isActive = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  await ProfileService.updateUser(
                    userId: user['id'],
                    email: emailController.text,
                    phone: phoneController.text.isEmpty ? null : phoneController.text,
                    role: selectedRole,
                    isActive: isActive,
                    yearsExperience: expController.text.isEmpty ? null : int.tryParse(expController.text),
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User updated successfully!'), backgroundColor: Colors.green),
                    );
                    _loadUsers();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(Map<String, dynamic> user) {
    bool generateTemp = true;
    final passwordController = TextEditingController();
    bool showPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Reset Password for ${user['username']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Generate temporary password'),
                value: generateTemp,
                onChanged: (value) => setDialogState(() {
                  generateTemp = value!;
                  if (generateTemp) passwordController.clear();
                }),
              ),
              if (!generateTemp) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => showPassword = !showPassword),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!generateTemp && passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  final result = await ProfileService.resetUserPassword(
                    userId: user['id'],
                    newPassword: generateTemp ? null : passwordController.text,
                    generateTempPassword: generateTemp,
                  );

                  if (mounted) Navigator.pop(context);
                  
                  if (result.containsKey('temporary_password')) {
                    _showTemporaryPasswordDialog(user['username'], result['temporary_password']);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset successfully!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to permanently delete user "${user['username']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ProfileService.deleteUser(user['id']);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green),
                  );
                  _loadUsers();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Create User'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('All')),
                          ButtonSegment(value: 'inspector', label: Text('Inspectors')),
                          ButtonSegment(value: 'manager', label: Text('Managers')),
                        ],
                        selected: {_filterRole},
                        onSelectionChanged: (value) {
                          setState(() {
                            _filterRole = value.first;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: const Text('Show Inactive'),
                      selected: _includeInactive,
                      onSelected: (value) {
                        setState(() => _includeInactive = value);
                        _loadUsers();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No users found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: user['role'] == 'manager' ? Colors.purple.shade100 : Colors.blue.shade100,
                                child: Icon(
                                  user['role'] == 'manager' ? Icons.admin_panel_settings : Icons.engineering,
                                  color: user['role'] == 'manager' ? Colors.purple : Colors.blue,
                                ),
                              ),
                              title: Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['email'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(
                                      user['role'].toString().toUpperCase(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: user['role'] == 'manager' ? Colors.purple.shade100 : Colors.blue.shade100,
                                  ),
                                  const SizedBox(width: 8),
                                  if (!user['is_active'])
                                    const Chip(
                                      label: Text('INACTIVE', style: TextStyle(fontSize: 10, color: Colors.white)),
                                      backgroundColor: Colors.red,
                                    ),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility), SizedBox(width: 8), Text('View Details')])),
                                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
                                      const PopupMenuItem(value: 'reset', child: Row(children: [Icon(Icons.lock_reset), SizedBox(width: 8), Text('Reset Password')])),
                                      PopupMenuItem(
                                        value: user['is_active'] ? 'deactivate' : 'activate',
                                        child: Row(children: [
                                          Icon(user['is_active'] ? Icons.block : Icons.check_circle),
                                          const SizedBox(width: 8),
                                          Text(user['is_active'] ? 'Deactivate' : 'Activate'),
                                        ]),
                                      ),
                                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                                    ],
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'view':
                                          _showUserDetailsDialog(user);
                                          break;
                                        case 'edit':
                                          _showEditUserDialog(user);
                                          break;
                                        case 'reset':
                                          _showResetPasswordDialog(user);
                                          break;
                                        case 'deactivate':
                                          ProfileService.deactivateUser(user['id']).then((_) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('User deactivated'), backgroundColor: Colors.orange),
                                            );
                                            _loadUsers();
                                          });
                                          break;
                                        case 'activate':
                                          ProfileService.activateUser(user['id']).then((_) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('User activated'), backgroundColor: Colors.green),
                                            );
                                            _loadUsers();
                                          });
                                          break;
                                        case 'delete':
                                          _confirmDeleteUser(user);
                                          break;
                                      }
                                    },
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              onTap: () => _showUserDetailsDialog(user),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
