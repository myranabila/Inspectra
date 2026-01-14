# Inspection Scope Fix - Implementation Guide

## 🎯 **Issue Summary**
The inspector workflow page initializes scope variables BUT does not conditionally show/hide sections based on manager's assignment.

## ✅ **What's Already Done**
File: `lib/inspection_workflow_page.dart` (lines 175-178)
```dart
_requireExternal = widget.inspection['require_external'] ?? true;
_requireWeld = widget.inspection['require_weld'] ?? true;  // ❌ Should be false
_requireInternal = widget.inspection['require_internal'] ?? false;
_requireThickness = widget.inspection['require_thickness'] ?? false;
```

## 🔧 **Fix #1: Correct Default Values**

**Current (Line 176):**
```dart
_requireWeld = widget.inspection['require_weld'] ?? true;
```

**Should be:**
```dart
_requireWeld = widget.inspection['require_weld'] ?? false;
```

**Reason**: Default should match backend default (weld is optional by default)

---

## 🔧 **Fix #2: Conditional Section Display**

The sections need to be wrapped in conditional statements. The workflow page likely has a main builder method that lists all sections.

**Pattern to apply:**
```dart
// External Visual Section (always show if required)
if (_requireExternal) ...[
  _buildExternalVisualSection(),
  SizedBox(height: 24),
],

// Weld Visual Section (conditional)
if (_requireWeld) ...[
  _buildWeldVisualSection(),
  SizedBox(height: 24),
],

// Internal Visual Section (conditional)
if (_requireInternal) ...[
  _buildInternalVisualSection(),
  SizedBox(height: 24),
],

// Thickness Measurement Section (conditional)
if (_requireThickness) ...[
  _buildThicknessMeasurementSection(),
  SizedBox(height: 24),
],
```

---

## 🔧 **Fix #3: Scope Indicator Badge**

Add visual indicator at top of workflow page showing assigned scope:

```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.blue.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.blue.shade200),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Inspection Scope (Assigned by Manager)',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade900,
        ),
      ),
      SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_requireExternal) _ScopeBadge(label: 'External Visual', icon: Icons.visibility),
          if (_requireWeld) _ScopeBadge(label: 'Weld Visual', icon: Icons.link),
          if (_requireInternal) _ScopeBadge(label: 'Internal Visual', icon: Icons.layers),
          if (_requireThickness) _ScopeBadge(label: 'Thickness Testing', icon: Icons.straighten),
        ],
      ),
    ],
  ),
)
```

Badge widget:
```dart
class _ScopeBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  
  const _ScopeBadge({required this.label, required this.icon});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryRed),
          SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryRed,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔧 **Fix #4: Validation on Submit**

Ensure only required sections are validated:

```dart
Future<void> _validateAndSubmit() async {
  List<String> errors = [];
  
  // Always validate equipment section
  if (_equipmentFindings.isEmpty) {
    errors.add('Equipment identification is required');
  }
  
  // Validate required sections only
  if (_requireExternal && _externalSections.isEmpty) {
    errors.add('External visual inspection is required');
  }
  
  if (_requireWeld && _weldSections.isEmpty) {
    errors.add('Weld visual inspection is required');
  }
  
  if (_requireInternal && _internalSections.isEmpty) {
    errors.add('Internal visual inspection is required');
  }
  
  if (_requireThickness && _thicknessData.isEmpty) {
    errors.add('Thickness measurements are required');
  }
  
  if (errors.isNotEmpty) {
    // Show errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errors.join('\n'))),
    );
    return;
  }
  
  // Proceed with submission
  await _submitReport();
}
```

---

## 📋 **Implementation Checklist**

- [ ] Fix default value for `_requireWeld` (line 176)
- [ ] Add conditional display for each section
- [ ] Add scope indicator badge at top
- [ ] Update validation to check only required sections
- [ ] Test with different scope combinations
- [ ] Verify rejection workflow maintains scope

---

**Next Step**: Search for the main build/body method in `inspection_workflow_page.dart` to locate where sections are listed and apply conditional wrapping.
