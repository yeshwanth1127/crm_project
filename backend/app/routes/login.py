from backend.app.schemas import LoginResponse
from fastapi import APIRouter, Depends, HTTPException, Form
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from jose import jwt
import os

from ..database import get_db
from ..models import User, Company

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = "HS256"

if not SECRET_KEY or not SECRET_KEY.strip():
    raise Exception("❌ SECRET_KEY is missing or empty in environment variables!")

router = APIRouter(prefix="/api", tags=["login"])
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


@router.post("/login", response_model=LoginResponse)
def login(
    email: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if not pwd_context.verify(password, user.password):
        raise HTTPException(status_code=401, detail="Incorrect password")

    company = db.query(Company).filter(Company.id == user.company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    token_data = {
        "sub": user.email,
        "role": user.role,
        "company_id": user.company_id
    }

    print(f"✅ Login success for {email}, generating JWT")

    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)

    return {
        "message": "Login successful",
        "token": token,
        "role": user.role,
        "company_id": user.company_id,
        "crm_type": company.crm_type,
        "email": user.email
    }
