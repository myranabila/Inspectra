
import sqlite3
import random
from datetime import datetime, timedelta

def create_exhibition_data():
    conn = sqlite3.connect('inspectra.db')
    cursor = conn.cursor()

    # User IDs from previous check
    MANAGER_ID = 1
    ADAM_ID = 2
    ALI_ID = 3
    ABU_ID = 4

    # Distribution: Adam (16), Ali (10), Abu (4) = 30 Total
    assignments = [
        (ADAM_ID, 16),
        (ALI_ID, 10),
        (ABU_ID, 4)
    ]

    equipment_types = [
        "Pressure Vessel", "Heat Exchanger", "Storage Tank", 
        "Piping Circuit", "Safety Valve", "Pump", "Compressor"
    ]
    
    locations = [
        "Zone A - Process Unit", "Zone B - Storage Area", 
        "Zone C - Utility Block", "Offshore Platform Alpha", 
        "Terminal 2", "Refinery Unit 4"
    ]

    # Generate tasks
    tasks = []
    task_count = 0
    
    current_date = datetime.now()

    print(f"Generating 30 tasks...")

    for inspector_id, count in assignments:
        for i in range(count):
            task_count += 1
            
            # Randomize details
            eq_type = random.choice(equipment_types)
            tag_num = f"{eq_type[0].upper()}-{random.randint(100, 999)}-{random.choice(['A', 'B', 'C'])}"
            location = random.choice(locations)
            
            # Create a realistic title
            title = f"{eq_type} Inspection - {tag_num}"
            
            # Date distribution:
            # 20% Overdue (past 1-7 days)
            # 20% Due Today
            # 30% Due Tomorrow/This Week
            # 30% Due Later
            rand_val = random.random()
            if rand_val < 0.2:
                # Overdue
                days_offset = random.randint(-7, -1)
            elif rand_val < 0.4:
                # Today
                days_offset = 0
            elif rand_val < 0.7:
                # Next few days
                days_offset = random.randint(1, 5)
            else:
                # Next week +
                days_offset = random.randint(6, 14)
                
            scheduled_date = (current_date + timedelta(days=days_offset)).strftime('%Y-%m-%d %H:%M:%S')

            # Scope booleans (randomize slightly)
            require_pressure = random.choice([True, False])
            require_weld = random.choice([True, False])
            require_internal = random.choice([True, False])
            # Ensure at least one is true
            if not (require_pressure or require_weld or require_internal):
                require_pressure = True


            task = (
                title,
                equipment_id := tag_num,
                equipment_type := eq_type,
                location,
                location, # Map to 'area' as well
                scheduled_date,
                'scheduled', # Status
                inspector_id,
                # Scope fields
                1 if require_pressure else 0,

                1 if require_weld else 0,
                1 if require_internal else 0,
                0, # require_thickness
                0  # rejection_count
            )
            tasks.append(task)

    print("Inserting tasks into database...")
    
    # Corrected schema: removed manager_id, added area
    cursor.executemany("""
    INSERT INTO inspections (
        title, equipment_id, equipment_type, location, area, scheduled_date, status, 
        inspector_id, 
        require_external, require_weld, require_internal, require_thickness,
        rejection_count
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, tasks)

    conn.commit()
    print(f"Successfully created {len(tasks)} tasks.")
    
    # Verify counts
    print("\nVerifying distribution:")
    cursor.execute("SELECT u.username, COUNT(i.id) FROM inspections i JOIN users u ON i.inspector_id = u.id GROUP BY u.username")
    results = cursor.fetchall()
    for row in results:
        print(f"{row[0]}: {row[1]} tasks")

    conn.close()

if __name__ == "__main__":
    create_exhibition_data()
