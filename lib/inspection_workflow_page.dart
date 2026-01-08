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
    'Pitting',
    'Discoloration',
    'Nil',
  ];

  // Section 1: Equipment Identification  // EQUIPMENT SECTION STATE
  List<InspectionSectionData> _equipmentSections = [
    InspectionSectionData(sectionNumber: 1)
  ];

  // EXTERNAL VISUAL SECTION STATE
  List<ExternalSectionData> _externalSections = [
    ExternalSectionData(sectionNumber: 2) // Initialize with 2 (after Equipment)
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
  List<WeldSectionData> _weldSections = [
    WeldSectionData(sectionNumber: 3) // Initialize with 3 (after External)
  ];

  // Section 4: Internal Visual (optional)

  // Section 4: Internal Visual
  bool _internalAccessible = false; // Still used to toggle section visibility
  List<InternalSectionData> _internalSections = [
    InternalSectionData(sectionNumber: 4) // Initialize after Weld (which is 3)
  ];

  // Section 5: Thickness Measurement

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

  final List<String> _weldComponents = [
    'Circumferential weld seams (CW)',
    'Longitudinal weld seams (LW)',
    'Manhole weldment',
  ];

  final Map<String, String> _weldSatisfactorySentences = {
    'Circumferential weld seams (CW)':
        'generally in good profile.',
    'Longitudinal weld seams (LW)':
        'observed in satisfactory condition.',
    'Manhole weldment':
        'serviceable condition.',
  };
  
  // NEW: Internal Visual Data Structure
  final List<String> _internalComponents = [
    'Internal shell wall',
    'Internal Bottom dish head',
    'Internal Top dish head',
    'Internal attachment nozzles',
    'Baffle plates, vortex breaker & thermocouple',
    'Manhole flange',
    'Gasket seat area',
  ];

  final List<String> _thicknessLocations = [
    'Shell',
    'Dish heads',
    'Welded joints',
  ];

  // Summary generation state
  bool _showSummary = false;

  final Map<String, String> _internalSatisfactorySentences = {
    'Internal shell wall':
        'found in serviceable condition with no bulging or major abnormalities; isolated mechanical marks or minor pitting noted and monitored.',
    'Internal Bottom dish head':
        'observed in satisfactory condition with no sign of degradation.',
    'Internal Top dish head':
        'generally satisfactory; surface discoloration noted on one equipment with no associated damage.',
    'Internal attachment nozzles':
        'found securely intact and free from visible defects.',
    'Baffle plates, vortex breaker & thermocouple':
        'observed securely intact and free from any significant damage.',
    'Manhole flange':
        'noted in satisfactory condition with no sign of damage.',
    'Gasket seat area':
        'noted in serviceable condition with no sign of significant imperfection; minor mechanical marks or dents observed at clock positions, conditions are acceptable per ASME PCC-1 and monitored.',
  };

  @override
  void initState() {
    super.initState();
    // Load scope requirements from Manager's assignment
    _requireExternal = widget.inspection['require_external'] ?? true;
    _requireWeld = widget.inspection['require_weld'] ?? true;
    _requireInternal = widget.inspection['require_internal'] ?? false;
    _requireThickness = widget.inspection['require_thickness'] ?? false;
    
    // Ensure section numbers are strictly sequential on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _updateAllSectionNumbers();
    });
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
  ];

  final List<String> _equipmentRecommendationOptions = [
    'Nil.',
    'To be monitored during next inspection',
    'Repaint',
    'Replace',
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
              if (sectionIndex != null && sectionIndex < _weldSections.length) {
                final currentCount = _weldSections[sectionIndex].photos.length;
                final availableSlots = 3 - currentCount;
                if (availableSlots > 0) {
                   _weldSections[sectionIndex].photos.addAll(picked!.take(availableSlots));
                } else {
                   if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Max 3 photos per section'), backgroundColor: Colors.orange),
                    );
                   }
                   return;
                }
              }
              break;
            case 'internal':
              if (sectionIndex != null && sectionIndex < _internalSections.length) {
                  // Limit to 3 photos
                  final currentCount = _internalSections[sectionIndex].photos.length;
                  final availableSlots = 3 - currentCount;
                  if (availableSlots > 0) {
                     _internalSections[sectionIndex].photos.addAll(picked!.take(availableSlots));
                  } else {
                     if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Max 3 photos per section'), backgroundColor: Colors.orange),
                      );
                     }
                     return;
                  }
               }
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
             var section = _equipmentSections[sectionIndex];
             section.photos.removeAt(index);
             
             // Shift map keys to keep findings aligned with remaining photos
             // 1. Remove data for deleted photo
             section.photoFindings.remove(index);
             section.photoRecommendations.remove(index);
             
             // 2. Shift subsequent items down
             // We need a temporary copy of keys to iterate safely or just loop from index+1 to max
             // Max possible photos was 3, so loop index+1 up to 2.
             for (int i = index + 1; i < 3; i++) {
                if (section.photoFindings.containsKey(i)) {
                   section.photoFindings[i - 1] = section.photoFindings[i]!;
                   section.photoFindings.remove(i);
                }
                if (section.photoRecommendations.containsKey(i)) {
                   section.photoRecommendations[i - 1] = section.photoRecommendations[i]!;
                   section.photoRecommendations.remove(i);
                }
             }
          }
          break;
        case 'external':
           if (sectionIndex != null && sectionIndex < _externalSections.length) {
             _externalSections[sectionIndex].photos.removeAt(index);
          }
          break;
        case 'weld':
          if (sectionIndex != null && sectionIndex < _weldSections.length) {
             _weldSections[sectionIndex].photos.removeAt(index);
          }
          break;
        case 'internal':
           if (sectionIndex != null && sectionIndex < _internalSections.length) {
              _internalSections[sectionIndex].photos.removeAt(index);
           }
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

  // Ensure sequential numbering across ALL section types
  void _updateAllSectionNumbers() {
    int currentNum = 1;
    
    // Equipment (always 1 or sequential if multiple)
    if (_equipmentSections.isNotEmpty) {
      for (int i = 0; i < _equipmentSections.length; i++) {
        _equipmentSections[i].sectionNumber = currentNum++;
      }
    } else {
       // If no equipment section, we still start counter at 1? 
       // Typically Equipment is required, but let's assume 1.
       currentNum = 1;
    }

    // External
    for (int i = 0; i < _externalSections.length; i++) {
      _externalSections[i].sectionNumber = currentNum++;
    }

    // Weld
    for (int i = 0; i < _weldSections.length; i++) {
      _weldSections[i].sectionNumber = currentNum++;
    }

    // Internal
    for (int i = 0; i < _internalSections.length; i++) {
      _internalSections[i].sectionNumber = currentNum++;
    }
  }

  void _addEquipmentSection() {
    setState(() {
      _equipmentSections.add(InspectionSectionData(sectionNumber: 0));
      _updateAllSectionNumbers();
    });
  }

  void _removeEquipmentSection(int index) {
    setState(() {
      _equipmentSections.removeAt(index);
      _updateAllSectionNumbers();
    });
  }

  // EXTERNAL SECTION MANAGEMENT helpers
  void _addExternalSection() {
    setState(() {
      _externalSections.add(ExternalSectionData(sectionNumber: 0));
      _updateAllSectionNumbers();
    });
  }

  void _removeExternalSection(int index) {
    setState(() {
      _externalSections.removeAt(index);
      _updateAllSectionNumbers();
    });
  }

  // WELD SECTION MANAGEMENT helpers
  void _addWeldSection() {
    setState(() {
      _weldSections.add(WeldSectionData(sectionNumber: 0));
      _updateAllSectionNumbers();
    });
  }

  void _removeWeldSection(int index) {
    setState(() {
      _weldSections.removeAt(index);
      _updateAllSectionNumbers();
    });
  }

  // Helper to generate text for PDF report based on component + defect + condition
  String _generateExternalFindingText(ExternalSectionData section) {
    if (section.componentName == null) return "Component not specified";
    
    // CASE 1: Satisfactory (Nil defect)
    if ((section.defectType == 'Nil' || section.defectType == null) &&
        (section.condition == 'Satisfactory' || section.condition == null)) {
       return '${section.componentName} - ${_externalSatisfactorySentences[section.componentName] ?? "observed in satisfactory condition."}';
    }

    // CASE 2: Defect Present
    // "minor galvanic corrosion on bolting..."
    // Construct: [Component] – [Defect] observed at [Location?]. Condition: [Condition].
    String defect = section.defectType ?? 'Defect';
    String cond = section.condition ?? 'Observation';
    
    // Custom logic for Attachment Nozzles example requested by user
    if (section.componentName == 'Attachment Nozzles' && defect != 'Nil') {
       return 'Attachment Nozzles - minor $defect on bolting due to dissimilar materials noted ($cond condition).';
    }

    // Generic fallback for others
    return '${section.componentName} - $defect observed. Condition noted as $cond.';
  }

  String _generateWeldFindingText(WeldSectionData section) {
    if (section.componentName == null) return "Component not specified";

    if ((section.defectType == 'Nil' || section.defectType == null) &&
        (section.condition == 'Satisfactory' || section.condition == null)) {
      return '${section.componentName} - ${_weldSatisfactorySentences[section.componentName] ?? "observed in satisfactory condition."}';
    }

    String defect = section.defectType ?? 'Defect';
    String cond = section.condition ?? 'Observation';

    // Specific sentences for common defects (Pitting/Mechanical) to provide rich detail
    if (section.condition == 'Observation') {
       if (section.componentName == 'Circumferential weld seams (CW)' && section.defectType == 'Pitting') {
           return '${section.componentName} - localized pitting or cluster porosity (<0.5 mm to approx 4 mm depth) noted and monitored with no propagation.';
       }
       if (section.componentName == 'Longitudinal weld seams (LW)' && 
          (section.defectType == 'Pitting' || section.defectType == 'Mechanical Damage')) {
           return '${section.componentName} - isolated cluster porosity or mechanical marks noted, previously tested and acceptable.';
       }
       if (section.componentName == 'Manhole weldment' && section.defectType == 'Pitting') {
           return '${section.componentName} - localized pitting at specific clock positions noted and recommended for monitoring.';
       }
    }

    return '${section.componentName} - $defect observed. Condition noted as $cond.';
  }

  // INTERNAL SECTION MANAGEMENT helpers
  void _addInternalSection() {
    setState(() {
      _internalSections.add(InternalSectionData(sectionNumber: 0));
      _updateAllSectionNumbers();
    });
  }

  void _removeInternalSection(int index) {
    setState(() {
      _internalSections.removeAt(index);
      _updateAllSectionNumbers();
    });
  }

  String _generateInternalFindingText(InternalSectionData section) {
    if (section.componentName == null) return "Component not specified";

    bool isSatisfactory = (section.defectType == 'Nil' || section.defectType == null) &&
        (section.condition == 'Satisfactory' || section.condition == null);

    if (isSatisfactory) {
      return '${section.componentName} - ${_internalSatisfactorySentences[section.componentName] ?? "observed in satisfactory condition."}';
    }

    String defect = section.defectType ?? 'Defect';
    String cond = section.condition ?? 'Observation';

    // Generic fallback for defects
    return '${section.componentName} - $defect observed. Condition noted as $cond.';
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
    } else {
       // Validate that each photo has a finding selected
       // AND each section matches the "at least 1 photo" rule (if we enforce strict per-section emptiness)
       // User request: "block submission also if there's a section that did not insert atleast 1 photo"
       for (var section in _equipmentSections) {
          if (section.photos.isEmpty) {
             missingItems.add('Equipment Identification Section ${section.sectionNumber}: At least 1 photo is required');
          } else {
              for (int i = 0; i < section.photos.length; i++) {
                 List<String>? findings = section.photoFindings[i];
                 if (findings == null || findings.isEmpty) {
                    missingItems.add('Equipment Identification: Finding for photo ${section.sectionNumber}.${i+1} is required');
                 }
              }
          }
       }
    }

     // 4. Validate EXTERNAL VISUAL (New Logic)
     if (_requireExternal) {
       if (_externalSections.isEmpty) {
         missingItems.add('External Visual: At least one section is required.');
       } else {
          for (int i = 0; i < _externalSections.length; i++) {
             var section = _externalSections[i];
             
             if (section.photos.isEmpty) {
                missingItems.add('External Section ${section.sectionNumber}: Photo is required');
             }
             if (section.componentName == null) {
                missingItems.add('External Section ${section.sectionNumber}: Component is required');
             }
             if (section.defectType == null) {
                missingItems.add('External Section ${section.sectionNumber}: Defect/Observation is required');
             }
             if (section.condition == null) {
                 missingItems.add('External Section ${section.sectionNumber}: Condition is required');
             }
             if (section.recommendation == null) {
                 missingItems.add('External Section ${section.sectionNumber}: Recommendation is required');
             }
          }
       }
     }

    // 5. Validate WELD VISUAL (New Logic)
    if (_requireWeld) {
      if (_weldSections.isEmpty) {
        missingItems.add('Weld Visual: At least one section is required.');
      } else {
        for (int i = 0; i < _weldSections.length; i++) {
          var section = _weldSections[i];

          if (section.photos.isEmpty) {
            missingItems.add('Weld Section ${section.sectionNumber}: Photo is required');
          }
          if (section.componentName == null) {
            missingItems.add('Weld Section ${section.sectionNumber}: Component is required');
          }
          if (section.defectType == null) {
             missingItems.add('Weld Section ${section.sectionNumber}: Defect/Observation is required');
          }
          if (section.condition == null) {
             missingItems.add('Weld Section ${section.sectionNumber}: Condition is required');
          }
          if (section.recommendation == null) {
             missingItems.add('Weld Section ${section.sectionNumber}: Recommendation is required');
          }
        }
      }
    }

    // Internal Visual - only if required by manager AND accessible
    if (_requireInternal && _internalAccessible) {
      if (_internalSections.isEmpty) {
        missingItems.add('Internal Visual: At least one section is required');
      } else {
        for (var section in _internalSections) {
          if (section.photos.isEmpty) {
            missingItems.add('Internal Visual Section ${section.sectionNumber}: Photo is required');
          }
           if (section.componentName == null) {
            _showError('Please select a component for Internal Section ${section.sectionNumber}');
            return;
          }
          if (section.defectType == null) {
            missingItems.add('Internal Visual Section ${section.sectionNumber}: Finding/Defect is required');
          }
          if (section.condition == null) {
            missingItems.add('Internal Visual Section ${section.sectionNumber}: Condition is required');
          }
          if (section.recommendation == null) {
            missingItems.add('Internal Visual Section ${section.sectionNumber}: Recommendation is required');
          }
        }
      }
    }

    // Thickness Measurement - only if required by manager
    if (_requireThickness) {
      if (_thicknessData.isEmpty) {
        missingItems.add(
          'Thickness Measurement: At least 1 measurement required',
        );
      } else if (_thicknessData.every((t) => (t['location'] ?? '').isEmpty)) {
         missingItems.add(
          'Thickness Measurement: Location is required for all entries',
        );
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

    // Overall Summary validation (Auto-generated now, check if empty not really needed unless we want to force at least one section)
    // if (_overallRecommendation.trim().isEmpty) { ... } // Removed since it's auto-generated

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
      
      // Legacy flat logic removed to fix compilation errors.
      
      // REVISED LOGIC based on "1.1 finding is for 1.1 image" request:
      // We will map the *first* selected finding to *first* photo, etc.
      
      // Refined logic removed to fix compilation errors.

      String finalEquipmentFinding = "See individual section details";
      String finalEquipmentRecommendation = "See individual section details";

      // Prepare structured data for PDF generator (to support multi-photo rows per section)
      List<Map<String, dynamic>> equipmentSectionsData = [];

      // 1. Process EQUIPMENT Sections
      for (var section in _equipmentSections) {
         List<String> sectionFindings = [];
         List<String> sectionRecommendations = [];
         
         // Iterate photos to get per-photo findings/recs
         for (int i = 0; i < section.photos.length; i++) {
            String label = '${section.sectionNumber}.${i + 1}';
            
            // Findings
            List<String>? findings = section.photoFindings[i];
            String fText = (findings != null && findings.isNotEmpty) 
                ? findings.join(', ') // Join multiple checkboxes with comma
                : 'Nil';
            sectionFindings.add('$label $fText');

            // Recommendations
            String? rec = section.photoRecommendations[i];
            String rText = (rec != null && rec.isNotEmpty) ? rec : 'Nil';
            sectionRecommendations.add('$label $rText');
         }
         
         // If no photos but section exists? (Validation should prevent this, but handle safely)
         if (section.photos.isEmpty) {
             sectionFindings.add('${section.sectionNumber}.1 Nil');
             sectionRecommendations.add('${section.sectionNumber}.1 Nil');
         }

         equipmentSectionsData.add({
           'type': 'equipment',
           'section_number': section.sectionNumber,
           'photos': section.photos, // List<XFile>
           'findings': sectionFindings,
           'recommendations': sectionRecommendations,
         });
      }

      // 2. Process EXTERNAL VISUAL Sections (Appended to same list for PDF flow)
      for (var section in _externalSections) {
        List<String> sectionFindings = [];
        List<String> sectionRecommendations = [];
        int photoCount = section.photos.length;
        
        if (photoCount > 0) {
           String autoFinding = _generateExternalFindingText(section).replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
           // Recommendation logic could be similar if we had specific logic, but for now generic or custom
           // The dashboard doesn't seem to have a recommendation builder for external yet beyond the dropdown? 
           // Ah, ExternalSectionData has 'recommendation' field.
           String autoRec = (section.recommendation ?? 'Nil').replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
           
           String label;
           if (photoCount == 1) {
             label = '${section.sectionNumber}.1';
           } else if (photoCount == 2) {
             label = '${section.sectionNumber}.1 & ${section.sectionNumber}.2';
           } else {
             label = '${section.sectionNumber}.1 - ${section.sectionNumber}.$photoCount';
           }
           
           sectionFindings.add('$label $autoFinding');
           sectionRecommendations.add('$label $autoRec');
        }

        equipmentSectionsData.add({
          'type': 'external',
          'section_number': section.sectionNumber,
          'photos': section.photos,
          'findings': sectionFindings,
          'recommendations': sectionRecommendations,
        });
      }

      // 3. Process WELD Sections (Appended to same list for PDF flow)
      for (var section in _weldSections) {
        List<String> sectionFindings = [];
        List<String> sectionRecommendations = [];
        int photoCount = section.photos.length;

        if (photoCount > 0) {
           String autoFinding = _generateWeldFindingText(section).replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
           String autoRec = (section.recommendation ?? 'Nil').replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
           
           String label;
           if (photoCount == 1) {
             label = '${section.sectionNumber}.1';
           } else if (photoCount == 2) {
             label = '${section.sectionNumber}.1 & ${section.sectionNumber}.2';
           } else {
             label = '${section.sectionNumber}.1 - ${section.sectionNumber}.$photoCount';
           }
           
           sectionFindings.add('$label $autoFinding');
           sectionRecommendations.add('$label $autoRec');
        }

        equipmentSectionsData.add({
          'type': 'weld',
          'section_number': section.sectionNumber,
          'photos': section.photos,
          'findings': sectionFindings,
          'recommendations': sectionRecommendations,
        });
      }

      // 4. Process INTERNAL VISUAL Sections
      if (_internalAccessible) {
        for (var section in _internalSections) {
          List<String> sectionFindings = [];
          List<String> sectionRecommendations = [];
          int photoCount = section.photos.length;

          if (photoCount > 0) {
             String autoFinding = _generateInternalFindingText(section).replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
             String autoRec = (section.recommendation ?? 'Nil').replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
             
             String label;
             if (photoCount == 1) {
               label = '${section.sectionNumber}.1';
             } else if (photoCount == 2) {
               label = '${section.sectionNumber}.1 & ${section.sectionNumber}.2';
             } else {
               label = '${section.sectionNumber}.1 - ${section.sectionNumber}.$photoCount';
             }
             
             sectionFindings.add('$label $autoFinding');
             sectionRecommendations.add('$label $autoRec');
          }

          equipmentSectionsData.add({
            'type': 'internal',
            'section_number': section.sectionNumber,
            'photos': section.photos,
            'findings': sectionFindings,
            'recommendations': sectionRecommendations,
          });
        }
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
        'equipment_sections_data': equipmentSectionsData, // Contains Equipment, External, and Weld

        // Legacy/Graph Support Fields (Still populated for backend parsing/analytics)
        'external_finding': _externalSections.isNotEmpty ? _externalSections.first.defectType ?? 'Nil' : 'Nil',
        'external_condition': _externalSections.isNotEmpty ? _externalSections.first.condition ?? 'Satisfactory' : 'Satisfactory',
        'external_section_recommendation': _externalSections.isNotEmpty ? _externalSections.first.recommendation ?? 'Nil' : 'Nil',
        'external_recommendation': 'See sections above',

        // Weld Visual with NEW fields
        'weld_finding': _weldSections.isNotEmpty ? _weldSections.first.defectType ?? 'Nil' : 'Nil',
        'weld_condition': _weldSections.isNotEmpty ? _weldSections.first.condition ?? 'Satisfactory' : 'Satisfactory',
        'weld_section_recommendation': _weldSections.isNotEmpty ? _weldSections.first.recommendation ?? 'Nil' : 'Nil',
        'weld_recommendation': 'See sections above',

        // Internal Visual with NEW fields from first section (summary)
        'internal_accessible': _internalAccessible,
        'internal_finding': _internalAccessible && _internalSections.isNotEmpty 
             ? (_internalSections.first.defectType ?? 'Nil') 
             : 'Nil',
        'internal_condition': _internalAccessible && _internalSections.isNotEmpty
            ? (_internalSections.first.condition ?? 'Satisfactory')
            : 'Satisfactory',
        'internal_section_recommendation': _internalAccessible && _internalSections.isNotEmpty
            ? (_internalSections.first.recommendation ?? 'Nil')
            : 'Nil',
        'internal_recommendation': 'See sections above',

        // Thickness with NEW fields
        'thickness_data': _thicknessData,
        'thickness_finding': _thicknessCondition == 'Satisfactory'
            ? 'No significant wall loss detected compared to nominal thickness upon testing. Please refer attachment report'
            : (_thicknessCondition == 'Observation'
                ? 'Minor wall loss detected compared to nominal thickness upon testing. Please refer attachment report'
                : 'Nil'),
        'thickness_condition': _thicknessCondition ?? 'Satisfactory',
        'thickness_section_recommendation':
            _thicknessSectionRecommendation ?? 'Nil',

        // Overall Summary with NEW field
        'overall_condition': _generateAutomatedSummary(),
        'overall_recommendation': _generateAutomatedRecommendations(),
        'general_recommendation': _generalRecommendation.isEmpty
            ? 'Continue routine schedule'
            : _generalRecommendation,
        'photos': [
          ...allEquipmentPhotos,
          ..._externalSections.expand((s) => s.photos).toList(),
          ..._weldSections.expand((s) => s.photos).toList(),
          ..._internalSections.expand((s) => s.photos).toList(),
        ],
        'photo_sections': {
          'equipment': allEquipmentPhotos.length,
          'external': _externalSections.expand((s) => s.photos).length,
          'weld': _weldSections.expand((s) => s.photos).length,
          'internal': _internalSections.expand((s) => s.photos).length,
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
            blurRadius: 20,
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
                         // Iterate through each photo to show its finding/rec block
                         ...section.photos.asMap().entries.map((entry) {
                            int photoIdx = entry.key;
                            String photoLabel = '${section.sectionNumber}.${photoIdx + 1}';
                            
                            // Initialize list if null
                            section.photoFindings[photoIdx] ??= [];
                            List<String> currentFindings = section.photoFindings[photoIdx]!;
                            
                            // Check if any finding is NOT "good condition"
                            bool hasBadCondition = currentFindings.any((f) => !f.contains('good condition'));
                            
                            // Auto-set recommendation to Nil if all good
                            if (!hasBadCondition && currentFindings.isNotEmpty) {
                               section.photoRecommendations[photoIdx] = 'Nil';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Finding for $photoLabel',
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    children: _equipmentFindingOptions.map((option) {
                                    return RadioListTile<String>(
                                      title: Text(option, style: GoogleFonts.inter(fontSize: 13)),
                                      value: option,
                                      groupValue: currentFindings.isNotEmpty ? currentFindings.first : null,
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      activeColor: AppTheme.primaryRed,
                                      controlAffinity: ListTileControlAffinity.leading,
                                      onChanged: (String? value) {
                                        setState(() {
                                            currentFindings.clear();
                                            if (value != null) {
                                                currentFindings.add(value);
                                            }
                                          
                                          // Re-evaluate recommendation logic immediately
                                          bool isAllGood = currentFindings.every((f) => f.contains('good condition'));
                                          if (isAllGood && currentFindings.isNotEmpty) {
                                             section.photoRecommendations[photoIdx] = 'Nil';
                                          } else if (currentFindings.isEmpty) {
                                              section.photoRecommendations[photoIdx] = null as String? ?? ''; // Reset
                                          } else {
                                              // Ensure Nil is unchecked/cleared if it was auto-set? 
                                              // Or just show the options.
                                              if (section.photoRecommendations[photoIdx] == 'Nil') {
                                                 section.photoRecommendations[photoIdx] = ''; 
                                              }
                                          }
                                        });
                                      },
                                    );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // RECOMMENDATION
                                  if (hasBadCondition) ...[
                                      Text('Recommendation for $photoLabel',
                                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 8),
                                      Column(
                                        children: _equipmentRecommendationOptions.map((recOption) {
                                          bool isSelected = section.photoRecommendations[photoIdx] == recOption;
                                          return RadioListTile<String>(
                                            title: Text(recOption, style: GoogleFonts.inter(fontSize: 13)),
                                            value: recOption,
                                            groupValue: section.photoRecommendations[photoIdx],
                                            activeColor: AppTheme.primaryRed,
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            onChanged: (v) {
                                              setState(() {
                                                section.photoRecommendations[photoIdx] = v!;
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                  ] else ...[
                                     if (currentFindings.isNotEmpty)
                                       Text('Recommendation for $photoLabel: Nil (Auto-set)',
                                           style: GoogleFonts.inter(fontSize: 13, color: Colors.green, fontStyle: FontStyle.italic)
                                       ),
                                  ],
                                ],
                              ),
                            );
                         }).toList(),
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
        ..._weldSections.asMap().entries.map((entry) {
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
                      onPressed: () => _removeWeldSection(index),
                      tooltip: 'Remove Section',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPhotoUploadSection(
                  'weld',
                  section.photos,
                  'Weld Joint Photos (Max 3)',
                  sectionIndex: index,
                  sectionNumber: section.sectionNumber,
                  maxPhotos: 3,
                ),
                const SizedBox(height: 20),

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
                      children: [
                        _buildDropdownField(
                          label: 'Component *',
                          value: section.componentName,
                          items: _weldComponents,
                          onChanged: (v) => setState(() => section.componentName = v),
                          hint: 'Select component',
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'Finding (Defect Type) *',
                          value: section.defectType,
                          items: _defectOptions,
                          onChanged: (v) {
                            setState(() {
                              section.defectType = v;
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
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'Condition *',
                          value: section.condition,
                          items: _conditionOptions,
                          onChanged: (v) => setState(() => section.condition = v),
                          hint: 'Select condition',
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'Section Recommendation *',
                          value: section.recommendation,
                          items: _sectionRecommendationOptions,
                          onChanged: (v) => setState(() => section.recommendation = v),
                          hint: 'Select recommendation',
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
            onPressed: _addWeldSection,
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
          
          ..._internalSections.asMap().entries.map((entry) {
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
                        onPressed: () => _removeInternalSection(index),
                        tooltip: 'Remove Section',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // PHOTOS
                  _buildPhotoUploadSection(
                    'internal',
                    section.photos,
                    'Internal Photos (Max 3)',
                    sectionIndex: index,
                    sectionNumber: section.sectionNumber,
                    maxPhotos: 3,
                  ),
                  const SizedBox(height: 20),

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
                        children: [
                           // COMPONENT
                           _buildDropdownField(
                            label: 'Component *',
                            value: section.componentName,
                            items: _internalComponents,
                            onChanged: (v) => setState(() => section.componentName = v),
                            hint: 'Select component',
                          ),
                          const SizedBox(height: 16),
                          
                          // FINDING (DEFECT)
                          _buildDropdownField(
                            label: 'Finding (Defect Type) *',
                            value: section.defectType,
                            items: _defectOptions,
                            onChanged: (v) {
                               setState(() {
                                 section.defectType = v;
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
                          const SizedBox(height: 16),

                          // CONDITION
                          _buildDropdownField(
                            label: 'Condition *',
                            value: section.condition,
                            items: _conditionOptions,
                            onChanged: (v) => setState(() => section.condition = v),
                            hint: 'Select condition',
                          ),
                          const SizedBox(height: 16),

                          // RECOMMENDATION
                          _buildDropdownField(
                            label: 'Section Recommendation *',
                            value: section.recommendation,
                            items: _sectionRecommendationOptions,
                            onChanged: (v) => setState(() => section.recommendation = v),
                            hint: 'Select recommendation',
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
              onPressed: _addInternalSection,
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
        
        // Photo upload section removed as per request

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
                      child: DropdownButtonFormField<String>(
                        value: _thicknessLocations.contains(_thicknessData[entry.key]['location']) 
                              ? _thicknessData[entry.key]['location'] 
                              : null,
                        decoration: const InputDecoration(
                          labelText: 'Component *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: _thicknessLocations.map((loc) {
                          return DropdownMenuItem(value: loc, child: Text(loc));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                             setState(() {
                               _thicknessData[entry.key]['location'] = v;
                             });
                          }
                        },
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
                  initialValue: _thicknessData[entry.key]['remarks'],
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

        // Defect Type (Finding) removed as per request

        // Condition Dropdown for overall thickness assessment
        _buildDropdownField(
          label: 'Overall Thickness Condition *',
          value: _thicknessCondition,
          items: _conditionOptions,
          onChanged: (v) {
            setState(() {
              _thicknessCondition = v;
              if (v == 'Satisfactory') {
                _thicknessSectionRecommendation = 'Nil';
              } else if (v == 'Observation') {
                _thicknessSectionRecommendation = 'Monitor';
              }
            });
          },
          hint: 'Select condition',
        ),
        const SizedBox(height: 16),

        // Section Recommendation Dropdown
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
        Text(
          'Overall Summary',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Divider(height: 24),

        if (!_showSummary)
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showSummary = true;
                });
              },
              icon: const Icon(Icons.summarize_outlined),
              label: const Text('Generate Overall Summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          )
        else ...[
           Row(
             mainAxisAlignment: MainAxisAlignment.end,
             children: [
               TextButton.icon(
                 onPressed: () {
                   setState(() {
                      // Just trigger rebuild to refresh summary
                   });
                 },
                 icon: const Icon(Icons.refresh, size: 16),
                 label: const Text('Update Summary'),
               ),
             ],
           ),
           Text(
            'Overall Finding *',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _generateAutomatedSummary(),
              style: GoogleFonts.inter(fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
  
          Text(
            'Overall Recommendation *',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _generateAutomatedRecommendations(),
               style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: AppTheme.primaryRed),
            ),
          ),
        ],
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

  // Helper to generate specific finding text for the Overall Summary list
  // Format: "X.Y ComponentName in Satisfactory condition" OR "X.Y ComponentName need observation on the [defect] part."
  String _getSectionSummaryLine(String sectionNum, String? component, String? defect, String? condition) {
      if (component == null) return '$sectionNum Component not specified';
      
      bool isSatisfactory = (defect == 'Nil' || defect == null) && (condition == 'Satisfactory' || condition == null);

      if (isSatisfactory) {
         return '$sectionNum $component in Satisfactory condition';
      } else {
         return '$sectionNum $component need observation on the $defect part.';
      }
  }

  String _generateAutomatedSummary() {
     List<String> summaryLines = [];
     
     // EQUIPMENT (Usually Section 1)
     for(var section in _equipmentSections) {
        if (section.photos.isNotEmpty) {
           for (int i = 0; i < section.photos.length; i++) {
              List<String>? findings = section.photoFindings[i];
              if (findings != null && findings.isNotEmpty) {
                 for (String f in findings) {
                    summaryLines.add('${section.sectionNumber}.${i+1} $f');
                 }
              } else {
                 summaryLines.add('${section.sectionNumber}.${i+1} Finding details not selected');
              }
           }
        } else {
            // No photos
            summaryLines.add('${section.sectionNumber}.1 Equipment details not selected (No photos)');
        }
     }

     // EXTERNAL
     if (_requireExternal) {
       for(var section in _externalSections) {
         String label = '${section.sectionNumber}'; // Typically X.1 etc is handled by photos? No, user wants X.1
         // Actually user example: "3.1 Anchor Bolts...". This implies each section is one item.
         // Let's use loop index if there are multiple photos? 
         // Assuming 1 item per section as per current UI structure (each section has 1 component dropdown).
         // So Section X is the item.
         String labelPrefix = '${section.sectionNumber}.1'; 
         // Allow for X.1-X.3 range if multiple photos?
         if (section.photos.length > 1) {
             labelPrefix = '${section.sectionNumber}.1-${section.sectionNumber}.${section.photos.length}';
         } else {
             labelPrefix = '${section.sectionNumber}.1';
         }
         
         summaryLines.add(_getSectionSummaryLine(labelPrefix, section.componentName, section.defectType, section.condition));
       }
     }

     // WELD
     if (_requireWeld) {
       for(var section in _weldSections) {
          String labelPrefix = '${section.sectionNumber}.1';
         if (section.photos.length > 1) {
             labelPrefix = '${section.sectionNumber}.1-${section.sectionNumber}.${section.photos.length}';
         } else {
             labelPrefix = '${section.sectionNumber}.1';
         }
         summaryLines.add(_getSectionSummaryLine(labelPrefix, section.componentName, section.defectType, section.condition));
       }
     }

     // INTERNAL
     if (_requireInternal && _internalAccessible) {
       for (var section in _internalSections) {
          String labelPrefix = '${section.sectionNumber}.1';
         if (section.photos.length > 1) {
             labelPrefix = '${section.sectionNumber}.1-${section.sectionNumber}.${section.photos.length}';
         } else {
             labelPrefix = '${section.sectionNumber}.1';
         }
         summaryLines.add(_getSectionSummaryLine(labelPrefix, section.componentName, section.defectType, section.condition));
       }
     }
     
     if (summaryLines.isEmpty) return "No findings recorded.";
     return summaryLines.join('\n');
  }

  String _generateAutomatedRecommendations() {
    List<String> recLines = [];

    // Equipment
    for(var section in _equipmentSections) {
       if (section.photoRecommendations.isNotEmpty) {
          section.photoRecommendations.forEach((photoIdx, rec) {
              if (rec != 'Nil' && rec != 'None' && rec.isNotEmpty) {
                  recLines.add('${section.sectionNumber}.${photoIdx+1} $rec');
              }
          });
       }
    }

    // Helper to process recommendation
    void processRec(String sectionNum, int photoCount, String? rec) {
       if (rec != null && rec != 'Nil' && rec.isNotEmpty) {
           String labelPrefix = '$sectionNum.1';
           if (photoCount > 1) {
               labelPrefix = '$sectionNum.1-$sectionNum.$photoCount';
           }
           recLines.add('$labelPrefix $rec');
       }
    }
    
    // External
    if (_requireExternal) {
        for(var get in _externalSections) {
            processRec(get.sectionNumber.toString(), get.photos.length, get.recommendation);
        }
    }
    // Weld
    if (_requireWeld) {
        for(var get in _weldSections) {
            processRec(get.sectionNumber.toString(), get.photos.length, get.recommendation);
        }
    }
    // Internal
    if (_requireInternal && _internalAccessible) {
        for (var get in _internalSections) {
            processRec(get.sectionNumber.toString(), get.photos.length, get.recommendation);
        }
    }
    // Thickness
     if (_requireThickness) {
         if (_thicknessSectionRecommendation != null && _thicknessSectionRecommendation != 'Nil') {
             recLines.add('UTTM Monitor (Thickness)');
         }
     }

    if (recLines.isEmpty) return "Nil";
    return recLines.join('\n');
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
  List<XFile> photos = [];
  // Key = photo index (0, 1, 2). Value = List of findings for that photo.
  Map<int, List<String>> photoFindings = {}; 
  // Key = photo index. Value = Recommendation string for that photo.
  Map<int, String> photoRecommendations = {};

  InspectionSectionData({required this.sectionNumber});
}

class ExternalSectionData {
  int sectionNumber;
  List<XFile> photos = []; // Max 3
  
  String? componentName;
  String? defectType;
  String? condition;
  String? recommendation;

  ExternalSectionData({required this.sectionNumber});
}

class WeldSectionData {
  int sectionNumber;
  List<XFile> photos = []; // Max 3
  
  String? componentName;
  String? defectType;
  String? condition;
  String? recommendation;

  WeldSectionData({required this.sectionNumber});
}

class InternalSectionData {
  int sectionNumber;
  List<XFile> photos = []; // Max 3
  
  String? componentName;
  String? defectType;
  String? condition;
  String? recommendation;

  InternalSectionData({required this.sectionNumber});
}
