from fastapi import APIRouter, Depends, HTTPException, Form, status
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List, Optional


from ..database import get_db
from ..models import Company, Customer, Interaction, Task, FollowUp, User
from ..schemas import UserCreateSchema, UserResponseSchema

router = APIRouter(prefix="/api/sales", tags=["Sales CRM Admin"])

# ============================== ✅ CUSTOMERS ==============================

@router.post("/customers/")
def create_customer(
    name: str = Form(...),
    company_name: str = Form(...),
    contact_number: str = Form(...),
    pipeline_stage: str = Form(...),
    lead_status: str = Form(...),
    assigned_to: int = Form(...),
    notes: str = Form(None),
    email: str = Form(None),
    db: Session = Depends(get_db)
):
    customer = Customer(
        name=name,
        company_name=company_name,
        contact_number=contact_number,
        pipeline_stage=pipeline_stage,
        lead_status=lead_status,
        assigned_to=assigned_to,
        notes=notes,
        email=email
    )
    db.add(customer)
    db.commit()
    db.refresh(customer)
    return {"message": "Customer created", "customer_id": customer.id}


@router.get("/customers/")
def list_customers(db: Session = Depends(get_db)):
    return db.query(Customer).all()


@router.get("/customers/{customer_id}")
def get_customer(customer_id: int, db: Session = Depends(get_db)):
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    return customer


@router.put("/customers/{customer_id}")
def update_customer(customer_id: int, db: Session = Depends(get_db), **data):
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    for field, value in data.items():
        setattr(customer, field, value)
    db.commit()
    db.refresh(customer)
    return {"message": "Customer updated"}


@router.delete("/customers/{customer_id}")
def delete_customer(customer_id: int, db: Session = Depends(get_db)):
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    db.delete(customer)
    db.commit()
    return {"message": "Customer deleted"}


# ============================== ✅ INTERACTIONS ==============================

@router.post("/interactions/")
def create_interaction(
    customer_id: int = Form(...),
    interaction_type: str = Form(...),
    notes: str = Form(None),
    outcome: str = Form(None),
    next_action_date: str = Form(None),
    db: Session = Depends(get_db)
):
    interaction = Interaction(
        customer_id=customer_id,
        interaction_type=interaction_type,
        notes=notes,
        outcome=outcome,
        next_action_date=next_action_date or None,
        interaction_date=datetime.utcnow()
    )
    db.add(interaction)
    db.commit()
    db.refresh(interaction)
    return {"message": "Interaction logged", "interaction_id": interaction.id}


@router.get("/interactions/")
def get_interactions(db: Session = Depends(get_db)):
    return db.query(Interaction).all()


# ============================== ✅ TASKS ==============================

@router.post("/tasks/")
def create_task(
    title: str = Form(...),
    description: str = Form(...),
    assigned_to: int = Form(...),
    due_date: str = Form(...),
    priority: str = Form(...),
    status: str = Form(...),
    db: Session = Depends(get_db)
):
    task = Task(
        title=title,
        description=description,
        assigned_to=assigned_to,
        due_date=due_date,
        priority=priority,
        status=status
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return {"message": "Task created", "task_id": task.id}


@router.get("/tasks/")
def get_tasks(db: Session = Depends(get_db)):
    return db.query(Task).all()


# ============================== ✅ FOLLOWUPS ==============================

@router.post("/followups/")
def create_followup(
    customer_id: int = Form(...),
    followup_date: str = Form(...),
    status: str = Form(...),
    notes: str = Form(None),
    db: Session = Depends(get_db)
):
    followup = FollowUp(
        customer_id=customer_id,
        followup_date=followup_date,
        status=status,
        notes=notes
    )
    db.add(followup)
    db.commit()
    db.refresh(followup)
    return {"message": "Follow-up created", "followup_id": followup.id}


@router.get("/followups/")
def get_followups(db: Session = Depends(get_db)):
    return db.query(FollowUp).all()


# ============================== ✅ PIPELINE ANALYTICS ==============================

@router.get("/pipeline-counts/")
def get_pipeline_counts(db: Session = Depends(get_db)):
    pipeline_data = db.query(Customer.pipeline_stage, db.func.count(Customer.id)).group_by(Customer.pipeline_stage).all()
    return {stage: count for stage, count in pipeline_data}


# ============================== ✅ DASHBOARD ANALYTICS ==============================

@router.get("/analytics/overview/")
def get_analytics(db: Session = Depends(get_db)):
    total_customers = db.query(Customer).count()
    total_leads = db.query(Customer).filter(Customer.lead_status == 'lead').count()
    total_clients = db.query(Customer).filter(Customer.lead_status == 'client').count()
    total_interactions = db.query(Interaction).count()
    pending_tasks = db.query(Task).filter(Task.status == 'pending').count()
    upcoming_followups = db.query(FollowUp).filter(FollowUp.followup_date >= datetime.utcnow()).count()

    return {
        "total_customers": total_customers,
        "leads": total_leads,
        "clients": total_clients,
        "interactions": total_interactions,
        "pending_tasks": pending_tasks,
        "upcoming_followups": upcoming_followups
    }

@router.post("/save-features")
def save_features(company_id: int, selected_features: List[str], db: Session = Depends(get_db)):
    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    company.selected_features = selected_features
    db.commit()
    return {"message": "Features saved successfully"}


@router.get("/get-features")
def get_features(company_id: int, db: Session = Depends(get_db)):
    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    return {"selected_features": company.selected_features or []}


@router.patch("/update-features")
def update_features(company_id: int, updated_features: List[str], db: Session = Depends(get_db)):
    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    company.selected_features = updated_features
    db.commit()
    return {"message": "Features updated successfully"}


# =========================== ✅ USER MANAGEMENT ROUTES ===========================

@router.post("/create-user", status_code=status.HTTP_201_CREATED)
def create_user(user_data: UserCreateSchema, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="User with this email already exists")
    new_user = User(
        full_name=user_data.full_name,
        email=user_data.email,
        phone=user_data.phone,
        password=user_data.password,  # ✅ Password hashing to be handled in production
        role=user_data.role,
        company_id=user_data.company_id
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@router.get("/list-users", response_model=List[UserResponseSchema])
def list_users(company_id: int, role: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(User).filter(User.company_id == company_id)
    if role:
        query = query.filter(User.role == role)
    return query.all()


@router.delete("/delete-user/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(user)
    db.commit()
    return {"message": "User deleted successfully"}


# =========================== ✅ COMPANY SETTINGS (OPTIONAL) ===========================

@router.get("/company-settings")
def get_company_settings(company_id: int, db: Session = Depends(get_db)):
    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    return {
        "company_name": company.company_name,
        "selected_features": company.selected_features or [],
        "crm_type": company.crm_type
    }


@router.patch("/update-company-settings")
def update_company_settings(company_id: int, selected_features: List[str], db: Session = Depends(get_db)):
    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    company.selected_features = selected_features
    db.commit()
    return {"message": "Company settings updated"}
