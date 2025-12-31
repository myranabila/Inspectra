import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/profile_service.dart';
import 'theme/app_theme.dart';
import 'widgets/collapsible_sidebar.dart';

class ManagerUserManagementPage extends StatefulWidget {
  const ManagerUserManagementPage({super.key});

  @override
  State<ManagerUserManagementPage> createState() => _ManagerUserManagementPageState();
}

class _ManagerUserManagementPageState extends State<ManagerUserManagementPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _statusFilter = 'Activated';
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _searchQuery = '';
  String _filterRole = 'all';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadUsers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      // Always fetch all users so we can filter by status locally
      final users = await ProfileService.getAllUsers(includeInactive: true);
      setState(() {
        _users = users;
        _applyFilters();
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: $e'),
            backgroundColor: AppTheme.statusRejected,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      final matchesSearch = user['username'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            user['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final isActive = user['is_active'] ?? true;
      final matchesStatus = (_statusFilter == 'Activated' && isActive) ||
                            (_statusFilter == 'Deactivated' && !isActive);

      final matchesRole = _filterRole == 'all' || user['role'] == _filterRole;
      return matchesSearch && matchesRole && matchesStatus;
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
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.statusCompleted.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person_add_rounded, color: AppTheme.statusCompleted, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Create New User',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Username', required: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: usernameController,
                          decoration: _modernInputDecoration(hint: 'Enter username', icon: Icons.person_rounded),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildFormLabel('Email', required: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailController,
                          decoration: _modernInputDecoration(hint: 'user@company.com', icon: Icons.email_rounded),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        _buildFormLabel('Phone'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: phoneController,
                          decoration: _modernInputDecoration(hint: '+1 234 567 8900', icon: Icons.phone_rounded),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildFormLabel('Role', required: true),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: _modernInputDecoration(hint: '', icon: Icons.work_rounded),
                          items: [
                            DropdownMenuItem(
                              value: 'inspector',
                              child: Row(
                                children: [
                                  Icon(Icons.engineering_rounded, size: 18, color: AppTheme.statusScheduled),
                                  const SizedBox(width: 10),
                                  const Text('Inspector'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'manager',
                              child: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings_rounded, size: 18, color: AppTheme.primaryRed),
                                  const SizedBox(width: 10),
                                  const Text('Manager'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) => setDialogState(() => selectedRole = value!),
                        ),
                        
                        if (selectedRole == 'inspector') ...[
                           // Years of Experience removed as requested
                        ],
                        
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              'Generate temporary password',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'User will be asked to change it on first login',
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            value: generateTempPassword,
                            onChanged: (value) => setDialogState(() {
                              generateTempPassword = value;
                              if (generateTempPassword) passwordController.clear();
                            }),
                            activeColor: AppTheme.primaryRed,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        
                        if (!generateTempPassword) ...[
                          const SizedBox(height: 16),
                          _buildFormLabel('Password', required: true),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: passwordController,
                            obscureText: !showPassword,
                            decoration: _modernInputDecoration(
                              hint: 'Min 6 characters',
                              icon: Icons.lock_rounded,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppTheme.textMuted,
                                ),
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
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
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
                              
                              if (result.containsKey('temporary_password')) {
                                _showTemporaryPasswordDialog(usernameController.text, result['temporary_password']);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Colors.white),
                                        const SizedBox(width: 12),
                                        const Text('User created successfully!'),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.statusCompleted,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                              
                              _loadUsers();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e'), backgroundColor: AppTheme.statusRejected),
                              );
                            }
                          },
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: const Text('Create User'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.statusCompleted,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTemporaryPasswordDialog(String username, String tempPassword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.key_rounded, color: AppTheme.accentYellow, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Temporary Password',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'User created successfully!',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentYellow.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        tempPassword,
                        style: GoogleFonts.firaCode(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, color: AppTheme.primaryRed),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: tempPassword));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Password copied to clipboard'),
                            backgroundColor: AppTheme.statusCompleted,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.statusRejected.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.statusRejected.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.statusRejected, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please save this password! It cannot be retrieved later.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.statusRejected,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Provide this password to $username. They should change it after first login.',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('I have saved the password', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetailsDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: user['role'] == 'manager' ? AppTheme.managerSidebarGradient : AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    user['username'][0].toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user['username'],
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: user['role'] == 'manager' ? AppTheme.primaryRed.withValues(alpha: 0.1) : AppTheme.statusScheduled.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user['role'].toString().toUpperCase(),
                      style: GoogleFonts.inter(
                        color: user['role'] == 'manager' ? AppTheme.primaryRed : AppTheme.statusScheduled,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: user['is_active'] ? AppTheme.statusCompleted.withValues(alpha: 0.1) : AppTheme.statusRejected.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user['is_active'] ? 'ACTIVE' : 'INACTIVE',
                      style: GoogleFonts.inter(
                        color: user['is_active'] ? AppTheme.statusCompleted : AppTheme.statusRejected,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildDetailItem(Icons.badge_rounded, 'Staff ID', user['staff_id'] ?? 'Not assigned'),
                    const SizedBox(height: 12),
                    _buildDetailItem(Icons.email_rounded, 'Email', user['email']),
                    const SizedBox(height: 12),
                    _buildDetailItem(Icons.phone_rounded, 'Phone', user['phone'] ?? 'Not set'),
                    if (user['years_experience'] != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailItem(Icons.work_rounded, 'Experience', '${user['years_experience']} years'),
                    ],
                    const SizedBox(height: 12),
                    _buildDetailItem(Icons.calendar_today_rounded, 'Created', _formatDate(user['created_at'])),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditUserDialog(user);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
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

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
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
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.edit_rounded, color: AppTheme.primaryRed, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit User',
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          Text(
                            user['username'],
                            style: GoogleFonts.inter(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Email', required: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailController,
                          decoration: _modernInputDecoration(hint: 'Email address', icon: Icons.email_rounded),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildFormLabel('Phone'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: phoneController,
                          decoration: _modernInputDecoration(hint: 'Phone number', icon: Icons.phone_rounded),
                        ),
                        const SizedBox(height: 16),
                        _buildFormLabel('Role'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: _modernInputDecoration(hint: '', icon: Icons.work_rounded),
                          items: [
                            DropdownMenuItem(value: 'inspector', child: Text('Inspector')),
                            DropdownMenuItem(value: 'manager', child: Text('Manager')),
                          ],
                          onChanged: (value) => setDialogState(() => selectedRole = value!),
                        ),
                        if (selectedRole == 'inspector') ...[
                           // Years of Experience removed as requested
                        ],
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.statusCompleted.withValues(alpha: 0.06) : AppTheme.statusRejected.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive ? AppTheme.statusCompleted.withValues(alpha: 0.2) : AppTheme.statusRejected.withValues(alpha: 0.2),
                            ),
                          ),
                          child: SwitchListTile(
                            title: Text('Account Active', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              isActive ? 'User can log in and access the system' : 'User is blocked from accessing the system',
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            value: isActive,
                            onChanged: (value) => setDialogState(() => isActive = value),
                            activeColor: AppTheme.statusCompleted,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
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
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Colors.white),
                                        const SizedBox(width: 12),
                                        const Text('User updated successfully!'),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.statusCompleted,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                _loadUsers();
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e'), backgroundColor: AppTheme.statusRejected),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text('Update User', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.lock_reset_rounded, color: AppTheme.accentYellow, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'Reset Password',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'For ${user['username']}',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: Text('Generate temporary password', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    value: generateTemp,
                    onChanged: (value) => setDialogState(() {
                      generateTemp = value;
                      if (generateTemp) passwordController.clear();
                    }),
                    activeColor: AppTheme.primaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (!generateTemp) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    decoration: _modernInputDecoration(hint: 'New password', icon: Icons.lock_rounded).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppTheme.textMuted),
                        onPressed: () => setDialogState(() => showPassword = !showPassword),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!generateTemp && passwordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Password must be at least 6 characters'),
                                backgroundColor: AppTheme.statusRejected,
                              ),
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
                                SnackBar(
                                  content: const Text('Password reset successfully!'),
                                  backgroundColor: AppTheme.statusCompleted,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$e'), backgroundColor: AppTheme.statusRejected),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentYellow,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text('Reset Password', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.statusRejected.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.delete_forever_rounded, color: AppTheme.statusRejected, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete User?',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to permanently delete "${user['username']}"? This action cannot be undone.',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await ProfileService.deleteUser(user['id']);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('User deleted successfully'),
                                backgroundColor: AppTheme.statusCompleted,
                              ),
                            );
                            _loadUsers();
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e'), backgroundColor: AppTheme.statusRejected),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.statusRejected,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                _buildSearchAndFilters(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Create User'),
      ),
    );
  }

  Widget _buildSidebar() {
    return const CollapsibleSidebar(currentPage: 'user_management');
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.people_rounded, color: AppTheme.primaryRed, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'User Management',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_filteredUsers.length}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage inspectors and managers in your organization',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadUsers,
              tooltip: 'Refresh',
              color: AppTheme.primaryRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 10),
              _buildFilterChip('Inspectors', 'inspector', icon: Icons.engineering_rounded),
              const SizedBox(width: 10),
              _buildFilterChip('Managers', 'manager', icon: Icons.admin_panel_settings_rounded),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Activated Tab
                    InkWell(
                      onTap: () {
                        setState(() {
                          _statusFilter = 'Activated';
                          _applyFilters();
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _statusFilter == 'Activated' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _statusFilter == 'Activated' ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)] : null,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16, color: _statusFilter == 'Activated' ? AppTheme.statusCompleted : AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Activated',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _statusFilter == 'Activated' ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Deactivated Tab
                    InkWell(
                      onTap: () {
                        setState(() {
                          _statusFilter = 'Deactivated';
                          _applyFilters();
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _statusFilter == 'Deactivated' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _statusFilter == 'Deactivated' ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)] : null,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.block_rounded, size: 16, color: _statusFilter == 'Deactivated' ? AppTheme.statusRejected : AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Deactivated',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _statusFilter == 'Deactivated' ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String role, {IconData? icon}) {
    final isSelected = _filterRole == role;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterRole = role;
          _applyFilters();
        });
      },
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: AppTheme.primaryRed,
      labelStyle: GoogleFonts.inter(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primaryRed),
          ),
          const SizedBox(height: 24),
          Text('Loading users...', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
                _searchQuery.isEmpty && _statusFilter == 'Deactivated' 
                    ? 'No deactivated users found' 
                    : (_searchQuery.isEmpty && _statusFilter == 'Activated' 
                        ? 'No activated users found' 
                        : 'No users found'),
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600)
            ),
            const SizedBox(height: 8),
            Text('Try adjusting your search or filters', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(32),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isManager = user['role'] == 'manager';
    final isActive = user['is_active'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: !isActive ? Border.all(color: AppTheme.statusRejected.withValues(alpha: 0.3), width: 2) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showUserDetailsDialog(user),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: isManager ? AppTheme.managerSidebarGradient : AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      isManager ? Icons.admin_panel_settings_rounded : Icons.engineering_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user['username'],
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isManager ? AppTheme.primaryRed.withValues(alpha: 0.1) : AppTheme.statusScheduled.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user['role'].toString().toUpperCase(),
                              style: GoogleFonts.inter(
                                color: isManager ? AppTheme.primaryRed : AppTheme.statusScheduled,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.statusRejected,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'DEACTIVATED',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'view',
                      child: Row(children: [
                        Icon(Icons.visibility_rounded, size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: 12),
                        const Text('View Details'),
                      ]),
                    ),
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_rounded, size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: 12),
                        const Text('Edit'),
                      ]),
                    ),
                    PopupMenuItem<String>(
                      value: 'reset',
                      child: Row(children: [
                        Icon(Icons.lock_reset_rounded, size: 18, color: AppTheme.accentYellow),
                        const SizedBox(width: 12),
                        const Text('Reset Password'),
                      ]),
                    ),
                    PopupMenuItem<String>(
                      value: user['is_active'] ? 'deactivate' : 'activate',
                      child: Row(children: [
                        Icon(
                          user['is_active'] ? Icons.block_rounded : Icons.check_circle_rounded,
                          size: 18,
                          color: user['is_active'] ? AppTheme.statusRejected : AppTheme.statusCompleted,
                        ),
                        const SizedBox(width: 12),
                        Text(user['is_active'] ? 'Deactivate' : 'Activate'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_forever_rounded, size: 18, color: AppTheme.statusRejected),
                        const SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: AppTheme.statusRejected)),
                      ]),
                    ),
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
                            SnackBar(content: const Text('User deactivated'), backgroundColor: AppTheme.accentYellow),
                          );
                          _loadUsers();
                        });
                        break;
                      case 'activate':
                        ProfileService.activateUser(user['id']).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('User activated'), backgroundColor: AppTheme.statusCompleted),
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
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        if (required)
          Text(' *', style: GoogleFonts.inter(color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
      ],
    );
  }

  InputDecoration _modernInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primaryRed, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.statusRejected, width: 1.5)),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      hintStyle: GoogleFonts.inter(color: AppTheme.textMuted),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
