from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
import models
from db import get_db
from auth import get_current_user
from pydantic import BaseModel
from typing import Optional

router = APIRouter()

# Request models
class SendMessageRequest(BaseModel):
    inspection_id: Optional[int] = None  # Made optional for general messages
    receiver_id: int
    reply_to_id: Optional[int] = None  # For reply threading
    subject: Optional[str] = None
    content: str

class CreateReminderRequest(BaseModel):
    inspection_id: int
    title: str
    message: Optional[str] = None
    remind_at: str  # ISO datetime string

# Send message
@router.post("/send")
def send_message(
    request: SendMessageRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a message about an inspection or general work message"""
    
    try:
        print(f"[MESSAGING] Sending message from user {current_user.id} to {request.receiver_id}")
        print(f"[MESSAGING] Request: inspection_id={request.inspection_id}, subject={request.subject}")
        
        # Verify inspection exists if provided
        if request.inspection_id:
            inspection = db.query(models.Inspection).filter(
                models.Inspection.id == request.inspection_id
            ).first()
            
            if not inspection:
                print(f"[MESSAGING ERROR] Inspection {request.inspection_id} not found")
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Inspection not found"
                )
        
        # Verify receiver exists
        receiver = db.query(models.User).filter(
            models.User.id == request.receiver_id
        ).first()
        
        if not receiver:
            print(f"[MESSAGING ERROR] Receiver {request.receiver_id} not found")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Receiver not found"
            )
        
        # Generate thread_id: sort user IDs to ensure same thread for both directions
        # Format: "user_1_2" where 1 < 2, or "inspection_5_user_1_2" for inspection-related
        user_ids = sorted([current_user.id, request.receiver_id])
        if request.inspection_id:
            thread_id = f"inspection_{request.inspection_id}_user_{user_ids[0]}_{user_ids[1]}"
        else:
            thread_id = f"user_{user_ids[0]}_{user_ids[1]}"
        
        print(f"[MESSAGING] Thread ID: {thread_id}")
        
        # Create message
        print(f"[MESSAGING] Creating message object...")
        new_message = models.Message(
            thread_id=thread_id,
            inspection_id=request.inspection_id,
            sender_id=current_user.id,
            receiver_id=request.receiver_id,
            reply_to_id=request.reply_to_id,
            subject=request.subject,
            content=request.content,
            status=models.MessageStatusEnum.unread
        )
        
        print(f"[MESSAGING] Adding message to database...")
        db.add(new_message)
        
        print(f"[MESSAGING] Committing transaction...")
        db.commit()
        
        print(f"[MESSAGING] Refreshing message object...")
        db.refresh(new_message)
        
        print(f"[MESSAGING SUCCESS] Message {new_message.id} sent to {receiver.full_name}")
        
        return {
            "message": "Message sent successfully",
            "message_id": new_message.id,
            "thread_id": thread_id,
            "sent_to": receiver.full_name,
            "sent_at": new_message.created_at.isoformat()
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"[MESSAGING ERROR] Exception occurred: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send message: {str(e)}"
        )

# Get conversation threads (Gmail-style)
@router.get("/threads")
def get_threads(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all conversation threads for current user, grouped like Gmail"""
    from sqlalchemy import func, or_, and_
    
    # Get all unique thread_ids involving current user
    threads_query = db.query(
        models.Message.thread_id,
        func.max(models.Message.created_at).label('last_message_time'),
        func.count(models.Message.id).label('message_count'),
        func.sum(
            func.cast(
                and_(
                    models.Message.receiver_id == current_user.id,
                    models.Message.status == models.MessageStatusEnum.unread
                ),
                Integer
            )
        ).label('unread_count')
    ).filter(
        models.Message.thread_id.isnot(None),
        or_(
            models.Message.sender_id == current_user.id,
            models.Message.receiver_id == current_user.id
        )
    ).group_by(models.Message.thread_id).order_by(
        func.max(models.Message.created_at).desc()
    ).all()
    
    threads = []
    for thread_info in threads_query:
        thread_id = thread_info[0]
        
        # Get the latest message for preview
        last_message = db.query(models.Message).filter(
            models.Message.thread_id == thread_id
        ).order_by(models.Message.created_at.desc()).first()
        
        if not last_message:
            continue
        
        # Determine the other participant
        other_user_id = (
            last_message.receiver_id 
            if last_message.sender_id == current_user.id 
            else last_message.sender_id
        )
        other_user = db.query(models.User).filter(models.User.id == other_user_id).first()
        
        # Get first message for subject
        first_message = db.query(models.Message).filter(
            models.Message.thread_id == thread_id
        ).order_by(models.Message.created_at.asc()).first()
        
        threads.append({
            "thread_id": thread_id,
            "subject": first_message.subject or "No subject",
            "other_user_id": other_user.id if other_user else None,
            "other_user_name": other_user.full_name if other_user else "Unknown",
            "other_user_role": other_user.role.value if other_user else None,
            "last_message_preview": last_message.content[:100] + ("..." if len(last_message.content) > 100 else ""),
            "last_message_time": last_message.created_at.isoformat(),
            "last_message_sender": "You" if last_message.sender_id == current_user.id else other_user.full_name if other_user else "Unknown",
            "message_count": thread_info[2],
            "unread_count": thread_info[3] or 0,
            "inspection_id": last_message.inspection_id,
            "inspection_title": last_message.inspection.title if last_message.inspection else None
        })
    
    return threads

# Get all messages in a thread
@router.get("/thread/{thread_id}")
def get_thread_messages(
    thread_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all messages in a conversation thread"""
    
    # Verify user has access to this thread
    messages = db.query(models.Message).filter(
        models.Message.thread_id == thread_id,
        or_(
            models.Message.sender_id == current_user.id,
            models.Message.receiver_id == current_user.id
        )
    ).order_by(models.Message.created_at.asc()).all()
    
    if not messages:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Thread not found or access denied"
        )
    
    # Mark all received messages in this thread as read
    unread_messages = [msg for msg in messages if msg.receiver_id == current_user.id and msg.status == models.MessageStatusEnum.unread]
    for msg in unread_messages:
        msg.status = models.MessageStatusEnum.read
        msg.read_at = datetime.now()
    
    if unread_messages:
        db.commit()
    
    return [{
        "id": msg.id,
        "thread_id": msg.thread_id,
        "sender_id": msg.sender_id,
        "sender_name": msg.sender.full_name,
        "receiver_id": msg.receiver_id,
        "receiver_name": msg.receiver.full_name,
        "content": msg.content,
        "created_at": msg.created_at.isoformat(),
        "is_sender": msg.sender_id == current_user.id
    } for msg in messages]

# Get messages for an inspection
@router.get("/inspection/{inspection_id}")
def get_inspection_messages(
    inspection_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all messages for an inspection"""
    
    messages = db.query(models.Message).filter(
        models.Message.inspection_id == inspection_id
    ).filter(
        (models.Message.sender_id == current_user.id) | 
        (models.Message.receiver_id == current_user.id)
    ).order_by(models.Message.created_at.desc()).all()
    
    return [{
        "id": msg.id,
        "inspection_id": msg.inspection_id,
        "inspection_title": msg.inspection.title if msg.inspection else None,
        "sender_id": msg.sender_id,
        "sender_name": msg.sender.full_name,
        "receiver_id": msg.receiver_id,
        "receiver_name": msg.receiver.full_name,
        "subject": msg.subject,
        "content": msg.content,
        "status": msg.status.value,
        "created_at": msg.created_at.isoformat(),
        "read_at": msg.read_at.isoformat() if msg.read_at else None,
        "is_sender": msg.sender_id == current_user.id
    } for msg in messages]

# Get all user messages
@router.get("/my-messages")
def get_my_messages(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all messages for current user"""
    
    messages = db.query(models.Message).filter(
        (models.Message.sender_id == current_user.id) | 
        (models.Message.receiver_id == current_user.id)
    ).order_by(models.Message.created_at.desc()).all()
    
    return [{
        "id": msg.id,
        "inspection_id": msg.inspection_id,
        "inspection_title": msg.inspection.title if msg.inspection else None,
        "sender_id": msg.sender_id,
        "sender_name": msg.sender.full_name,
        "receiver_id": msg.receiver_id,
        "receiver_name": msg.receiver.full_name,
        "reply_to_id": msg.reply_to_id,
        "subject": msg.subject,
        "content": msg.content,
        "status": msg.status.value,
        "created_at": msg.created_at.isoformat(),
        "read_at": msg.read_at.isoformat() if msg.read_at else None,
        "is_sender": msg.sender_id == current_user.id
    } for msg in messages]

# Get unread message count
@router.get("/unread-count")
def get_unread_count(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get count of unread messages"""
    
    count = db.query(models.Message).filter(
        models.Message.receiver_id == current_user.id,
        models.Message.status == models.MessageStatusEnum.unread
    ).count()
    
    return {"unread_count": count}

# Mark message as read
@router.post("/mark-read/{message_id}")
def mark_message_read(
    message_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark a message as read"""
    
    message = db.query(models.Message).filter(
        models.Message.id == message_id,
        models.Message.receiver_id == current_user.id
    ).first()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    
    message.status = models.MessageStatusEnum.read
    message.read_at = datetime.now()
    db.commit()
    
    return {"message": "Message marked as read"}

# Get all users for messaging
@router.get("/users")
def get_all_users(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all users in the system for messaging"""
    
    users = db.query(models.User).filter(
        models.User.id != current_user.id  # Exclude current user
    ).all()
    
    return [{
        "id": user.id,
        "full_name": user.full_name,
        "username": user.username,
        "email": user.email,
        "role": user.role.value
    } for user in users]

# Create reminder
@router.post("/reminder/create")
def create_reminder(
    request: CreateReminderRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a reminder for an inspection"""
    
    # Verify inspection exists
    inspection = db.query(models.Inspection).filter(
        models.Inspection.id == request.inspection_id
    ).first()
    
    if not inspection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inspection not found"
        )
    
    # Parse datetime
    try:
        remind_at = datetime.fromisoformat(request.remind_at.replace('Z', '+00:00'))
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid datetime format. Use ISO format"
        )
    
    # Create reminder
    new_reminder = models.Reminder(
        inspection_id=request.inspection_id,
        user_id=current_user.id,
        title=request.title,
        message=request.message,
        remind_at=remind_at,
        status=models.ReminderStatusEnum.pending
    )
    
    db.add(new_reminder)
    db.commit()
    db.refresh(new_reminder)
    
    return {
        "message": "Reminder created successfully",
        "reminder_id": new_reminder.id,
        "remind_at": new_reminder.remind_at.isoformat()
    }

# Get user reminders
@router.get("/reminder/my-reminders")
def get_my_reminders(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all reminders for current user"""
    
    reminders = db.query(models.Reminder).filter(
        models.Reminder.user_id == current_user.id
    ).order_by(models.Reminder.remind_at.asc()).all()
    
    return [{
        "id": rem.id,
        "inspection_id": rem.inspection_id,
        "inspection_title": rem.inspection.title,
        "title": rem.title,
        "message": rem.message,
        "remind_at": rem.remind_at.isoformat(),
        "status": rem.status.value,
        "created_at": rem.created_at.isoformat()
    } for rem in reminders]

# Get pending reminders
@router.get("/reminder/pending")
def get_pending_reminders(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get pending reminders that are due"""
    
    now = datetime.now()
    
    reminders = db.query(models.Reminder).filter(
        models.Reminder.user_id == current_user.id,
        models.Reminder.status == models.ReminderStatusEnum.pending,
        models.Reminder.remind_at <= now
    ).order_by(models.Reminder.remind_at.asc()).all()
    
    return [{
        "id": rem.id,
        "inspection_id": rem.inspection_id,
        "inspection_title": rem.inspection.title,
        "title": rem.title,
        "message": rem.message,
        "remind_at": rem.remind_at.isoformat(),
        "status": rem.status.value
    } for rem in reminders]

# Dismiss reminder
@router.post("/reminder/dismiss/{reminder_id}")
def dismiss_reminder(
    reminder_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Dismiss a reminder"""
    
    reminder = db.query(models.Reminder).filter(
        models.Reminder.id == reminder_id,
        models.Reminder.user_id == current_user.id
    ).first()
    
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reminder not found"
        )
    
    reminder.status = models.ReminderStatusEnum.dismissed
    db.commit()
    
    return {"message": "Reminder dismissed"}
