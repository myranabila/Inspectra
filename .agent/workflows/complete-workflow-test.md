---
description: Complete System Workflow Test - Task Assignment to Approval
---

# Complete Inspectra Workflow Test Guide

This document outlines the complete end-to-end workflow testing procedure for the Inspectra system.

## 1. Task Assignment by Manager

### Prerequisites
- Login as Manager (username: `manager`, password: `manager123`)
- Navigate to "Assign Task" from sidebar

### Steps to Assign Task

1. **Select Inspector**
   - From dropdown, choose an available inspector
   - System shows only registered inspectors

2. **Define Inspection Details**
   - **Inspection Title**: Enter custom title (e.g., "API 510 Pressure Vessel Inspection")
   - **Equipment Tag**: Enter equipment identifier
   - **Location**: Select from dropdown
   - **Equipment Type**: Select type (API 510, API 653, etc.)
   - **Scheduled Date**: Pick inspection date

3. **Select Required Sections**
   - ✅ Equipment Identification (Always required)
   - ☑️ External Visual Inspection
   - ☑️ Weld Visual Inspection  
   - ☑️ Internal Visual Inspection
   - ☑️ Thickness Measurement
   
   **Important**: Only checked sections will appear in the inspector's form

4. **Submit Assignment**
   - Click "Assign Task"
   - System creates inspection with status: `scheduled`
   - Inspector receives the task

### Expected Backend Behavior
- Inspection record created with:
  - `status`: scheduled
  - `require_external`: based on selection
  - `require_weld`: based on selection
  - `require_internal`: based on selection
  - `require_thickness`: based on selection
  - `title`: manager-defined title
  - `inspector_id`: assigned inspector

---

## 2. Inspector Receives and Completes Task

### Prerequisites
- Login as Inspector (username: `inspector`, password: `inspector123`)
- Navigate to "Pending Tasks"

### Steps to Complete Inspection

1. **View Assigned Task**
   - Task appears in "Pending Tasks" with status: `scheduled`
   - Click task card to open report form

2. **Generate Inspection Report**
   - Page shows: **Manager-defined title** in header
   - Form displays **only the sections** manager selected:
     - Always: Equipment Identification + Inspection Date
     - Conditional: External, Weld, Internal, Thickness (based on manager selection)

3. **Fill Out Report**
   - Enter findings and recommendations for each visible section
   - Upload photos (optional but recommended)
   - Complete all required fields

4. **Preview PDF**
   - Click "Generate PDF Preview"
   - System displays PDF with:
     - All entered data
     - Photos in 3-column table (Photo | Finding | Recommendation)
     - Only sections that were filled

5. **Review and Edit**
   - Use Ctrl+Mouse Wheel to zoom in/out
   - Review all details
   - Click "Edit Report" if changes needed
   - Click "Submit Final Report" when ready

### Expected Backend Behavior
- On submit:
  - Inspection status changes: `scheduled` → `pending_review`
  - Report data saved
  - Photos stored
  - Manager notified

---

## 3. Manager Reviews Submitted Report

### Prerequisites
- Login as Manager
- Navigate to "Pending Review" from sidebar

### Steps to Review Report

1. **View Pending Reports**
   - List shows all reports with status: `pending_review`
   - Each card shows:
     - Inspection title
     - Inspector name
     - Submission date
     - Equipment tag

2. **Open Report Details**
   - Click on report card
   - System displays:
     - Full report content
     - All findings and recommendations
     - Uploaded photos
     - Inspection sections completed

3. **Make Decision**
   - Two options available:
     - **Approve** - if report is satisfactory
     - **Reject** - if revisions needed

---

## 4. Approval Flow

### Steps to Approve Report

1. Click "Approve" button
2. (Optional) Add approval notes
3. Confirm approval

### Expected System Behavior

**Backend:**
- Inspection status: `pending_review` → `completed`
- `completion_date` set to today
- Approval notes added to inspection record

**Manager Dashboard:**
- Completed count increases by 1
- Pending review count decreases by 1
- Report moves to "History" section

**Inspector Dashboard:**
- Task moves from "Pending" to "History"
- Completed count increases by 1
- Status badge shows: "COMPLETED"

---

## 5. Rejection Flow

### Steps to Reject Report

1. Click "Reject" button
2. **Enter rejection reason** (required)
3. **Add feedback** (optional but recommended)
4. Confirm rejection

### Expected System Behavior

**Backend:**
- Inspection status: `pending_review` → `rejected`
- `rejection_reason` saved
- `rejection_feedback` saved
- `rejection_count` incremented
- `last_rejected_at` timestamp updated

**Manager Dashboard:**
- Rejected count increases by 1
- Pending review count decreases by 1
- Report appears in rejected section

**Inspector Dashboard:**
- Task reappears in "Pending Tasks"
- Status badge shows: "REJECTED"
- Inspector can see rejection reason
- Inspector can revise and resubmit

**Manager Options After Rejection:**
1. **Keep with same inspector**: Inspector revises and resubmits
2. **Reassign to different inspector**: Use "Reassign Task" feature

---

