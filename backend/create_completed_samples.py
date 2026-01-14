import sqlite3
import os
from datetime import datetime, timedelta
import random

def create_sample_completed_inspections():
    """Create a few completed inspections with mock PDF paths for testing"""
    
    db_path = 'inspectra.db'
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("=" * 60)
    print("CREATING SAMPLE COMPLETED INSPECTIONS")
    print("=" * 60)
    
    # Get inspectors
    cursor.execute("SELECT id, username FROM users WHERE role='inspector'")
    inspectors = cursor.fetchall()
    
    if not inspectors:
        print("❌ No inspectors found!")
        conn.close()
        return
    
    # Equipment types
    equipment_types = ["Pressure Vessel", "Heat Exchanger", "Compressor"]
    locations = ["Offshore Platform Alpha", "Refinery Unit 4", "Storage Area"]
    
    # Create reports directory if it doesn't exist
    reports_dir = os.path.join(os.path.dirname(__file__), 'reports', 'generated')
    os.makedirs(reports_dir, exist_ok=True)
    
    # Create 3 completed inspections
    completed_inspections = []
    current_date = datetime.now()
    
    for i in range(1, 4):
        inspector_id, inspector_name = random.choice(inspectors)
        eq_type = equipment_types[i-1]
        
        # Equipment prefix mapping
        eq_code_map = {
            "Pressure Vessel": "PV",
            "Heat Exchanger": "HE",
            "Compressor": "C"
        }
        eq_prefix = eq_code_map.get(eq_type, "EQ")
        tag_num = f"{eq_prefix}-{random.randint(100, 999)}-{random.choice(['A', 'B'])}"
        
        location = locations[i-1]
        title = f"{eq_type} Inspection - {tag_num}"
        
        # Dates
        completion_date = (current_date - timedelta(days=random.randint(1, 10))).strftime('%Y-%m-%d')
        scheduled_date = (current_date - timedelta(days=random.randint(15, 30))).strftime('%Y-%m-%d')
        
        # Generate IDs
        date_str = current_date.strftime('%Y%m%d')
        inspection_id_display = f"INS-{date_str}-{9000+i:04d}"
        report_number = f"RPT-{date_str}-{9000+i:04d}"
        dosh_number = f"DOSH/2026/{random.randint(50000, 59999)}"
        
        # Create a simple mock PDF file name
        pdf_filename = f"inspection_{9000+i}_{current_date.strftime('%Y%m%d_%H%M%S')}.pdf"
        pdf_report_path = f"reports/generated/{pdf_filename}"
        
        # Create a placeholder PDF file (empty for now, just to test the path)
        pdf_full_path = os.path.join(reports_dir, pdf_filename)
        with open(pdf_full_path, 'wb') as f:
            f.write(b'%PDF-1.4\n%%EOF\n')  # Minimal valid PDF
        
        completed_inspections.append((
            inspection_id_display,
            report_number,
            title,
            tag_num,
            eq_type,
            dosh_number,
            location,
            location,
            scheduled_date,
            completion_date,
            'completed',
            inspector_id,
            pdf_report_path,
            1,  # require_external
            0,  # require_weld
            0,  # require_internal
            0,  # require_thickness
            0,  # rejection_count
            current_date.strftime('%Y-%m-%d %H:%M:%S'),
            current_date.strftime('%Y-%m-%d %H:%M:%S')
        ))
        
        print(f"✓ Created: {title}")
        print(f"  - PDF Path: {pdf_report_path}")
        print(f"  - Inspector: {inspector_name}")
    
    # Insert into database
    cursor.executemany("""
    INSERT INTO inspections (
        inspection_id_display, report_number, title, equipment_id, equipment_type, dosh_registration,
        location, area, scheduled_date, completion_date, status,
        inspector_id, pdf_report_path,
        require_external, require_weld, require_internal, require_thickness,
        rejection_count, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, completed_inspections)
    
    conn.commit()
    
    # Verify
    cursor.execute("SELECT COUNT(*) FROM inspections WHERE status='completed'")
    count = cursor.fetchone()[0]
    print(f"\n✓ Total completed inspections in database: {count}")
    
    conn.close()
    print("\n✓ Sample completed inspections created successfully!")

if __name__ == "__main__":
    create_sample_completed_inspections()
