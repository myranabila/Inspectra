import 'package:flutter/material.dart';
import 'services/auth_service.dart'; // Keep backend service import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');

  String? _error;
  bool _loading = false;

  // --- Backend/Logic unchanged ---
  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final username = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _loading = true);

    try {
      // Call the real backend API
      final response = await AuthService.login(
        username: username,
        password: password,
      );

      // If login successful, navigate to dashboard based on role
      if (response['access_token'] != null && mounted) {
        final role = await AuthService.getUserRole();
        
        if (role == 'manager') {
          Navigator.pushReplacementNamed(context, '/manager-dashboard');
        } else {
          // Inspector or default role
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  // --- Design adjustments start here ---
  @override
  Widget build(BuildContext context) {
    // 1. Define Color Palette for consistency
    const Color primaryColor = Color(0xFF4C75FF); // Clean Blue Accent
    const Color lightGrey = Color(0xFFF7F7F7); // Very light background
    const Color textGrey = Color(0xFF6A6A6A); // Soft Text Color

    return Scaffold(
      // 2. Minimalist background: single light color
      backgroundColor: lightGrey,
      
      body: Center(
        child: SingleChildScrollView( // Added to prevent overflow on small screens
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // Slightly reduced width
            child: Card(
              // 3. Softer Card Style
              elevation: 4, // Reduced elevation
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Increased radius for softer look
                side: const BorderSide(color: Color(0xFFEEEEEE), width: 1), // Light border for definition
              ),
              child: Padding(
                padding: const EdgeInsets.all(32), // More padding for whitespace
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // HEADER ----------------------------------------------
                    Column(
                      children: [
                        // 4. Logo/Icon: Simplified, but keeping the visual element
                        Container(
                          height: 56,
                          width: 56,
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.checklist,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 24), // Increased spacing
                        
                        // 5. Typography: Lighter weight and subtle color
                        const Text(
                          'Inspection System',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your account to continue',
                          style: TextStyle(
                            fontSize: 15,
                            color: textGrey,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // FORM ----------------------------------------------
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Error Message - Modernized
                          if (_error != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16), // More space
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDEDE), // Lighter red background
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Error: $_error',
                                style: const TextStyle(
                                    color: Color(0xFFD32F2F), fontWeight: FontWeight.w500),
                              ),
                            ),

                          // Email Label/Input
                          const Text('Username',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            // 6. Minimalist Input Decoration: UnderlineInputBorder
                            decoration: InputDecoration(
                              hintText: 'Enter your username',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10), // Adjust padding for a sleeker look
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFC7C7C7)),
                              ),
                              errorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red, width: 2),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter username' : null,
                          ),

                          const SizedBox(height: 20), // Increased spacing

                          // Password Label/Input
                          const Text('Password',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            // 6. Minimalist Input Decoration: UnderlineInputBorder
                            decoration: const InputDecoration(
                              hintText: 'Enter your password',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFC7C7C7)),
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red, width: 2),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                          ),

                          const SizedBox(height: 32), // More space before CTA

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                // 7. Clean Button Style
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0, // Flat design
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Sign In',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w600)),
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
        ),
      ),
    );
  }
}
