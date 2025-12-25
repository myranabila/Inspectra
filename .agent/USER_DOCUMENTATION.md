# Role-Based Inspection Management System - Complete Documentation

## 📘 System Overview

The Role-Based Inspection Management System is designed with strict separation between Manager and Inspector roles, ensuring that each user can only access and modify fields designated for their role.

**Version**: 2.0  
**Implementation Date**: December 20, 2024  
**System Type**: Web-based Inspection Management

---

## 👥 User Roles

### Manager Role
**Responsibilities**: Task Setup & Assignment (Pre-Inspection)

**Can Access:**
- Equipment Type selection (5 options)
- Equipment Tag Number entry and validation
- Area selection (5 options)
- Required Inspection Sections selection
- Inspector assignment
- Due Date setting
- View auto-generated Inspection ID and Report Number

**Cannot Access:**
- Inspection findings
- Condition assessments
- Photos from inspection
- Section recommendations
- Overall summary fields

### Inspector Role
**Responsibilities**: Inspection Execution & Reporting

**Can Access:**
- View assigned task details (read-only)
- Enter findings for each section
- Select condition for each section
- Upload photos (minimum 1 per section)
- Select recommendations for each section
- Fill overall summary (Page 1)

**Cannot Access:**
- Equipment type modification
- Area modification
- Inspector reassignment
- Due date modification
- Required sections modification

---

## 🔴 MANAGER USER GUIDE

### Accessing the System

1. **Login**
   - Navigate to http://localhost:8080
   - Enter your manager credentials
   - Click "Login"

2. **Dashboard**
   - View inspection statistics
   - See recent activities
   - Access management functions

### Assigning an Inspection Task

#### Step 1: Navigate to Assign Task
- Click "Assign Task" in the sidebar
- Or click "Assign New Task" button on dashboard

#### Step 2: Fill Task Details

**1. Task Title**
- Enter a descriptive title for the inspection
- Example: "Annual Pressure Vessel Inspection - Unit 2"

**2. Equipment Type** (Required)
Select from EXACTLY 5 options:
- **Reactor**: For reaction vessels and reactors
- **Pressure Vessel**: For pressure-containing equipment
- **Heat Exchanger**: For heat transfer equipment
- **Storage Tank**: For storage vessels
- **Tower**: For distillation towers and columns

**3. Equipment Tag Number** (Required)
- Format depends on equipment type:
  - Reactor: **R** + 3 digits (e.g., R001, R099)
  - Pressure Vessel: **P** + 3 digits (e.g., P001)
  - Heat Exchanger: **H** + 3 digits (e.g., H001)
  - Storage Tank: **T** + 3 digits (e.g., T001)
  - Tower: **TW** + 3 digits (e.g., TW001)
- Use auto-generate button for quick tag creation
- Or enter manually following the format

**Format Validation:**
- ✅ VALID: R001, P142, H023, T050, TW007
- ❌ INVALID: R1 (not 3 digits), A001 (wrong prefix), R1234 (too many digits)

**4. Area** (Required)
Select from EXACTLY 5 options:
- **Plant 1**: Main processing plant
- **Plant 2**: Secondary processing plant
- **Utility Area**: Utilities section
- **Offsite Area**: Outside main plant boundary
- **Process Area**: Core process units

**5. Required Inspection Sections** (Required)
Select which sections the inspector must complete:
- ☑ **External Visual Inspection**: Shell, heads, nozzles, supports
- ☐ **Weld Visual Inspection**: Visual inspection of welds (No NDT)
- ☐ **Internal Inspection**: Internal surfaces (if accessible)
- ☐ **Thickness Inspection**: Thickness measurements

**Note**: At least ONE section must be selected.

**6. Assigned Inspector** (Required)
- Select from dropdown of active inspectors
- Shows inspector name and staff ID

**7. Due Date** (Required)
- Click calendar icon
- Select target completion date
- Must be a future date

#### Step 3: Submit Task

- Review all entered information
- Click "Assign Task" button
- Wait for confirmation dialog

#### Step 4: Note Auto-Generated IDs

After successful submission, a dialog appears showing:

**Auto-Generated Reference Numbers:**
- **Inspection ID**: INS-2024-XXX
  - Format: INS-{YEAR}-{SequentialNumber}
  - Example: INS-2024-001, INS-2024-002
  - Unique identifier for tracking

- **Report Number**: RPT-2024-XXX
  - Format: RPT-{YEAR}-{SequentialNumber}
  - Example: RPT-2024-001
  - Used for final report reference

