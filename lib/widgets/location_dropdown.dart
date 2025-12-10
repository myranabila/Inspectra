import 'package:flutter/material.dart';

class LocationDropdown extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const LocationDropdown({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Simple implementation using Autocomplete or just a TextField for now
    // to satisfy the dependency.
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Location *',
        hintText: 'e.g., Building A, Floor 2',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      validator: validator,
      onTap: () {
        // In a real app, this might show a modal bottom sheet or dropdown
        // For now, we allow manual entry which is robust.
      },
    );
  }
}