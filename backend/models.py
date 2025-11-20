from sqlalchemy import Column, Integer, String, Enum, TIMESTAMP, func
from db import Base
import enum

class RoleEnum(str, enum.Enum):
    inspector = "inspector"
    manager = "manager"

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(80), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(150))
    email = Column(String(150))
    role = Column(Enum(RoleEnum), default=RoleEnum.inspector, nullable=False)
    phone = Column(String(30), nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
