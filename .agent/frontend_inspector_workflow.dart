"""
INSPECTOR UI - Updated Inspection Workflow Page
File: lib/inspection_workflow_page.dart

KEY CHANGES for role-based inspector input
"""

// CONDITION & RECOMMENDATION DROPDOWN DATA (Add at top)
class InspectionFieldData {
  static const List<String> conditions = [
    'Satisfactory',
    'Observation',
  ];
  
  static const List<String> recommendations = [
    'Nil',
    'Monitor',
  ];
}

// STATE VARIABLES FOR EACH SECTION (Add to _InspectionWorkflowPageState)
// External Visual Inspection
String _externalFinding = '';
String? _externalCondition;
String? _externalRecommendation;
List<String> _externalPhotos = [];

// Weld Visual Inspection  
String _weldFinding = '';
String? _weldCondition;
String? _weldRecommendation;
List<String> _weldPhotos = [];

// Internal Inspection
String _internalFinding = '';
String? _internalCondition;
String? _internalRecommendation;
List<String> _internalPhotos = [];

// Thickness Inspection
String _thicknessFinding = '';
String? _thicknessCondition;
String? _thicknessRecommendation;
List<String> _thicknessPhotos = [];

// Page 1 Summary (filled after all sections complete)
String _overallFinding = '';
String _overallRecommendation = '';
String _additionalComments = '';

// Section completion tracking
Set<String> _completedSections = {};

// Check if section is complete
bool _isSectionComplete(String sectionType) {
  switch (sectionType) {
    case 'external':
      return _externalFinding.isNotEmpty &&
             _externalCondition != null &&
             _externalRecommendation != null &&
             _externalPhotos.isNotEmpty;
    case 'weld':
      return _weldFinding.isNotEmpty &&
             _weldCondition != null &&
             _weldRecommendation != null &&
             _weldPhotos.isNotEmpty;
    case 'internal':
      return _internalFinding.isNotEmpty &&
             _internalCondition != null &&
             _internalRecommendation != null &&
             _internalPhotos.isNotEmpty;
    case 'thickness':
      return _thicknessFinding.isNotEmpty &&
             _thicknessCondition != null &&
             _thicknessRecommendation != null &&
             _thicknessPhotos.isNotEmpty;
    default:
      return false;
  }
}

// Check if all required sections are complete
bool _areAllRequiredSectionsComplete() {
  bool allComplete = true;
  
  if (widget.requireExternal && !_isSectionComplete('external')) allComplete = false;
  if (widget.requireWeld && !_isSectionComplete('weld')) allComplete = false;
  if (widget.requireInternal && !_isSectionComplete('internal')) allComplete = false;
  if (widget.requireThickness && !_isSectionComplete('thickness')) allComplete = false;
  
  return allComplete;
}

// SECTION INPUT WIDGET (reusable for all sections)
Widget _buildSectionInput({
  required String sectionTitle,
  required String sectionType,
  required String finding,
  required Function(String) onFindingChanged,
  required String? condition,
  required Function(String?) onConditionChanged,
  required String? recommendation,
  required Function(String?) onRecommendationChanged,
  required List<String> photos,
  required Function(List<String>) onPhotosChanged,
}) {
  final isComplete = _isSectionComplete(sectionType);
  
  return Container(
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isComplete 
            ? Colors.green.shade300 
            : Colors.grey.shade300,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isComplete 
                    ? Colors.green.withOpacity(0.1)
                    : AppTheme.inspectorPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isComplete ? Icons.check_circle : Icons.edit_note,
                color: isComplete ? Colors.green : AppTheme.inspectorPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                sectionTitle,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (isComplete)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Complete',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const Divider(height: 32),
        
        // Finding Input
        _buildLabel('Finding', required: true),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          onChanged: onFindingChanged,
          decoration: InputDecoration(
            hintText: 'Describe your findings for this section...',
            hintStyle: GoogleFonts.inter(color: Colors.grey),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.inter(fontSize: 14),
        ),
        const SizedBox(height: 20),
        
        // Condition Dropdown
        _buildLabel('Condition', required: true),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: condition,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              hintText: 'Select condition',
              hintStyle: GoogleFonts.inter(color: Colors.grey),
            ),
            items: InspectionFieldData.conditions.map((cond) {
              return DropdownMenuItem(
                value: cond,
                child: Row(
                  children: [
                    Icon(
                      cond == 'Satisfactory' 
                          ? Icons.check_circle 
                          : Icons.warning,
                      color: cond == 'Satisfactory' 
                          ? Colors.green 
                          : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cond,
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onConditionChanged,
          ),
        ),
        const SizedBox(height: 20),
        
        // Photo Evidence
        _buildLabel('Photo Evidence', required: true, subtitle: 'Minimum 1 photo required'),
        const SizedBox(height: 8),
        _buildPhotoUpload(
          photos: photos,
          onPhotosChanged: onPhotosChanged,
        ),
        const SizedBox(height: 20),
        
        // Section Recommendation Dropdown
        _buildLabel('Section Recommendation', required: true),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: recommendation,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              hintText: 'Select recommendation',
              hintStyle: GoogleFonts.inter(color: Colors.grey),
            ),
            items: InspectionFieldData.recommendations.map((rec) {
              return DropdownMenuItem(
                value: rec,
                child: Text(
                  rec,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: onRecommendationChanged,
          ),
        ),
      ],
    ),
  );
}

// PAGE 1 SUMMARY (Only accessible after all sections complete)
Widget _buildPage1Summary() {
  if (!_areAllRequiredSectionsComplete()) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            'Complete All Sections First',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You must complete all required inspection sections before filling the overall summary.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Summary',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const Divider(height: 32),
        
        // Overall Finding
        _buildLabel('Overall Finding', required: true, subtitle: 'Summary of all sections'),
        const SizedBox(height: 8),
        TextField(
          maxLines: 4,
          onChanged: (value) => setState(() => _overallFinding = value),
          decoration: InputDecoration(
            hintText: 'Provide an overall summary of your inspection findings...',
            hintStyle: GoogleFonts.inter(color: Colors.grey),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.inter(fontSize: 14),
        ),
        const SizedBox(height: 20),
        
        // Overall Recommendation
        _buildLabel('Overall Recommendation', required: true),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          onChanged: (value) => setState(() => _overallRecommendation = value),
          decoration: InputDecoration(
            hintText: 'Provide your overall recommendation...',
            hintStyle: GoogleFonts.inter(color: Colors.grey),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.inter(fontSize: 14),
        ),
        const SizedBox(height: 20),
        
        // Additional Comments
        _buildLabel('Additional Comments', required: false),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          onChanged: (value) => setState(() => _additionalComments = value),
          decoration: InputDecoration(
            hintText: 'Any additional comments or notes...',
            hintStyle: GoogleFonts.inter(color: Colors.grey),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ],
    ),
  );
}

// Helper: Build label with optional required indicator
Widget _buildLabel(String text, {bool required = false, String? subtitle}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            Text(
              '*',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryRed,
              ),
            ),
          ],
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ],
  );
}
