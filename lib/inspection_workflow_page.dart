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
  String?
  _selectedMethod; // null = not selected, 'manual' = manual, 'automated' = automated (disabled)

  // Inspection metadata
  DateTime _inspectionDate = DateTime.now();

  // Scope requirements (from Manager's assignment)
  late bool _requireExternal;
  late bool _requireWeld;
  late bool _requireInternal;
  late bool _requireThickness;

  // Defect type options (used for analytics)
  final List<String> _defectOptions = [
    'Corrosion',
    'Crack',
    'Leakage',
    'Mechanical Damage',
    'Other',
    'Nil',
  ];

  // Section 1: Equipment Identification  // EQUIPMENT SECTION STATE
  List<InspectionSectionData> _equipmentSections = [
    InspectionSectionData(sectionNumber: 1)
  ];

  // EXTERNAL VISUAL SECTION STATE
  List<ExternalSectionData> _externalSections = [
    ExternalSectionData(sectionNumber: 1) // Initialize with 1 section by default
  ];

  final List<String> _externalComponents = [
    'Concrete foundation and skirt / support legs',
    'Anchor Bolts',
    'Earthing Cable',
    'External Shell',
    'Bottom Dish Head',
    'Top Dish Head',
    'Lifting Lugs',
    'Manhole',
    'Manhole Cover',
    'Davit Arm',
    'Attachment Nozzles',
    'Pressure Gauge',
  ];

  final Map<String, String> _externalSatisfactorySentences = {
    'Concrete foundation and skirt / support legs': 'observed in satisfactory condition with no significant damage or abnormalities.',
    'Anchor Bolts': 'noted secured, intact, and tightened with no sign of degradation or looseness.',
    'Earthing Cable': 'observed securely intact and in satisfactory condition.',
    'External Shell': 'found in good condition with insulation or coating intact and no visible abnormalities.',
    'Bottom Dish Head': 'observed in satisfactory condition with no evidence of significant damage.',
    'Top Dish Head': 'found in satisfactory profile with no sign of damage or deformation.',
    'Lifting Lugs': 'noted in serviceable condition and securely attached.',
    'Manhole': 'observed in serviceable condition with no deformation.',
    'Manhole Cover': 'observed in serviceable condition with no deformation.',
    'Davit Arm': 'observed in serviceable condition with no deformation.',
    'Attachment Nozzles': 'generally found in satisfactory condition.',
    'Pressure Gauge': 'observed in serviceable condition with no abnormalities.',
  };

  // Section 3: Weld Visual
  List<XFile> _weldPhotos = [];
  String? _weldFinding; // Changed to nullable to allow validation
  String? _weldCondition; // NEW: Satisfactory/Observation
  String _weldRecommendation = '';
  String? _weldSectionRecommendation; // NEW: Nil/Monitor

  // Section 4: Internal Visual (optional)
  bool _internalAccessible = false;
  List<XFile> _internalPhotos = [];
  String? _internalFinding; // Changed to nullable to allow validation
  String? _internalCondition; // NEW: Satisfactory/Observation
  String _internalRecommendation = '';
  String? _internalSectionRecommendation; // NEW: Nil/Monitor

  // Section 5: Thickness Measurement
  List<XFile> _thicknessPhotos = []; // ADDED: Thickness photos
  List<Map<String, String>> _thicknessData = [];
  String? _thicknessFinding;
  String? _thicknessCondition; // NEW: Satisfactory/Observation
  String? _thicknessSectionRecommendation; // NEW: Nil/Monitor

  // Section 6: Summary
  String _overallCondition = 'Satisfactory';
  String _generalRecommendation = '';
  String _overallRecommendation = ''; // NEW: Overall Recommendation for Page 1

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

  // Standardized Options for Equipment Identification
  final List<String> _equipmentFindingOptions = [
    'Nameplate tag in a good condition.',
    'Nameplate tag in a bad condition.',
    'PMT number in a good condition.',
    'PMT number in a bad condition.',
    'Equipment number in a good condition.',
    'Equipment number in a bad condition.',
    'General view of this equipment in a good condition.',
    'General view of this equipment in a bad condition.',
    'Other (please describe it)',
  ];

  final List<String> _equipmentRecommendationOptions = [
    'Nil.',
    'To be monitored during next inspection',
    'Repaint tag number',
    'Replace nameplate',
    'Other (please describe it)',
  ];

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inspectionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _inspectionDate = picked);
  }

  Future<void> _pickPhotos(String section, {int? sectionIndex}) async {
    try {
      // Try multi-image picker first (works on mobile)
      List<XFile>? picked;

      try {
        picked = await picker.pickMultiImage(imageQuality: 85);
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
              if (sectionIndex != null && sectionIndex < _equipmentSections.length) {
                // Limit to 3 photos per section
                final currentCount = _equipmentSections[sectionIndex].photos.length;
                final availableSlots = 3 - currentCount;
                if (availableSlots > 0) {
                   _equipmentSections[sectionIndex].photos.addAll(picked!.take(availableSlots));
                } else {
                   if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Max 3 photos per section'), backgroundColor: Colors.orange),
                    );
                   }
                   return; // Exit early
                }
              }
              break;
            case 'external':
              if (sectionIndex != null && sectionIndex < _externalSections.length) {
                final currentCount = _externalSections[sectionIndex].photos.length;
                final availableSlots = 3 - currentCount;
                if (availableSlots > 0) {
                   _externalSections[sectionIndex].photos.addAll(picked!.take(availableSlots));
                } else {
                   if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Max 3 photos per section'), backgroundColor: Colors.orange),
                    );
                   }
                   return;
                }
              } else {
                 // Fallback if no index provided (shouldn't happen with new UI)
                 // _externalPhotos legacy support removed
              }
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

  void _removePhoto(String section, int index, {int? sectionIndex}) {
    setState(() {
      switch (section) {
        case 'equipment':
          if (sectionIndex != null && sectionIndex < _equipmentSections.length) {
             _equipmentSections[sectionIndex].photos.removeAt(index);
          }
          break;
        case 'external':
           if (sectionIndex != null && sectionIndex < _externalSections.length) {
             _externalSections[sectionIndex].photos.removeAt(index);
          }
          break;
        case 'weld':
          _weldPhotos.removeAt(index);
          break;
        case 'internal':
          _internalPhotos.removeAt(index);
          break;
      }
    });
  }

  void _addThicknessEntry() {
    setState(
      () =>
          _thicknessData.add({'location': '', 'thickness': '', 'remarks': ''}),
    );
  }

  void _removeThicknessEntry(int index) {
    setState(() => _thicknessData.removeAt(index));
  }

  void _addEquipmentSection() {
    setState(() {
      int nextSectionNum = _equipmentSections.isEmpty
          ? 1
          : _equipmentSections.last.sectionNumber + 1;
      _equipmentSections.add(InspectionSectionData(sectionNumber: nextSectionNum));
      
      // Update External sections to follow sequence
      _updateExternalSectionNumbers();
    });
  }

  void _removeEquipmentSection(int index) {
    setState(() {
      _equipmentSections.removeAt(index);
      // Renumber sections
      for (int i = 0; i < _equipmentSections.length; i++) {
        _equipmentSections[i].sectionNumber = i + 1;
      }
      // Update External sections to follow sequence
      _updateExternalSectionNumbers();
    });
  }

  // EXTERNAL SECTION MANAGEMENT helpers
  void _addExternalSection() {
    setState(() {
       // Start strictly AFTER the last equipment section
      int startNum = _equipmentSections.isEmpty ? 1 : _equipmentSections.last.sectionNumber + 1;
      int nextSectionNum = _externalSections.isEmpty
          ? startNum
          : _externalSections.last.sectionNumber + 1;
          
      _externalSections.add(ExternalSectionData(sectionNumber: nextSectionNum));
    });
  }

  void _removeExternalSection(int index) {
    setState(() {
      _externalSections.removeAt(index);
      _updateExternalSectionNumbers();
    });
  }
  
  void _updateExternalSectionNumbers() {
      int startNum = _equipmentSections.isEmpty ? 1 : _equipmentSections.last.sectionNumber + 1;
      for (int i = 0; i < _externalSections.length; i++) {
        _externalSections[i].sectionNumber = startNum + i;
      }
  }

  // Helper to generate text for PDF report based on component + defect + condition
  String _generateExternalFindingText(ExternalSectionData section) {
    if (section.componentName == null) return "Component not specified";
    
    // CASE 1: Satisfactory (Nil defect)
    if ((section.defectType == 'Nil' || section.defectType == null) &&
        (section.condition == 'Satisfactory' || section.condition == null)) {
       return '${section.componentName} – ${_externalSatisfactorySentences[section.componentName] ?? "observed in satisfactory condition."}';
    }

    // CASE 2: Defect Present
    // "minor galvanic corrosion on bolting..."
    // Construct: [Component] – [Defect] observed at [Location?]. Condition: [Condition].
    String defect = section.defectType ?? 'Defect';
    String cond = section.condition ?? 'Observation';
    
    // Custom logic for Attachment Nozzles example requested by user
    if (section.componentName == 'Attachment Nozzles' && defect != 'Nil') {
       return 'Attachment Nozzles – minor $defect on bolting due to dissimilar materials noted ($cond condition).';
    }

    // Generic fallback for others
    return '${section.componentName} – $defect observed. Condition noted as $cond.';
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    // ========== VALIDATION FOR REQUIRED SECTIONS ==========
    // Ensure all manager-assigned sections are completed before submission

    List<String> missingItems = [];

    // Equipment Identification (always required)
    // Flatten consolidated list of all photos
    List<XFile> allEquipmentPhotos = [];
    for (var s in _equipmentSections) {
      allEquipmentPhotos.addAll(s.photos);
    }

    if (allEquipmentPhotos.isEmpty) {
      missingItems.add('Equipment Identification: At least 1 photo required');
    }

    // Weld Visual - only if required by manager
      // Validating WELD Section
      // Only valid if photos are added
      if (_weldPhotos.isNotEmpty) {
           if (_weldFinding == null) {
              _showError('Please select a finding for Weld Visual section');
              return;
           }
           if (_weldCondition == null) {
              _showError('Please select a condition for Weld Visual section');
              return;
           }
           if (_weldSectionRecommendation == null) {
              _showError('Please select a recommendation for Weld Visual section');
              return;
           }
      }

      // 4. Validate EXTERNAL VISUAL (New Logic)
      // Iterate through sections to ensure required fields are filled if section exists
      if (_externalSections.isNotEmpty) {
         for (int i = 0; i < _externalSections.length; i++) {
            var section = _externalSections[i];
            
            if (section.photos.isEmpty) {
               _showError('Please add at least 1 photo for External Section ${section.sectionNumber}');
               return;
            }

            if (section.componentName == null) {
               _showError('Please select a component for External Section ${section.sectionNumber}');
               return;
            }
            if (section.defectType == null) {
               _showError('Please select a defect type for External Section ${section.sectionNumber}');
               return;
            }
            if (section.condition == null) {
               _showError('Please select a condition for External Section ${section.sectionNumber}');
               return;
            }
            if (section.recommendation == null) {
               _showError('Please select a recommendation for External Section ${section.sectionNumber}');
               return;
            }
         }
      }
    // Internal Visual - only if required by manager AND accessible
    if (_requireInternal && _internalAccessible) {
      if (_internalFinding == null) {
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
      if (_thicknessData.isEmpty ||
          _thicknessData.every((t) => (t['location'] ?? '').isEmpty)) {
        missingItems.add(
          'Thickness Measurement: At least 1 measurement required',
        );
      }
      if (_thicknessFinding == null) {
        missingItems.add('Thickness Measurement: Finding is required');
      }
      if (_thicknessCondition == null) {
        missingItems.add('Thickness Measurement: Condition is required');
      }
      if (_thicknessSectionRecommendation == null) {
        missingItems.add(
          'Thickness Measurement: Section Recommendation is required',
        );
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
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.accentYellow,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Incomplete Sections',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please complete the following required items before generating the report:',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...missingItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 8,
                        color: AppTheme.primaryRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Flatten Findings to mimic legacy structure: "1.1 Finding text\n1.2 Finding text"
      // Map one finding/recommendation to one photo if possible, or just list them.
      // Logic: For each section, list findings prefixed with X.Y
      // The user wants: "can we specify '1.1 finding' is for '1.1 image'?"
      // Ideally, the checkbox selection implies it applies to the photos in that section.
      
      List<String> flatFindings = [];
      List<String> flatRecommendations = [];

      for (var section in _equipmentSections) {
        for (int i = 0; i < section.photos.length; i++) {
           // If there are findings selected, assign them to photos cyclically or just list all
           // But the prompt implies standard checkboxes.
           // Let's formatting: "1.x <Finding Text>"
           // If the user selected multiple findings, we assume they apply to the set of photos.
           // However, let's just dump the selected checkboxes as text lines.
        }
        // Actually, better approach for report readability:
        // "Section 1 Findings: \n - Finding 1 \n - Finding 2"
        // But user wants "1.1 finding".
        // Let's format as: 
        // "1.1: [First Selected Finding]" 
        // "1.2: [Second Selected Finding]" (if 2nd photo exists)
        // If simply checkboxes, maybe we just list them all under the section.
        
        if (section.selectedFindings.isNotEmpty) {
           for (var f in section.selectedFindings) {
             flatFindings.add('${section.sectionNumber}.x $f'); 
           }
        }
        if (section.selectedRecommendations.isNotEmpty) {
           for (var r in section.selectedRecommendations) {
             flatRecommendations.add('${section.sectionNumber}.x $r');
           }
        }
      }
      
      // REVISED LOGIC based on "1.1 finding is for 1.1 image" request:
      // We will map the *first* selected finding to *first* photo, etc.
      
      List<String> refinedFindings = [];
      List<String> refinedRecommendations = [];
      
      for (var section in _equipmentSections) {
        int photoCount = section.photos.length;
        int findingCount = section.selectedFindings.length;
        int recCount = section.selectedRecommendations.length;
        
        for (int i = 0; i < photoCount; i++) {
          String label = '${section.sectionNumber}.${i + 1}';
          
          // Finding
          String findingText = 'Nil';
          if (i < findingCount) {
            findingText = section.selectedFindings[i];
          } else if (findingCount > 0) {
             // If more photos than findings, repeat last or leave empty?
             // Let's just use "See above" or if findingCount == 1, apply to all.
             // If findingCount == 1, apply to all photos
             if (findingCount == 1) findingText = section.selectedFindings[0];
          }
          refinedFindings.add('$label $findingText');
          
          // Recommendation
          String recText = 'Nil';
          if (i < recCount) {
             recText = section.selectedRecommendations[i];
          } else if (recCount > 0) {
             if (recCount == 1) recText = section.selectedRecommendations[0];
          }
          refinedRecommendations.add('$label $recText');
        }
      }

      String finalEquipmentFinding = refinedFindings.join('\n');
      String finalEquipmentRecommendation = refinedRecommendations.join('\n');

      // Prepare structured data for PDF generator (to support multi-photo rows per section)
      List<Map<String, dynamic>> equipmentSectionsData = [];

      // 1. Process EQUIPMENT Sections
      for (var section in _equipmentSections) {
         List<String> sectionFindings = [];
         List<String> sectionRecommendations = [];
         
         int photoCount = section.photos.length;
         int findingCount = section.selectedFindings.length;
         int recCount = section.selectedRecommendations.length;

         for (int i = 0; i < photoCount; i++) {
            String label = '${section.sectionNumber}.${i + 1}';
            
            String fText = 'Nil';
            if (i < findingCount) fText = section.selectedFindings[i];
            else if (findingCount == 1) fText = section.selectedFindings[0];
            sectionFindings.add('$label $fText');

            String rText = 'Nil';
            if (i < recCount) rText = section.selectedRecommendations[i];
            else if (recCount == 1) rText = section.selectedRecommendations[0];
            sectionRecommendations.add('$label $rText');
         }

         equipmentSectionsData.add({
           'section_number': section.sectionNumber,
           'photos': section.photos, // List<XFile>
           'findings': sectionFindings,
           'recommendations': sectionRecommendations,
         });
      }

      // 2. Process EXTERNAL Sections (Appended to same list for PDF flow)
      for (var section in _externalSections) {
        List<String> sectionFindings = [];
        List<String> sectionRecommendations = [];
        int photoCount = section.photos.length;

        // Generate the automated finding text
        String autoFinding = _generateExternalFindingText(section);
        String autoRec = section.recommendation ?? 'Nil';

        for (int i = 0; i < photoCount; i++) {
           String label = '${section.sectionNumber}.${i + 1}';
           // For external, the single generated sentence applies to the whole section (all photos)
           sectionFindings.add('$label $autoFinding');
           sectionRecommendations.add('$label $autoRec');
        }
        
        equipmentSectionsData.add({
           'section_number': section.sectionNumber,
           'photos': section.photos,
           'findings': sectionFindings,
           'recommendations': sectionRecommendations,
        });
      }

      // Collect all form data
      final reportData = {
        'inspection_date': DateFormat('yyyy-MM-dd').format(_inspectionDate),
        'equipment_finding': finalEquipmentFinding.isEmpty
            ? 'Nil'
            : finalEquipmentFinding,
        'equipment_recommendation': finalEquipmentRecommendation.isEmpty
            ? 'Nil'
            : finalEquipmentRecommendation,
        'equipment_sections_data': equipmentSectionsData, // Contains BOTH Equipment and External

        // Legacy/Graph Support Fields (Still populated for backend parsing/analytics)
        'external_finding': _externalSections.isNotEmpty ? _externalSections.first.defectType ?? 'Nil' : 'Nil',
        'external_condition': _externalSections.isNotEmpty ? _externalSections.first.condition ?? 'Satisfactory' : 'Satisfactory',
        'external_section_recommendation': _externalSections.isNotEmpty ? _externalSections.first.recommendation ?? 'Nil' : 'Nil',
        'external_recommendation': 'See sections above',

        // Weld Visual with NEW fields
        'weld_finding': _weldFinding ?? 'Nil',
        'weld_condition': _weldCondition ?? 'Satisfactory',
        'weld_section_recommendation': _weldSectionRecommendation ?? 'Nil',
        'weld_recommendation': _weldRecommendation.isEmpty
            ? 'Nil'
            : _weldRecommendation,

        // Internal Visual with NEW fields
        'internal_accessible': _internalAccessible,
        'internal_finding': _internalAccessible ? (_internalFinding ?? 'Nil') : null,
        'internal_condition': _internalAccessible
            ? (_internalCondition ?? 'Satisfactory')
            : null,
        'internal_section_recommendation': _internalAccessible
            ? (_internalSectionRecommendation ?? 'Nil')
            : null,
        'internal_recommendation': _internalAccessible
            ? (_internalRecommendation.isEmpty
                  ? 'Nil'
                  : _internalRecommendation)
            : null,

        // Thickness with NEW fields
        'thickness_data': _thicknessData,
        'thickness_finding': _thicknessFinding ?? 'Nil',
        'thickness_condition': _thicknessCondition ?? 'Satisfactory',
        'thickness_section_recommendation':
            _thicknessSectionRecommendation ?? 'Nil',

        // Overall Summary with NEW field
        'overall_condition': _overallCondition,
        'overall_recommendation': _overallRecommendation.isEmpty
            ? 'Nil'
            : _overallRecommendation,
        'general_recommendation': _generalRecommendation.isEmpty
            ? 'Continue routine schedule'
            : _generalRecommendation,
        'photos': [
          ...allEquipmentPhotos,
          ..._externalSections.expand((s) => s.photos).toList(),
          ..._weldPhotos,
          ..._internalPhotos,
        ],
        'photo_sections': {
          'equipment': allEquipmentPhotos.length,
          'external': _externalSections.expand((s) => s.photos).length,
          'weld': _weldPhotos.length,
          'internal': _internalPhotos.length,
        },
      };

      // TODO: Send reportData to backend or generate PDF
      // For now, let's just generate the PDF directly
      setState(() => _isSubmitting = true);
      
      try {
        final pdfBytes = await PdfGenerator.generateVisualInspectionReport(
          inspection: widget.inspection,
          reportData: reportData,
          requireExternal: _requireExternal,
          requireWeld: _requireWeld,
          requireInternal: _requireInternal,
          requireThickness: _requireThickness,
        );
        
        setState(() => _isSubmitting = false);

        if (mounted) {
          Navigator.push(
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
        }
      } catch (e) {
        setState(() => _isSubmitting = false);
        _showError('Error generating PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
                    description:
                        'Manually fill in inspection details and upload evidence',
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
                    description:
                        'AI-powered inspection with automated data collection',
                    isAvailable: false,
                    isSelected: false,
                    comingSoon: true,
                    onTap: () {
                      // Disabled - show message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Automated Inspection is coming soon!',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
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
        border: Border.all(
          color: AppTheme.primaryRed.withValues(alpha: 0.2),
          width: 2,
        ),
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
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.primaryRed,
                  size: 24,
                ),
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
            'Inspection Title:',
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
              widget.inspection['title'] ?? 'N/A',
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
          'Equipment Tag:',
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
            widget.inspection['equipment_id'] ?? 'N/A', // Fixed key
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Equipment Type
        Text(
          'Equipment Type:',
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
            widget.inspection['equipment_type'] ?? 'N/A',
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
          'Location:',
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
              widget.inspection['location'] ?? 'N/A',
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
            'Inspection Date:',
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
              fontWeight: isRequired
                  ? FontWeight.w700
                  : FontWeight.w500, // Bold if required
              color: isRequired
                  ? AppTheme.primaryRed
                  : Colors.grey.shade600, // Red if required, gray otherwise
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
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppTheme.textMuted,
            ),
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
              border: Border.all(
                color: AppTheme.primaryRed.withValues(alpha: 0.3),
                width: 1.5,
              ),
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
                  child: const Icon(
                    Icons.event,
                    color: AppTheme.primaryRed,
                    size: 20,
                  ),
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
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(24), child: content),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._equipmentSections.asMap().entries.map((entry) {
          final index = entry.key;
          final section = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Section ${section.sectionNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (_equipmentSections.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.primaryRed, size: 20),
                        onPressed: () => _removeEquipmentSection(index),
                        tooltip: 'Remove Section',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPhotoUploadSection(
                  'equipment',
                  section.photos,
                  'Photos (Max 3)',
                  sectionIndex: index,
                  sectionNumber: section.sectionNumber,
                  maxPhotos: 3,
                ),
                const SizedBox(height: 20),

                // WARNING if no photos
                if (section.photos.isEmpty)
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 8.0),
                     child: Row(
                       children: [
                         const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                         const SizedBox(width: 8),
                         Text(
                           'Please add a photo to enable details.',
                           style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade800),
                         ),
                       ],
                     ),
                   ),

                Opacity(
                  opacity: section.photos.isEmpty ? 0.5 : 1.0,
                  child: IgnorePointer(
                    ignoring: section.photos.isEmpty,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finding',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200)),
                          child: Column(
                            children: _equipmentFindingOptions.map((option) {
                              return CheckboxListTile(
                                title: Text(option,
                                    style: GoogleFonts.inter(fontSize: 13)),
                                value: section.selectedFindings.contains(option),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppTheme.primaryRed,
                                controlAffinity: ListTileControlAffinity.leading,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      section.selectedFindings.add(option);
                                    } else {
                                      section.selectedFindings.remove(option);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Recommendation',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    children: _equipmentRecommendationOptions.map((option) {
                      return CheckboxListTile(
                        title: Text(option,
                            style: GoogleFonts.inter(fontSize: 13)),
                        value: section.selectedRecommendations.contains(option),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppTheme.primaryRed,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              section.selectedRecommendations.add(option);
                            } else {
                              section.selectedRecommendations.remove(option);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                      ], 
                    ), 
                  ), 
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _addEquipmentSection,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Add Section'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExternalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shell, Heads, Nozzles, Supports, Accessories',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        
        ..._externalSections.asMap().entries.map((entry) {
          final index = entry.key;
          final section = entry.value;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Section ${section.sectionNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.primaryRed, size: 20),
                      onPressed: () => _removeExternalSection(index),
                      tooltip: 'Remove Section',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // PHOTOS
                _buildPhotoUploadSection(
                  'external',
                  section.photos,
                  'External Photos (Max 3)',
                  sectionIndex: index,
                  sectionNumber: section.sectionNumber,
                  maxPhotos: 3,
                ),
                const SizedBox(height: 20),

                // WARNING if no photos
                if (section.photos.isEmpty)
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 8.0),
                     child: Row(
                       children: [
                         const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                         const SizedBox(width: 8),
                         Text(
                           'Please add a photo to enable details.',
                           style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade800),
                         ),
                       ],
                     ),
                   ),

                // Fields are disabled until photos are added
                Opacity(
                  opacity: section.photos.isEmpty ? 0.5 : 1.0,
                  child: IgnorePointer(
                    ignoring: section.photos.isEmpty,
                    child: Column(
                      children: [
                        // COMPONENT DROPDOWN
                        _buildDropdownField(
                          label: 'Component *',
                          value: section.componentName,
                          items: _externalComponents,
                          onChanged: (v) => setState(() => section.componentName = v),
                          hint: 'Select component',
                        ),
                        const SizedBox(height: 16),
                
                        // FINDING DROPDOWN
                        _buildDropdownField(
                          label: 'Finding (Defect Type) *',
                          value: section.defectType,
                          items: _defectOptions,
                          onChanged: (v) {
                             setState(() {
                               section.defectType = v;
                               // Automatic logic:
                               if (v == 'Nil') {
                                 section.condition = 'Satisfactory';
                                 section.recommendation = 'Nil';
                               } else {
                                 section.condition = 'Observation';
                                 section.recommendation = 'Monitor';
                               }
                             });
                          },
                          hint: 'Select defect type',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // CONDITION DROPDOWN
                _buildDropdownField(
                  label: 'Condition *',
                  value: section.condition,
                  items: _conditionOptions,
                  onChanged: (v) => setState(() => section.condition = v),
                  hint: 'Select condition',
                ),
                const SizedBox(height: 16),

                // RECOMMENDATION DROPDOWN
                _buildDropdownField(
                  label: 'Section Recommendation *',
                  value: section.recommendation,
                  items: _sectionRecommendationOptions,
                  onChanged: (v) => setState(() => section.recommendation = v),
                  hint: 'Select recommendation',
                ),
              ],
            ),
          );
        }).toList(),
        
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _addExternalSection,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Add Section'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeldSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visual inspection of weld joints only (No NDT)',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        _buildPhotoUploadSection('weld', _weldPhotos, 'Weld Joint Photos'),
        const SizedBox(height: 20),

        if (_weldPhotos.isEmpty)
           Padding(
             padding: const EdgeInsets.symmetric(vertical: 8.0),
             child: Row(
               children: [
                 const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                 const SizedBox(width: 8),
                 Text(
                   'Please add a photo to enable details.',
                   style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade800),
                 ),
               ],
             ),
           ),

        Opacity(
          opacity: _weldPhotos.isEmpty ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: _weldPhotos.isEmpty,
            child: Column(
              children: [
                _buildDropdownField(
                  label: 'Finding (Defect Type) *',
                  value: _weldFinding,
                  items: _defectOptions,
                  onChanged: (v) => setState(() => _weldFinding = v),
                  hint: 'Select defect type',
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInternalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(
            'Internal Inspection Accessible?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          value: _internalAccessible,
          onChanged: (v) => setState(() => _internalAccessible = v),
          activeColor: AppTheme.primaryRed,
        ),
        if (_internalAccessible) ...[
          const SizedBox(height: 16),
          _buildPhotoUploadSection(
            'internal',
            _internalPhotos,
            'Internal Component Photos',
          ),
          const SizedBox(height: 20),

        if (_internalPhotos.isEmpty)
           Padding(
             padding: const EdgeInsets.symmetric(vertical: 8.0),
             child: Row(
               children: [
                 const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                 const SizedBox(width: 8),
                 Text(
                   'Please add a photo to enable details.',
                   style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade800),
                 ),
               ],
             ),
           ),

          Opacity(
            opacity: _internalPhotos.isEmpty ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: _internalPhotos.isEmpty,
              child: Column(
                children: [
                    _buildDropdownField(
                      label: 'Finding (Defect Type) *',
                      value: _internalFinding,
                      items: _defectOptions,
                      onChanged: (v) => setState(() => _internalFinding = v),
                      hint: 'Select defect type',
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
                      onChanged: (v) =>
                          setState(() => _internalSectionRecommendation = v),
                      hint: 'Select recommendation',
                    ),
                    const SizedBox(height: 16),
          
                    _buildFindingRecommendation(
                      'Additional Notes',
                      _internalRecommendation,
                      (v) => _internalRecommendation = v,
                      'Any additional notes or detailed recommendations',
                    ),
                ],
              ),
            ),
          ),
        ] else
          Text(
            'Internal inspection not performed',
            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildThicknessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Record measured thickness values only (No calculations)',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        
        // NEW: Thickness Photos
        _buildPhotoUploadSection(
            'thickness', 
            _thicknessPhotos, 
            'Thickness Measurement Photos'
        ),
        const SizedBox(height: 20),

        if (_thicknessPhotos.isEmpty)
           Padding(
             padding: const EdgeInsets.symmetric(vertical: 8.0),
             child: Row(
               children: [
                 const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                 const SizedBox(width: 8),
                 Text(
                   'Please add a photo to enable details.',
                   style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade800),
                 ),
               ],
             ),
           ),

        Opacity(
            opacity: _thicknessPhotos.isEmpty ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: _thicknessPhotos.isEmpty,
              child: Column(
                children: [
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
                        onChanged: (v) =>
                            _thicknessData[entry.key]['location'] = v,
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
                        onChanged: (v) =>
                            _thicknessData[entry.key]['thickness'] = v,
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

        // NEW: Thickness Finding (Defect Type)
        _buildDropdownField(
          label: 'Thickness Finding (Defect Type) *',
          value: _thicknessFinding,
          items: _defectOptions,
          onChanged: (v) => setState(() => _thicknessFinding = v),
          hint: 'Select defect type',
        ),
        const SizedBox(height: 16),

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
              ),
            ),
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Summary',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Divider(height: 24),

        Text(
          'Overall Finding *',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Summary of all inspection sections',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        TextFormField(
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText:
                'Provide an overall summary of your inspection findings...',
          ),
          onChanged: (v) => _overallCondition = v,
        ),
        const SizedBox(height: 20),

        Text(
          'Overall Recommendation *',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
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

        Text(
          'Additional Comments',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Optional',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
        ),
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

  Widget _buildPhotoUploadSection(
    String section,
    List<XFile> photos,
    String label, {
    int? sectionIndex,
    int? sectionNumber, // ADDED: Passing explicit number avoids incorrect list lookup
    int maxPhotos = 100,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (photos.length < maxPhotos)
          OutlinedButton.icon(
            onPressed: () => _pickPhotos(section, sectionIndex: sectionIndex),
            icon: const Icon(Icons.add_photo_alternate),
            label: Text('Add Photos (${photos.length}/$maxPhotos)'),
          ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: photos.asMap().entries.map((e) {
              final photoIndex = e.key + 1;
              // use sectionNumber if provided, otherwise standard label
              final String photoLabel = sectionNumber != null
                  ? '$sectionNumber.$photoIndex'
                  : 'Photo $photoIndex';

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
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8)),
                      ),
                      child: Text(
                        photoLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      onPressed: () =>
                          _removePhoto(section, e.key, sectionIndex: sectionIndex),
                      icon: const Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 20,
                      ),
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

  Widget _buildFindingRecommendation(
    String label,
    String value,
    Function(String) onChanged,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: 2,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
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
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
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
                        color: item == 'Satisfactory'
                            ? Colors.green
                            : Colors.orange,
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
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
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
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.check_circle),
        label: Text(
          _isSubmitting
              ? 'Generating PDF Report...'
              : 'Submit Report & Generate PDF',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class InspectionSectionData {
  int sectionNumber;
  List<XFile> photos;
  List<String> selectedFindings;
  List<String> selectedRecommendations;

  InspectionSectionData({
    required this.sectionNumber,
    List<XFile>? photos,
    List<String>? selectedFindings,
    List<String>? selectedRecommendations,
  })  : photos = photos ?? [],
        selectedFindings = selectedFindings ?? [],
        selectedRecommendations = selectedRecommendations ?? [];
}

class ExternalSectionData {
  int sectionNumber;
  List<XFile> photos;
  String? componentName;
  String? defectType; 
  String? condition;
  String? recommendation; 

  ExternalSectionData({
    required this.sectionNumber,
    List<XFile>? photos,
    this.componentName,
    this.defectType,
    this.condition,
    this.recommendation,
  }) : photos = photos ?? [];
}
