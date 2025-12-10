from sqlalchemy import Column, Integer, String, Enum, TIMESTAMP, Text, Date, ForeignKey, func
from sqlalchemy.orm import relationship
from db import Base
import enum

class RoleEnum(str, enum.Enum):
    inspector = "inspector"
    manager = "manager"

class InspectionStatusEnum(str, enum.Enum):
    scheduled = "scheduled"
    pending_review = "pending_review"
    rejected = "rejected"
    completed = "completed"

class ReportStatusEnum(str, enum.Enum):
    draft = "draft"
    pending_review = "pending_review"
    approved = "approved"

class MessageStatusEnum(str, enum.Enum):
    unread = "unread"
    read = "read"

class ReminderStatusEnum(str, enum.Enum):
    pending = "pending"
    sent = "sent"
    dismissed = "dismissed"

class Location(Base):
    __tablename__ = "locations"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), unique=True, nullable=False, index=True)
    description = Column(String(500), nullable=True)
    is_active = Column(Integer, default=1, nullable=False)  # 1 = active, 0 = inactive
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(80), unique=True, nullable=False, index=True)
    staff_id = Column(String(20), unique=True, nullable=False, index=True)  # Auto-generated unique ID for login
    password_hash = Column(String(255), nullable=False)
    email = Column(String(150))
    role = Column(Enum(RoleEnum), default=RoleEnum.inspector, nullable=False)
    phone = Column(String(30), nullable=True)
    profile_picture = Column(String(500), nullable=True)  # URL or path to profile picture
    years_experience = Column(Integer, nullable=True)  # For inspectors
    is_active = Column(Integer, default=1, nullable=False)  # 1 = active, 0 = deactivated
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    last_password_change = Column(TIMESTAMP, nullable=True)
    
    # Relationships
    inspections = relationship("Inspection", back_populates="inspector")
    reports = relationship("Report", back_populates="created_by_user")
    sent_messages = relationship("Message", foreign_keys="Message.sender_id", back_populates="sender")
    received_messages = relationship("Message", foreign_keys="Message.receiver_id", back_populates="receiver")
    reminders = relationship("Reminder", back_populates="user")

class Inspection(Base):
    __tablename__ = "inspections"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    location = Column(String(200))
    equipment_id = Column(String(100), nullable=True)  # Equipment Tag Number
    equipment_type = Column(String(200), nullable=True)  # Equipment Type/Description
    status = Column(Enum(InspectionStatusEnum), default=InspectionStatusEnum.scheduled, nullable=False)
    scheduled_date = Column(Date, nullable=True)
    completion_date = Column(Date, nullable=True)
    notes = Column(Text, nullable=True)
    inspector_id = Column(Integer, ForeignKey('users.id'), nullable=True)
    
    # Report fields
    pdf_report_path = Column(String(500), nullable=True)
    report_findings = Column(Text, nullable=True)
    report_recommendations = Column(Text, nullable=True)
    
    # Rejection fields
    rejection_reason = Column(String(500), nullable=True)
    rejection_feedback = Column(Text, nullable=True)
    rejection_count = Column(Integer, default=0, nullable=False)
    last_rejected_at = Column(TIMESTAMP, nullable=True)
    
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    inspector = relationship("User", back_populates="inspections")
    reports = relationship("Report", back_populates="inspection")
    messages = relationship("Message", back_populates="inspection")
    reminders = relationship("Reminder", back_populates="inspection")

class Report(Base):
    __tablename__ = "reports"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    inspection_id = Column(Integer, ForeignKey('inspections.id'), nullable=True)
    status = Column(Enum(ReportStatusEnum), default=ReportStatusEnum.draft, nullable=False)
    content = Column(Text, nullable=True)
    findings = Column(Text, nullable=True)
    recommendations = Column(Text, nullable=True)
    created_by = Column(Integer, ForeignKey('users.id'), nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    inspection = relationship("Inspection", back_populates="reports")
    created_by_user = relationship("User", back_populates="reports")

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True)
    thread_id = Column(String(100), nullable=True, index=True)  # Thread identifier for grouping conversations
    inspection_id = Column(Integer, ForeignKey('inspections.id'), nullable=True)
    sender_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    receiver_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    reply_to_id = Column(Integer, ForeignKey('messages.id'), nullable=True)  # For threading
    subject = Column(String(200), nullable=True)
    content = Column(Text, nullable=False)
    attachment_url = Column(String(500), nullable=True)  # URL/path to file or photo
    attachment_type = Column(String(50), nullable=True)  # e.g. 'image', 'pdf', 'doc', etc.
    attachment_name = Column(String(255), nullable=True) # Original filename
    status = Column(Enum(MessageStatusEnum), default=MessageStatusEnum.unread, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())
    read_at = Column(TIMESTAMP, nullable=True)
    
    # Relationships
    inspection = relationship("Inspection", back_populates="messages")
    sender = relationship("User", foreign_keys=[sender_id], back_populates="sent_messages")
    receiver = relationship("User", foreign_keys=[receiver_id], back_populates="received_messages")
    reply_to = relationship("Message", remote_side=[id], foreign_keys=[reply_to_id])

class Reminder(Base):
    __tablename__ = "reminders"
    id = Column(Integer, primary_key=True, index=True)
    inspection_id = Column(Integer, ForeignKey('inspections.id'), nullable=False)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=True)
    remind_at = Column(TIMESTAMP, nullable=False)
    status = Column(Enum(ReminderStatusEnum), default=ReminderStatusEnum.pending, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())
    sent_at = Column(TIMESTAMP, nullable=True)
    
    # Relationships
    inspection = relationship("Inspection", back_populates="reminders")
    user = relationship("User", back_populates="reminders")