**Important**: Write down these IDs for future reference!

#### Step 5: Confirmation
- Click "Close" to return to dashboard
- Task is now assigned to inspector
- Inspector will see it in their "Pending Tasks"

### Best Practices for Managers

1. **Equipment Tagging**
   - Use consistent numbering within each type
   - Keep a master list of all equipment tags
   - Don't reuse tags

2. **Section Selection**
   - Only select sections that are necessary
   - Consider equipment accessibility
   - Discuss with inspector if unsure

3. **Due Dates**
   - Allow adequate time for inspection
   - Consider inspector workload
   - Factor in equipment downtime windows

4. **Inspector Assignment**
   - Match inspector expertise to equipment type
   - Check inspector availability
   - Distribute workload evenly

---

## 🔵 INSPECTOR USER GUIDE

### Accessing Assigned Tasks

1. **Login**
   - Navigate to http://localhost:8080
   - Enter your inspector credentials
   - Click "Login"

2. **View Pending Tasks**
   - Click "Pending Tasks" in sidebar
   - See list of tasks assigned to you
   - Select a task to begin inspection

### Starting an Inspection

#### Step 1: Select Inspection Method
- Choose **"Manual Inspection"**
- Click to proceed to inspection form
- (Automated option coming soon)

#### Step 2: Review Task Details
View (but cannot edit) manager-assigned information:
- Equipment Type
- Equipment Tag
- Area
- Due Date
- Required Sections

### Completing Inspection Sections

You will see ONLY the sections selected by the manager.

#### External Visual Inspection

**1. Finding** (Required *)
- Text field for observations
- Example: "No visible corrosion on shell. Minor rust on support brackets at base."
- Be specific and detailed

**2. Condition** (Required *)
Select ONE:
- **Satisfactory** ✓ (Green): Equipment is in good condition
- **Observation** ⚠ (Orange): Issues noted requiring attention

**3. Photo Evidence** (Required - Minimum 1)
- Click "Upload Photos"
- Select photos from your device
- Multiple photos allowed and encouraged
- Take clear, well-lit photos
- Include overall view and close-ups of issues

**4. Section Recommendation** (Required *)
Select ONE:
- **Nil**: No action required
- **Monitor**: Continue monitoring, action may be needed eventually

**5. Additional Notes** (Optional)
- Any extra observations
- Detailed recommendations
- Follow-up suggestions

#### Weld Visual Inspection

Same fields as External Visual:
- Finding *
- Condition * (Satisfactory/Observation)
- Photos * (Minimum 1)
- Section Recommendation * (Nil/Monitor)
- Additional Notes

**Focus on**: Weld joints, weld quality, no cracks or defects

#### Internal Inspection

**Accessibility Toggle**:
- First, indicate if internal access was possible
- Toggle "Internal Inspection Accessible?"

**If YES** (Accessible):
- Finding *
- Condition *
- Photos *
- Section Recommendation *
- Additional Notes

**If NO** (Not Accessible):
- System records "Internal inspection not performed"
- No further input required

#### Thickness Measurement

**Measurements Table**:
- Click "Add Thickness Measurement"
- For each measurement point:
  - **Location**: Where measured (e.g., "Shell CML-1", "Head North CML-2")
  - **Thickness (mm)**: Measured value
  - **Remarks**: Any notes about this point
- Add multiple measurements as needed
- Can delete measurements if needed

**After all measurements**:
- **Overall Thickness Condition** * (Satisfactory/Observation)
- **Section Recommendation** * (Nil/Monitor)

### Completing Page 1 Summary

After completing ALL required sections, fill the overall summary:

**1. Overall Finding** (Required *)
- Comprehensive summary of entire inspection
- Synthesize all section findings
- Example: "Overall equipment condition is satisfactory. External surfaces show minor weathering appropriate for age. All welds appear sound with no cracks detected. Thickness measurements within acceptable range."

**2. Overall Recommendation** (Required *)
- Your professional recommendation
- Example: "Continue with routine inspection schedule. Monitor support bracket rust and repaint during next shutdown. No immediate action required."

**3. Additional Comments** (Optional)
- Any other relevant information
- Suggestions for next inspection
- Special considerations

### Submitting the Report

#### Pre-Submission Checklist:
- ✓ All required sections completed
- ✓ All findings filled in
- ✓ All conditions selected
- ✓ All photos uploaded (minimum 1 per section)
- ✓ All recommendations selected
- ✓ Overall summary completed

