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
  bool _includeInactive = true; 
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _searchQuery = '';
  String _filterRole = 'all';
  String _sortBy = 'name'; 

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // --- LOGIC: FETCH DATA FROM SERVICE ---
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
      _showSnackBar('Failed to load data: $e', isError: true);
    }
  }

  // --- LOGIC: SORTING & FILTERING ---
  void _applyFilters() {
    List<Map<String, dynamic>> results = _users.where((user) {
      final matchesSearch = user['username'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            user['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _filterRole == 'all' || user['role'] == _filterRole;
      return matchesSearch && matchesRole;
    }).toList();

    if (_sortBy == 'name') {
      results.sort((a, b) => a['username'].toString().toLowerCase().compareTo(b['username'].toString().toLowerCase()));
    } else if (_sortBy == 'newest') {
      results.sort((a, b) => b['created_at'].toString().compareTo(a['created_at'].toString()));
    } else if (_sortBy == 'role') {
      results.sort((a, b) => a['role'].toString().compareTo(b['role'].toString()));
    }

    setState(() {
      _filteredUsers = results;
    });
  }

  // --- UI: MINI-FUNCTIONS DASHBOARD ---
  Widget _buildDashboard() {
    int total = _users.length;
    int activeInspectors = _users.where((u) => u['role'] == 'inspector' && u['is_active'] == true).length;
    int inactive = _users.where((u) => u['is_active'] == false).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Users', total.toString(), Icons.group),
          _buildStatItem('Active Inspectors', activeInspectors.toString(), Icons.engineering),
          _buildStatItem('Inactive', inactive.toString(), Icons.person_off),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  // --- UI: SEARCH & FILTER BAR ---
  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Material(
            elevation: 3,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(15),
            child: TextField(
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search username or email...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _filterChip('Inspectors', 'inspector'),
                      const SizedBox(width: 8),
                      _filterChip('Managers', 'manager'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort_rounded, color: Colors.blue),
                tooltip: 'Sort Data',
                onSelected: (val) {
                  setState(() {
                    _sortBy = val;
                    _applyFilters();
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'name', child: Text('Sort: Name (A-Z)')),
                  const PopupMenuItem(value: 'newest', child: Text('Sort: Newest')),
                  const PopupMenuItem(value: 'role', child: Text('Sort: Role')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    bool isSelected = _filterRole == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
      selected: isSelected,
      selectedColor: Colors.blue.shade700,
      backgroundColor: Colors.white,
      onSelected: (s) {
        setState(() {
          _filterRole = value;
          _applyFilters();
        });
      },
    );
  }

  // --- UI: USER LIST CARDS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('User Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('New User'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          _buildDashboard(),
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    bool isManager = user['role'] == 'manager';
    bool isActive = user['is_active'] ?? true;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: isManager ? Colors.purple.shade50 : Colors.blue.shade50,
          child: Icon(
            isManager ? Icons.admin_panel_settings : Icons.engineering,
            color: isManager ? Colors.purple : Colors.blue,
          ),
        ),
        title: Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Row(
              children: [
                _statusBadge(isActive),
                const SizedBox(width: 8),
                Text(user['role'].toString().toUpperCase(), 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) => _handleMenuAction(val, user),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.visibility), title: Text('Full Profile'), dense: true)),
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit Data'), dense: true)),
            const PopupMenuItem(value: 'reset', child: ListTile(leading: Icon(Icons.lock_reset), title: Text('Reset Password'), dense: true)),
            PopupMenuItem(
              value: isActive ? 'deactivate' : 'activate',
              child: ListTile(
                leading: Icon(isActive ? Icons.block : Icons.check_circle, color: isActive ? Colors.red : Colors.green),
                title: Text(isActive ? 'Deactivate' : 'Activate'),
                dense: true,
              ),
            ),
            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete Permanently', style: TextStyle(color: Colors.red)), dense: true)),
          ],
        ),
        onTap: () => _showUserDetailsDialog(user),
      ),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Text(active ? 'ACTIVE' : 'INACTIVE', 
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: active ? Colors.green.shade700 : Colors.red.shade700)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No users found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  // --- LOGIC: MENU ACTIONS ---
  void _handleMenuAction(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'view': _showUserDetailsDialog(user); break;
      case 'edit': _showEditUserDialog(user); break;
      case 'reset': _showResetPasswordDialog(user); break;
      case 'deactivate': _toggleStatus(user, false); break;
      case 'activate': _toggleStatus(user, true); break;
      case 'delete': _confirmDeleteUser(user); break;
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> user, bool activate) async {
    try {
      if (activate) await ProfileService.activateUser(user['id']);
      else await ProfileService.deactivateUser(user['id']);
      _showSnackBar(activate ? 'Account activated' : 'Account deactivated');
      _loadUsers();
    } catch (e) { _showSnackBar(e.toString(), isError: true); }
  }

  // --- DIALOGS ---

  void _showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    final userC = TextEditingController();
    final emailC = TextEditingController();
    final phoneC = TextEditingController();
    final passC = TextEditingController();
    final expC = TextEditingController();
    String role = 'inspector';
    bool genTemp = true;
    bool showPassword = false; // New variable for visibility

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: userC, decoration: const InputDecoration(labelText: 'Username *'), validator: (v) => v!.isEmpty ? 'Required' : null),
                  TextFormField(controller: emailC, decoration: const InputDecoration(labelText: 'Email *'), validator: (v) => !v!.contains('@') ? 'Invalid email' : null),
                  TextFormField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone Number')),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: const [DropdownMenuItem(value: 'inspector', child: Text('Inspector')), DropdownMenuItem(value: 'manager', child: Text('Manager'))],
                    onChanged: (v) => setDialogState(() => role = v!),
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  if (role == 'inspector') TextFormField(controller: expC, decoration: const InputDecoration(labelText: 'Years of Experience'), keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('Use Temporary Password', style: TextStyle(fontSize: 14)),
                    value: genTemp,
                    onChanged: (v) => setDialogState(() => genTemp = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (!genTemp) 
                    TextFormField(
                      controller: passC, 
                      obscureText: !showPassword, // Hide or show based on variable
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setDialogState(() => showPassword = !showPassword),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final res = await ProfileService.createUser(
                    username: userC.text, email: emailC.text, role: role, phone: phoneC.text,
                    yearsExperience: int.tryParse(expC.text), password: genTemp ? null : passC.text,
                    generateTempPassword: genTemp
                  );
                  Navigator.pop(context);
                  if (res.containsKey('temporary_password')) {
                    _showTempPassDialog(userC.text, res['temporary_password']);
                  } else {
                    _showSnackBar('User registered successfully');
                  }
                  _loadUsers();
                } catch (e) { _showSnackBar(e.toString(), isError: true); }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final emailC = TextEditingController(text: user['email']);
    final phoneC = TextEditingController(text: user['phone'] ?? '');
    final expC = TextEditingController(text: user['years_experience']?.toString() ?? '');
    String role = user['role'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${user['username']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: emailC, decoration: const InputDecoration(labelText: 'Email')),
              TextFormField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone')),
              DropdownButtonFormField<String>(
                value: role,
                items: const [DropdownMenuItem(value: 'inspector', child: Text('Inspector')), DropdownMenuItem(value: 'manager', child: Text('Manager'))],
                onChanged: (v) => setDialogState(() => role = v!),
              ),
              if (role == 'inspector') TextFormField(controller: expC, decoration: const InputDecoration(labelText: 'Experience (Years)'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ProfileService.updateUser(
                    userId: user['id'], email: emailC.text, phone: phoneC.text,
                    role: role, yearsExperience: int.tryParse(expC.text)
                  );
                  Navigator.pop(context);
                  _showSnackBar('Data updated successfully');
                  _loadUsers();
                } catch (e) { _showSnackBar(e.toString(), isError: true); }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(Map<String, dynamic> user) {
    bool genTemp = true;
    final passC = TextEditingController();
    bool showPassword = false; // New variable for visibility

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reset for user: ${user['username']}'),
              const SizedBox(height: 15),
              CheckboxListTile(
                title: const Text('Generate temporary password'),
                value: genTemp,
                onChanged: (v) => setDialogState(() => genTemp = v!),
              ),
              if (!genTemp) 
                TextFormField(
                  controller: passC, 
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => showPassword = !showPassword),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                try {
                  final res = await ProfileService.resetUserPassword(userId: user['id'], newPassword: genTemp ? null : passC.text, generateTempPassword: genTemp);
                  Navigator.pop(context);
                  if (res.containsKey('temporary_password')) {
                    _showTempPassDialog(user['username'], res['temporary_password']);
                  } else {
                    _showSnackBar('Password changed successfully');
                  }
                } catch (e) { _showSnackBar(e.toString(), isError: true); }
              },
              child: const Text('Reset Now'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTempPassDialog(String user, String pass) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('PLEASE COPY PASSWORD'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Temporary password for $user:'),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
              child: SelectableText(pass, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.blue)),
            ),
            const SizedBox(height: 10),
            const Text('⚠️ Please provide this code to the user.', style: TextStyle(color: Colors.red, fontSize: 11)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pass));
              Navigator.pop(context);
              _showSnackBar('Copied to clipboard');
            }, 
            child: const Text('Copy & Close')
          )
        ],
      ),
    );
  }

  void _showUserDetailsDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user['username']}\'s Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow('Email', user['email']),
            _detailRow('Phone', user['phone'] ?? '-'),
            _detailRow('Role', user['role'].toString().toUpperCase()),
            _detailRow('Status', user['is_active'] ? 'ACTIVE' : 'INACTIVE'),
            if (user['years_experience'] != null) _detailRow('Experience', '${user['years_experience']} Years'),
            _detailRow('Staff ID', user['staff_id'] ?? 'Not assigned'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _detailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
          Expanded(child: Text(': $val')),
        ],
      ),
    );
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to permanently delete account "${user['username']}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ProfileService.deleteUser(user['id']);
                Navigator.pop(context);
                _showSnackBar('User deleted');
                _loadUsers();
              } catch (e) { _showSnackBar(e.toString(), isError: true); }
            }, 
            child: const Text('Delete Now'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green, behavior: SnackBarBehavior.floating),
    );
  }
}