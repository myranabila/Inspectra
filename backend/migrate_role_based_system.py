"""
Database Migration Script for Role-Based Inspection System
Add new fields and modify existing ones for strict role separation
"""

from sqlalchemy import Column, String, Integer, Enum, Boolean
from db import engine, Base

def upgrade():
    """Add new fields to inspections table"""
    
    # SQL commands to add new columns
    migration_sql = """
    -- Add auto-generated IDs (read-only)
    ALTER TABLE inspections ADD COLUMN inspection_id_display VARCHAR(50) UNIQUE;
    ALTER TABLE inspections ADD COLUMN report_number VARCHAR(50) UNIQUE;
    
    -- Add area field (replaces location for dropdown)
    ALTER TABLE inspections ADD COLUMN area VARCHAR(100);
    
    -- Add per-section inspector fields
    ALTER TABLE inspections ADD COLUMN external_condition VARCHAR(50);
    ALTER TABLE inspections ADD COLUMN external_recommendation VARCHAR(50);
    ALTER TABLE inspections ADD COLUMN external_finding TEXT;
    
    ALTER TABLE inspections ADD COLUMN weld_condition VARCHAR(50);
    ALTER TABLE inspections ADD COLUMN weld_recommendation VARCHAR(50);
    ALTER TABLE inspections ADD COLUMN weld_finding TEXT;
    
    ALTER TABLE inspections ADD COLUMN internal_condition VARCHAR(50);
    ALTER TABLE inspections ADD COLUMN internal_recommendation VARCHAR(50);
    ALTER TABLE inspections ADD COLUMN internal_finding TEXT;
    
    ALTER TABLE inspections ADD COLUMN thickness_condition VARCHAR(50);
    ALTER TABLE inspections ADD COLUMN thickness_recommendation VARCHAR(50);
    ALTER TABLE inspections ADD COLUMN thickness_finding TEXT;
    
    -- Add overall summary fields
    ALTER TABLE inspections ADD COLUMN overall_finding TEXT;
    ALTER TABLE inspections ADD COLUMN overall_recommendation TEXT;
    ALTER TABLE inspections ADD COLUMN additional_comments TEXT;
    
    -- Create indexes for performance
    CREATE INDEX idx_inspection_id_display ON inspections(inspection_id_display);
    CREATE INDEX idx_report_number ON inspections(report_number);
    CREATE INDEX idx_area ON inspections(area);
    """
    
    print("Running migration...")
    with engine.connect() as conn:
        for statement in migration_sql.split(';'):
            if statement.strip():
                try:
                    conn.execute(statement)
                    print(f"✓ Executed: {statement.strip()[:50]}...")
                except Exception as e:
                    print(f"✗ Error: {e}")
    
    print("Migration completed!")

def downgrade():
    """Remove added fields (rollback)"""
    
    rollback_sql = """
    ALTER TABLE inspections DROP COLUMN inspection_id_display;
    ALTER TABLE inspections DROP COLUMN report_number;
    ALTER TABLE inspections DROP COLUMN area;
    ALTER TABLE inspections DROP COLUMN external_condition;
    ALTER TABLE inspections DROP COLUMN external_recommendation;
    ALTER TABLE inspections DROP COLUMN external_finding;
    ALTER TABLE inspections DROP COLUMN weld_condition;
    ALTER TABLE inspections DROP COLUMN weld_recommendation;
    ALTER TABLE inspections DROP COLUMN weld_finding;
    ALTER TABLE inspections DROP COLUMN internal_condition;
    ALTER TABLE inspections DROP COLUMN internal_recommendation;
    ALTER TABLE inspections DROP COLUMN internal_finding;
    ALTER TABLE inspections DROP COLUMN thickness_condition;
    ALTER TABLE inspections DROP COLUMN thickness_recommendation;
    ALTER TABLE inspections DROP COLUMN thickness_finding;
    ALTER TABLE inspections DROP COLUMN overall_finding;
    ALTER TABLE inspections DROP COLUMN overall_recommendation;
    ALTER TABLE inspections DROP COLUMN additional_comments;
    """
    
    print("Rolling back migration...")
    with engine.connect() as conn:
        for statement in rollback_sql.split(';'):
            if statement.strip():
                try:
                    conn.execute(statement)
                    print(f"✓ Rolled back: {statement.strip()[:50]}...")
                except Exception as e:
                    print(f"✗ Error: {e}")
    
    print("Rollback completed!")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "downgrade":
        downgrade()
    else:
        upgrade()
