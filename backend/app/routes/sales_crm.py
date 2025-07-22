from fastapi import APIRouter, Depends, HTTPException, Form, status
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List, Optional
import json
from sqlalchemy import func

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
    company_id: int = Form(...),  # ✅ Add this line
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
        company_id=company_id,  # ✅ Set it here
        notes=notes,
        email=email
    )

    db.add(customer)
    db.commit()
    db.refresh(customer)
    return {"message": "Customer created", "customer_id": customer.id}

@router.get("/customers/status-summary")
def get_customer_status_summary(company_id: int, db: Session = Depends(get_db)):
    status_counts = db.query(Customer.account_status, func.count(Customer.id))\
                      .filter(Customer.company_id == company_id)\
                      .group_by(Customer.account_status).all()
    return {status: count for status, count in status_counts}

@router.get("/customers/filter-by-status")
def filter_customers_by_status(company_id: int, status: str, db: Session = Depends(get_db)):
    return db.query(Customer)\
             .filter(Customer.company_id == company_id, Customer.account_status == status).all()

@router.get("/customers/")
def list_customers(company_id: int, db: Session = Depends(get_db)):
    return db.query(Customer).filter(Customer.company_id == company_id).all()

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
def get_pipeline_counts(company_id: int, db: Session = Depends(get_db)):
    pipeline_data = (
        db.query(Customer.pipeline_stage, func.count(Customer.id))
        .filter(Customer.company_id == company_id)
        .group_by(Customer.pipeline_stage)
        .all()
    )
    return {stage: count for stage, count in pipeline_data}


@router.get("/analytics/overview/")
def get_analytics(company_id: int, db: Session = Depends(get_db)):
    total_customers = db.query(Customer).filter(Customer.company_id == company_id).count()
    total_leads = db.query(Customer).filter(Customer.company_id == company_id, Customer.lead_status == 'lead').count()
    total_clients = db.query(Customer).filter(Customer.company_id == company_id, Customer.lead_status == 'client').count()
    total_interactions = (
        db.query(Interaction)
        .join(Customer, Customer.id == Interaction.customer_id)
        .filter(Customer.company_id == company_id)
        .count()
    )
    pending_tasks = (
        db.query(Task)
        .join(User, User.id == Task.assigned_to)
        .filter(User.company_id == company_id, Task.status == 'pending')
        .count()
    )
    upcoming_followups = (
        db.query(FollowUp)
        .join(Customer, Customer.id == FollowUp.customer_id)
        .filter(Customer.company_id == company_id, FollowUp.followup_date >= datetime.utcnow())
        .count()
    )

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

@router.patch("/change-role/{user_id}")
def change_user_role(user_id: int, new_role: str = Form(...), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = new_role
    db.commit()
    return {"message": "Role updated"}

@router.patch("/assign-team-leader")
def assign_team_leader(salesman_id: int = Form(...), team_leader_id: int = Form(...), db: Session = Depends(get_db)):
    salesman = db.query(User).filter(User.id == salesman_id, User.role == 'salesman').first()
    if not salesman:
        raise HTTPException(status_code=404, detail="Salesman not found")
    team_leader = db.query(User).filter(User.id == team_leader_id, User.role == 'team_leader').first()
    if not team_leader:
        raise HTTPException(status_code=404, detail="Team Leader not found")
    salesman.assigned_team_leader = team_leader_id
    db.commit()
    return {"message": "Salesman assigned to Team Leader"}

@router.patch("/assign-customers-criteria")
def assign_customers_criteria(salesman_id: int = Form(...), pipeline_stage: Optional[str] = Form(None), lead_status: Optional[str] = Form(None), db: Session = Depends(get_db)):
    query = db.query(Customer).filter(Customer.assigned_to == None)
    if pipeline_stage:
        query = query.filter(Customer.pipeline_stage == pipeline_stage)
    if lead_status:
        query = query.filter(Customer.lead_status == lead_status)
    affected = query.update({"assigned_to": salesman_id}, synchronize_session=False)
    db.commit()
    return {"message": f"{affected} customers assigned"}

@router.get("/team-leader/{team_leader_id}/salesmen")
def get_salesmen(team_leader_id: int, db: Session = Depends(get_db)):
    return db.query(User).filter(User.assigned_team_leader == team_leader_id, User.role == 'salesman').all()

@router.get("/salesman/{salesman_id}/customers")
def get_customers_of_salesman(salesman_id: int, db: Session = Depends(get_db)):
    return db.query(Customer).filter(Customer.assigned_to == salesman_id).all()

@router.get("/get-hierarchy")
def get_hierarchy(company_id: int, db: Session = Depends(get_db)):
    # ✅ Step 1: Fetch all team leaders for this company
    team_leaders = db.query(User).filter(
        User.company_id == company_id,
        User.role == 'team_leader'
    ).all()

    result = []

    for leader in team_leaders:
        # ✅ Step 2: Fetch salesmen under this team leader
        salesmen = db.query(User).filter(
            User.company_id == company_id,
            User.role == 'salesman',
            User.assigned_team_leader == leader.id
        ).all()

        salesmen_data = []

        for salesman in salesmen:
            # ✅ Step 3: Fetch customers assigned to this salesman
            customers = db.query(Customer).filter(
                Customer.assigned_to == salesman.id
            ).all()

            salesmen_data.append({
                "id": salesman.id,
                "name": salesman.full_name,
                "customers": [customer.name for customer in customers]
            })

        result.append({
            "id": leader.id,
            "name": leader.full_name,
            "salesmen": salesmen_data
        })

    return {"team_leaders": result}




@router.patch("/customers/update-status/{customer_id}")
def update_customer_status(customer_id: int, new_status: str = Form(...), db: Session = Depends(get_db)):
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    customer.account_status = new_status
    db.commit()
    return {"message": "Customer status updated successfully"}




@router.get("/employees/status-summary")
def get_employee_status_summary(company_id: int, db: Session = Depends(get_db)):
    status_counts = db.query(User.account_status, func.count(User.id))\
                      .filter(User.company_id == company_id)\
                      .group_by(User.account_status).all()
    return {status: count for status, count in status_counts}

@router.patch("/employees/update-status/{user_id}")
def update_employee_status(user_id: int, new_status: str = Form(...), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.account_status = new_status
    db.commit()
    return {"message": "Employee status updated successfully"}

@router.patch("/employees/update-rewards/{user_id}")
def update_employee_rewards(user_id: int, reward_points: int = Form(...), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.reward_points = reward_points
    db.commit()
    return {"message": "Reward points updated successfully"}

@router.get("/employees/by-role-status")
def get_employees_by_role_status(company_id: int, role: str, status: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(User).filter(User.company_id == company_id, User.role == role)
    if status:
        query = query.filter(User.account_status == status)
    return query.all()