#### Submit Process:
1. Click "Submit Report" button at bottom
2. System validates all required fields
3. If validation fails:
   - Error dialog shows missing items
   - Review and complete missing fields
   - Try again
4. If validation passes:
   - Report generates successfully
   - Success confirmation appears
   - Task marked as complete

### Validation Error Messages

If you see these errors, take action:

| Error Message | Action Required |
|---------------|-----------------|
| "External Visual: Finding is required" | Fill the Finding text field |
| "External Visual: Condition is required" | Select Satisfactory or Observation |
| "External Visual: Section Recommendation is required" | Select Nil or Monitor |
| "External Visual: At least 1 photo required" | Upload minimum 1 photo |
| "Summary: Overall Recommendation is required" | Fill Overall Recommendation field |

### Best Practices for Inspectors

1. **Photo Documentation**
   - Take photos before starting (overall view)
   - Take close-ups of any issues
   - Include scale references when possible
   - Ensure good lighting
   - Take more photos than minimum required

2. **Findings Documentation**
   - Be specific and objective
   - Use technical terminology
   - Quantify when possible (e.g., "rust area approximately 10cm x 5cm")
   - Note locations precisely

3. **Condition Assessment**
   - **Satisfactory**: Use when equipment meets standards with no significant issues
   - **Observation**: Use when issues exist but don't require immediate action

4. **Recommendations**
   - **Nil**: Everything is acceptable, no action needed
   - **Monitor**: Issues noted, should be watched, may need future action

5. **Overall Summary**
   - Read through all your section findings first
   - Synthesize key points
   - Highlight critical items
   - Be clear about urgency

---

## 🔧 TECHNICAL SPECIFICATIONS

### Equipment Type Options
| Equipment Type | Prefix | Example Tag | Typical Use |
|----------------|--------|-------------|-------------|
| Reactor | R | R001 | Reaction vessels |
| Pressure Vessel | P | P001 | Pressure equipment |
| Heat Exchanger | H | H001 | Heat transfer |
| Storage Tank | T | T001 | Storage vessels |
| Tower | TW | TW001 | Distillation towers |

### Area Options
| Area | Description |
|------|-------------|
| Plant 1 | Main processing plant |
| Plant 2 | Secondary processing plant |
| Utility Area | Utilities and support systems |
| Offsite Area | Outside main plant boundary |
| Process Area | Core process units |

### Condition Values
| Value | Meaning | Icon |
|-------|---------|------|
| Satisfactory | Equipment meets standards | ✓ Green checkmark |
| Observation | Issues noted, monitoring needed | ⚠ Orange warning |

### Recommendation Values
| Value | Meaning |
|-------|---------|
| Nil | No action required |
| Monitor | Continue monitoring |

---

## 🆘 TROUBLESHOOTING

### Common Issues and Solutions

**Issue**: Cannot select equipment type
- **Solution**: Ensure you're logged in as Manager, refresh page

**Issue**: Equipment tag validation error
- **Solution**: Check prefix matches equipment type, ensure exactly 3 digits after prefix

**Issue**: Inspector doesn't see assigned sections
- **Solution**: Verify manager selected required sections when assigning task

**Issue**: Cannot submit - validation errors
- **Solution**: Check all required fields marked with *, upload photos, select all dropdowns

**Issue**: Auto-generated IDs not showing
- **Solution**: Ensure backend is running, check network connection

**Issue**: Photos not uploading
- **Solution**: Check photo file size (max 5MB), use JPG or PNG format

---

## 📞 SUPPORT

For technical support:
- **System Administrator**: [Contact Info]
- **Help Desk**: [Contact Info]
- **Documentation**: `.agent/` folder in project directory

For training:
- **User Manual**: This document
- **Video Tutorials**: [Link if available]
- **Testing Checklist**: `TESTING_CHECKLIST.md`

---

## 📊 APPENDIX

### Keyboard Shortcuts
- **Tab**: Move between fields
- **Enter**: Submit forms (when button is focused)
- **Esc**: Close dialogs

### Data Retention
- Inspection records: Retained permanently
- Photos: Stored with inspection
- Auto-generated IDs: Unique and permanent

### Security
- Role-based access control enforced
- All actions logged
- Data encrypted in transit
- Session timeout after 30 minutes of inactivity

### System Requirements
- **Browser**: Chrome, Firefox, Edge (latest versions)
- **Internet**: Required for cloud deployment
- **Resolution**: Minimum 1280x720
- **JavaScript**: Must be enabled

---

**Document Version**: 1.0  
**Last Updated**: December 20, 2024  
**Next Review**: As needed based on system updates
