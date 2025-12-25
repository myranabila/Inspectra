import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'theme/app_theme.dart';
import 'widgets/collapsible_sidebar.dart';
import 'services/dashboard_service.dart';
import 'utils/pdf_generator.dart';
import 'pdf_preview_page.dart';

class InspectionWorkflowPage extends StatefulWidget {
  final Map<String, dynamic> inspection;

  const InspectionWorkflowPage({super.key, required this.inspection});

  @override
  State<InspectionWorkflowPage> createState() => _InspectionWorkflowPageState();
}

class _InspectionWorkflowPageState extends State<InspectionWorkflowPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  final picker = ImagePicker();

  // Inspection Method Selection
  String? _selectedMethod; // null = not selected, 'manual' = manual, 'automated' = automated (disabled)

  // Inspection metadata
  DateTime _inspectionDate = DateTime.now();

  // Scope requirements (from Manager's assignment)
  late bool _requireExternal;
  late bool _requireWeld;
  late bool _requireInternal;
  late bool _requireThickness;

  // Section 1: Equipment Identification (always required)
  List<XFile> _equipmentPhotos = [];
  String _equipmentFinding = '';
  String _equipmentRecommendation = '';

  // Section 2: External Visual
  List<XFile> _externalPhotos = [];
  String _externalFinding = '';
  String? _externalCondition;  // NEW: Satisfactory/Observation
  String _externalRecommendation = '';
  String? _externalSectionRecommendation;  // NEW: Nil/Monitor

  // Section 3: Weld Visual
  List<XFile> _weldPhotos = [];
  String _weldFinding = '';
  String? _weldCondition;  // NEW: Satisfactory/Observation
  String _weldRecommendation = '';
  String? _weldSectionRecommendation;  // NEW: Nil/Monitor

  // Section 4: Internal Visual (optional)
  bool _internalAccessible = false;
  List<XFile> _internalPhotos = [];
  String _internalFinding = '';
  String? _internalCondition;  // NEW: Satisfactory/Observation
  String _internalRecommendation = '';
  String? _internalSectionRecommendation;  // NEW: Nil/Monitor

  // Section 5: Thickness Measurement
  List<Map<String, String>> _thicknessData = [];
  String? _thicknessCondition;  // NEW: Satisfactory/Observation
  String? _thicknessSectionRecommendation;  // NEW: Nil/Monitor

  // Section 6: Summary
  String _overallCondition = 'Satisfactory';
  String _generalRecommendation = '';
  String _overallRecommendation = '';  // NEW: Overall Recommendation for Page 1
  
  // Dropdown options
  final List<String> _conditionOptions = ['Satisfactory', 'Observation'];
  final List<String> _sectionRecommendationOptions = ['Nil', 'Monitor'];

  @override
  void initState() {
    super.initState();
    // Load scope requirements from Manager's assignment
    _requireExternal = widget.inspection['require_external'] ?? true;
    _requireWeld = widget.inspection['require_weld'] ?? true;
    _requireInternal = widget.inspection['require_internal'] ?? false;
    _requireThickness = widget.inspection['require_thickness'] ?? false;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inspectionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _inspectionDate = picked);
  }

  Future<void> _pickPhotos(String section) async {
    try {
      // Try multi-image picker first (works on mobile)
      List<XFile>? picked;
      
      try {
        picked = await picker.pickMultiImage(
          imageQuality: 85,
        );
      } catch (e) {
        // If pickMultiImage fails (common on web), fall back to single image
        print('Multi-image picker failed, trying single image: $e');
        final XFile? singleImage = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (singleImage != null) {
          picked = [singleImage];
        }
      }
      
      if (picked != null && picked.isNotEmpty) {
        setState(() {
          switch (section) {
            case 'equipment': 
              _equipmentPhotos.addAll(picked!); 
              break;
            case 'external': 
              _externalPhotos.addAll(picked!); 
              break;
            case 'weld': 
              _weldPhotos.addAll(picked!); 
              break;
            case 'internal': 
              _internalPhotos.addAll(picked!); 
              break;
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${picked.length} photo(s) added successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Photo picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking photos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }


  void _removePhoto(String section, int index) {
    setState(() {
      switch (section) {
        case 'equipment': _equipmentPhotos.removeAt(index); break;
        case 'external': _externalPhotos.removeAt(index); break;
        case 'weld': _weldPhotos.removeAt(index); break;
        case 'internal': _internalPhotos.removeAt(index); break;
      }
    });
  }

  void _addThicknessEntry() {
    setState(() => _thicknessData.add({'location': '', 'thickness': '', 'remarks': ''}));
  }

  void _removeThicknessEntry(int index) {
    setState(() => _thicknessData.removeAt(index));
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    // ========== VALIDATION FOR REQUIRED SECTIONS ==========
    // Ensure all manager-assigned sections are completed before submission
    
    List<String> missingItems = [];

    // Equipment Identification (always required)
    if (_equipmentPhotos.isEmpty) {
      missingItems.add('Equipment Identification: At least 1 photo required');
    }

    // External Visual - only if required by manager
    if (_requireExternal) {
      if (_externalFinding.trim().isEmpty) {
        missingItems.add('External Visual: Finding is required');
      }
      if (_externalCondition == null) {
        missingItems.add('External Visual: Condition is required');
      }
      if (_externalSectionRecommendation == null) {
        missingItems.add('External Visual: Section Recommendation is required');
      }
      if (_externalPhotos.isEmpty) {
        missingItems.add('External Visual: At least 1 photo required');
      }
    }

    // Weld Visual - only if required by manager
    if (_requireWeld) {
      if (_weldFinding.trim().isEmpty) {
        missingItems.add('Weld Visual: Finding is required');
      }
      if (_weldCondition == null) {
        missingItems.add('Weld Visual: Condition is required');
      }
      if (_weldSectionRecommendation == null) {
        missingItems.add('Weld Visual: Section Recommendation is required');
      }
      if (_weldPhotos.isEmpty) {
        missingItems.add('Weld Visual: At least 1 photo required');
      }
    }

    // Internal Visual - only if required by manager AND accessible
    if (_requireInternal && _internalAccessible) {
      if (_internalFinding.trim().isEmpty) {
        missingItems.add('Internal Visual: Finding is required');
      }
      if (_internalCondition == null) {
        missingItems.add('Internal Visual: Condition is required');
      }
      if (_internalSectionRecommendation == null) {
        missingItems.add('Internal Visual: Section Recommendation is required');
      }
    }

    // Thickness Measurement - only if required by manager
    if (_requireThickness) {
      if (_thicknessData.isEmpty || _thicknessData.every((t) => (t['location'] ?? '').isEmpty)) {
        missingItems.add('Thickness Measurement: At least 1 measurement required');
      }
      if (_thicknessCondition == null) {
        missingItems.add('Thickness Measurement: Condition is required');
      }
      if (_thicknessSectionRecommendation == null) {
        missingItems.add('Thickness Measurement: Section Recommendation is required');
      }
    }
    
    // Overall Summary validation
    if (_overallRecommendation.trim().isEmpty) {
      missingItems.add('Summary: Overall Recommendation is required');
    }

    // Show validation errors if any
    if (missingItems.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.accentYellow, size: 28),
              const SizedBox(width: 12),
              Text('Incomplete Sections', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please complete the following required items before generating the report:', 
                style: GoogleFonts.inter(fontSize: 14)),
              const SizedBox(height: 16),
              ...missingItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 8, color: AppTheme.primaryRed),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: GoogleFonts.inter(fontSize: 13))),
                  ],
                ),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Collect all form data
      final reportData = {
        'inspection_date': DateFormat('yyyy-MM-dd').format(_inspectionDate),
        'equipment_finding': _equipmentFinding.isEmpty ? 'Nil' : _equipmentFinding,
        'equipment_recommendation': _equipmentRecommendation.isEmpty ? 'Nil' : _equipmentRecommendation,
        
        // External Visual with NEW fields
        'external_finding': _externalFinding.isEmpty ? 'Nil' : _externalFinding,
        'external_condition': _externalCondition ?? 'Satisfactory',
        'external_section_recommendation': _externalSectionRecommendation ?? 'Nil',
        'external_recommendation': _externalRecommendation.isEmpty ? 'Nil' : _externalRecommendation,
        
        // Weld Visual with NEW fields
        'weld_finding': _weldFinding.isEmpty ? 'Nil' : _weldFinding,
        'weld_condition': _weldCondition ?? 'Satisfactory',
        'weld_section_recommendation': _weldSectionRecommendation ?? 'Nil',
        'weld_recommendation': _weldRecommendation.isEmpty ? 'Nil' : _weldRecommendation,
        
        // Internal Visual with NEW fields
        'internal_accessible': _internalAccessible,
        'internal_finding': _internalAccessible ? (_internalFinding.isEmpty ? 'Nil' : _internalFinding) : null,
        'internal_condition': _internalAccessible ? (_internalCondition ?? 'Satisfactory') : null,
        'internal_section_recommendation': _internalAccessible ? (_internalSectionRecommendation ?? 'Nil') : null,
        'internal_recommendation': _internalAccessible ? (_internalRecommendation.isEmpty ? 'Nil' : _internalRecommendation) : null,
        
        // Thickness with NEW fields
        'thickness_data': _thicknessData,
        'thickness_condition': _thicknessCondition ?? 'Satisfactory',
        'thickness_section_recommendation': _thicknessSectionRecommendation ?? 'Nil',
        
        // Overall Summary with NEW field
        'overall_condition': _overallCondition,
        'overall_recommendation': _overallRecommendation.isEmpty ? 'Nil' : _overallRecommendation,
        'general_recommendation': _generalRecommendation.isEmpty ? 'Continue routine schedule' : _generalRecommendation,
        'photos': [..._equipmentPhotos, ..._externalPhotos, ..._weldPhotos, ..._internalPhotos],
        'photo_sections': {
          'equipment': _equipmentPhotos.length,
          'external': _externalPhotos.length,
          'weld': _weldPhotos.length,
          'internal': _internalPhotos.length,
        },
      };

      // Generate PDF preview
      final pdfBytes = await PdfGenerator.generateVisualInspectionReport(
        inspection: widget.inspection,
        reportData: reportData,
        requireExternal: _requireExternal,
        requireWeld: _requireWeld,
        requireInternal: _requireInternal,
        requireThickness: _requireThickness,
      );

      if (!mounted) return;

      // Navigate to PDF Preview Page
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewPage(
            pdfBytes: pdfBytes,
            reportData: reportData,
            inspectionId: widget.inspection['id'],
            onEdit: () {
              Navigator.pop(context); // Go back to edit
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                Expanded(
                  child: _selectedMethod == null
                      ? _buildMethodSelectionScreen()
                      : _buildInspectionForm(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return const CollapsibleSidebar(
      currentPage: 'inspection_workflow',
      isMainPage: false, // This is a sub-page, show Back button
    );
  }

  Widget _buildMethodSelectionScreen() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryRed,
                    AppTheme.primaryRed.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRed.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.build_circle_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Select Inspection Method',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose how you want to conduct this inspection',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Method Options
            Row(
              children: [
                // Manual Inspection
                Expanded(
                  child: _buildMethodCard(
                    icon: Icons.assignment_rounded,
                    title: 'Manual Inspection',
                    description: 'Manually fill in inspection details and upload evidence',
                    isAvailable: true,
                    isSelected: false,
                    onTap: () {
                      setState(() {
                        _selectedMethod = 'manual';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 24),
                // Automated Inspection
                Expanded(
                  child: _buildMethodCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Automated Inspection',
                    description: 'AI-powered inspection with automated data collection',
                    isAvailable: false,
                    isSelected: false,
                    comingSoon: true,
                    onTap: () {
                      // Disabled - show message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Automated Inspection is coming soon!',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppTheme.accentYellow,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isAvailable,
    required bool isSelected,
    bool comingSoon = false,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryRed
              : isAvailable
                  ? AppTheme.divider.withOpacity(0.3)
                  : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppTheme.primaryRed.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: isSelected ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: isAvailable
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryRed.withOpacity(0.15),
                              AppTheme.primaryRed.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade200,
                              Colors.grey.shade100,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: isAvailable
                        ? AppTheme.primaryRed
                        : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isAvailable
                        ? AppTheme.textPrimary
                        : Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Description
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (comingSoon) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.accentYellow.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'COMING SOON',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentYellow,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildMetadataCard(),
                const SizedBox(height: 24),
                _buildSectionCard(
                  'Equipment Identification',
                  Icons.badge_rounded,
                  _buildEquipmentSection(),
                ),
                // Only show External if Manager requires it
                if (_requireExternal) ...[
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    'External Visual Inspection',
                    Icons.visibility_rounded,
                    _buildExternalSection(),
                  ),
                ],
                // Only show Weld if Manager requires it
                if (_requireWeld) ...[
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    'Weld Visual Inspection',
                    Icons.linear_scale_rounded,
                    _buildWeldSection(),
                  ),
                ],
                // Only show Internal if Manager requires it
                if (_requireInternal) ...[
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    'Internal Visual Inspection',
                    Icons.auto_awesome_rounded,
                    _buildInternalSection(),
                  ),
                ],
                // Only show Thickness if Manager requires it
                if (_requireThickness) ...[
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    'Thickness Measurement',
                    Icons.straighten_rounded,
                    _buildThicknessSection(),
                  ),
                ],
                const SizedBox(height: 24),
                _buildSectionCard(
                  'Summary & Overall Condition',
                  Icons.summarize_rounded,
                  _buildSummarySection(),
                ),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryRedDark, AppTheme.primaryRed],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              Row(
                children: [
                  AppTheme.standardHeaderIcon(
                    icon: Icons.assignment_rounded,
                    hasGlow: true,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generate Inspection Report',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Complete all required sections and submit your inspection findings',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // In Progress badge removed as requested
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple title with icon - matching Equipment Identification
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryRed, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Inspection Details',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Inspection Type *
          Text(
            'Inspection Type *',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.inspection['title'] ?? 'Visual Inspection',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Equipment Tag
          Text(
            'Equipment Tag',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.inspection['equipment_tag'] ?? 'N/A',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Location
          Text(
            'Location',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.inspection['location'] ?? 'Process Area',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Inspection Date
          Text(
            'Inspection Date',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildDateSelector(),
          const SizedBox(height: 24),

          // Required Sections - show ALL sections with required ones in bold red
          Text(
            'Required Sections (Assigned by Manager)',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Show ALL sections - required ones are bold and red
              _buildSectionBadge('External Visual', _requireExternal),
              _buildSectionBadge('Weld Visual', _requireWeld),
              _buildSectionBadge('Internal Visual', _requireInternal),
              _buildSectionBadge('Thickness', _requireThickness),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBadge(String label, bool isRequired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        // RED for required, gray for non-required
        color: isRequired 
            ? AppTheme.primaryRed.withOpacity(0.12) 
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRequired ? AppTheme.primaryRed : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRequired ? Icons.check_circle : Icons.cancel_outlined,
            size: 16,
            color: isRequired ? AppTheme.primaryRed : Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isRequired ? FontWeight.w700 : FontWeight.w500, // Bold if required
              color: isRequired ? AppTheme.primaryRed : Colors.grey.shade600, // Red if required, gray otherwise
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(
              'Inspection Date',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event, color: AppTheme.primaryRed, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  DateFormat('EEEE, MMMM dd, yyyy').format(_inspectionDate),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryRed, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhotoUploadSection('equipment', _equipmentPhotos, 'Nameplate, Tag, & General Photos *'),
        const SizedBox(height: 20),
        _buildFindingRecommendation(
          'Finding',
          _equipmentFinding,
          (v) => _equipmentFinding = v,
          'e.g., Nameplate legible, tag number verified',
        ),
        const SizedBox(height: 16),
        _buildFindingRecommendation(
          'Recommendation',
          _equipmentRecommendation,
          (v) => _equipmentRecommendation = v,
          'e.g., Nil or repaint tag number',
        ),
      ],
    );
  }

  Widget _buildExternalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shell, Heads, Nozzles, Supports, Accessories', 
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        _buildPhotoUploadSection('external', _externalPhotos, 'External Component Photos'),
        const SizedBox(height: 20),
        _buildFindingRecommendation(
          'Finding',
          _externalFinding,
          (v) => _externalFinding = v,
          'e.g., No visible corrosion, minor rust on support',
        ),
        const SizedBox(height: 16),
        
        // NEW: Condition Dropdown
        _buildDropdownField(
          label: 'Condition *',
          value: _externalCondition,
          items: _conditionOptions,
          onChanged: (v) => setState(() => _externalCondition = v),
          hint: 'Select condition',
        ),
        const SizedBox(height: 16),
        
        // NEW: Section Recommendation Dropdown
        _buildDropdownField(
          label: 'Section Recommendation *',
          value: _externalSectionRecommendation,
          items: _sectionRecommendationOptions,
          onChanged: (v) => setState(() => _externalSectionRecommendation = v),
          hint: 'Select recommendation',
        ),
        const SizedBox(height: 16),
        
        _buildFindingRecommendation(
          'Additional Notes',
          _externalRecommendation,
          (v) => _externalRecommendation = v,
          'Any additional notes or detailed recommendations',
        ),
      ],
    );
  }

  Widget _buildWeldSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visual inspection of weld joints only (No NDT)', 
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        _buildPhotoUploadSection('weld', _weldPhotos, 'Weld Joint Photos'),
        const SizedBox(height: 20),
        _buildFindingRecommendation(
          'Finding',
          _weldFinding,
          (v) => _weldFinding = v,
          'e.g., Welds appear sound, no visible cracks',
        ),
        const SizedBox(height: 16),
        
        // NEW: Condition Dropdown
        _buildDropdownField(
          label: 'Condition *',
          value: _weldCondition,
          items: _conditionOptions,
          onChanged: (v) => setState(() => _weldCondition = v),
          hint: 'Select condition',
        ),
        const SizedBox(height: 16),
        
        // NEW: Section Recommendation Dropdown
        _buildDropdownField(
          label: 'Section Recommendation *',
          value: _weldSectionRecommendation,
          items: _sectionRecommendationOptions,
          onChanged: (v) => setState(() => _weldSectionRecommendation = v),
          hint: 'Select recommendation',
        ),
        const SizedBox(height: 16),
        
        _buildFindingRecommendation(
          'Additional Notes',
          _weldRecommendation,
          (v) => _weldRecommendation = v,
          'Any additional notes or detailed recommendations',
        ),
      ],
    );
  }

  Widget _buildInternalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text('Internal Inspection Accessible?', 
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          value: _internalAccessible,
          onChanged: (v) => setState(() => _internalAccessible = v),
          activeColor: AppTheme.primaryRed,
        ),
        if (_internalAccessible) ...[
          const SizedBox(height: 16),
          _buildPhotoUploadSection('internal', _internalPhotos, 'Internal Component Photos'),
          const SizedBox(height: 20),
          _buildFindingRecommendation(
            'Finding',
            _internalFinding,
            (v) => _internalFinding = v,
            'e.g., Internal surface clean, no corrosion observed',
          ),
          const SizedBox(height: 16),
          
          // NEW: Condition Dropdown
          _buildDropdownField(
            label: 'Condition *',
            value: _internalCondition,
            items: _conditionOptions,
            onChanged: (v) => setState(() => _internalCondition = v),
            hint: 'Select condition',
          ),
          const SizedBox(height: 16),
          
          // NEW: Section Recommendation Dropdown
          _buildDropdownField(
            label: 'Section Recommendation *',
            value: _internalSectionRecommendation,
            items: _sectionRecommendationOptions,
            onChanged: (v) => setState(() => _internalSectionRecommendation = v),
            hint: 'Select recommendation',
          ),
          const SizedBox(height: 16),
          
          _buildFindingRecommendation(
            'Additional Notes',
            _internalRecommendation,
            (v) => _internalRecommendation = v,
            'Any additional notes or detailed recommendations',
          ),
        ] else
          Text('Internal inspection not performed', 
            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }

  Widget _buildThicknessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Record measured thickness values only (No calculations)', 
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        ..._thicknessData.asMap().entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'e.g., Shell CML-1',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => _thicknessData[entry.key]['location'] = v,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Thickness (mm)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => _thicknessData[entry.key]['thickness'] = v,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeThicknessEntry(entry.key),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Remarks (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _thicknessData[entry.key]['remarks'] = v,
                ),
              ],
            ),
          );
        }).toList(),
        OutlinedButton.icon(
          onPressed: _addThicknessEntry,
          icon: const Icon(Icons.add),
          label: const Text('Add Thickness Measurement'),
        ),
        const SizedBox(height: 24),
        
        // NEW: Condition Dropdown for overall thickness assessment
        _buildDropdownField(
          label: 'Overall Thickness Condition *',
          value: _thicknessCondition,
          items: _conditionOptions,
          onChanged: (v) => setState(() => _thicknessCondition = v),
          hint: 'Select condition',
        ),
        const SizedBox(height: 16),
        
        // NEW: Section Recommendation Dropdown
        _buildDropdownField(
          label: 'Section Recommendation *',
          value: _thicknessSectionRecommendation,
          items: _sectionRecommendationOptions,
          onChanged: (v) => setState(() => _thicknessSectionRecommendation = v),
          hint: 'Select recommendation',
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overall Summary', 
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        const Divider(height: 24),
        
        Text('Overall Finding *', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Summary of all inspection sections', 
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        TextFormField(
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Provide an overall summary of your inspection findings...',
          ),
          onChanged: (v) => _overallCondition = v,
        ),
        const SizedBox(height: 20),
        
        Text('Overall Recommendation *', 
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextFormField(
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Provide your overall recommendation...',
          ),
          onChanged: (v) => _overallRecommendation = v,
        ),
        const SizedBox(height: 20),
        
        Text('Additional Comments', 
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Optional', 
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        TextFormField(
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Any additional comments or notes...',
          ),
          onChanged: (v) => _generalRecommendation = v,
        ),
      ],
    );
  }

  Widget _buildPhotoUploadSection(String section, List<XFile> photos, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _pickPhotos(section),
          icon: const Icon(Icons.add_photo_alternate),
          label: Text('Add Photos (${photos.length})'),
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: photos.asMap().entries.map((e) {
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FutureBuilder<Uint8List>(
                        future: e.value.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            );
                          } else {
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      onPressed: () => _removePhoto(section, e.key),
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildFindingRecommendation(String label, String value, Function(String) onChanged, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: 2,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
  
  // NEW: Dropdown field builder for Condition and Section Recommendation
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            if (label.contains('*'))
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Row(
                  children: [
                    if (label.contains('Condition')) ...[
                      Icon(
                        item == 'Satisfactory'
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: item == 'Satisfactory' ? Colors.green : Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(item, style: GoogleFonts.inter(fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitReport,
        icon: _isSubmitting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.check_circle),
        label: Text(_isSubmitting ? 'Generating PDF Report...' : 'Submit Report & Generate PDF',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
