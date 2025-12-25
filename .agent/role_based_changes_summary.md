# Role-Based Inspection System - Change Summary

## Current System Analysis

### Existing Fields in Inspection Model (backend/models.py):
✅ equipment_id (Column 67) - Can be used for Equipment Tag Number
✅ equipment_type (Column 68) - Needs dropdown restriction
✅ location (Column 66) - Needs to be changed to "area" with dropdown
✅ inspector_id (Column 73) - Already exists for assignment
✅ scheduled_date (Column 70) - Can be used for Due Date
✅ require_external, require_weld, require_internal, require_thickness (Lines 76-79) - Perfect for Required Sections!

### What Needs to be Added/Modified:

#### Backend Changes:
1. **Add new fields to Inspection model**:
   - `inspection_id_display` (auto-generated, read-only, e.g., "INS-2024-001")
   - `report_number` (auto-generated, read-only, e.g., "RPT-2024-001")
   - `area` (replace location, use dropdown values)
   
2. **Equipment Type Restriction**:
   - Limit to: Reactor, Pressure Vessel, Heat Exchanger, Storage Tank, Tower
   
3. **Equipment Tag Validation**:
   - Reactor: R + 3 digits (R001, R002, etc.)
   - Pressure Vessel: P + 3 digits (P001, P002, etc.)
   - Heat Exchanger: H + 3 digits (H001, H002, etc.)
   - Storage Tank: T + 3 digits (T001, T002, etc.)
   - Tower: TW + 3 digits (TW001, TW002, etc.)

4. **Area Dropdown Values**:
   - Plant 1, Plant 2, Utility Area, Offsite Area, Process Area

#### Frontend Changes:

##### Manager Side (assign_task_page.dart):
1. Equipment Type dropdown (5 options)
2. Equipment Tag Number with validation
3. Area dropdown (5 options instead of current location)
4. Required Inspection Sections checkboxes (already exists!)
5. Assigned Inspector dropdown (already exists!)
6. Due Date picker (already exists!)
7. Display auto-generated Inspection ID and Report Number (read-only)

##### Inspector Side (inspection_workflow_page.dart):
1. Per Section Fields:
   - Finding (short text) - ALREADY EXISTS as "findings"
   - Condition dropdown (Satisfactory, Observation) - NEW
   - Photo Evidence (min 1) - ALREADY EXISTS
   - Section Recommendation dropdown (Nil, Monitor) - NEW

2. Page 1 Summary (after all sections complete):
   - Overall Finding - MODIFY existing summary
   - Overall Recommendation - NEW
   - Additional Comments - ALREADY EXISTS

3. Dynamic Section Display:
   - Only show sections where require_* is true

## Implementation Plan

### Step 1: Backend Database Migration
```python
# Add to Inspection model:
- inspection_id_display: String(50), unique, auto-generated
- report_number: String(50), unique, auto-generated  
- area: String(100), replace location

# Modify equipment_type to use enum with 5 options
```

### Step 2: Backend API Updates
- Update inspection creation to auto-generate IDs
- Add equipment tag validation
- Add area dropdown validation
- Update task assignment endpoint

### Step 3: Manager UI (assign_task_page.dart)
- Replace location field with area dropdown
- Add equipment type dropdown (5 options)
- Add equipment tag validation
- Display auto-generated IDs (read-only)
- Keep existing: sections checkboxes, inspector dropdown, due date

### Step 4: Inspector UI (inspection_workflow_page.dart)
- Add condition dropdown per section
- Add section recommendation dropdown per section
- Modify Page 1 to add Overall Recommendation
- Dynamic section display based on require_* flags
- Keep existing: findings, photos, comments

### Step 5: Role-Based Access Control
- Manager cannot access: findings, conditions, photos, recommendations
- Inspector cannot access: equipment details, area, assignment, due date
- Both can view auto-generated IDs (read-only)

## Files to Modify

### Backend:
1. `backend/models.py` - Add new fields
2. `backend/manager.py` - Update task assignment logic
3. `backend/dashboard.py` - Update inspector task fetch
4. `backend/report.py` - Update report submission

### Frontend:
1. `lib/assign_task_page.dart` - Manager interface
2. `lib/inspection_workflow_page.dart` - Inspector interface
3. `lib/services/manager_service.dart` - API calls
4. `lib/services/dashboard_service.dart` - API calls

## Testing Checklist
- [ ] Equipment tag validation works for all 5 types
- [ ] Area dropdown shows 5 options
- [ ] Auto-generated IDs are unique and read-only
- [ ] Only selected sections appear for inspector
- [ ] Photo upload enforces minimum 1 per section
- [ ] Condition and recommendation dropdowns work
- [ ] Page 1 summary unlocks after all sections complete
- [ ] Manager cannot see inspector fields
- [ ] Inspector cannot edit manager fields
- [ ] Existing system flow still works smoothly

## Backward Compatibility Strategy
- Keep existing API endpoints working
- Add new optional parameters
- Use feature flags if needed
- Gradual migration of existing data
