# DOSH Registration Manual Entry - Implementation Complete

## ✅ Backend Implementation (DONE)

### 1. Database Column Added
- ✅ Added `dosh_registration` column to `inspections` table
- ✅ Migration script executed successfully

### 2. Backend Model & API Updated
- ✅ Updated `models.py` - added `dosh_registration` field to Inspection model
- ✅ Updated `manager.py` - added `dosh_registration` to AssignTaskRequest
- ✅ Updated `manager.py` - stores DOSH registration when creating inspection

### 3. Frontend Service Updated
- ✅ Updated `manager_service.dart` - added `doshRegistration` parameter to assignTask method
- ✅ Updated `assign_task_page.dart` - added controller and pass to API

### 4. PDF Generator Updated
- ✅ Updated `pdf_generator.dart` - reads DOSH registration from inspection data
- ✅ Removed hardcoded equipment-type logic

## ⚠️ TODO: Add UI Form Field

### Location: `lib/assign_task_page.dart`

Find the Equipment Tag field (around line 600-700) and add this DOSH Registration field right after it:

```dart
// DOSH Registration Number field
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: AppTheme.softShadow,
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.badge_outlined, size: 20, color: AppTheme.primaryRed),
          const SizedBox(width: 8),
          Text(
            'DOSH Registration Number',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _doshRegistrationController,
        decoration: InputDecoration(
          labelText: 'DOSH Registration No.',
          hintText: _getDoshHint(),  // Dynamic hint based on equipment type
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.textMuted.withOpacity(0.6),
          ),
          prefixIcon: const Icon(Icons.numbers),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        style: GoogleFonts.robotoMono(fontSize: 14),  // Monospace for registration numbers
      ),
      const SizedBox(height: 8),
      // Helper text showing format
      RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          children: [
            const TextSpan(text: '💡 Format: '),
            TextSpan(
              text: 'DOSH/PV/[State]/[Year]/[Number]-[TypeCode]',
              style: GoogleFonts.robotoMono(fontSize: 11),
            ),
          ],
        ),
      ),
      if (_selectedEquipmentType != null) ...[
        const SizedBox(height: 4),
        Text(
          'Example for ${_selectedEquipmentType}: ${_getDoshExample()}',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.accentYellow,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ],
  ),
),
const SizedBox(height: 24),
```

### Add Helper Methods (at the end of `_AssignTaskPageState` class):

```dart
/// Get DOSH hint text based on selected equipment type
String _getDoshHint() {
  if (_selectedEquipmentType == null) {
    return 'Select equipment type first';
  }
  
  switch (_selectedEquipmentType) {
    case 'Reactor':
      return 'e.g., DOSH/PV/SEL/2024/001-R';
    case 'Pressure Vessel':
      return 'e.g., DOSH/PV/SEL/2024/002-PV';
    case 'Heat Exchanger':
      return 'e.g., DOSH/PV/SEL/2024/003-HE';
    case 'Storage Tank':
      return 'e.g., DOSH/PV/SEL/2024/004-ST';
    case 'Tower':
      return 'e.g., DOSH/PV/SEL/2024/005-TW';
    default:
      return 'DOSH/PV/[State]/[Year]/[Number]-[Code]';
  }
}

/// Get DOSH example based on selected equipment type
String _getDoshExample() {
  if (_selectedEquipmentType == null) return '';
  
  switch (_selectedEquipmentType) {
    case 'Reactor':
      return 'DOSH/PV/SEL/2024/001-R';
    case 'Pressure Vessel':
      return 'DOSH/PV/SEL/2024/002-PV';
    case 'Heat Exchanger':
      return 'DOSH/PV/SEL/2024/003-HE';
    case 'Storage Tank':
      return 'DOSH/PV/SEL/2024/004-ST';
    case 'Tower':
      return 'DOSH/PV/SEL/2024/005-TW';
    default:
      return '';
  }
}
```

## 🎯 How It Works

1. **Manager assigns task** → Enters DOSH registration number manually
2. **UI shows hints** → Based on equipment type selected, shows example format
3. **Backend saves** → Stores DOSH registration with inspection
4. **Inspection workflow** → Inspector sees DOSH number in inspection details
5. **PDF Report** → Auto-includes the DOSH registration number in headers

## 📝 Format Guide for Users

| Equipment Type | Type Code | Example |
|----------------|-----------|---------|
| Reactor | R | DOSH/PV/SEL/2024/001-R |
| Pressure Vessel | PV | DOSH/PV/SEL/2024/002-PV |
| Heat Exchanger | HE | DOSH/PV/SEL/2024/003-HE |
| Storage Tank | ST | DOSH/PV/SEL/2024/004-ST |
| Tower | TW | DOSH/PV/SEL/2024/005-TW |

**Notes:**
- SEL = Selangor (change based on state)
- 2024 = Registration year
- Number should match actual DOSH certificate
- This is optional - can be left blank if equipment not yet registered

---

*Implementation Date: January 14, 2026*
