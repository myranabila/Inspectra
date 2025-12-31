"""
Updated Models for Role-Based Inspection System
Add this to backend/models.py - Replace the Inspection class
"""

from sqlalchemy import Column, Integer, String, Enum, TIMESTAMP, Text, Date, ForeignKey, func, Boolean
from sqlalchemy.orm import relationship
from db import Base
import enum
from datetime import datetime

# Enums for strict dropdown values
class EquipmentTypeEnum(str, enum.Enum):
    reactor = "Reactor"
    pressure_vessel = "Pressure Vessel"
    heat_exchanger = "Heat Exchanger"
    storage_tank = "Storage Tank"
    tower = "Tower"

class AreaEnum(str, enum.Enum):
    plant_1 = "Plant 1"
    plant_2 = "Plant 2"
    utility_area = "Utility Area"
    offsite_area = "Offsite Area"
    process_area = "Process Area"

class ConditionEnum(str, enum.Enum):
    satisfactory = "Satisfactory"
    observation = "Observation"

class RecommendationEnum(str, enum.Enum):
    nil = "Nil"
    monitor = "Monitor"


class Inspection(Base):
    __tablename__ = "inspections"
    id = Column(Integer, primary_key=True, index=True)
    
    # AUTO-GENERATED (READ-ONLY) - System fields
    inspection_id_display = Column(String(50), unique=True, nullable=True)  # e.g., "INS-2024-001"
    report_number = Column(String(50), unique=True, nullable=True)  # e.g., "RPT-2024-001"
    
    # MANAGER FIELDS (Pre-Inspection Setup)
    title = Column(String(200), nullable=False)
    equipment_type = Column(Enum(EquipmentTypeEnum), nullable=True)  # Dropdown: 5 options
    equipment_id = Column(String(100), nullable=True)  # Equipment Tag Number (e.g., R001, P001)
    area = Column(Enum(AreaEnum), nullable=True)  # Dropdown: 5 options
    location = Column(String(200), nullable=True)  # DEPRECATED - kept for backward compatibility
    scheduled_date = Column(Date, nullable=True)  # Due Date
    inspector_id = Column(Integer, ForeignKey('users.id'), nullable=True)  # Assigned Inspector
    
    # Required Inspection Sections (Manager Selects)
    require_external = Column(Boolean, default=True, nullable=False)
    require_weld = Column(Boolean, default=False, nullable=False)
    require_internal = Column(Boolean, default=False, nullable=False)
    require_thickness = Column(Boolean, default=False, nullable=False)
    
    # EXTERNAL VISUAL INSPECTION - Inspector Fields
    external_finding = Column(Text, nullable=True)  # Inspector input
    external_condition = Column(Enum(ConditionEnum), nullable=True)  # Dropdown
    external_photos = Column(Text, nullable=True)  # JSON array of photo URLs
    external_recommendation = Column(Enum(RecommendationEnum), nullable=True)  # Dropdown
    
    # WELD VISUAL INSPECTION - Inspector Fields
    weld_finding = Column(Text, nullable=True)
    weld_condition = Column(Enum(ConditionEnum), nullable=True)
    weld_photos = Column(Text, nullable=True)
    weld_recommendation = Column(Enum(RecommendationEnum), nullable=True)
    
    # INTERNAL INSPECTION - Inspector Fields
    internal_finding = Column(Text, nullable=True)
    internal_condition = Column(Enum(ConditionEnum), nullable=True)
    internal_photos = Column(Text, nullable=True)
    internal_recommendation = Column(Enum(RecommendationEnum), nullable=True)
    
    # THICKNESS INSPECTION - Inspector Fields
    thickness_finding = Column(Text, nullable=True)
    thickness_condition = Column(Enum(ConditionEnum), nullable=True)
    thickness_photos = Column(Text, nullable=True)
    thickness_recommendation = Column(Enum(RecommendationEnum), nullable=True)
    
    # OVERALL SUMMARY (Page 1) - Inspector fills after all sections
    overall_finding = Column(Text, nullable=True)  # Summary of all sections
    overall_recommendation = Column(Text, nullable=True)
    additional_comments = Column(Text, nullable=True)
    
    # System Status Fields
    status = Column(Enum(InspectionStatusEnum), default=InspectionStatusEnum.scheduled, nullable=False)
    completion_date = Column(Date, nullable=True)
    notes = Column(Text, nullable=True)  # DEPRECATED - use additional_comments
    
    # Timestamps
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    inspector = relationship("User", back_populates="inspections")
    reports = relationship("Report", back_populates="inspection")


# Helper functions for auto-generation
def generate_inspection_id(db_session):
    """Generate unique inspection ID: INS-YYYY-NNN"""
    year = datetime.now().year
    prefix = f"INS-{year}-"
    
    # Get the highest number for this year
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
    last_inspection = db_session.query(Inspection).filter(
        Inspection.report_number.like(f"{prefix}%")
    ).order_by(Inspection.report_number.desc()).first()
    
    if last_inspection and last_inspection.report_number:
        last_num = int(last_inspection.report_number.split('-')[-1])
        new_num = last_num + 1
    else:
        new_num = 1
    
    return f"{prefix}{new_num:03d}"


def validate_equipment_tag(equipment_type: str, equipment_tag: str) -> tuple[bool, str]:
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
