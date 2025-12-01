"""
Clear all inspection and report data - Fresh start for new system
"""
from db import SessionLocal
import models

def clear_all_data():
    db = SessionLocal()
    
    try:
        # Count before delete
        inspections_count = db.query(models.Inspection).count()
        reports_count = db.query(models.Report).count()
        
        print(f"\n📊 Current Data:")
        print(f"   Inspections: {inspections_count}")
        print(f"   Reports: {reports_count}")
        
        # Delete all inspections and reports
        db.query(models.Report).delete()
        db.query(models.Inspection).delete()
        db.commit()
        
        print(f"\n✅ All data cleared!")
        print(f"   System is now fresh with 0 inspections and 0 reports")
        
        # Verify
        inspections_after = db.query(models.Inspection).count()
        reports_after = db.query(models.Report).count()
        
        print(f"\n📊 After Clear:")
        print(f"   Inspections: {inspections_after}")
        print(f"   Reports: {reports_after}")
        
        # Show existing users (we keep users)
        users = db.query(models.User).all()
        print(f"\n👥 Existing Users (kept):")
        for user in users:
            print(f"   - {user.username} ({user.role.value}): {user.full_name}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("=" * 60)
    print("🗑️  CLEARING ALL INSPECTION & REPORT DATA")
    print("=" * 60)
    
    confirm = input("\n⚠️  This will delete ALL inspections and reports. Continue? (yes/no): ")
    
    if confirm.lower() == 'yes':
        clear_all_data()
    else:
        print("\n❌ Cancelled. No data deleted.")
