import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  final VoidCallback onBackToLogin;
  const SignUpPage({super.key, required this.onBackToLogin});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _role; // <-- Now nullable so "Choose role" shows first
  String? _error;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters long');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your full name');
      return;
    }
    if (_role == null) {
      setState(() => _error = 'Please choose a role');
      return;
    }

    setState(() => _loading = true);

    try {
      // Call the real backend API
      await AuthService.register(
        username: username,
        password: pass,
        fullName: name,
        email: email,
      );

      // Show success message and navigate back to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF6FF), Color(0xFFEAEBFF)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // HEADER
                      Column(
                        children: [
                          Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade600,
                            ),
                            child: const Icon(
                              Icons.checklist,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Create Your Account',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign up to start managing inspections',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      if (_error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),

                      const SizedBox(height: 12),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Username',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Username',
                                isDense: true,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Enter username' : null,
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Full Name',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Full Name',
                                isDense: true,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Enter your full name' : null,
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Email',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Email',
                                isDense: true,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Enter email' : null,
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Role',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),

                            // Updated Dropdown with "Choose role" shown first
                            DropdownButtonFormField<String>(
                              value: _role,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              hint: const Text("Choose role"),
                              items: [
                                // Disabled placeholder (not selectable)
                                const DropdownMenuItem(
                                  enabled: false,
                                  value: null,
                                  child: Text(
                                    "Choose role",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),

                                // Actual roles
                                const DropdownMenuItem(
                                  value: 'inspector',
                                  child: Text('inspector'),
                                ),
                                const DropdownMenuItem(
                                  value: 'manager',
                                  child: Text('manager'),
                                ),
                              ],
                              onChanged: (val) => setState(() => _role = val),
                              validator: (value) =>
                                  value == null ? 'Please choose a role' : null,
                            ),

                            const SizedBox(height: 4),
                            Text(
                              'Select your role in the organization',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Password',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Password',
                                isDense: true,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Enter password' : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Must be at least 6 characters',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Confirm Password',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _confirmController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Confirm Password',
                                isDense: true,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Confirm password' : null,
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      )
                                    : const Text('Sign Up'),
                              ),
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Back to Login'),
                                onPressed: widget.onBackToLogin,
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
