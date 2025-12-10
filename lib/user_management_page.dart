import 'package:flutter/material.dart';
import 'package:photo_visual_report/services/profile_service.dart';
import 'theme/app_theme.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final usersData = await ProfileService.getAllUsers();
      setState(() {
        _users = usersData;
        _filteredUsers = usersData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final username = user['username']?.toLowerCase() ?? '';
        final email = user['email']?.toLowerCase() ?? '';
        final staffId = user['staff_id']?.toLowerCase() ?? '';
        return username.contains(query) ||
            email.contains(query) ||
            staffId.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        elevation: 1,
        title: const Text('User Management'),
        backgroundColor: AppTheme.managerPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh Users',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to a "Create User" page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navigate to Create User page (to be implemented).')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New User'),
        backgroundColor: AppTheme.managerPrimary,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by username, email, or staff ID...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              const Text(
                'Failed to load users',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Text('No users found.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80), // Padding for FAB
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final role = user['role'] ?? 'unknown';
        final isActive = user['is_active'] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(role).withOpacity(0.15),
              child: Icon(
                role == 'manager' ? Icons.manage_accounts : Icons.engineering,
                color: _getRoleColor(role),
              ),
            ),
            title: Row(
              children: [
                Text(
                  user['username'] ?? 'No Username',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'INACTIVE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(user['email'] ?? 'No Email'),
                const SizedBox(height: 2),
                Text(
                  '${user['staff_id'] ?? 'No Staff ID'} • ${role.toUpperCase()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                // TODO: Implement user actions
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$value action for ${user['username']}')),
                );
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit User'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'reset_password',
                  child: ListTile(
                    leading: Icon(Icons.lock_reset),
                    title: Text('Reset Password'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'deactivate',
                  child: ListTile(
                    leading: Icon(Icons.power_settings_new, color: Colors.orange),
                    title: Text('Deactivate', style: TextStyle(color: Colors.orange)),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete User', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'manager':
        return Colors.purple;
      case 'inspector':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}