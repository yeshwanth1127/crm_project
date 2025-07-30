from fastapi import APIRouter, Depends, HTTPException, Form, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import List, Optional
import json
from sqlalchemy import func, Enum
from ..utils.audit_logger import log_audit, serialize_model
from ..auth import get_current_user
from ..models import CustomerCustomField, CustomerCustomValue, TaskAssignment
from ..schemas import CustomFieldCreateSchema, CustomFieldSchema, CustomValueCreateSchema, CustomerCustomValueInput, CustomerUpdate
from ..database import get_db
from ..models import Company, Customer, Interaction, Task, FollowUp, User, AuditLog
from ..schemas import UserCreateSchema, UserResponseSchema
from ..models import CustomerLifecycleConfig
from ..schemas import LifecycleConfigCreate, LifecycleConfigResponse
from backend.app import schemas
from ..models import Conversation
from ..schemas import ConversationCreate, ConversationResponse
from backend.app import models

router = APIRouter(prefix="/api/sales", tags=["Sales CRM Admin"])



@router.post("/customers/")
def create_customer(
    first_name: str = Form(...),
    last_name: str = Form(...),
    contact_number: str = Form(...),
    email: Optional[str] = Form(None),
    pipeline_stage: Optional[str] = Form(None),
    lead_status: Optional[str] = Form(None),
    assigned_to: int = Form(...),
    company_id: int = Form(...),
    custom_values: Optional[str] = Form(None),  
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    
    company_name = user.company.company_name if user.company else "Unknown"

    
    customer = Customer(
        first_name=first_name,
        last_name=last_name,
        company_name=company_name,
        contact_number=contact_number,
        email=email,
        pipeline_stage=pipeline_stage,
        lead_status=lead_status,
        assigned_to=assigned_to,
        company_id=company_id,
    )

    db.add(customer)
    db.commit()
    db.refresh(customer)

    
    if custom_values:
        try:
            parsed_values = json.loads(custom_values)
            for val in parsed_values:
                validated = CustomerCustomValueInput(**val)
                db.add(CustomerCustomValue(
                    customer_id=customer.id,
                    field_id=validated.field_id,
                    value=validated.value
                ))
            db.commit()
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid custom_values: {str(e)}")

    
    log_audit(
    db, user.id, user.company_id, user.role,
    "Created Customer", "customer", customer.id,
    None, customer  
)


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
    customers = db.query(Customer).filter(Customer.company_id == company_id).all()
    result = []

    for customer in customers:
        
        custom_values = db.query(CustomerCustomValue, CustomerCustomField)\
            .join(CustomerCustomField, CustomerCustomValue.field_id == CustomerCustomField.id)\
            .filter(CustomerCustomValue.customer_id == customer.id).all()

        custom_fields = {
            field.field_name: value.value
            for value, field in custom_values
        }

        customer_data = customer.__dict__.copy()
        customer_data["custom_fields"] = custom_fields
        result.append(customer_data)

    return result

@router.get("/customers/{customer_id}")
def get_customer(customer_id: int, db: Session = Depends(get_db)):
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    
    custom_values = db.query(CustomerCustomValue, CustomerCustomField)\
        .join(CustomerCustomField, CustomerCustomValue.field_id == CustomerCustomField.id)\
        .filter(CustomerCustomValue.customer_id == customer_id).all()

    custom_fields = [
        {
            "field_name": field.field_name,
            "value": value.value,
            "field_type": field.field_type
        }
        for value, field in custom_values
    ]

    customer_data = customer.__dict__.copy()
    customer_data["custom_fields"] = custom_fields

    return customer_data









@router.put("/customers/{customer_id}")
def update_customer(
    customer_id: int,
    data: CustomerUpdate,  
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    before = serialize_model(customer)

    update_data = data.dict(exclude_unset=True)  
    for field, value in update_data.items():
        setattr(customer, field, value)

    db.commit()
    db.refresh(customer)

    log_audit(db, user.id, user.company_id, user.role, "Updated Customer",
              "customer", customer.id, before, customer)

    return {"message": "Customer updated"}

@router.delete("/customers/{customer_id}")
def delete_customer(
    customer_id: int, 
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
):
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    
    before = serialize_model(customer)

    db.delete(customer)
    db.commit()

    log_audit(db, user.id, user.company_id, user.role, "Deleted Customer", 
              "customer", customer_id, before, None)

    return {"message": "Customer deleted"}





@router.post("/tasks/")
def create_task(
    title: str = Form(...),
    description: str = Form(...),
    assigned_to: int = Form(...),
    due_date: str = Form(...),
    priority: str = Form(...),
    status: str = Form(...),
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
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

    log_audit(db, user.id, user.company_id, user.role, "Created Task", 
              "task", task.id, None, task.__dict__)

    return {"message": "Task created", "task_id": task.id}


@router.get("/tasks/")
def get_tasks(db: Session = Depends(get_db)):
    return db.query(Task).all()




@router.post("/followups/")
def create_followup(
    customer_id: int = Form(...),
    followup_date: str = Form(...),
    status: str = Form(...),
    notes: str = Form(None),
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
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

    log_audit(db, user.id, user.company_id, user.role, "Created Follow-up", 
              "followup", followup.id, None, followup.__dict__)

    return {"message": "Follow-up created", "followup_id": followup.id}



@router.get("/followups/")
def get_followups(db: Session = Depends(get_db)):
    return db.query(FollowUp).all()




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
    db.query(models.TaskAssignment)
    .join(models.User, models.User.id == models.TaskAssignment.assigned_to)
    .filter(models.User.company_id == company_id, models.TaskAssignment.status == 'assigned')
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




@router.post("/create-user", status_code=status.HTTP_201_CREATED)
def create_user(
    user_data: UserCreateSchema, 
    db: Session = Depends(get_db)
):
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="User with this email already exists")
    
    new_user = User(
        full_name=user_data.full_name,
        email=user_data.email,
        phone=user_data.phone,
        password=user_data.password,
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
def delete_user(
    user_id: int, 
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
):
    user_del = db.query(User).filter(User.id == user_id).first()
    if not user_del:
        raise HTTPException(status_code=404, detail="User not found")
    
    before = user_del.__dict__.copy()
    db.delete(user_del)
    db.commit()

    log_audit(db, user.id, user.company_id, user.role, "Deleted User", 
              "user", user_id, before, None)

    return {"message": "User deleted successfully"}





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
def update_company_settings(
    company_id: int, 
    updated_features: List[str],
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
):
    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    
    before = {"features": company.selected_features.copy()}
    company.selected_features = updated_features
    db.commit()

    log_audit(db, user.id, user.company_id, user.role, "Updated Company Settings", 
              "company", company.id, before, {"features": updated_features})

    return {"message": "Company settings updated"}

@router.patch("/change-role/{user_id}")
def change_user_role(
    user_id: int, 
    new_role: str = Form(...),
    db: Session = Depends(get_db),
):
    u = db.query(User).filter(User.id == user_id).first()
    if not u:
        raise HTTPException(status_code=404, detail="User not found")
    
    before = {"role": u.role}
    u.role = new_role
    db.commit()


    return {"message": "Role updated"}

@router.patch("/assign-team-leader")
def assign_team_leader(
    salesman_id: int = Form(...), 
    team_leader_id: int = Form(...),
    db: Session = Depends(get_db)
):
    salesman = db.query(User).filter(User.id == salesman_id, User.role == 'salesman').first()
    if not salesman:
        raise HTTPException(status_code=404, detail="Salesman not found")

    team_leader = db.query(User).filter(User.id == team_leader_id, User.role == 'team_leader').first()
    if not team_leader:
        raise HTTPException(status_code=404, detail="Team Leader not found")

    salesman.assigned_team_leader = team_leader_id
    db.commit()

    return {"message": "Assigned"}


@router.patch("/assign-customers-criteria")
def assign_customers_criteria(
    salesman_id: int = Form(...), 
    pipeline_stage: Optional[str] = Form(None), 
    lead_status: Optional[str] = Form(None),
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
):
    query = db.query(Customer).filter(Customer.assigned_to == None)
    if pipeline_stage:
        query = query.filter(Customer.pipeline_stage == pipeline_stage)
    if lead_status:
        query = query.filter(Customer.lead_status == lead_status)
    
    before_count = query.count()
    affected = query.update({"assigned_to": salesman_id}, synchronize_session=False)
    db.commit()

    log_audit(db, user.id, user.company_id, user.role, f"Bulk Assigned {affected} Customers", 
              "customer", None, {"unassigned": before_count}, {"assigned": affected})

    return {"message": f"{affected} customers assigned"}


@router.get("/team-leader/{team_leader_id}/salesmen")
def get_salesmen(team_leader_id: int, db: Session = Depends(get_db)):
    return db.query(User).filter(User.assigned_team_leader == team_leader_id, User.role == 'salesman').all()

@router.get("/salesman/{salesman_id}/customers")
def get_customers_of_salesman(salesman_id: int, db: Session = Depends(get_db)):
    return db.query(Customer).filter(Customer.assigned_to == salesman_id).all()

@router.get("/get-hierarchy")
def get_hierarchy(company_id: int, db: Session = Depends(get_db)):
    
    team_leaders = db.query(User).filter(
        User.company_id == company_id,
        User.role == 'team_leader'
    ).all()

    result = []

    for leader in team_leaders:
        
        salesmen = db.query(User).filter(
            User.company_id == company_id,
            User.role == 'salesman',
            User.assigned_team_leader == leader.id
        ).all()

        salesmen_data = []

        for salesman in salesmen:
            
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
def update_customer_status(
    customer_id: int, 
    new_status: str = Form(...),
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
):
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    
    before = {"status": customer.account_status}
    customer.account_status = new_status
    db.commit()

    log_audit(db, user.id, user.company_id, user.role, "Updated Customer Status", 
              "customer", customer_id, before, {"status": new_status})

    return {"message": "Customer status updated successfully"}





@router.get("/employees/status-summary")
def get_employee_status_summary(company_id: int, db: Session = Depends(get_db)):
    status_counts = db.query(User.account_status, func.count(User.id))\
                      .filter(User.company_id == company_id)\
                      .group_by(User.account_status).all()
    return {status: count for status, count in status_counts}

@router.patch("/employees/update-status/{user_id}")
def update_employee_status(
    user_id: int, 
    new_status: str = Form(...),
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
):
    u = db.query(User).filter(User.id == user_id).first()
    if not u:
        raise HTTPException(status_code=404, detail="User not found")
    
    before = {"status": u.account_status}
    u.account_status = new_status
    db.commit()

    log_audit(db, user.id, user.company_id, user.role, "Updated Employee Status", 
              "user", user_id, before, {"status": new_status})

    return {"message": "Employee status updated successfully"}


@router.patch("/employees/update-rewards/{user_id}")
def update_employee_rewards(
    user_id: int, 
    reward_points: int = Form(...),
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
):
    u = db.query(User).filter(User.id == user_id).first()
    if not u:
        raise HTTPException(status_code=404, detail="User not found")
    
    before = {"reward_points": u.reward_points}
    u.reward_points = reward_points
    db.commit()

    log_audit(db, user.id, user.company_id, user.role, "Updated Reward Points", 
              "user", user_id, before, {"reward_points": reward_points})

    return {"message": "Reward points updated successfully"}

@router.get("/employees/by-role-status")
def get_employees_by_role_status(company_id: int, role: str, status: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(User).filter(User.company_id == company_id, User.role == role)
    if status:
        query = query.filter(User.account_status == status)
    return query.all()

@router.get("/logs", response_model=List[schemas.AuditLogOut])
def get_audit_logs(
    company_id: int,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    action: Optional[str] = None,
    user_id: Optional[int] = None,
    db: Session = Depends(get_db),
):
    query = db.query(models.AuditLog).filter(models.AuditLog.company_id == company_id)

    if start_date:
        query = query.filter(models.AuditLog.timestamp >= start_date)
    if end_date:
        query = query.filter(models.AuditLog.timestamp <= end_date)
    if action:
        query = query.filter(models.AuditLog.action.ilike(f"%{action}%"))
    if user_id:
        query = query.filter(models.AuditLog.user_id == user_id)

    logs = query.order_by(models.AuditLog.timestamp.desc()).all()
    return logs


@router.post("/log")
def create_audit_log(log: schemas.AuditLogCreate, user_id: int, company_id: int, role: str, db: Session = Depends(get_db)):
    new_log = models.AuditLog(
        user_id=user_id,
        company_id=company_id,
        role=role,
        action=log.action,
        resource_type=log.resource_type,
        resource_id=log.resource_id,
        before_data=log.before_data,
        after_data=log.after_data,
        ip_address=log.ip_address,
        device_info=log.device_info
    )
    db.add(new_log)
    db.commit()
    db.refresh(new_log)
    return {"message": "Audit log created successfully"}


@router.post("/custom-fields/", response_model=CustomFieldSchema)
def create_custom_field(field: CustomFieldCreateSchema, db: Session = Depends(get_db), user = Depends(get_current_user)):
    new_field = CustomerCustomField(**field.dict())
    db.add(new_field)
    db.commit()
    db.refresh(new_field)
    return new_field


@router.get("/custom-fields/")
def get_custom_fields(company_id: int, db: Session = Depends(get_db)):
    fields = db.query(CustomerCustomField).filter(CustomerCustomField.company_id == company_id).all()
    return [
        {
            "id": field.id,
            "field_name": field.field_name,
            "field_type": field.field_type,
            "is_required": field.is_required
        }
        for field in fields
    ]


@router.post("/custom-values/")
def save_custom_values(
    data: List[CustomValueCreateSchema],
    db: Session = Depends(get_db)
):
    try:
        for item in data:
            value = CustomerCustomValue(
                customer_id=item.customer_id,
                field_id=item.field_id,
                value=item.value
            )
            db.add(value)
        db.commit()
        return {"message": "Custom values saved successfully"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error saving custom values: {str(e)}")


@router.get("/custom-values/{customer_id}")
def get_custom_values(customer_id: int, db: Session = Depends(get_db)):
    values = db.query(CustomerCustomValue).filter(CustomerCustomValue.customer_id == customer_id).all()
    return [{"field_id": v.field_id, "value": v.value} for v in values]

@router.get("/customers/check-duplicate")
def check_duplicate_customer(
    email: Optional[str] = None,
    phone: Optional[str] = None,
    company_id: int = Form(...),
    db: Session = Depends(get_db)
):
    query = db.query(Customer).filter(Customer.company_id == company_id)

    if email:
        query = query.filter(Customer.email == email)
    if phone:
        query = query.filter(Customer.contact_number == phone)

    duplicate_exists = db.query(query.exists()).scalar()
    return {"duplicate": duplicate_exists}

@router.post("/lifecycle-config/", response_model=LifecycleConfigResponse)
def create_lifecycle_config(
    config: LifecycleConfigCreate,
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
):
    entry = CustomerLifecycleConfig(**config.dict())
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry

@router.get("/lifecycle-config/", response_model=List[LifecycleConfigResponse])
def get_lifecycle_configs(company_id: int, db: Session = Depends(get_db)):
    return db.query(CustomerLifecycleConfig)\
             .filter(CustomerLifecycleConfig.company_id == company_id).all()

@router.put("/lifecycle-config/{config_id}", response_model=LifecycleConfigResponse)
def update_lifecycle_config(
    config_id: int,
    updated: LifecycleConfigCreate,
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
):
    config = db.query(CustomerLifecycleConfig).filter(CustomerLifecycleConfig.id == config_id).first()
    if not config:
        raise HTTPException(status_code=404, detail="Config not found")

    config.stage = updated.stage
    config.statuses = updated.statuses
    db.commit()
    db.refresh(config)
    return config

@router.post("/conversations/", response_model=ConversationResponse)
def log_conversation(
    convo: ConversationCreate,
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
):
    new_convo = Conversation(**convo.dict())
    db.add(new_convo)
    db.commit()
    db.refresh(new_convo)

    log_audit(db, user.id, user.company_id, user.role, "Logged Conversation", 
              "conversation", new_convo.id, None, new_convo.__dict__)

    return new_convo


@router.get("/conversations/", response_model=List[ConversationResponse])
def filter_conversations(
    customer_id: int,
    channel: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    is_read: Optional[bool] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Conversation).filter(Conversation.customer_id == customer_id)

    if channel:
        query = query.filter(Conversation.channel == channel)
    if is_read is not None:
        query = query.filter(Conversation.is_read == is_read)
    if start_date:
        query = query.filter(Conversation.timestamp >= start_date)
    if end_date:
        query = query.filter(Conversation.timestamp <= end_date)

    return query.order_by(Conversation.timestamp.desc()).all()

@router.post("/interactions/create", response_model=schemas.InteractionResponse)
def log_interaction(
    interaction: schemas.InteractionCreate,
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
):
    new_interaction = Interaction(
        customer_id=interaction.customer_id,
        user_id=user.id,
        interaction_type=interaction.interaction_type,
        subtype=interaction.subtype,
        content=interaction.content,
        outcome=interaction.outcome,
        visibility=interaction.visibility,
        channel=interaction.channel,
        next_steps=interaction.next_steps,
        timestamp=datetime.utcnow(),
        company_id=user.company_id
    )

    db.add(new_interaction)
    db.commit()
    db.refresh(new_interaction)

    log_audit(db, user.id, user.company_id, user.role, "Created Interaction", 
              "interaction", new_interaction.id, None, serialize_model(new_interaction))

    return new_interaction

@router.get("/interactions/by-customer/{customer_id}", response_model=List[schemas.InteractionResponse])
def get_interactions_by_customer(
    customer_id: int,
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
):
    interactions = db.query(Interaction).filter(
        Interaction.customer_id == customer_id,
        Interaction.company_id == user.company_id
    ).order_by(Interaction.timestamp.desc()).all()

    return interactions

@router.post("/task-types/")
def create_task_type(
    name: str = Form(...),
    description: Optional[str] = Form(None),
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    existing = db.query(models.TaskType).filter(models.TaskType.name == name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Task type already exists")

    task_type = models.TaskType(name=name, description=description)
    db.add(task_type)
    db.commit()
    db.refresh(task_type)
    return {"message": "Task type created", "task_type_id": task_type.id}


@router.get("/task-types/")
def get_task_types(db: Session = Depends(get_db)):
    return db.query(models.TaskType).all()


@router.post("/assign-task/")
def assign_task(
    task_data: schemas.TaskAssignmentCreate,
    db: Session = Depends(get_db)
):
    task = models.TaskAssignment(
        task_type_id=task_data.task_type_id,
        assigned_by=task_data.assigned_by,
        assigned_to=task_data.assigned_to,
        customer_id=task_data.customer_id,  
        title=task_data.title,
        description=task_data.description,
        due_date=task_data.due_date,
        priority=task_data.priority,
        status="assigned"
    )

    db.add(task)
    db.commit()
    db.refresh(task)

    log = models.TaskLog(
        task_id=task.id,
        action="created",
        performed_by=task_data.assigned_by
    )
    db.add(log)
    db.commit()

    return {"message": "Task assigned successfully", "task_id": task.id}

@router.get("/tasks/by-company/{company_id}", response_model=List[schemas.TaskAssignmentOut])
def get_tasks_by_company(company_id: int, db: Session = Depends(get_db)):
    tasks = (
        db.query(models.TaskAssignment)
        .join(models.User, models.TaskAssignment.assigned_to == models.User.id)
        .filter(models.User.company_id == company_id)
        .all()
    )
    return [schemas.TaskAssignmentOut.from_orm_with_names(task) for task in tasks]

@router.get("/tasks/assigned/")
def get_assigned_tasks(
    company_id: int,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
):
    query = db.query(models.TaskAssignment).join(models.User, models.User.id == models.TaskAssignment.assigned_to)\
                .filter(models.User.company_id == company_id)
    if status:
        query = query.filter(models.TaskAssignment.status == status)
    return query.order_by(models.TaskAssignment.due_date.asc()).all()


@router.patch("/tasks/complete/{task_id}")
def mark_task_complete(
    task_id: str,
    db: Session = Depends(get_db)
):
    task = db.query(models.TaskAssignment).filter(models.TaskAssignment.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.status == "completed":
        raise HTTPException(status_code=400, detail="Task already completed")

    task.status = "completed"
    task.completed_at = datetime.utcnow()
    db.commit()

    log = models.TaskLog(
        task_id=task.id,
        action="completed",
        performed_by=task.assigned_by  
    )
    db.add(log)
    db.commit()

    return {"message": "Task marked as completed"}



@router.get("/tasks/logs/")
def get_task_logs(
    company_id: int,
    db: Session = Depends(get_db)
):
    query = db.query(models.TaskLog).join(models.TaskAssignment, models.TaskLog.task_id == models.TaskAssignment.id)\
            .join(models.User, models.TaskAssignment.assigned_to == models.User.id)\
            .filter(models.User.company_id == company_id)\
            .order_by(models.TaskLog.performed_at.desc())
    return query.all()

@router.get("/tasks/user/{user_id}")
def get_tasks_for_user(
    user_id: int,
    status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(models.TaskAssignment).filter(models.TaskAssignment.assigned_to == user_id)
    if status:
        query = query.filter(models.TaskAssignment.status == status)
    return query.order_by(models.TaskAssignment.due_date.asc()).all()

@router.post("/init-task-types/")
def initialize_task_types(db: Session = Depends(get_db)):
    task_names = [
        ("Follow-Up", "Reminder to follow up after a call or meeting."),
        ("Call", "Scheduled phone call with lead or client."),
        ("Email", "Send an important email to the customer."),
        ("Meeting", "Set up a virtual or in-person meeting."),
        ("Document Sharing", "Send proposal, invoice or files."),
        ("Internal Reminder", "Internal admin or team task."),
        ("Recurring Task", "Weekly/monthly check-in or process."),
        ("Pipeline Action", "Task triggered by pipeline movement."),
        ("Feedback Request", "Ask for feedback or review."),
        ("Deal Closure", "Final steps to close a deal."),
    ]

    existing = db.query(models.TaskType).count()
    if existing >= 10:
        return {"message": "Task types already initialized."}

    for name, desc in task_names:
        task_type = models.TaskType(name=name, description=desc)
        db.add(task_type)

    db.commit()
    return {"message": "10 task types initialized successfully."}



@router.get("/team-leader/{team_leader_id}/overview")
def get_team_leader_dashboard_overview(team_leader_id: int, db: Session = Depends(get_db)):
    
    salesmen = db.query(User).filter(
        User.assigned_team_leader == team_leader_id,
        User.role == 'salesman'
    ).all()

    salesmen_ids = [s.id for s in salesmen]
    if not salesmen_ids:
        return {
            "salesmen": [],
            "customers": [],
            "pipeline_summary": {},
            "task_summary": {"assigned": 0, "completed": 0},
            "followups": {"due_today": 0, "upcoming": 0}
        }

    
    customers = db.query(Customer).filter(Customer.assigned_to.in_(salesmen_ids)).all()

    
    pipeline_counts = {}
    for customer in customers:
        stage = customer.pipeline_stage or "Unspecified"
        pipeline_counts[stage] = pipeline_counts.get(stage, 0) + 1

    
    assigned_tasks = db.query(models.TaskAssignment).filter(
        models.TaskAssignment.assigned_to.in_(salesmen_ids),
        models.TaskAssignment.status == "assigned"
    ).count()

    completed_tasks = db.query(models.TaskAssignment).filter(
        models.TaskAssignment.assigned_to.in_(salesmen_ids),
        models.TaskAssignment.status == "completed"
    ).count()

    
    from datetime import datetime, timedelta
    now = datetime.utcnow()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start + timedelta(days=1)

    followups_due_today = db.query(FollowUp).join(Customer).filter(
        Customer.assigned_to.in_(salesmen_ids),
        FollowUp.followup_date >= today_start,
        FollowUp.followup_date < today_end
    ).count()

    upcoming_followups = db.query(FollowUp).join(Customer).filter(
        Customer.assigned_to.in_(salesmen_ids),
        FollowUp.followup_date > today_end
    ).count()

    return {
        "salesmen": [
            {
                "id": s.id,
                "name": s.full_name,
                "email": s.email,
                "phone": s.phone,
                "reward_points": s.reward_points,
                "account_status": s.account_status
            }
            for s in salesmen
        ],
        "customers": [
            {
                "id": c.id,
                "first_name": c.first_name,
                "last_name": c.last_name,
                "email": c.email,
                "contact_number": c.contact_number,
                "assigned_to": c.assigned_to,
                "pipeline_stage": c.pipeline_stage,
                "lead_status": c.lead_status,
                "account_status": c.account_status
            }
            for c in customers
        ],
        "pipeline_summary": pipeline_counts,
        "task_summary": {
            "assigned": assigned_tasks,
            "completed": completed_tasks
        },
        "followups": {
            "due_today": followups_due_today,
            "upcoming": upcoming_followups
        }
    }

@router.get("/salesman/overview/{salesman_id}")
def get_salesman_overview(salesman_id: int, db: Session = Depends(get_db)):
    

    
    salesman = db.query(User).filter(User.id == salesman_id, User.role == 'salesman').first()
    if not salesman:
        raise HTTPException(status_code=404, detail="Salesman not found")

    
    total_customers = db.query(Customer).filter(Customer.assigned_to == salesman_id).count()

    
    now = datetime.utcnow()
    in_3_days = now + timedelta(days=3)

    upcoming_followups = db.query(FollowUp)\
        .join(Customer, FollowUp.customer_id == Customer.id)\
        .filter(
            Customer.assigned_to == salesman_id,
            FollowUp.followup_date >= now,
            FollowUp.followup_date <= in_3_days
        ).count()

    
    pending_tasks = db.query(TaskAssignment).filter(
        TaskAssignment.assigned_to == salesman_id,
        TaskAssignment.status == 'assigned'
    ).count()

    
    last_7_days = now - timedelta(days=7)
    recent_interactions = db.query(Interaction).filter(
        Interaction.user_id == salesman_id,
        Interaction.timestamp >= last_7_days
    ).count()

    return {
        "total_customers": total_customers,
        "upcoming_followups": upcoming_followups,
        "pending_tasks": pending_tasks,
        "recent_interactions": recent_interactions
    }

@router.get("/customers/assigned/{salesman_id}")
def get_assigned_customers(salesman_id: int, db: Session = Depends(get_db)):
    customers = db.query(Customer).filter(Customer.assigned_to == salesman_id).all()
    return customers

@router.get("/tasks/assigned/{salesman_id}")
def get_pending_tasks_for_salesman(salesman_id: int, db: Session = Depends(get_db)):
    tasks = db.query(TaskAssignment).filter(
        TaskAssignment.assigned_to == salesman_id,
        TaskAssignment.status == "assigned"
    ).all()

    result = []
    for task in tasks:
        result.append({
            "id": task.id,
            "title": task.title,
            "description": task.description,
            "due_date": task.due_date.isoformat() if task.due_date else None,
            "priority": task.priority,
            "customer_id": task.customer_id,
        })

    return result
