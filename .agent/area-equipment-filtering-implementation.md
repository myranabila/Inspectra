# Area-Equipment Type Filtering - Complete Implementation

## Overview
This document outlines the complete implementation of Area-based Equipment Type filtering with validation at all system layers.

## System Architecture

### 1. Database Layer (models.py)
**Fields in `inspections` table:**
- `location` (String, 200) - Backward compatibility
- `area` (String, 100) - Primary area field
- `equipment_type` (String, 200) - Equipment type field

**Status:** ✅ Fields exist and are properly indexed

### 2. Backend API Layer (backend/manager.py)

#### Area-Equipment Type Mapping:
```python
AREA_EQUIPMENT_MAP = {
    'Plant 1': ['Reactor', 'Pressure Vessel', 'Heat Exchanger'],
    'Plant 2': ['Storage Tank', 'Tower', 'Pressure Vessel'],
    'Utility Area': ['Heat Exchanger', 'Storage Tank'],
    'Offsite Area': ['Storage Tank', 'Tower'],
    'Process Area': ['Reactor', 'Pressure Vessel', 'Heat Exchanger', 'Tower'],
}
```

#### New API Endpoint:
**POST** `/manager/update/inspection?inspection_id={id}`

**Request Body:**
```json
{
  "location": "Plant 1",
  "inspection_type": "Reactor"
}
```

**Validation Logic:**
1. Check if Area exists in AREA_EQUIPMENT_MAP
2. Validate Equipment Type is in allowed list for that Area
3. Return HTTP 400 with descriptive error if invalid
4. Update both `location` and `area` fields in database
5. Update `equipment_type` field
6. Return success response

**Response (Success):**
```json
{
  "message": "Inspection updated successfully",
  "inspection_id": 123,
  "location": "Plant 1",
  "equipment_type": "Reactor"
}
```

**Response (Error):**
```json
{
  "detail": "Equipment Type 'Storage Tank' is not valid for Area 'Plant 1'. Valid types are: Reactor, Pressure Vessel, Heat Exchanger"
}
```

#### Updated Endpoint:
**GET** `/manager/pending/inspections`

**Added Fields:**
- `inspection_id_display` - For display in Edit dialog
- `equipment_tag` - Equipment tag number
- `inspection_type` - Current equipment type

### 3. Frontend Service Layer (lib/services/manager_service.dart)

#### New Method:
```dart
static Future<Map<String, dynamic>> updateInspectionDetails({
  required int inspectionId,
  required String area,
  required String equipmentType,
}) async {
  // Calls POST /manager/update/inspection
  // Sends location and inspection_type
  // Returns response with validation
}
```

### 4. Frontend UI Layer (lib/edit_inspection_dialog.dart)

#### Features:
- **Pre-fills existing values** from inspection data
- **Dynamic filtering** - Equipment Type dropdown updates based on Area
- **Auto-correction** - Resets Equipment Type if incompatible with new Area
- **User warnings** - Shows SnackBar when auto-correction occurs
- **Validation** - Prevents submission of invalid combinations

#### Area-Equipment Mapping (Frontend):
```dart
final Map<String, List<String>> _areaEquipmentMap = {
  'Plant 1': ['Reactor', 'Pressure Vessel', 'Heat Exchanger'],
  'Plant 2': ['Storage Tank', 'Tower', 'Pressure Vessel'],
  'Utility Area': ['Heat Exchanger', 'Storage Tank'],
  'Offsite Area': ['Storage Tank', 'Tower'],
  'Process Area': ['Reactor', 'Pressure Vessel', 'Heat Exchanger', 'Tower'],
};
```

#### Dialog Workflow:
1. **Load current values** → Pre-fill Area and Equipment Type dropdowns
2. **Area change** → Call `_validateEquipmentTypeForArea()`
3. **Validation** → Check if Equipment Type is valid for new Area
4. **Auto-correct** → If invalid, select first valid Equipment Type
5. **Warning** → Show SnackBar with yellow background
6. **Submit** → Call backend API with validated data

### 5. UI Integration (lib/manager_approvals_page.dart)

#### Edit Button Style:
```dart
TextButton.icon(
  icon: Icon(Icons.edit_rounded, size: 16, color: AppTheme.primaryRed),
  label: Text('Edit', ...),
  style: TextButton.styleFrom(
    backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.08),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
)
```

**Location:** Between PDF and Details buttons in inspection card

## Validation Flow

### Frontend Validation (First Layer)
```
1. User selects Area
   ↓
2. _validateEquipmentTypeForArea() called
   ↓
3. Check if current Equipment Type is valid for new Area
   ↓
4. If invalid → Auto-select first valid Equipment Type
   ↓
5. Show warning SnackBar to user
   ↓
6. User selects Equipment Type from filtered dropdown
   ↓
7. User clicks "Save Changes"
   ↓
8. Frontend sends validated data to backend
```

