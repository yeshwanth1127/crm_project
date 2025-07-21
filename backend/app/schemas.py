from dataclasses import Field
from datetime import datetime
from typing import Optional
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
    name: str
    company_name: str
    contact_number: str
    pipeline_stage: str
    lead_status: str
    assigned_to: int
    notes: Optional[str] = None
    email: Optional[EmailStr] = None

class CustomerCreate(CustomerBase):
    pass

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
