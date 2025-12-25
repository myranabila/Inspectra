"""
Helper functions for role-based inspection system
Add this to the end of backend/models.py
"""

from datetime import datetime

def generate_inspection_id(db_session):
    """Generate unique inspection ID: INS-YYYY-NNN"""
    year = datetime.now().year
    prefix = f"INS-{year}-"
    
    # Get the highest number for this year
    from models import Inspection
    last_inspection = db_session.query(Inspection).filter(
        Inspection.inspection_id_display.like(f"{prefix}%")
    ).order_by(Inspection.inspection_id_display.desc()).first()
    
    if last_inspection and last_inspection.inspection_id_display:
        last_num = int(last_inspection.inspection_id_display.split('-')[-1])
        new_num = last_num + 1
    else:
        new_num = 1
    
    return f"{prefix}{new_num:03d}"


def generate_report_number(db_session):
    """Generate unique report number: RPT-YYYY-NNN"""
    year = datetime.now().year
    prefix = f"RPT-{year}-"
    
    # Get the highest number for this year
    from models import Inspection
    last_inspection = db_session.query(Inspection).filter(
        Inspection.report_number.like(f"{prefix}%")
    ).order_by(Inspection.report_number.desc()).first()
    
    if last_inspection and last_inspection.report_number:
        last_num = int(last_inspection.report_number.split('-')[-1])
        new_num = last_num + 1
    else:
        new_num = 1
    
    return f"{prefix}{new_num:03d}"


def validate_equipment_tag(equipment_type: str, equipment_tag: str):
    """
    Validate equipment tag format based on equipment type
    Returns: (is_valid, error_message)
    """
    validation_rules = {
        "Reactor": {"prefix": "R", "format": "R + 3 digits", "example": "R001"},
        "Pressure Vessel": {"prefix": "P", "format": "P + 3 digits", "example": "P001"},
        "Heat Exchanger": {"prefix": "H", "format": "H + 3 digits", "example": "H001"},
        "Storage Tank": {"prefix": "T", "format": "T + 3 digits", "example": "T001"},
        "Tower": {"prefix": "TW", "format": "TW + 3 digits", "example": "TW001"},
    }
    
    if equipment_type not in validation_rules:
        return False, "Invalid equipment type"
    
    rule = validation_rules[equipment_type]
    prefix = rule["prefix"]
    
    # Check if tag starts with correct prefix
    if not equipment_tag.startswith(prefix):
        return False, f"{equipment_type} tag must start with {prefix}. Example: {rule['example']}"
    
    # Check if remaining part is 3 digits
    number_part = equipment_tag[len(prefix):]
    if not (number_part.isdigit() and len(number_part) == 3):
        return False, f"{equipment_type} tag format: {rule['format']}. Example: {rule['example']}"
    
    return True, ""
