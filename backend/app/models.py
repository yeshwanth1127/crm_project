from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, Text, JSON, Enum
from sqlalchemy.sql import func
from .database import Base
from sqlalchemy.orm import relationship
import uuid


from datetime import datetime

class Company(Base):
    __tablename__ = "companies"

    id = Column(Integer, primary_key=True, index=True)
    company_name = Column(String, nullable=False)
    industry = Column(String, nullable=False)
    company_size = Column(String, nullable=False)
    location = Column(String, nullable=False)
    crm_type = Column(String, nullable=False)
    
    selected_features = Column(String, nullable=True)  # ✅ For dynamic feature selection


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    phone = Column(String, nullable=False)
    password = Column(String, nullable=False)
    role = Column(String, default="admin")
    company_id = Column(Integer, ForeignKey("companies.id"))
    assigned_team_leader = Column(Integer, ForeignKey('users.id'), nullable=True)
    account_status = Column(String, default='Active', nullable=True)
    reward_points = Column(Integer, default=0, nullable=True)
    company = relationship("Company")


class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    company_name = Column(String, nullable=False)  # Extract from admin
    contact_number = Column(String, nullable=False)
    email = Column(String, nullable=True)
    pipeline_stage = Column(String, nullable=True)
    lead_status = Column(String, nullable=True)
    assigned_to = Column(Integer, ForeignKey("users.id"), nullable=False)
    notes = Column(Text, nullable=True)
    account_status = Column(String, default='Active', nullable=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    interactions = relationship("Interaction", back_populates="customer", cascade="all, delete-orphan")




class FeatureCatalog(Base):
    __tablename__ = "features_catalog"

    id = Column(Integer, primary_key=True, index=True)
    feature_key = Column(String, unique=True, nullable=False)
    group = Column(String, nullable=False)
    label = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    default_enabled = Column(Boolean, default=False)


class CompanyFeatureSettings(Base):
    __tablename__ = "company_feature_settings"

    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False, index=True)
    feature_key = Column(String, nullable=False)
    is_enabled = Column(Boolean, nullable=False, default=False)
    visibility = Column(String, nullable=True)  # salesman, team_leader, all
    access_level = Column(String, nullable=True)  # readonly, full
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())


class FeatureChangeLog(Base):
    __tablename__ = "feature_change_logs"

    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False, index=True)
    admin_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    feature_key = Column(String, nullable=False)
    action = Column(String, nullable=False)  # enabled / disabled
    timestamp = Column(DateTime, server_default=func.now())


class FeaturePreset(Base):
    __tablename__ = "feature_presets"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False)
    features = Column(JSON, nullable=False)  # {feature_key: true/false}


class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)

    title = Column(String, nullable=False)
    description = Column(Text, nullable=False)

    assigned_to = Column(Integer, ForeignKey("users.id"), nullable=False)  # assigned salesman or team leader
    due_date = Column(DateTime(timezone=True), nullable=False)

    priority = Column(String, nullable=False)  # low, medium, high
    status = Column(String, nullable=False, default="pending")  # pending, completed, cancelled

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class FollowUp(Base):
    __tablename__ = "followups"

    id = Column(Integer, primary_key=True, index=True)

    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=False)

    followup_date = Column(DateTime(timezone=True), nullable=False)
    status = Column(String, nullable=False, default="pending")  # pending, completed, missed
    notes = Column(Text, nullable=True)  # Summary or discussion points

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)

    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    role = Column(String, nullable=False)

    action = Column(String, nullable=False)  # e.g., 'Updated Customer'
    resource_type = Column(String, nullable=False)  # 'customer', 'task', 'interaction'
    resource_id = Column(Integer, nullable=True)

    before_data = Column(JSON, nullable=True)
    after_data = Column(JSON, nullable=True)

    ip_address = Column(String, nullable=True)
    device_info = Column(String, nullable=True)

class CustomerCustomField(Base):
    __tablename__ = "customer_custom_fields"

    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    field_name = Column(String, nullable=False)
    field_type = Column(String, nullable=False)  # text, number, date, dropdown, etc.
    is_required = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class CustomerCustomValue(Base):
    __tablename__ = "customer_custom_values"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=False)
    field_id = Column(Integer, ForeignKey("customer_custom_fields.id"), nullable=False)
    value = Column(String, nullable=True)

class CustomerLifecycleConfig(Base):
    __tablename__ = "customer_lifecycle_config"

    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    stage = Column(String, nullable=False)        # e.g., Lead, Prospect, Customer
    statuses = Column(JSON, nullable=False)       # e.g., ["Warm", "Hot", "Lost"]
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())

class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=False)

    channel = Column(String, nullable=False)        # email, sms, call, etc.
    direction = Column(String, nullable=False)      # inbound, outbound
    message = Column(Text, nullable=False)

    is_read = Column(Boolean, default=False)        # ✅ NEW: read/unread toggle
    attachment_url = Column(String, nullable=True)  # ✅ NEW: optional file

    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)

class Interaction(Base):
    __tablename__ = "interactions"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    interaction_type = Column(String, nullable=False)      # e.g. Call, Email
    subtype = Column(String, nullable=True)                # e.g. Outbound
    content = Column(Text, nullable=True)                  # Notes
    timestamp = Column(DateTime, default=datetime.utcnow)
    outcome = Column(String, nullable=True)                # e.g. Success
    visibility = Column(String, default="public")          # public/internal
    channel = Column(String, nullable=True)                # WhatsApp, Zoom
    next_steps = Column(String, nullable=True)             # Optional
    company_id = Column(Integer, ForeignKey("companies.id"))

    customer = relationship("Customer", back_populates="interactions")
    user = relationship("User")

class TaskType(Base):
    __tablename__ = "task_types"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False, unique=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class TaskAssignment(Base):
    __tablename__ = "task_assignments"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    task_type_id = Column(String, ForeignKey("task_types.id"), nullable=False)
    assigned_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    assigned_to = Column(Integer, ForeignKey("users.id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)  # ✅ NEW

    title = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    due_date = Column(DateTime, nullable=True)
    priority = Column(Enum("low", "medium", "high", name="task_priority"), default="medium")
    status = Column(Enum("assigned", "completed", name="task_status"), default="assigned")

    created_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)

    # Relationships
    task_type = relationship("TaskType")
    assigned_user = relationship("User", foreign_keys=[assigned_to])  # ✅ Used to access assigned user's name
    assigned_by_user = relationship("User", foreign_keys=[assigned_by])
    customer = relationship("Customer")  # ✅ New relationship to get customer name/info


class TaskLog(Base):
    __tablename__ = "task_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    task_id = Column(String, ForeignKey("task_assignments.id"), nullable=False)
    action = Column(Enum("created", "completed", name="log_action"), nullable=False)
    performed_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    performed_at = Column(DateTime, default=datetime.utcnow)

    task = relationship("TaskAssignment")
    performer = relationship("User")