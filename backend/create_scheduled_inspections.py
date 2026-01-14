import sqlite3
from datetime import datetime, timedelta
import random

def create_scheduled_inspections():
    db_path = 'inspectra.db'
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("=" * 60)
    print("GENERATING 30 SCHEDULED INSPECTIONS")
    print("=" * 60)

    # 1. Clear existing inspections
    cursor.execute("DELETE FROM inspections")
    cursor.execute("DELETE FROM sqlite_sequence WHERE name='inspections'")
    print("\n✓ Cleared all existing inspections.")

    # 2. Get Inspectors
    cursor.execute("SELECT id, username FROM users WHERE role='inspector'")
    inspectors = cursor.fetchall()
    
    if not inspectors:
        print("❌ No inspectors found!")
        return

    print(f"✓ Found {len(inspectors)} inspectors: {[i[1] for i in inspectors]}")

    # 3. Define Location-Specific Equipment Types (from dropdown specification)
    location_equipment_map = {
        "Process Area": [
            "Pressure Vessel",
            "Reactor",
            "Separator",
            "Heat Exchanger",
            "Column"
        ],
        "Utility Area": [
            "Air Receiver",
            "Nitrogen Vessel",
            "Utility Pressure Vessel",
            "Boiler"
        ],
        "Main Deck": [
            "Pressure Vessel",
            "Skid-mounted"
        ],
        "Wellhead Area": [
            "Pressure Vessel",
            "Separator",
            "Manifold Vessel"
        ],
        "Offsite Facilities": [
            "Air Receiver",
            "Utility Pressure Vessel",
            "Small Storage Vessel"
        ]
    }

    # Equipment prefix mapping
    equipment_prefix_map = {
        "Pressure Vessel": "PV",
        "Reactor": "RE",
        "Separator": "SEP",
        "Heat Exchanger": "HE",
        "Column": "COL",
        "Air Receiver": "AR",
        "Nitrogen Vessel": "NV",
        "Utility Pressure Vessel": "UPV",
        "Boiler": "BLR",
        "Skid-mounted": "SKD",
        "Manifold Vessel": "MV",
        "Small Storage Vessel": "SSV"
    }

    # 4. Generate 30 Tasks
    tasks = []
    current_date = datetime.now()
    
    # Distribution logic
    total_tasks = 30
    tasks_per_inspector = total_tasks // len(inspectors)
    remainder = total_tasks % len(inspectors)

    task_counter = 0
    locations = list(location_equipment_map.keys())

    for idx, (inspector_id, inspector_name) in enumerate(inspectors):
        count = tasks_per_inspector
        if idx < remainder:
            count += 1
            
        for _ in range(count):
            task_counter += 1
            
            # Select location and corresponding equipment type
            location = random.choice(locations)
            available_equipment = location_equipment_map[location]
            eq_type = random.choice(available_equipment)
            
            # Generate equipment tag
            eq_prefix = equipment_prefix_map.get(eq_type, "EQ")
            tag_num = f"{eq_prefix}-{random.randint(100, 999)}-{random.choice(['A', 'B', 'C'])}"
            
            title = f"{eq_type} Inspection - {tag_num}"
            
            # Schedule dates
            days_offset = random.randint(1, 30)
            scheduled_date = (current_date + timedelta(days=days_offset)).strftime('%Y-%m-%d')

            # Generate IDs
            date_str = current_date.strftime('%Y%m%d')
            inspection_id_display = f"INS-{date_str}-{task_counter:04d}"
            report_number = f"RPT-{date_str}-{task_counter:04d}"
            
            # Generate DOSH number
            year = current_date.year
            dosh_number = f"DOSH/{year}/{random.randint(10000, 99999)}"

            # Create Inspection Record
            tasks.append((
                inspection_id_display,
                report_number,
                title,
                tag_num,              # equipment_id
                eq_type,              # equipment_type
                dosh_number,          # dosh_registration
                location,             # location
                location,             # area
                scheduled_date,
                'scheduled',
                inspector_id,
                1,                    # require_external
                0,                    # require_weld
                0,                    # require_internal
                0,                    # require_thickness
                0,                    # rejection_count
                datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            ))

    # 5. Insert into Database
    cursor.executemany("""
    INSERT INTO inspections (
        inspection_id_display, report_number, title, equipment_id, equipment_type, dosh_registration,
        location, area, scheduled_date, status, 
        inspector_id, 
        require_external, require_weld, require_internal, require_thickness,
        rejection_count, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, tasks)

    conn.commit()
    print(f"\n✓ Successfully created {len(tasks)} scheduled inspections.")
    
    # 6. Verify
    cursor.execute("SELECT count(*) FROM inspections WHERE status='scheduled'")
    count = cursor.fetchone()[0]
    print(f"✓ Verification: {count} inspections are in 'scheduled' status.")
    
    # 7. Verify equipment types are location-specific
    print("\n✓ Location-Equipment Distribution:")
    for location in locations:
        cursor.execute("""
            SELECT COUNT(*), GROUP_CONCAT(DISTINCT equipment_type)
            FROM inspections 
            WHERE location = ?
        """, (location,))
        count, types = cursor.fetchone()
        if count:
            print(f"  • {location}: {count} inspections")

    conn.close()

if __name__ == "__main__":
    create_scheduled_inspections()
