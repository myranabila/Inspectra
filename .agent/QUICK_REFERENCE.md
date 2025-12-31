# Quick Reference Card - Role-Based Inspection System

## 🎯 MANAGER QUICK REFERENCE

### Assign Task - Required Fields
1. **Equipment Type** (5 options)
   - Reactor | Pressure Vessel | Heat Exchanger | Storage Tank | Tower

2. **Equipment Tag** (Format: PREFIX + 3 digits)
   - R001 | P001 | H001 | T001 | TW001

3. **Area** (5 options)
   - Plant 1 | Plant 2 | Utility Area | Offsite Area | Process Area

4. **Required Sections** (Check 1-4)
   - ☑ External | ☑ Weld | ☑ Internal | ☑ Thickness

5. **Inspector** (Select from dropdown)

6. **Due Date** (Future date)

### Auto-Generated IDs
✅ **Inspection ID**: INS-2024-XXX
✅ **Report Number**: RPT-2024-XXX

---

## 🎯 INSPECTOR QUICK REFERENCE

### Per-Section Fields (All Requiredannot*)
1. **Finding** - Detailed observations
2. **Condition** - Satisfactory ✓ OR Observation ⚠
3. **Photo** - Minimum 1 (more recommended)
4. **Section Recommendation** - Nil OR Monitor
5. **Additional Notes** - Optional details

### Page 1 Summary (Required*)
1. **Overall Finding** - Comprehensive summary
2. **Overall Recommendation** - Professional recommendation
3. **Additional Comments** - Optional

### Pre-Submit Checklist
- ✓ All findings filled
- ✓ All conditions selected
- ✓ All photos uploaded (min 1 each)
- ✓ All recommendations selected
- ✓ Overall summary complete

---

## 📋 DROPDOWN OPTIONS CHEAT SHEET

| Field | Options |
|-------|---------|
| Equipment Type | Reactor, Pressure Vessel, Heat Exchanger, Storage Tank, Tower |
| Area | Plant 1, Plant 2, Utility Area, Offsite Area, Process Area |
| Condition | Satisfactory, Observation |
| Section Recommendation | Nil, Monitor |

---

## 🚨 COMMON ERRORS & FIXES

| Error | Fix |
|-------|-----|
| "Condition is required" | Select Satisfactory or Observation |
| "At least 1 photo required" | Upload minimum 1 photo |
| "Overall Recommendation is required" | Fill the Overall Recommendation field |
| Invalid equipment tag | Check prefix matches type (R, P, H, T, TW) + 3 digits |

---

## 🔗 SYSTEM ACCESS

**URL**: http://localhost:8080
**Manager Login**: manager@example.com
**Inspector Login**: inspector@example.com

---

## 📞 SUPPORT

- **Testing Checklist**: `.agent/TESTING_CHECKLIST.md`
- **User Guide**: `.agent/USER_DOCUMENTATION.md`
- **Implementation Summary**: `.agent/IMPLEMENTATION_SUMMARY.md`

---

**Quick Tip**: All fields marked with * are required!
