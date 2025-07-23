from sqlalchemy.orm import Session
from backend.app import models

def log_audit(
    db: Session,
    user_id: int,
    company_id: int,
    role: str,
    action: str,
    resource_type: str,
    resource_id: int,
    before_data: dict,
    after_data: dict,
    ip_address: str = None,
    device_info: str = None
):
    log = models.AuditLog(
        user_id=user_id,
        company_id=company_id,
        role=role,
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        before_data=before_data,
        after_data=after_data,
        ip_address=ip_address,
        device_info=device_info
    )
    db.add(log)
    db.commit()
