# Role-Based Inspection System - Testing Checklist

## 🧪 Complete Testing Guide

### System Information
- **Implementation Date**: December 20, 2024
- **System Version**: Role-Based Inspection Management v2.0
- **Testing Environment**: http://localhost:8080
- **Backend**: http://localhost:5000

---

## 📋 Pre-Testing Setup

- [ ] Backend server is running (check port 5000)
- [ ] Frontend application is running (check port 8080)
- [ ] Database has sample data (Manager and Inspector users)
- [ ] Test credentials available:
  - Manager: `manager@example.com` / password
  - Inspector: `inspector@example.com` / password

---

## 🔴 MANAGER TESTING

### Test 1: Login and Dashboard Access
- [ ] Login as Manager
- [ ] Dashboard loads successfully
- [ ] Can navigate to "Assign Task" page
- [ ] Sidebar shows correct manager menu items

### Test 2: Equipment Type Dropdown
- [ ] Navigate to Assign Task page
- [ ] Equipment Type dropdown is visible
- [ ] Dropdown shows EXACTLY 5 options:
  - [ ] Reactor
  - [ ] Pressure Vessel
  - [ ] Heat Exchanger
  - [ ] Storage Tank
  - [ ] Tower
- [ ] No other options are present
- [ ] Can select each option successfully

### Test 3: Area Dropdown
- [ ] Area dropdown is visible
- [ ] Dropdown shows EXACTLY 5 options:
  - [ ] Plant 1
  - [ ] Plant 2
  - [ ] Utility Area
  - [ ] Offsite Area
  - [ ] Process Area
- [ ] No other options are present
- [ ] Can select each option successfully

### Test 4: Equipment Tag Validation
- [ ] Select "Reactor" equipment type
- [ ] Equipment tag field shows format hint: "R + 3 digits"
- [ ] Auto-generate button creates tag starting with "R" (e.g., R001)
- [ ] Manual entry accepts valid format (R001, R099, etc.)
- [ ] Manual entry rejects invalid formats:
  - [ ] Rejects "A001" (wrong prefix)
  - [ ] Rejects "R1" (not 3 digits)
  - [ ] Rejects "R12" (not 3 digits)
  - [ ] Rejects "R1234" (too many digits)

**Repeat for each equipment type:**
- [ ] Pressure Vessel: P + 3 digits (P001)
- [ ] Heat Exchanger: H + 3 digits (H001)
- [ ] Storage Tank: T + 3 digits (T001)
- [ ] Tower: TW + 3 digits (TW001)

### Test 5: Required Inspection Sections
- [ ] All 4 checkboxes are visible:
  - [ ] External Visual Inspection
  - [ ] Weld Visual Inspection
  - [ ] Internal Inspection
  - [ ] Thickness Inspection
- [ ] Can check/uncheck each section
- [ ] External is checked by default
- [ ] Must select at least one section

### Test 6: Inspector Assignment
- [ ] Inspector dropdown shows all active inspectors
- [ ] Can select an inspector
- [ ] Inspector name displays correctly

### Test 7: Due Date Selection
- [ ] Date picker is functional
- [ ] Can select any future date
- [ ] Date displays in correct format

### Test 8: Task Submission with Auto-Generated IDs
- [ ] Fill all required fields
- [ ] Click "Assign Task" button
- [ ] Success dialog appears showing:
  - [ ] Green checkmark icon
  - [ ] "Task Assigned Successfully!" message
  - [ ] Auto-generated Inspection ID (format: INS-2024-XXX)
  - [ ] Auto-generated Report Number (format: RPT-2024-XXX)
  - [ ] IDs are unique (assign multiple tasks to verify)
- [ ] Close dialog returns to dashboard

### Test 9: Manager Field Restrictions
- [ ] Manager CANNOT see/access inspector-specific fields:
  - [ ] No Condition dropdowns visible on Assign Task page
  - [ ] No Section Recommendation dropdowns
  - [ ] No Finding fields
  - [ ] No Photo upload sections

---

## 🔵 INSPECTOR TESTING

### Test 10: Login and Task View
- [ ] Login as Inspector
- [ ] Dashboard loads successfully
- [ ] Navigate to "Pending Tasks"
- [ ] Can see tasks assigned by manager
- [ ] Task shows correct equipment type and area (read-only)

### Test 11: Inspection Method Selection
- [ ] Must select "Manual Inspection" to proceed
- [ ] After selection, inspection form loads
- [ ] Cannot skip method selection

### Test 12: Dynamic Section Display
**Scenario A: Only External + Weld required**
- [ ] Assign task with only External and Weld checked
- [ ] Inspector sees ONLY External and Weld sections
- [ ] Internal and Thickness sections are hidden

**Scenario B: All sections required**
- [ ] Assign task with all sections checked
- [ ] Inspector sees all 4 sections

**Scenario C: Only Thickness required**
- [ ] Assign task with only Thickness checked
- [ ] Inspector sees ONLY Thickness section

