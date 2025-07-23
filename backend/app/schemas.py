from dataclasses import Field
from datetime import datetime
from typing import List, Optional, Dict
from pydantic import BaseModel, EmailStr, Field, constr
from typing import Literal

class OnboardingSchema(BaseModel):
    company_name: str
    company_size: str
    crm_type: str


class RegisterSchema(BaseModel):
    company_id: int
    full_name: str
    email: str
    phone: str
    password: str

class LoginResponse(BaseModel):
    message: str
    token: str
    role: str
    company_id: int
    crm_type: str
    email: str

class UserCreateSchema(BaseModel):
    full_name: constr(min_length=2, max_length=100)
    email: EmailStr
    phone: constr(min_length=7, max_length=20)
    password: constr(min_length=6, max_length=100)
    role: Literal['admin', 'team_leader', 'salesman'] = Field(..., description="Role must be admin, team_leader, or salesman")
    company_id: int

class UserResponseSchema(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    phone: str
    role: Literal['admin', 'team_leader', 'salesman']
    company_id: int

    class Config:
        orm_mode = True 
# ===================== ✅ CUSTOMER SCHEMAS =====================

class CustomerBase(BaseModel):
    first_name: str
    last_name: str
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    lifecycle_stage: Optional[str] = None
    status: Optional[str] = None
    assigned_to: int
    company_id: int

class CustomerCustomValueInput(BaseModel):
    field_id: int
    value: Optional[str]

class CustomerCreate(CustomerBase):
    custom_values: Optional[List[CustomerCustomValueInput]] = []



class CustomerResponse(CustomerBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        orm_mode = True

# ===================== ✅ INTERACTION SCHEMAS =====================

class InteractionBase(BaseModel):
    customer_id: int
    interaction_type: str
    notes: Optional[str] = None
    outcome: Optional[str] = None
    next_action_date: Optional[datetime] = None

class InteractionCreate(InteractionBase):
    pass

class InteractionResponse(InteractionBase):
    id: int
    interaction_date: datetime
    created_at: datetime

    class Config:
        orm_mode = True

# ===================== ✅ TASK SCHEMAS =====================

class TaskBase(BaseModel):
    title: str
    description: str
    assigned_to: int
    due_date: datetime
    priority: str
    status: str

class TaskCreate(TaskBase):
    pass

class TaskResponse(TaskBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        orm_mode = True

# ===================== ✅ FOLLOW-UP SCHEMAS =====================

class FollowUpBase(BaseModel):
    customer_id: int
    followup_date: datetime
    status: str
    notes: Optional[str] = None

class FollowUpCreate(FollowUpBase):
    pass

class FollowUpResponse(FollowUpBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        orm_mode = True


class AuditLogCreate(BaseModel):
    action: str
    resource_type: str
    resource_id: Optional[int]
    before_data: Optional[Dict]
    after_data: Optional[Dict]
    ip_address: Optional[str]
    device_info: Optional[str]

# For responses to frontend
class AuditLogOut(BaseModel):
    id: int
    timestamp: datetime
    user_id: int
    company_id: int
    role: str
    action: str
    resource_type: str
    resource_id: Optional[int]
    before_data: Optional[Dict]
    after_data: Optional[Dict]
    ip_address: Optional[str]
    device_info: Optional[str]

    class Config:
        orm_mode = True

class CustomFieldSchema(BaseModel):
    id: int
    company_id: int
    field_name: str
    field_type: str
    is_required: bool

    class Config:
        orm_mode = True


class CustomFieldCreateSchema(BaseModel):
    company_id: int
    field_name: str
    field_type: str
    is_required: bool = False


class CustomValueCreateSchema(BaseModel):
    customer_id: int
    field_id: int
    value: Optional[str] = None

class LifecycleConfigCreate(BaseModel):
    company_id: int
    stage: str
    statuses: list[str]

class LifecycleConfigResponse(BaseModel):
    id: int
    company_id: int
    stage: str
    statuses: list[str]

    class Config:
        orm_mode = True

class ConversationCreate(BaseModel):
    customer_id: int
    channel: str
    direction: str
    message: str
    is_read: Optional[bool] = False
    attachment_url: Optional[str] = None
    created_by: Optional[int] = None

class ConversationResponse(ConversationCreate):
    id: int
    timestamp: datetime

    class Config:
        orm_mode = True
