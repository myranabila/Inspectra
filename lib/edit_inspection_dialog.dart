import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/manager_service.dart';
import 'utils/animations_config.dart';

class EditInspectionDialog extends StatefulWidget {
  final Map<String, dynamic> inspection;
  final VoidCallback onUpdated;

  const EditInspectionDialog({
    super.key,
    required this.inspection,
    required this.onUpdated,
  });

  @override
  State<EditInspectionDialog> createState() => _EditInspectionDialogState();
}

class _EditInspectionDialogState extends State<EditInspectionDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Form fields
  late String _selectedArea;
  late String _selectedEquipmentType;

  // STRICT Areas - ONLY 5 options allowed
  final List<String> _areas = [
    'Plant 1',
    'Plant 2',
    'Utility Area',
    'Offsite Area',
    'Process Area',
  ];

  // ALL Equipment Types
  final List<String> _allEquipmentTypes = [
    'Reactor',
    'Pressure Vessel',
    'Heat Exchanger',
    'Storage Tank',
    'Tower',
  ];

  // Equipment types filtered by area
  final Map<String, List<String>> _areaEquipmentMap = {
    'Plant 1': ['Reactor', 'Pressure Vessel', 'Heat Exchanger'],
    'Plant 2': ['Storage Tank', 'Tower', 'Pressure Vessel'],
    'Utility Area': ['Heat Exchanger', 'Storage Tank'],
    'Offsite Area': ['Storage Tank', 'Tower'],
    'Process Area': ['Reactor', 'Pressure Vessel', 'Heat Exchanger', 'Tower'],
  };

  @override
  void initState() {
    super.initState();
    // Initialize with current values
    _selectedArea = widget.inspection['location'] ?? _areas[0];
    _selectedEquipmentType = widget.inspection['inspection_type'] ?? _allEquipmentTypes[0];

    // Validate that current equipment type is available for current area
    _validateEquipmentTypeForArea();
  }

  void _validateEquipmentTypeForArea() {
    final availableTypes = _areaEquipmentMap[_selectedArea] ?? _allEquipmentTypes;
    
    // If current equipment type is not available for this area, reset to first available
    if (!availableTypes.contains(_selectedEquipmentType)) {
      setState(() {
        _selectedEquipmentType = availableTypes.first;
      });

      // Show warning to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Equipment Type was reset because it\'s not available in the selected Area',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: AppTheme.accentYellow,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<String> _getAvailableEquipmentTypes() {
    return _areaEquipmentMap[_selectedArea] ?? _allEquipmentTypes;
  }

  Future<void> _submitChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Call backend API to update inspection
      await ManagerService.updateInspectionDetails(
        inspectionId: widget.inspection['id'],
        area: _selectedArea,
        equipmentType: _selectedEquipmentType,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Inspection updated successfully',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Callback to refresh parent
      widget.onUpdated();

      // Close dialog
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryRed.withValues(alpha: 0.15),
                          AppTheme.primaryRed.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: AppTheme.primaryRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Inspection Details',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update Area and Equipment Type',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              // Current Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Current Details',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Inspection ID', widget.inspection['inspection_id_display'] ?? 'N/A'),
                    const SizedBox(height: 6),
                    _buildInfoRow('Equipment Tag', widget.inspection['equipment_tag'] ?? 'N/A'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Area Selection
              Text(
                'Area *',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedArea,
                decoration: AppTheme.inputDecoration('Select area'),
                items: _areas.map((area) => DropdownMenuItem(
                  value: area,
                  child: Text(area, style: GoogleFonts.inter(fontSize: 14)),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedArea = value!;
                    // Re-validate equipment type when area changes
                    _validateEquipmentTypeForArea();
                  });
                },
              ),

              const SizedBox(height: 20),

              // Equipment Type Selection
              Text(
                'Equipment Type *',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Filtered based on selected Area',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedEquipmentType,
                decoration: AppTheme.inputDecoration('Select equipment type'),
                items: _getAvailableEquipmentTypes().map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type, style: GoogleFonts.inter(fontSize: 14)),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedEquipmentType = value!);
                },
              ),

              const SizedBox(height: 24),

              // Warning box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentYellow.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.accentYellow, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Changing Area will filter available Equipment Types. Your current selection may be reset if incompatible.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: AppTheme.ghostButton,
                    child: Text('Cancel', style: GoogleFonts.inter(fontSize: 15)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitChanges,
                    style: AppTheme.primaryButton,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade900,
          ),
        ),
      ],
    );
  }
}
