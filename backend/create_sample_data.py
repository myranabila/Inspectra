import sys
import os
from datetime import datetime, timedelta, date
import random

# Change to backend directory
os.chdir('c:\\workshop2\\Inspectra\\backend')
sys.path.insert(0, 'c:\\workshop2\\Inspectra\\backend')

from db import SessionLocal, engine
import models

# Ensure all tables are created
print("Creating database tables...")
models.Base.metadata.create_all(bind=engine)

# Sample data
inspection_titles = [
    "Building A Inspection",
    "Office Safety Audit",
    "Electrical Inspection",
    "Fire Safety Check",
    "HVAC System Review",
    "Plumbing Inspection",
    "Structural Assessment",
    "Security System Audit",
    "Rooftop Safety Inspection",
    "Emergency Exit Verification"
]

locations = [
    "Main Building - Floor 1",
    "Office Complex - Tower A",
    "Warehouse District",
    "Manufacturing Plant",
    "Corporate Headquarters",
    "Research Facility",
    "Parking Structure B",
    "Main Entrance Lobby"
]

report_titles = [
    "Monthly Safety Report",
    "Compliance Audit Results",
    "Quarterly Inspection Summary",
    "Annual Review Document",
    "Emergency Preparedness Report",
    "Equipment Maintenance Report",
    "Safety Violation Report",
    "Corrective Action Report"
]

def create_sample_data():
    db = SessionLocal()
    
    # Get existing users
    users = db.query(models.User).all()
    if not users:
        print("No users found! Creating default users...")
        
        # Create default users with argon2 hashing
        from argon2 import PasswordHasher
        ph = PasswordHasher()
        
        default_users_data = [
            ('manager', 'manager@inspectra.com', models.RoleEnum.manager),
            ('adam', 'adam@inspectra.com', models.RoleEnum.inspector),
            ('ali', 'ali@inspectra.com', models.RoleEnum.inspector),
            ('abu', 'abu@inspectra.com', models.RoleEnum.inspector),
        ]
        
        for username, email, role in default_users_data:
            user = models.User(
                username=username,
                password_hash=ph.hash(f'{username}123'),  # password is username123
                email=email,
                role=role,
                phone=f'012345{random.randint(1000, 9999)}'
            )
            db.add(user)
        
        db.commit()
        users = db.query(models.User).all()
        print(f"Created {len(users)} default users")
    
    print(f"Found {len(users)} users in database")
    
    # Create inspections for the last 3 months
    today = date.today()
    inspections_created = 0
    
    for month_offset in range(3):
        # Calculate the target month
        target_month = today.month - month_offset
        target_year = today.year
        
        if target_month <= 0:
            target_month += 12
            target_year -= 1
        
        # Create 20-30 inspections per month
        num_inspections = random.randint(20, 30)
        
        for i in range(num_inspections):
            # Random date in the target month
            day = random.randint(1, 28)
            insp_date = date(target_year, target_month, day)
            
            # Determine status based on date
            if month_offset == 0:  # Current month
                status_choices = [
                    models.InspectionStatusEnum.scheduled,
                    models.InspectionStatusEnum.pending_review,
                    models.InspectionStatusEnum.rejected,
                    models.InspectionStatusEnum.completed
                ]
                status = random.choice(status_choices)
            else:  # Past months
                status_choices = [
                    models.InspectionStatusEnum.completed,
                    models.InspectionStatusEnum.pending_review
                ]
                status = random.choice(status_choices)
            
            completion_date = None
            if status == models.InspectionStatusEnum.completed:
                completion_date = insp_date + timedelta(days=random.randint(1, 7))
            
            inspection = models.Inspection(
                title=random.choice(inspection_titles),
                location=random.choice(locations),
                status=status,
                scheduled_date=insp_date,
                completion_date=completion_date,
                notes=f"Inspection created for {insp_date.strftime('%B %Y')}",
                inspector_id=random.choice(users).id,
                created_at=datetime(target_year, target_month, day, random.randint(8, 17), random.randint(0, 59))
            )
            
            db.add(inspection)
            inspections_created += 1
    
    db.commit()
    print(f"✓ Created {inspections_created} inspections")
    
    # Create reports for some inspections
    all_inspections = db.query(models.Inspection).all()
    reports_created = 0
    
    for inspection in all_inspections:
        # 70% chance to have a report
        if random.random() < 0.7:
            # Determine report status
            if inspection.status == models.InspectionStatusEnum.completed:
                report_status = random.choice([
                    models.ReportStatusEnum.approved,
                    models.ReportStatusEnum.pending_review
                ])
            elif inspection.status == models.InspectionStatusEnum.pending_review:
                report_status = models.ReportStatusEnum.pending_review
            else:
                report_status = models.ReportStatusEnum.draft
            
            report = models.Report(
                title=random.choice(report_titles),
                inspection_id=inspection.id,
                status=report_status,
                content=f"Report for {inspection.title}",
                findings="Sample findings for the inspection",
                recommendations="Sample recommendations based on findings",
                created_by=inspection.inspector_id,
                created_at=inspection.created_at + timedelta(hours=random.randint(1, 24))
            )
            
            db.add(report)
            reports_created += 1
    
    db.commit()
    print(f"✓ Created {reports_created} reports")
    
    # Print summary statistics
    print("\n" + "="*60)
    print("SAMPLE DATA SUMMARY")
    print("="*60)
    
    total_inspections = db.query(models.Inspection).count()
    scheduled = db.query(models.Inspection).filter(
        models.Inspection.status == models.InspectionStatusEnum.scheduled
    ).count()
    rejected = db.query(models.Inspection).filter(
        models.Inspection.status == models.InspectionStatusEnum.rejected
    ).count()
    pending_review_insp = db.query(models.Inspection).filter(
        models.Inspection.status == models.InspectionStatusEnum.pending_review
    ).count()
    completed = db.query(models.Inspection).filter(
        models.Inspection.status == models.InspectionStatusEnum.completed
    ).count()
    
    total_reports = db.query(models.Report).count()
    pending_review_reports = db.query(models.Report).filter(
        models.Report.status == models.ReportStatusEnum.pending_review
    ).count()
    
    # Current month stats
    from sqlalchemy import extract
    current_month = today.month
    current_year = today.year
    
    inspections_this_month = db.query(models.Inspection).filter(
        extract('month', models.Inspection.created_at) == current_month,
        extract('year', models.Inspection.created_at) == current_year
    ).count()
    
    completed_this_month = db.query(models.Inspection).filter(
        models.Inspection.status == models.InspectionStatusEnum.completed,
        extract('month', models.Inspection.completion_date) == current_month,
        extract('year', models.Inspection.completion_date) == current_year
    ).count()
    
    print(f"Total Inspections: {total_inspections}")
    print(f"  - Scheduled: {scheduled}")
    print(f"  - Pending Review: {pending_review_insp}")
    print(f"  - Rejected: {rejected}")
    print(f"  - Completed: {completed}")
    print(f"\nTotal Reports: {total_reports}")
    print(f"  - Pending Review: {pending_review_reports}")
    print(f"\nThis Month ({today.strftime('%B %Y')}):")
    print(f"  - New Inspections: {inspections_this_month}")
    print(f"  - Completed: {completed_this_month}")
    print("="*60)
    
    db.close()
    print("\n✓ Sample data created successfully!")

if __name__ == "__main__":
    create_sample_data()
