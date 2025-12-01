# TROUBLESHOOTING: Messages Not Appearing

## Problem
Adam hantar message kepada Abu, tetapi Abu tidak nampak message tersebut.

## Root Cause Analysis
✅ Backend API - WORKING (tested via Python script)
✅ Database - WORKING (messages saved correctly)
✅ Authentication - WORKING (both users can login)
❓ Flutter UI - Need to verify refresh behavior

## Test Results
```
Test: Adam → Abu message via API
Status: ✅ SUCCESS
- Message ID: 3 created
- Abu received message correctly
- Content: "Hi Abu! This is a test message from Adam."
- Status: unread
```

## Solution Steps

### For Abu (Receiver):
1. **Logout** dari app (jika sedang login)
2. **Login** semula sebagai `abu` / `abu123`
3. **Go to Messages** page
4. **Click refresh button** (🔄 icon di AppBar)
5. **OR Pull down** to refresh (swipe down gesture)

### Alternative (If still not showing):
1. Close Chrome tab completely
2. Re-run Flutter app: `flutter run -d chrome`
3. Login as `abu`
4. Navigate to Messages

### For Adam (Sender):
Selepas send message:
1. Message akan appear dalam **Sent Items** (dengan send icon)
2. Jika nak verify:
   - Logout
   - Login semula
   - Go to Messages
   - Should see message dengan "sent" icon

## Features Added
✅ **Refresh button** di AppBar - Click untuk reload messages manually
✅ **Pull-to-refresh** - Swipe down pada message list
✅ **Better error messages** - Show actual error kalau ada masalah

## Verify Message Flow
1. Login as `adam` → Send message to `abu` → Should see in sent items
2. Logout
3. Login as `abu` → Click refresh → Message should appear with NEW badge
4. Click message → Should mark as read
5. Refresh → NEW badge should disappear

## Common Issues
- ❌ **Not refreshing page** - Solution: Click refresh button atau pull down
- ❌ **Old session** - Solution: Logout and login again
- ❌ **Browser cache** - Solution: Hard refresh (Ctrl+Shift+R) or close tab
- ❌ **Backend not running** - Solution: Check http://127.0.0.1:8000/health

## Debug Commands
Check abu's messages via terminal:
```bash
cd C:\workshop2\Inspectra\backend
python check_abu_messages.py
```

Send test message:
```bash
python test_adam_to_abu.py
```

Check all messages in database:
```bash
python check_all_messages.py
```

## Current System Status
- Backend: ✅ Running on http://127.0.0.1:8000
- Flutter: ✅ Running on Chrome
- Database: ✅ Messages table created
- Users: ✅ adam, abu, ali, manager (all with password: username123)