## 6. Resubmission After Rejection

### Inspector Steps

1. **View Rejected Task**
   - Task appears in "Pending Tasks" with RED rejected badge
   - Click to open

2. **View Rejection Details**
   - System shows rejection reason
   - System shows manager feedback
   - Previous data pre-filled for editing

3. **Make Corrections**
   - Update findings/recommendations
   - Add/remove photos
   - Address manager's feedback

4. **Resubmit**
   - Click "Generate PDF Preview"
   - Review changes
   - Click "Submit Final Report"

### Expected Backend Behavior
- Status changes: `rejected` → `pending_review`
- Resubmission count tracked
- Manager can review again

---

## 7. Dashboard Count Verification

### Manager Dashboard Counts

- **Total Inspections**: All inspections
- **Scheduled**: Tasks assigned but not started
- **Pending Review**: Inspector submitted, awaiting manager
- **Completed**: Manager approved
- **Rejected**: Manager rejected
- **Overdue**: Past scheduled date, not completed

### Inspector Dashboard Counts

- **My Tasks**: Total assigned to inspector
- **Pending**: Scheduled + Rejected (need action)
- **Submitted**: Waiting for manager review
- **Completed**: Manager approved
- **Rejected**: Manager rejected (also in Pending)

---

## 8. Notification System

### Manager Notifications

- ✉️ New report submitted (pending_review)
- Alert shown in dashboard
- Pending review count badge

### Inspector Notifications

- ✉️ Task assigned
- ✉️ Report approved
- ✉️ Report rejected (with reason)
- Badges on task cards

---

## 9. Reassignment Feature

### Manager Reassigns Rejected Task

1. Navigate to rejected inspection
2. Click "Reassign Task"
3. Select new inspector from dropdown
4. Optionally add reassignment notes
5. Confirm

### Expected Behavior
- Original inspector: task removed from list
- New inspector: task appears as new assignment
- Status: `rejected` → `scheduled`
- Assignment history tracked

---

## Test Scenarios to Verify

### Scenario 1: Happy Path
- Manager assigns → Inspector completes → Manager approves ✅

### Scenario 2: Rejection and Resubmission
- Manager assigns → Inspector submits → Manager rejects → Inspector revises → Inspector resubmits → Manager approves ✅

### Scenario 3: Multiple Rejections
- Same task rejected 2-3 times, tracking rejection_count ✅

### Scenario 4: Selective Sections
- Manager selects only External + Weld
- Inspector should NOT see Internal or Thickness sections ✅

### Scenario 5: Photo Integration
- Inspector uploads 5 photos
- All 5 photos appear in PDF report ✅

### Scenario 6: Dashboard Accuracy
- All counts match database states ✅

---

## Known Features

✅ Manager defines custom inspection titles
✅ Manager selects visible sections (dynamic forms)
✅ Only selected sections appear for inspector
✅ Inspector can upload photos
✅ Photos appear in PDF (3-column table format)
✅ Ctrl+Mouse Wheel zoom in PDF preview
✅ Professional UI with gradient headers
✅ Consistent back buttons across pages
✅ Approve/Reject functionality
✅ Rejection tracking with reason & feedback
✅ Resubmission flow
✅ Dashboard count updates
✅ Task filtering (Pending/History)

---

## Troubleshooting

### Task Not Appearing for Inspector
- Check inspector_id assignment
- Verify status is `scheduled` or `rejected`
- Check filter settings

### Section Not Showing
- Verify `require_external`, `require_weld`, etc. flags
- Check manager task assignment selections

### PDF Not Generated
- Ensure all required fields filled
- Check photo upload sizes
- Verify backend PDF generator

### Approval/Reject Not Working
- Check user role (must be manager)
- Verify inspection status is `pending_review`
- Check backend logs

---

## Backend API Endpoints Reference

### Manager Endpoints
- `POST /api/manager/assign-task` - Assign inspection task
- `GET /api/manager/pending/review` - Get pending reviews
- `POST /api/manager/approve/inspection` - Approve inspection
- `POST /api/manager/reject/inspection` - Reject inspection

### Inspector Endpoints
- `GET /api/dashboard/my-tasks` - Get assigned tasks
- `POST /api/dashboard/submit-report` - Submit inspection report

### Status Flow
```
scheduled → pending_review → completed (approved)
         ↓                 ↓
         → rejected --------→ (resubmit cycle)
```

---

## Final Verification Checklist

- [ ] Manager can assign tasks with custom titles
- [ ] Manager can select required sections
- [ ] Inspector sees only selected sections
- [ ] Inspector can complete and submit report
- [ ] Manager receives notification of submission
- [ ] Manager can view full report
- [ ] Manager can approve report
- [ ] Manager can reject report with reason
- [ ] Rejection sends task back to inspector
- [ ] Inspector can revise and resubmit
- [ ] Dashboard counts are accurate
- [ ] History shows correct records
- [ ] Photos appear in PDF correctly
- [ ] Zoom works without clicking (Ctrl+Wheel)
- [ ] UI is professional and consistent

---

**Test completed successfully when all checkboxes are marked ✅**
