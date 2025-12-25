# Quick Test Guide - Inspectra System Flow

## 🚀 Quick Start Testing

### Step 1: Login as Manager
```
URL: http://localhost:8000 (or your frontend URL)
Username: manager
Password: manager123
```

### Step 2: Assign Inspection Task
1. Click sidebar: **"Assign Task"**
2. Fill form:
   - Inspector: Select from dropdown
   - Title: "Tank T-101 API 653 Inspection"
   - Equipment Tag: "T-101"
   - Location: Select location
   - Equipment Type: "API 653"
   - Date: Pick today's date
3. **Check sections to require:**
   - ☑️ External Visual Inspection
   - ☑️ Weld Visual Inspection
   - ☐ Internal Visual Inspection (leave unchecked to test)
   - ☐ Thickness Measurement (leave unchecked to test)
4. Click **"Assign Task"**
5. ✅ Success message appears

---

### Step 3: Login as Inspector
```
Logout, then login:
Username: inspector
Password: inspector123
```

### Step 4: Complete Report
1. Click sidebar: **"Pending Tasks"**
2. Find assigned task (should show "Tank T-101 API 653 Inspection")
3. Click the task card
4. **Verify**: Only Equipment, External, and Weld sections appear (NOT Internal/Thickness)
5. Fill the form:
   - **Equipment Info:**
     - Finding: "Equipment properly labeled and identified"
     - Recommendation: "Continue regular monitoring"
     - Upload 1-2 photos
   
   - **External Visual:**
     - Finding: "Minor surface corrosion observed on north side"
     - Recommendation: "Schedule surface treatment within 30 days"
     - Upload 1-2 photos
   
   - **Weld Visual:**
     - Finding: "All welds intact, no visible cracks"
     - Recommendation: "No immediate action required"
     - Upload 1-2 photos

6. Click **"Generate PDF Preview"**
7. **Test Zoom:**
   - Hold **Ctrl** + scroll mouse wheel up/down
   - Should zoom in/out smoothly
8. Review PDF, then click **"Submit Final Report"**
9. ✅ Success message: "Report Submitted Successfully"

---

### Step 5: Manager Reviews Report
1. Logout and login as manager again
2. Dashboard should show: **Pending Review count = 1**
3. Click sidebar: **"Pending Review"**
4. See the submitted report
5. Click on it to view details
6. Review all information

---

### Step 6: Test Approval Flow
Option A: **Approve the Report**
1. Click **"Approve"** button
2. Add note (optional): "Well done, excellent report"
3. Confirm
4. ✅ Check dashboard: Completed count +1

Option B: **Test Rejection Flow**
1. Click **"Reject"** button
2. Enter reason: "Please provide more detail on corrosion extent"
3. Add feedback: "Specify affected area dimensions and corrosion depth"
4. Confirm
5. ✅ Check dashboard: Rejected count +1

---

### Step 7: Test Resubmission (if rejected)
1. Logout, login as inspector
2. Go to **"Pending Tasks"**
3. See task with **RED "REJECTED"** badge
4. Click to open
5. Update findings with more detail
6. Add more photos if needed
7. Submit again
8. ✅ Task goes back to manager's pending review

---

## ✅ Success Criteria

### If Approval Worked Correctly:
- Inspector's "Pending Tasks" - task disappears
- Inspector's "History" - task appears as completed
- Manager's dashboard - completed count increased
- Database: inspection status = `completed`

### If Rejection Worked Correctly:
- Inspector's "Pending Tasks" - task reappears with RED badge
- Inspector can see rejection reason
- Manager's dashboard - rejected count increased
- Inspector can revise and resubmit
- Database: inspection status = `rejected`

---

## 🎯 Key Things to Verify

1. **Dynamic Sections:**
   - ✅ Only checked sections appear in inspector's form
   - ✅ Unchecked sections are completely hidden

2. **Manager-Defined Title:**
   - ✅ Inspector sees exact title manager entered
   - ✅ Title appears in header of report page

3. **Photos in PDF:**
   - ✅ All uploaded photos appear in PDF
   - ✅ Photos arranged in 3-column table (Photo | Finding | Recommendation)

4. **Zoom Functionality:**
   - ✅ Hold Ctrl + scroll mouse wheel
   - ✅ Works immediately without clicking
   - ✅ Zoom range 25% - 200%
   - ✅ Position persists when releasing Ctrl

5. **Professional UI:**
   - ✅ Gradient red headers
   - ✅ Consistent back buttons (semi-transparent white)
   - ✅ Professional cards and spacing
   - ✅ Status badges with colors

6. **Dashboard Accuracy:**
   - ✅ All counts match actual database states
   - ✅ Pending/History filters work correctly

---

## 📱 Dashboard Count Verification

### Manager Dashboard Should Show:
- Total Inspections: Sum of all
- Scheduled: Tasks assigned but not started
- Pending Review: Tasks submitted by inspectors
- Completed: Tasks approved by manager
- Rejected: Tasks rejected by manager

### Inspector Dashboard Should Show:
- My Tasks: All assigned to this inspector
- Pending: scheduled + rejected (need action)
- Submitted: pending_review (waiting for manager)
- Completed: Approved by manager

---

## 🐛 Common Issues & Solutions

### Issue: Task not appearing for inspector
**Solution:** Check that status is `scheduled` and inspector_id is correct

### Issue: Section not showing in form
**Solution:** Verify manager checked that section during assignment

### Issue: Zoom not working
**Solution:** 
- Ensure Ctrl key is pressed
- Check browser console for errors
- Try full page refresh

### Issue: Photos not in PDF
**Solution:** 
- Verify photos were uploaded
- Check file size (should be < 5MB each)
- Ensure submit completed successfully

### Issue: Dashboard counts wrong
**Solution:**
- Refresh page
- Check backend logs
- Verify database statuses

---

## 🔧 Developer Tools

### Check Backend Logs:
```powershell
# Backend terminal shows all API calls
# Look for:
[POST] /api/manager/assign-task
[GET] /api/dashboard/my-tasks
[POST] /api/dashboard/submit-report
[POST] /api/manager/approve/inspection
[POST] /api/manager/reject/inspection
```

### Check Frontend Console:
```javascript
// Browser DevTools > Console
// Look for:
"[SUCCESS] Task fetched: ..."
"[SUCCESS] Report submitted..."
"Zoom level: 150%"
```

### Database Check:
```sql
-- Check inspection status
SELECT id, title, status, inspector_id, require_external, require_weld 
FROM inspections 
ORDER BY created_at DESC 
LIMIT 10;

-- Check counts
SELECT status, COUNT(*) 
FROM inspections 
GROUP BY status;
```

---

## ✅ Test Complete When:

- [ ] Manager can assign task with custom title
- [ ] Inspector sees only selected sections
- [ ] Photos appear in generated PDF
- [ ] Ctrl+Mouse Wheel zoom works without clicking
- [ ] Report submits successfully
- [ ] Manager sees pending review
- [ ] Approval changes status to completed
- [ ] Rejection sends task back to inspector
- [ ] Inspector can revise and resubmit
- [ ] All dashboard counts are accurate
- [ ] UI looks professional with gradients
- [ ] Back buttons are consistent

---

**All checkboxes marked = System working perfectly! ✅**

## 🎉 System Status

Both services running:
- ✅ Backend: http://localhost:8000
- ✅ Frontend: Chrome (Flutter)

**Ready for testing!**
