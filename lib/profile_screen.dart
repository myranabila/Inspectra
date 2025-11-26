// lib/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart'; // Required for avatar selection
import 'package:firebase_auth/firebase_auth.dart'; // Required for email update logic
import 'providers/inspector_provider.dart'; 

// Convert to StatefulWidget for in-place editing state
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State for managing edit mode
  bool _isEditing = false;

  // Text controllers for editable fields
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _uidController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<InspectorProvider>();
    
    _fullNameController = TextEditingController(text: provider.inspectorUser?.fullName ?? 'N/A');
    _phoneController = TextEditingController(text: provider.inspectorUser?.phone ?? 'N/A');
    _emailController = TextEditingController(text: provider.firebaseUser?.email ?? 'N/A'); 
    _uidController = TextEditingController(text: provider.uid);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update controllers if provider data changes (e.g., after loading/sign in)
    final provider = context.read<InspectorProvider>();
    _fullNameController.text = provider.inspectorUser?.fullName ?? 'N/A';
    _phoneController.text = provider.inspectorUser?.phone ?? 'N/A';
    _emailController.text = provider.firebaseUser?.email ?? 'N/A';
    _uidController.text = provider.uid;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _uidController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      // When entering edit mode, ensure controllers reflect latest data
      if (_isEditing) {
        final provider = context.read<InspectorProvider>();
        _fullNameController.text = provider.inspectorUser?.fullName ?? 'N/A';
        _phoneController.text = provider.inspectorUser?.phone ?? 'N/A';
        _emailController.text = provider.firebaseUser?.email ?? 'N/A';
        _uidController.text = provider.uid;
      }
    });
  }

  void _saveProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final newEmail = _emailController.text.trim();
    
    // --- 1. HANDLE FIREBASE AUTH EMAIL UPDATE ---
    if (currentUser != null && newEmail != currentUser.email) {
      try {
        await currentUser.verifyBeforeUpdateEmail(newEmail);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email change requires verification link sent to new address!')));
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email update failed: ${e.message}')));
        return; 
      }
    }
    
    // --- 2. HANDLE FIRESTORE DATA UPDATE (SIMULATION) ---
    // (Actual Firestore update logic would go here)

    setState(() {
      _isEditing = false;
    });
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved (Email update pending verification)')));
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit cancelled')));
  }
  
  // Function to handle avatar selection
  Future<void> _pickAvatarImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, // Filter specifically for image types
      allowMultiple: false,
      withData: true, 
    );

    if (!mounted) return;

    if (result != null && result.files.isNotEmpty) {
      PlatformFile file = result.files.first;
      
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar selected: ${file.name}. Ready for upload (simulated).')));
      // Provider logic to upload avatar would go here
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar selection cancelled.')));
    }
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InspectorProvider>();
    
    // Safely extract display names
    final user = provider.inspectorUser;
    final name = user?.name ?? 'Fetching Name...';
    final role = user?.role ?? 'Fetching Role...';
    
    if (provider.isLoading) {
      return const Scaffold(
        appBar: _ProfileAppBar(title: 'User Profile'),
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return Scaffold(
      appBar: const _ProfileAppBar(title: 'User Profile'),
      backgroundColor: Colors.grey.shade50,
      
      // FIX: Use SingleChildScrollView and Align to prevent bottom overflow
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(32.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 500,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- AVATAR ---
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 8), 

                    // NEW: Update Avatar Button
                    OutlinedButton(
                      onPressed: _pickAvatarImage, // Call the new image picker function
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        // ignore: deprecated_member_use
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text("UPDATE NEW AVATAR"),
                    ),
                    const SizedBox(height: 8), // Adjusted spacing
                    
                    // Display Name
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Display Role
                    Text(
                      role,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    
                    const Divider(height: 40),
                    
                    // --- EDIT/SAVE/CANCEL BUTTONS ---
                    _isEditing 
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _saveProfile,
                                icon: const Icon(Icons.check),
                                label: const Text('SAVE'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: _cancelEdit,
                                icon: const Icon(Icons.cancel),
                                label: const Text('CANCEL'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                            ],
                          )
                        : ElevatedButton.icon(
                            onPressed: _toggleEditMode,
                            icon: const Icon(Icons.edit),
                            label: const Text('EDIT PERSONAL INFO'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                    const SizedBox(height: 30),
                    
                    // --- User Details List (Conditional Display) ---
                    // Full Name
                    _isEditing
                        ? _buildEditableDetailRow(context, Icons.person_outline, 'Full Name', _fullNameController)
                        : _buildDetailRow(context, Icons.person_outline, 'Full Name', user?.fullName ?? 'N/A'),
                    
                    // Phone Number
                    _isEditing
                        ? _buildEditableDetailRow(context, Icons.phone, 'Phone Number', _phoneController)
                        : _buildDetailRow(context, Icons.phone, 'Phone Number', user?.phone ?? 'N/A'),
                    
                    // Email (Editable if in edit mode)
                    _isEditing
                        ? _buildEditableDetailRow(context, Icons.email, 'Email', _emailController)
                        : _buildDetailRow(context, Icons.email, 'Email', provider.firebaseUser?.email ?? 'N/A'),
                    
                    // User ID (Read-only TextField in edit mode)
                    _isEditing
                        ? _buildEditableDetailRow(context, Icons.badge, 'User ID', _uidController, readOnly: true)
                        : _buildDetailRow(context, Icons.badge, 'User ID', provider.uid),
                    
                    const SizedBox(height: 30),
                    
                    // Sign Out Button
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('LOG OUT'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  
  // Helper widget for displaying key-value pairs (READ-ONLY)
  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NEW Helper widget for displaying key-value pairs (EDITABLE with TextField)
  Widget _buildEditableDetailRow(BuildContext context, IconData icon, String label, TextEditingController controller, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded( // Use Expanded to allow TextField to take available space
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                ),
                TextField(
                  controller: controller,
                  readOnly: readOnly, // Apply readOnly state here
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                    border: const OutlineInputBorder(), 
                    // Optional: Hint text for disabled fields
                    fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
                    filled: true,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    // Dim text color if read-only
                    color: readOnly ? Colors.grey.shade600 : Colors.black, 
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom AppBar for consistency
class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _ProfileAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/'), 
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}