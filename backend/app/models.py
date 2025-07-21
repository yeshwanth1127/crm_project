from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, Text, JSON
from sqlalchemy.sql import func
from .database import Base

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

class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    company_name = Column(String, nullable=False)
    contact_number = Column(String, nullable=False)
    email = Column(String, nullable=True)  # optional
    
    pipeline_stage = Column(String, nullable=False)  # e.g., lead, qualified, proposal, won, lost
    lead_status = Column(String, nullable=False)  # lead or client
    
    assigned_to = Column(Integer, ForeignKey("users.id"), nullable=False)
    notes = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

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


class Interaction(Base):
        __tablename__ = "interactions"

        id = Column(Integer, primary_key=True, index=True)
        
        customer_id = Column(Integer, ForeignKey("customers.id"), nullable=False)
        interaction_type = Column(String, nullable=False)  # call, visit, email, meeting, demo, etc.
        interaction_date = Column(DateTime(timezone=True), server_default=func.now())
        
        notes = Column(Text, nullable=True)  # Optional notes about the interaction
        outcome = Column(String, nullable=True)  # positive, neutral, negative or future custom status
        next_action_date = Column(DateTime(timezone=True), nullable=True)  # Optional follow-up scheduling

        created_at = Column(DateTime(timezone=True), server_default=func.now())

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