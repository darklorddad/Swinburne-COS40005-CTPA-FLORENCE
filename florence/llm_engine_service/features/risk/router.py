from fastapi import APIRouter, HTTPException, Header
from features.risk.service import RiskAssessmentService

router = APIRouter()

@router.post("/assess")
async def assess_risk(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    token = authorization.split(" ")[1]
    
    service = RiskAssessmentService()
    try:
        result = await service.assess_patient_risk(token)
        return {"status": "success", "risk_level": result["risk_level"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Risk assessment failed: {str(e)}")
