import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/manager_service.dart';
import 'theme/app_theme.dart';
import 'widgets/collapsible_sidebar.dart';
import 'manager_dashboard_page.dart';
import 'utils/animations_config.dart';

class AssignTaskPage extends StatefulWidget {
  const AssignTaskPage({super.key});

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _equipmentIdController = TextEditingController();


  final _notesController = TextEditingController();
  final _reportNumberController = TextEditingController(text: 'Auto-generated (RPT-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}...)');
  final _reportDateController = TextEditingController(text: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');

  List<dynamic> _inspectors = [];
  final List<String> _staticLocations = [
    'Process Area',
    'Utility Area',
    'Main Deck',
    'Wellhead Area',
    'Offsite Facilities',
  ];
  final Map<String, List<String>> _equipmentByLocation = {
    'Process Area': ['Pressure Vessel', 'Reactor', 'Separator', 'Heat Exchanger', 'Column'],
    'Utility Area': ['Air Receiver', 'Nitrogen Vessel', 'Utility Pressure Vessel', 'Boiler'],
    'Main Deck': ['Pressure Vessel', 'Skid-mounted'],
    'Wellhead Area': ['Pressure Vessel', 'Separator', 'Manifold Vessel'],
    'Offsite Facilities': ['Air Receiver', 'Utility Pressure Vessel', 'Small Storage Vessel'],
  };

  int? _selectedInspectorId;
  String? _selectedLocationId;
  String? _selectedEquipmentType;
  DateTime? _scheduledDate;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  String _searchQuery = '';

  // Scope of Work Flags (Default matches DB behavior)
  bool _requireExternal = true;
  bool _requireWeld = false;
  bool _requireInternal = false;
  bool _requireThickness = false;
  
  final List<String> _initialConditions = [];
  final List<String> _availableConditions = [
    'Damaged',
    'Leaking',
    'Corrosion',
    'Cracked',
    'No Defect / Normal'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _equipmentIdController.dispose();

    _notesController.dispose();
    _reportNumberController.dispose();
    _reportDateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final inspectors = await ManagerService.getInspectors();
      setState(() {
        _inspectors = inspectors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _assignTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInspectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an inspector'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Enforce valid Location and Equipment Type combination
    if (_selectedLocationId != null && _selectedEquipmentType != null) {
      final validTypes = _equipmentByLocation[_selectedLocationId];
      if (validTypes == null || !validTypes.contains(_selectedEquipmentType)) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid Equipment Type "$_selectedEquipmentType" for Location "$_selectedLocationId".'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Format scheduled date to ISO string
      String? scheduledDateStr;
      if (_scheduledDate != null) {
        scheduledDateStr = _scheduledDate!.toIso8601String().split('T')[0];
      }

      // Call API to assign task
      await ManagerService.assignTask(
        inspectorId: _selectedInspectorId!,
        inspectionTitle: _titleController.text.trim(),
        inspectionType: _selectedEquipmentType ?? '',
        equipmentTag: _equipmentIdController.text.trim(),
        location: _selectedLocationId ?? '',
        dueDate:
            scheduledDateStr ??
            DateTime.now()
                .add(const Duration(days: 7))
                .toIso8601String()
                .split('T')[0],
        requireExternal: _requireExternal,
        requireWeld: _requireWeld,
        requireInternal: _requireInternal,
        requireThickness: _requireThickness,
        initialConditions: _initialConditions,
      );

      if (!mounted) return;

      final inspectorName = _inspectors.firstWhere(
        (i) => i['id'] == _selectedInspectorId,
      )['username'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task successfully assigned to $inspectorName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pushReplacement(
        context,
        FadePageRoute(page: const ManagerDashboardPage()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInspectors = _inspectors.where((inspector) {
      if (inspector['role'] == 'Manager') return false;
      final name = (inspector['username'] ?? '').toString().toLowerCase();
      final email = (inspector['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        children: [
          CollapsibleSidebar(currentPage: 'assign'),
          Expanded(
            child: Column(
              children: [
                // Modern Glassy Top Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.managerPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.assignment_add,
                          color: AppTheme.managerPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign New Task',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Select an inspector and define the scope of work',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Content Workspace
                Expanded(
                  child: _isLoading
                      ? Center(child: AppTheme.standardLoadingState())
                      : _error != null
                          ? Center(
                              child: AppTheme.standardErrorState(
                                error: _error!,
                                onRetry: _loadData,
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LEFT PANEL: Inspector Selection
                                Expanded(
                                  flex: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(32, 32, 16, 0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Available Inspectors',
                                              style: GoogleFonts.outfit(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF374151),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                              ),
                                              child: Text(
                                                '${filteredInspectors.length} Matching',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF6B7280),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Search Bar
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.03),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: TextField(
                                            onChanged: (value) => setState(() => _searchQuery = value),
                                            decoration: InputDecoration(
                                              hintText: 'Search by name or email...',
                                              hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
                                              prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Inspector List
                                        Expanded(
                                          child: filteredInspectors.isEmpty 
                                              ? Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                                                      const SizedBox(height: 16),
                                                      Text(
                                                        'No inspectors found',
                                                        style: GoogleFonts.inter(color: Colors.grey[500]),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : ListView.separated(
                                                  padding: const EdgeInsets.only(bottom: 32),
                                                  itemCount: filteredInspectors.length,
                                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                                  itemBuilder: (context, index) {
                                                    final inspector = filteredInspectors[index];
                                                    final isSelected = _selectedInspectorId == inspector['id'];
                                                    
                                                    return LayoutBuilder(
                                                      builder: (context, constraints) {
                                                        return MouseRegion(
                                                          cursor: SystemMouseCursors.click,
                                                          child: AnimatedContainer(
                                                            duration: const Duration(milliseconds: 200),
                                                            curve: Curves.easeOut,
                                                            decoration: BoxDecoration(
                                                              color: Colors.white,
                                                              borderRadius: BorderRadius.circular(16),
                                                              border: Border.all(
                                                                color: isSelected ? AppTheme.managerPrimary : Colors.transparent,
                                                                width: 2,
                                                              ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: isSelected 
                                                                      ? AppTheme.managerPrimary.withOpacity(0.15)
                                                                      : Colors.black.withOpacity(0.04),
                                                                  blurRadius: isSelected ? 12 : 8,
                                                                  offset: const Offset(0, 4),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Material(
                                                              color: Colors.transparent,
                                                              child: InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    _selectedInspectorId = inspector['id'];
                                                                  });
                                                                },
                                                                borderRadius: BorderRadius.circular(16),
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(16),
                                                                  child: Row(
                                                                    children: [
                                                                      Container(
                                                                        width: 48,
                                                                        height: 48,
                                                                        decoration: BoxDecoration(
                                                                          gradient: LinearGradient(
                                                                            colors: isSelected
                                                                                ? [AppTheme.managerPrimary, const Color(0xFF6366F1)]
                                                                                : [const Color(0xFF9CA3AF), const Color(0xFF4B5563)],
                                                                            begin: Alignment.topLeft,
                                                                            end: Alignment.bottomRight,
                                                                          ),
                                                                          shape: BoxShape.circle,
                                                                        ),
                                                                        child: Center(
                                                                          child: Text(
                                                                            (inspector['username'] ?? 'U').substring(0, 1).toUpperCase(),
                                                                            style: GoogleFonts.outfit(
                                                                              color: Colors.white,
                                                                              fontSize: 20,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(width: 16),
                                                                      Expanded(
                                                                        child: Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              inspector['username'] ?? 'Unknown',
                                                                              style: GoogleFonts.outfit(
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.w600,
                                                                                color: const Color(0xFF1F2937),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 2),
                                                                            Row(
                                                                              children: [
                                                                                Icon(Icons.email_outlined, size: 12, color: Colors.grey[500]),
                                                                                const SizedBox(width: 4),
                                                                                Expanded(
                                                                                  child: Text(
                                                                                    inspector['email'] ?? 'No email',
                                                                                    style: GoogleFonts.inter(
                                                                                      fontSize: 12,
                                                                                      color: const Color(0xFF6B7280),
                                                                                    ),
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      AnimatedContainer(
                                                                        duration: const Duration(milliseconds: 200),
                                                                        width: 24,
                                                                        height: 24,
                                                                        decoration: BoxDecoration(
                                                                          color: isSelected ? AppTheme.managerPrimary : Colors.white,
                                                                          border: Border.all(
                                                                            color: isSelected ? AppTheme.managerPrimary : const Color(0xFFD1D5DB),
                                                                            width: 2,
                                                                          ),
                                                                          shape: BoxShape.circle,
                                                                        ),
                                                                        child: isSelected 
                                                                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                                                                            : null,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // RIGHT PANEL: Task Form
                                Expanded(
                                  flex: 6,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(16, 32, 32, 32),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                           Text(
                                            'Task Details & Scope',
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(32),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.06),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [

                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEFF6FF),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Icon(Icons.assignment_outlined, color: Colors.blue, size: 16),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'What needs to be inspected?',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 16, // Pro-style increased font
                                                        fontWeight: FontWeight.w600,
                                                        color: AppTheme.textPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                const SizedBox(height: 8),
                                                TextFormField(
                                                  controller: _titleController,
                                                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w500),
                                                  decoration: InputDecoration(
                                                    hintText: 'e.g., Annual Pressure Vessel Inspection',
                                                    hintStyle: GoogleFonts.outfit(color: Colors.grey[300], fontSize: 20),
                                                    filled: true,
                                                    fillColor: Colors.grey[50], // Very subtle background
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                                  ),
                                                  validator: (value) => 
                                                      (value?.trim().isEmpty ?? true) ? 'Required' : null,
                                                ),
                                                const SizedBox(height: 32),
                                                
                                                // Group 1: Logistics (Where & When)
                                                Container(
                                                  padding: const EdgeInsets.all(24),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF9FAFB),
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Logistics'.toUpperCase(), style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.grey[500],
                                                        letterSpacing: 1,
                                                      )),
                                                      const SizedBox(height: 20),
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text('Where is it?', style: _labelStyle()),
                                                                const SizedBox(height: 12),
                                                                DropdownButtonFormField<String>(
                                                                  value: _selectedLocationId,
                                                                  hint: Text('Select Plant / Area', style: GoogleFonts.inter(color: Colors.grey[400])),
                                                                  items: _staticLocations.map<DropdownMenuItem<String>>((loc) {
                                                                    return DropdownMenuItem<String>(
                                                                      value: loc,
                                                                      child: Text(loc),
                                                                    );
                                                                  }).toList(),
                                                                  onChanged: (value) {
                                                                    setState(() {
                                                                      _selectedLocationId = value;
                                                                      _selectedEquipmentType = null;
                                                                    });
                                                                  },
                                                                  decoration: _inputDecoration('').copyWith(
                                                                    prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                                                                    fillColor: Colors.white,
                                                                  ),
                                                                  validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(width: 24),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text('When?', style: _labelStyle()),
                                                                const SizedBox(height: 12),
                                                                InkWell(
                                                                  onTap: _selectDate,
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  child: Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors.white,
                                                                      borderRadius: BorderRadius.circular(12),
                                                                      border: Border.all(color: Colors.grey[200]!),
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(
                                                                          Icons.calendar_month_outlined,
                                                                          color: _scheduledDate != null ? AppTheme.managerPrimary : Colors.grey[400],
                                                                          size: 20
                                                                        ),
                                                                        const SizedBox(width: 12),
                                                                        Text(
                                                                          _scheduledDate != null
                                                                              ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                                                                              : 'Select Date',
                                                                          style: GoogleFonts.inter(
                                                                            color: _scheduledDate != null ? Colors.black87 : Colors.grey[400],
                                                                            fontSize: 15,
                                                                            fontWeight: _scheduledDate != null ? FontWeight.w500 : FontWeight.normal,
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
                                                ),
                                                const SizedBox(height: 32),
                                                const SizedBox(height: 24),
                                                
                                                // Group 2: Asset Details
                                                Container(
                                                  padding: const EdgeInsets.all(24),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF9FAFB),
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                       Text('Asset Specification'.toUpperCase(), style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.grey[500],
                                                        letterSpacing: 1,
                                                      )),
                                                      const SizedBox(height: 20),
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text('Equipment Type', style: _labelStyle()),
                                                                  const SizedBox(height: 12),
                                                                  DropdownButtonFormField<String>(
                                                                    value: _selectedEquipmentType,
                                                                    hint: Text('Select Type', style: GoogleFonts.inter(color: Colors.grey[400])),
                                                                    items: (_selectedLocationId != null && _equipmentByLocation.containsKey(_selectedLocationId))
                                                                        ? _equipmentByLocation[_selectedLocationId!]!.map((type) {
                                                                            return DropdownMenuItem(
                                                                              value: type,
                                                                              child: Text(type),
                                                                            );
                                                                          }).toList()
                                                                        : [],
                                                                    onChanged: _selectedLocationId == null ? null : (value) => setState(() => _selectedEquipmentType = value),
                                                                    decoration: _inputDecoration('').copyWith(
                                                                      filled: true,
                                                                      fillColor: Colors.white,
                                                                    ),
                                                                    validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(width: 24),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text('Equipment Tag Number', style: _labelStyle()),
                                                                  const SizedBox(height: 12),
                                                                  TextFormField(
                                                                    controller: _equipmentIdController,
                                                                    decoration: _inputDecoration('e.g., R-001').copyWith(
                                                                      filled: true,
                                                                      fillColor: Colors.white,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 32),
                                                
                                                // Inspection Summary Section

                                                const SizedBox(height: 32),
                                                
                                                // Scope of Work Section
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF3E8FF),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Icon(Icons.playlist_add_check_rounded, color: Colors.purple, size: 16),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text('Inspection Scope (Manager Selection)', style: _labelStyle()),
                                                    const Spacer(),
                                                    TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          final bool allSelected = _requireExternal && _requireWeld && _requireInternal && _requireThickness;
                                                          final bool newState = !allSelected;
                                                          _requireExternal = newState;
                                                          _requireWeld = newState;
                                                          _requireInternal = newState;
                                                          _requireThickness = newState;
                                                        });
                                                      },
                                                      child: Text(
                                                        (_requireExternal && _requireWeld && _requireInternal && _requireThickness) ? 'Clear All' : 'Select All',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppTheme.managerPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: _buildScopeCard(
                                                            title: 'External Visual',
                                                            subtitle: 'Outer surface & insulation check',
                                                            icon: Icons.visibility_outlined,
                                                            isSelected: _requireExternal,
                                                            onTap: () => setState(() => _requireExternal = !_requireExternal),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: _buildScopeCard(
                                                            title: 'Weld Visual',
                                                            subtitle: 'Joints & seams inspection',
                                                            icon: Icons.construction_outlined,
                                                            isSelected: _requireWeld,
                                                            onTap: () => setState(() => _requireWeld = !_requireWeld),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: _buildScopeCard(
                                                            title: 'Internal Visual',
                                                            subtitle: 'Confined space entry required',
                                                            icon: Icons.sensor_door_outlined,
                                                            isSelected: _requireInternal,
                                                            onTap: () => setState(() => _requireInternal = !_requireInternal),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: _buildScopeCard(
                                                            title: 'Thickness',
                                                            subtitle: 'UT measurements points',
                                                            icon: Icons.straighten_outlined,
                                                            isSelected: _requireThickness,
                                                            onTap: () => setState(() => _requireThickness = !_requireThickness),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 32),
                                                Row(
                                                  children: [
                                                    Icon(Icons.description_outlined, size: 16, color: Colors.grey[500]),
                                                    const SizedBox(width: 8),
                                                    Text('Instructions & Notes', style: _labelStyle()),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                TextFormField(
                                                  controller: _notesController,
                                                  maxLines: 4,
                                                  decoration: _inputDecoration('Any specific instructions for the inspector...'),
                                                ),
                                                const SizedBox(height: 40),
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 56,
                                                  child: ElevatedButton(
                                                    onPressed: _isSubmitting ? null : _assignTask,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppTheme.managerPrimary,
                                                      foregroundColor: Colors.white,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                    child: _isSubmitting 
                                                        ? const Center(
                                                            child: SizedBox(
                                                              width: 24, height: 24,
                                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                                                            )
                                                          )
                                                        : Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              const Icon(Icons.send_rounded),
                                                              const SizedBox(width: 12),
                                                              Text(
                                                                'Assign Task Now',
                                                                style: GoogleFonts.outfit(
                                                                  fontSize: 18,
                                                                  fontWeight: FontWeight.w600,
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle() {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF6B7280),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildScopeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.managerPrimary.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.managerPrimary : Colors.grey.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected 
                ? [BoxShadow(color: AppTheme.managerPrimary.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.managerPrimary.withOpacity(0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppTheme.managerPrimary : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
               Icon(Icons.check_circle_rounded, color: AppTheme.managerPrimary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