### Test 13: External Visual Inspection Section
- [ ] Section is visible with correct title
- [ ] Finding text field is present
- [ ] **Condition dropdown** is present with 2 options:
  - [ ] Satisfactory (with green checkmark icon)
  - [ ] Observation (with warning icon)
- [ ] Photo upload section (minimum 1 photo required)
- [ ] **Section Recommendation dropdown** with 2 options:
  - [ ] Nil
  - [ ] Monitor
- [ ] Additional Notes text field

### Test 14: Weld Visual Inspection Section
- [ ] Section is visible
- [ ] Finding text field is present
- [ ] **Condition dropdown** (Satisfactory/Observation)
- [ ] Photo upload (minimum 1)
- [ ] **Section Recommendation dropdown** (Nil/Monitor)
- [ ] Additional Notes field

### Test 15: Internal Inspection Section
- [ ] Toggle "Internal Inspection Accessible?" switch
- [ ] When ON:
  - [ ] Finding field appears
  - [ ] **Condition dropdown** appears
  - [ ] Photo upload appears
  - [ ] **Section Recommendation dropdown** appears
  - [ ] Additional Notes field appears
- [ ] When OFF:
  - [ ] Shows "Internal inspection not performed"
  - [ ] Fields are hidden

### Test 16: Thickness Measurement Section
- [ ] Can add thickness measurement entries
- [ ] Each entry has Location and Thickness fields
- [ ] Can add multiple entries
- [ ] Can delete entries
- [ ] **Overall Thickness Condition dropdown** at bottom
- [ ] **Section Recommendation dropdown** at bottom

### Test 17: Page 1 Summary Section
- [ ] "Page 1 - Overall Summary" title visible
- [ ] **Overall Finding** text field (required)
  - [ ] Placeholder: "Provide an overall summary of your inspection findings..."
  - [ ] Marked with * (required)
- [ ] **Overall Recommendation** text field (required)
  - [ ] Placeholder: "Provide your overall recommendation..."
  - [ ] Marked with * (required)
- [ ] **Additional Comments** text field (optional)
  - [ ] Clearly marked as "Optional"

### Test 18: Validation - Missing Required Fields

**Test missing Finding:**
- [ ] Leave Finding field empty in External section
- [ ] Try to submit
- [ ] Error appears: "External Visual: Finding is required"

**Test missing Condition:**
- [ ] Fill Finding but leave Condition dropdown unselected
- [ ] Try to submit
- [ ] Error appears: "External Visual: Condition is required"

**Test missing Section Recommendation:**
- [ ] Fill Finding and Condition but leave Section Recommendation unselected
- [ ] Try to submit
- [ ] Error appears: "External Visual: Section Recommendation is required"

**Test missing Photo:**
- [ ] Fill all fields but don't upload photo
- [ ] Try to submit
- [ ] Error appears: "External Visual: At least 1 photo required"

**Test missing Overall Recommendation:**
- [ ] Complete all sections but leave Overall Recommendation empty
- [ ] Try to submit
- [ ] Error appears: "Summary: Overall Recommendation is required"

### Test 19: Successful Submission
- [ ] Fill all required fields in all sections
- [ ] Select appropriate Condition for each section
- [ ] Select appropriate Recommendation for each section
- [ ] Upload minimum 1 photo per section
- [ ] Fill Overall Finding and Overall Recommendation
- [ ] Click Submit
- [ ] Report generates successfully
- [ ] PDF preview or success confirmation appears

### Test 20: Inspector Field Restrictions
- [ ] Inspector CANNOT see/edit manager fields:
  - [ ] Equipment Type (read-only or hidden)
  - [ ] Area (read-only or hidden)
  - [ ] Inspector assignment (not visible)
  - [ ] Due date (read-only)
  - [ ] Required sections (not editable)

---

## 🔄 END-TO-END WORKFLOW TESTING

### Scenario 1: Complete Flow - Reactor Inspection
1. **Manager:**
   - [ ] Login as Manager
   - [ ] Go to Assign Task
   - [ ] Select "Reactor" equipment type
   - [ ] Generate/enter tag "R001"
   - [ ] Select "Plant 1" area
   - [ ] Check: External + Weld + Thickness
   - [ ] Assign to Inspector
   - [ ] Set due date
   - [ ] Submit and note auto-generated IDs

2. **Inspector:**
   - [ ] Login as Inspector
   - [ ] See new task for R001
   - [ ] Select Manual Inspection
   - [ ] See only 3 sections (External, Weld, Thickness)
   - [ ] Fill External: Finding + Condition (Satisfactory) + Photo + Recommendation (Nil)
   - [ ] Fill Weld: Finding + Condition (Observation) + Photo + Recommendation (Monitor)
   - [ ] Fill Thickness: Measurements + Condition + Recommendation
   - [ ] Fill Page 1: Overall Finding + Overall Recommendation
   - [ ] Submit successfully

