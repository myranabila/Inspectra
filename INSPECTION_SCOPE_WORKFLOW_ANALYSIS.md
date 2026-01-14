# Inspection Scope Workflow - Analysis & Issues

## 🔍 **Workflow Analysis**

### **Current Flow:**
1. ✅ Manager assigns task → Saves scope correctly
2. ✅ Backend sends scope to inspector → All API endpoints include scope
3. ❌ **Inspector workflow page** → NOT using the scope data!
4. ❓ Inspector submits → Unknown if scope is validated
5. ❓ Manager reviews → Unknown if scope is shown
6. ❓ Manager rejects → Unknown if scope persists

---

## ❌ **Issues Found:**

### **Issue #1: Inspector Workflow NOT Using Scope (CRITICAL)**
**File**: `lib/inspection_workflow_page.dart`
**Problem**: 
- Lines 34-37 declare scope variables (`_requireExternal`, `_requireWeld`, etc.)
- **NEVER initialized** from `widget.inspection` data
- Inspector sees ALL sections regardless of what manager assigned

**Impact**: 
- Inspector wastes time on sections not required
- Inconsistent with manager's assignment
- Reports may include unrequested data

**Fix Needed**:
```dart
@override
void initState() {
  super.initState();
  
  // Initialize scope from inspection data
  _requireExternal = widget.inspection['require_external'] ?? true;
  _requireWeld = widget.inspection['require_weld'] ?? false;
  _requireInternal = widget.inspection['require_internal'] ?? false;
  _requireThickness = widget.inspection['require_thickness'] ?? false;
  
  // ... rest of init
}
```

---

### **Issue #2: Scope Not Displayed in Inspection Details**
**Problem**: Inspector cannot see what sections manager requires
**Fix Needed**: Add scope indicators in inspection details view

---

### **Issue #3: Rejection Workflow - Scope Persistence**
**Need to verify**:
- When manager rejects and sends back to inspector
- Does the scope requirement persist?
- Does inspector still see only required sections?

---

## ✅ **What's Working:**

1. ✅ **Manager Assignment** (`backend/manager.py` lines 114-117)
   - Correctly saves `require_external`, `require_weld`, `require_internal`, `require_thickness`

2. ✅ **Backend API** (`backend/dashboard.py`)
   - `/my-tasks` (lines 65-68)
   - `/history` (lines 135-138)
   - `/inspections/all` (lines 377-380)
   - `/inspections/completed` (lines 417-420)
   - `/inspections/pending-review` (lines 456-459)
   - All send scope data correctly

3. ✅ **Manager Rejection** (`backend/manager.py`)
   - Rejection maintains inspection record (doesn't delete scope)
   - Status changes to 'rejected'
   - Inspector ID maintained

---

## 🔧 **Required Fixes:**

### **Priority 1: Initialize Scope in Inspector Workflow**
File: `lib/inspection_workflow_page.dart`

Add initialization logic to read scope from inspection data and conditionally show/hide sections.

### ** Priority 2: Display Scope in Inspection Card**
Show badges indicating which sections are required:
```
Scope: [External] [Weld] [Internal] [Thickness]
```

### **Priority 3: Validate Submission**
Ensure inspector can only submit data for required sections.

---

## 📋 **Test Checklist:**

- [ ] Manager assigns with specific scope → Inspector sees only those sections
- [ ] Inspector submits → Only required sections included
- [ ] Manager reviews → Sees what was assigned vs what was submitted
- [ ] Manager rejects → Inspector gets task back with same scope
- [ ] Inspector resubmits → Still constrained to original scope

---

**Status**: Issues identified, fixes documented, ready to implement.
