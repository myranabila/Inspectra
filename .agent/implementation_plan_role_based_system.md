# Role-Based Inspection Management System - Implementation Plan

## Overview
Implement strict role-based separation between Manager and Inspector roles with clear field ownership and access control.

## 1. User Roles Definition

### Manager Role
**Responsibilities**: Task Setup & Assignment (Pre-Inspection)
**Can Access/Edit**:
- Equipment Type (dropdown: Reactor, Pressure Vessel, Heat Exchanger, Storage Tank, Tower)
- Equipment Tag Number (validation: R001 for Reactor, P001 for Pressure Vessel, etc.)
- Area (dropdown: Plant 1, Plant 2, Utility Area, Offsite Area, Process Area)
- Required Inspection Sections (checkboxes):
  * External Visual Inspection
  * Weld Visual Inspection
  * Internal Inspection
  * Thickness Inspection
- Assigned Inspector (dropdown from registered inspectors)
- Due Date

**Cannot Access/Edit**:
- Findings
- Conditions
- Photos
- Recommendations
- Overall Summary

### Inspector Role
**Responsibilities**: Inspection Execution & Reporting
**Can Access/Edit** (for assigned sections only):
- Finding (short text per section)
- Condition (dropdown: Satisfactory, Observation)
- Photo Evidence (minimum 1 photo required)
- Section Recommendation (dropdown: Nil, Monitor)
- Overall Finding (Page 1 summary)
- Overall Recommendation (Page 1)
- Additional Comments (Page 1)

**Cannot Access/Edit**:
- Equipment Type
- Equipment Tag Number
- Area
- Required Sections
- Inspector Assignment
- Due Date

### System Auto-Generated (Read-Only)
- Inspection ID
- Report Number

## 2. Implementation Steps

### Phase 1: Backend Updates
- [ ] Update database schema for strict role separation
- [ ] Create equipment tag number validation rules
- [ ] Update API endpoints for role-based access
- [ ] Implement section-based data structure
- [ ] Add validation for required fields per role

### Phase 2: Manager Interface (Assign Task Page)
- [ ] Redesign task assignment form
- [ ] Add equipment type dropdown with 5 options
- [ ] Implement tag number validation based on equipment type
- [ ] Add area dropdown with 5 options
- [ ] Create inspection sections checkboxes
- [ ] Add inspector selection dropdown
- [ ] Add due date picker
- [ ] Display read-only auto-generated fields
- [ ] Implement form validation

### Phase 3: Inspector Interface (Inspection Workflow)
- [ ] Redesign inspection form with role check
- [ ] Display only manager-assigned sections
- [ ] Implement per-section data entry:
  - Finding text input
  - Condition dropdown
  - Photo upload (minimum 1)
  - Section recommendation dropdown
- [ ] Create Page 1 summary form:
  - Overall Finding
  - Overall Recommendation
  - Additional Comments
- [ ] Implement section completion tracking
- [ ] Add validation for required photos

### Phase 4: Access Control
- [ ] Implement frontend role checks
- [ ] Add backend authorization middleware
- [ ] Prevent cross-role field access
- [ ] Add appropriate error messages
- [ ] Implement read-only displays for restricted fields

### Phase 5: Workflow Logic
- [ ] Enforce workflow: Manager → Inspector → Submission
- [ ] Prevent inspector access before manager assignment
- [ ] Lock manager fields after inspector starts
- [ ] Implement status tracking
- [ ] Add workflow state validation

## 3. Data Structure

### Inspection Task (Manager Creates)
```json
{
  "inspection_id": "AUTO-GENERATED",
  "report_number": "AUTO-GENERATED",
  "equipment_type": "Reactor|Pressure Vessel|Heat Exchanger|Storage Tank|Tower",
  "equipment_tag": "R001|P001|...",
  "area": "Plant 1|Plant 2|Utility Area|Offsite Area|Process Area",
  "required_sections": {
    "external_visual": boolean,
    "weld_visual": boolean,
    "internal": boolean,
    "thickness": boolean
  },
  "assigned_inspector_id": integer,
  "due_date": "YYYY-MM-DD",
  "status": "assigned|in_progress|completed",
  "created_by": manager_id,
  "created_at": timestamp
}
```

### Inspection Report (Inspector Fills)
```json
{
  "inspection_id": reference,
  "sections": {
    "external_visual": {
      "finding": "text",
      "condition": "Satisfactory|Observation",
      "photos": ["url1", "url2"],
      "recommendation": "Nil|Monitor"
    },
    "weld_visual": {...},
    "internal": {...},
    "thickness": {...}
  },
  "summary": {
    "overall_finding": "text",
    "overall_recommendation": "text",
    "additional_comments": "text"
  },
  "completed_by": inspector_id,
  "completed_at": timestamp
}
```

## 4. Validation Rules

### Equipment Tag Number Format
- **Reactor**: R + 3 digits (e.g., R001, R002)
- **Pressure Vessel**: P + 3 digits (e.g., P001)
- **Heat Exchanger**: H + 3 digits (e.g., H001)
- **Storage Tank**: T + 3 digits (e.g., T001)
- **Tower**: TW + 3 digits (e.g., TW001)

### Photo Requirements
- Minimum 1 photo per section
- Supported formats: JPG, PNG
- Maximum file size: 5MB per photo

### Required Fields
**Manager Must Fill**:
- Equipment Type
- Equipment Tag Number
- Area
- At least 1 inspection section
- Assigned Inspector
- Due Date

**Inspector Must Fill** (for each assigned section):
- Finding
- Condition
- At least 1 photo
- Recommendation

**Inspector Summary** (mandatory after all sections):
- Overall Finding
- Overall Recommendation

## 5. UI/UX Guidelines

### Manager View
- Clean form layout with clear field labels
- Dropdown menus for all predefined options
- Tag number field with format hint based on equipment type
- Checkbox group for inspection sections with clear labels
- Inspector dropdown showing name and employee ID
- Calendar widget for due date
- Display-only fields for generated IDs
- Prominent "Assign Task" button

### Inspector View
- Display task details at top (read-only)
- Show only assigned sections as tabs or cards
- Clear progress indicator (e.g., 2/4 sections completed)
- Easy photo upload with preview
- Dropdown menus for standardized fields
- Section-by-section save capability
- Page 1 summary unlocked after all sections complete
- "Submit Report" button enabled only when all required fields filled

### Both Roles
- Clear role indicator in header
- Appropriate access denied messages
- Read-only display of non-editable fields
- Status badges for workflow stages
- Helpful tooltips and validation messages

## 6. Testing Checklist

- [ ] Manager cannot access inspector fields
- [ ] Inspector cannot access manager fields
- [ ] Tag number validation works correctly
- [ ] Only assigned sections appear for inspector
- [ ] Photo upload enforces minimum requirement
- [ ] Summary page unlocks after section completion
- [ ] Auto-generated IDs are read-only
- [ ] Dropdowns show only valid options
- [ ] Workflow sequence is enforced
- [ ] Role-based API authorization works
- [ ] Form validation prevents invalid submissions
- [ ] Error messages are clear and helpful

## 7. Security Considerations

- Backend must verify role before allowing any data modification
- API endpoints must enforce role-based permissions
- Frontend role checks are for UX only, not security
- Audit log all role-based access attempts
- Encrypt photo uploads
- Validate all inputs server-side
- Use JWT tokens with role claims

## 8. Future Enhancements (Post-MVP)

- Email notifications on task assignment
- Mobile app for photo capture
- Offline mode for inspectors
- Batch task assignment
- Report templates and customization
- Advanced analytics per equipment type
- Integration with maintenance systems