3. **Manager:**
   - [ ] See completed inspection
   - [ ] Can view report with all details

### Scenario 2: Multiple Equipment Types
- [ ] Test with each of the 5 equipment types
- [ ] Verify tag validation for each prefix
- [ ] Verify area selection for each

### Scenario 3: Validation Edge Cases
- [ ] Try submitting with no equipment type selected
- [ ] Try invalid equipment tags
- [ ] Try assigning without selecting inspector
- [ ] Try assigning without due date
- [ ] Try assigning without any sections checked

---

## 🎯 DATA PERSISTENCE TESTING

### Test 21: Database Storage
- [ ] Assign task and check database
- [ ] Verify `inspection_id_display` is stored correctly
- [ ] Verify `report_number` is stored correctly
- [ ] Verify `area` field contains correct value
- [ ] Verify equipment_type stores actual type (not "API 510 Vessel")

### Test 22: Inspector Data Storage
- [ ] Complete inspection with all dropdowns
- [ ] Check database for stored values:
  - [ ] external_condition
  - [ ] external_section_recommendation  
  - [ ] weld_condition
  - [ ] weld_section_recommendation
  - [ ] internal_condition
  - [ ] internal_section_recommendation
  - [ ] thickness_condition
  - [ ] thickness_section_recommendation
  - [ ] overall_recommendation

### Test 23: ID Uniqueness
- [ ] Assign 5 tasks in sequence
- [ ] Verify each gets unique Inspection ID
- [ ] Verify each gets unique Report Number
- [ ] Format should be: INS-2024-001, INS-2024-002, etc.

---

## 🔒 SECURITY TESTING

### Test 24: Role-Based Access Control
- [ ] Inspector cannot access `/assign-task` endpoint
- [ ] Manager cannot access inspector-only endpoints
- [ ] Unauthorized users redirected to login

### Test 25: Data Validation
- [ ] Backend rejects invalid equipment types
- [ ] Backend rejects invalid area values
- [ ] Backend rejects invalid condition values
- [ ] Backend rejects invalid recommendation values

---

## 🎨 UI/UX TESTING

### Test 26: Responsive Design
- [ ] Test on different screen sizes
- [ ] Dropdowns are clearly visible
- [ ] Required field indicators (*) are visible
- [ ] Error messages are readable

### Test 27: User Feedback
- [ ] Success dialog appears after task assignment
- [ ] Auto-generated IDs are prominently displayed
- [ ] Validation errors are clear and helpful
- [ ] Loading states work correctly

---

## ✅ ACCEPTANCE CRITERIA

All tests must pass to consider the system ready for production:

**Critical (Must Pass):**
- [ ] All 5 equipment types work correctly
- [ ] All 5 areas work correctly
- [ ] Equipment tag validation works for all types
- [ ] All 4 inspection sections show dropdownscorrectly
- [ ] Condition dropdown has exactly 2 options
- [ ] Section Recommendation dropdown has exactly 2 options
- [ ] Overall Recommendation field is present and required
- [ ] Auto-generated IDs are unique and display correctly
- [ ] Validation prevents submission with missing required fields
- [ ] Data is saved correctly to database

**Important (Should Pass):**
- [ ] Dynamic section display works
- [ ] Photo upload enforces minimum 1 per section
- [ ] Success dialog shows after task assignment
- [ ] Error messages are clear
- [ ] UI is professional and consistent

**Nice to Have:**
- [ ] Smooth animations
- [ ] Icons display correctly
- [ ] Color coding works (green for satisfactory, orange for observation)
- [ ] Responsive design works on all screens

---

## 🐛 Known Issues / Limitations

Document any issues found during testing:

1. **Issue**: _________________
   - **Severity**: Critical / High / Medium / Low
   - **Steps to Reproduce**: _________________
   - **Expected**: _________________
   - **Actual**: _________________
   - **Status**: Open / Fixed / Won't Fix

---

## 📝 Test Results Summary

**Test Date**: __________  
**Tester**: __________  
**Environment**: __________

| Category | Total Tests | Passed | Failed | Notes |
|----------|-------------|--------|--------|-------|
| Manager UI | 9 | __ | __ | |
| Inspector UI | 11 | __ | __ | |
| End-to-End | 3 | __ | __ | |
| Data Persistence | 3 | __ | __ | |
| Security | 2 | __ | __ | |
| UI/UX | 2 | __ | __ | |
| **TOTAL** | **30** | **__** | **__** | |

**Overall Status**: ☐ PASS ☐ FAIL ☐ NEEDS REVIEW

**Sign-off**: ____________________ Date: __________

---

## 🚀 Next Steps After Testing

If all tests pass:
- [ ] Document any minor issues for future updates
- [ ] Create user training materials
- [ ] Schedule production deployment
- [ ] Set up monitoring and logging
- [ ] Create backup and recovery procedures

If tests fail:
- [ ] Document all failures
- [ ] Prioritize critical issues
- [ ] Fix issues and retest
- [ ] Update documentation as needed
