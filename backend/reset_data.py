"""Reset database - Clear all inspections and reports for fresh testing"""
import sys
sys.path.insert(0, 'C:/workshop2/Inspectra/backend')

from db import engine, SessionLocal
import models

def reset_data():
    print("=" * 50)
    print("RESETTING INSPECTRA DATABASE")
    print("=" * 50)
    
    db = SessionLocal()
    
    try:
        # Delete all inspections (this cascades to reports)
        deleted_inspections = db.query(models.Inspection).delete()
        print(f"Deleted {deleted_inspections} inspections")
        
        # Delete all reports
        deleted_reports = db.query(models.Report).delete()
        print(f"Deleted {deleted_reports} reports")
        
        db.commit()
        print("\n✅ Database reset complete!")
        print("Users retained (manager/inspector accounts still exist)")
        print("\nYou can now test the fresh system flow.")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    reset_data()