### Backend Validation (Second Layer)
```
1. Receive request at /manager/update/inspection
   ↓
2. Check if Area exists in AREA_EQUIPMENT_MAP
   ↓
3. If Area invalid → Return HTTP 400 error
   ↓
4. Get valid Equipment Types for Area
   ↓
5. Check if Equipment Type is in valid list
   ↓
6. If invalid → Return HTTP 400 with descriptive error
   ↓
7. If valid → Update database fields:
   - location = new area
   - area = new area  
   - equipment_type = new equipment type
   - updated_at = now()
   ↓
8. Commit transaction
   ↓
9. Return success response
```

## Error Handling

### Frontend Errors:
- Network errors → Show red SnackBar
- Validation errors from backend → Show error in dialog
- Auto-correction → Show yellow warning SnackBar

### Backend Errors:
- Invalid Area → HTTP 400: "Invalid area: {area}"
- Invalid Equipment Type → HTTP 400: "Equipment Type '{type}' is not valid for Area '{area}'. Valid types are: {list}"
- Database error → HTTP 500: "Failed to update inspection: {error}"
- Inspection not found → HTTP 404: "Inspection not found"
- Permission denied → HTTP 403: "Only managers can access this endpoint"

## Testing Checklist

### ✅ Database:
- [x] `location` field exists
- [x] `area` field exists
- [x] `equipment_type` field exists
- [x] Fields are properly typed (String)
- [x] Fields allow updates

### ✅ Backend:
- [x] AREA_EQUIPMENT_MAP is defined
- [x] POST /manager/update/inspection endpoint exists
- [x] Validation logic implemented
- [x] Error responses are descriptive
- [x] Success responses include updated data
- [x] Manager-only access enforced
- [x] GET /pending/inspections includes new fields

### ✅ Frontend:
- [x] EditInspectionDialog component created
- [x] Area dropdown populated
- [x] Equipment Type dropdown filters by Area
- [x] Pre-fills existing values
- [x] Validates on Area change
- [x] Auto-corrects invalid combinations
- [x] Shows warnings to user
- [x] ManagerService.updateInspectionDetails() method exists
- [x] Edit button styled correctly
- [x] Edit button integrated in Manager Approvals page

## Security Considerations

1. **Authentication:** All endpoints require valid JWT token
2. **Authorization:** Only managers can edit inspections
3. **Validation:** Two-layer validation (frontend + backend)
4. **Database Protection:** Backend validation prevents invalid data from being saved
5. **Transaction Safety:** Database updates use try-catch with rollback on error

## Performance Considerations

1. **Efficient Filtering:** Frontend filtering is O(1) lookup in HashMap
2. **Minimal Database Queries:** Single UPDATE query per save
3. **Optimized Response:** Only returns necessary fields
4. **Validation Speed:** Backend validation is O(1) for Area check, O(n) for Equipment Type check where n is small (max 5)

## Maintenance Notes

### To Add New Area:
1. Add to `AREA_EQUIPMENT_MAP` in `backend/manager.py`
2. Add to `_areaEquipmentMap` in `lib/edit_inspection_dialog.dart`
3. Add to `_areas` list in both files

### To Add New Equipment Type:
1. Add to relevant areas in `AREA_EQUIPMENT_MAP` (backend)
2. Add to relevant areas in `_areaEquipmentMap` (frontend)
3. Add to `_allEquipmentTypes` list if completely new

### To Change Validation Rules:
1. Update `AREA_EQUIPMENT_MAP` in backend (source of truth)
2. Update `_areaEquipmentMap` in frontend (for consistency)
3. Test both valid and invalid combinations
4. Verify error messages are clear

## Deployment Checklist

- [x] Database migrations completed (fields already exist)
- [x] Backend code deployed with new endpoint
- [x] Frontend code deployed with Edit dialog
- [x] Backend validation tested
- [x] Frontend validation tested
- [x] Error handling tested
- [x] UI/UX verified
- [x] Button styling matches design
- [x] Two-layer validation working
- [x] Backend restarted with new code

## Status: ✅ COMPLETE

All layers are implemented, validated, and deployed:
- ✅ Database fields available
- ✅ Backend API with validation
- ✅ Frontend service integration
- ✅ UI with Edit dialog
- ✅ Manager Approvals page integration
- ✅ Two-layer validation working
- ✅ Error handling complete
- ✅ Backend restarted and running

The system now fully supports Area-based Equipment Type filtering with robust validation at all levels.
