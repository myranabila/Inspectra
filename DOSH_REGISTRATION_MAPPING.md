# DOSH Registration Numbers - Manual Entry System

## Overview
The Inspectra system allows managers to **manually enter DOSH (Department of Occupational Safety and Health) Registration Numbers** when assigning inspection tasks. This approach ensures that each piece of equipment has its correct, unique DOSH registration number as issued by the Malaysian Department of Occupational Safety and Health.

## Why Manual Entry?

DOSH registration numbers are issued **per equipment unit**, not per equipment type:
- Each reactor (`R-001`, `R-002`) has its own DOSH number
- Different pressure vessels have different DOSH numbers
- Numbers are issued by DOSH upon equipment registration/certification

**Manual entry ensures**:
- ✅ Accuracy - Manager enters the actual DOSH certificate number
- ✅ Flexibility - Can handle any DOSH format
- ✅ Real-world compliance - Matches physical DOSH certificates

---

## DOSH Registration Format
`DOSH/PV/[State]/[Year]/[Number]-[Type Code]`

Where:
- **DOSH** = Department of Occupational Safety and Health
- **PV** = Pressure Vessel category
- **State** = State code (SEL=Selangor, JHR=Johor, etc.)
- **Year** = Registration year
- **Number** = Unique sequential number from DOSH
- **Type Code** = Equipment type identifier (optional)

---

## Format Examples by Equipment Type

To help managers, the system provides format hints based on equipment type:

| Equipment Type | Suggested Code | Example Format |
|----------------|----------------|----------------|
| **Reactor** | R | `DOSH/PV/SEL/2024/001-R` |
| **Pressure Vessel** | PV | `DOSH/PV/SEL/2024/002-PV` |
| **Heat Exchanger** | HE | `DOSH/PV/SEL/2024/003-HE` |
| **Storage Tank** | ST | `DOSH/PV/SEL/2024/004-ST` |
| **Tower** | TW | `DOSH/PV/SEL/2024/005-TW` |

**Note**: These are examples only. Managers should enter the actual DOSH number from equipment's registration certificate.

---

## How It Works

### 1. Assignment Phase (Manager)
When assigning an inspection task:
1. Manager selects equipment type (e.g., "Reactor")
2. DOSH field appears with hint: `e.g., DOSH/PV/SEL/2024/001-R`
3. Manager enters **actual DOSH number** from equipment's certificate
4. Field is **optional** - can be left blank for unregistered equipment

### 2. Inspection Phase (Inspector)
- Inspector sees DOSH number in inspection details
- Verifies against physical nameplate/certificate

### 3. Report Generation
- PDF report automatically includes the DOSH registration number
- Shows in header on all pages
- If blank, shows empty (equipment not yet registered)

---

## Consistency Guarantees

✅ **Fixed Numbers** - Each equipment type always gets the same DOSH number  
✅ **No Manual Entry** - Automatically populated, no human error  
✅ **Validation** - System validates equipment types against the mapping  
✅ **Frontend/Backend Sync** - Both systems use identical mappings  

---

## Updating DOSH Numbers (If Needed)

To update DOSH registration numbers in the future:

1. Edit `backend/dosh_config.py`
2. Edit `lib/utils/dosh_config.dart`
3. Ensure both files have identical mappings
4. Restart backend server
5. Hot reload/restart Flutter app

**Note**: Changing DOSH numbers only affects **new reports**. Previously generated PDF reports retain their original DOSH numbers.

---

## Compliance

These DOSH registration numbers follow the standard Malaysian format for pressure vessel registration as required by the **Occupational Safety and Health Act 1994** and **Factories and Machinery (Pressure Vessel) Regulations 1970**.

---

*Last Updated: January 14, 2026*
