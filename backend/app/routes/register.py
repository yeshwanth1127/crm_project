from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from ..schemas import RegisterSchema
from ..models import User, Company
from ..database import get_db

router = APIRouter(prefix="/api", tags=["register"])
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@router.post("/register")
def register(data: RegisterSchema, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered.")

    company = db.query(Company).filter(Company.id == data.company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Invalid company ID. Please complete onboarding first.")

    hashed_password = pwd_context.hash(data.password)

    user = User(
        full_name=data.full_name,
        email=data.email,
        phone=data.phone,
        password=hashed_password,
        role="admin",
        company_id=company.id
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return {
        "message": "Account created successfully",
        "company_id": company.id,
        "crm_type": company.crm_type,
        "user_id": user.id,
        "role": user.role,
        "email": user.email  # ✅ added back
    }

