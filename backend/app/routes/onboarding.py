from fastapi import APIRouter, status, Depends
from sqlalchemy.orm import Session
from .. import schemas, models
from ..database import get_db

router = APIRouter(
    prefix="/api/onboarding",
    tags=["Onboarding"]
)

@router.post("/", status_code=status.HTTP_201_CREATED)
def save_onboarding(
    data: schemas.OnboardingSchema,
    db: Session = Depends(get_db)
):
    company = models.Company(
    company_name=data.company_name,
    company_size=data.company_size,
    industry="Default Industry",
    location="Default Location",
    crm_type=data.crm_type.lower().replace(" ", "_")
)

    db.add(company)
    db.commit()
    db.refresh(company)
    return {
        "message": "Company created successfully",
        "company_id": company.id,
        "crm_type": company.crm_type
    }

