from fastapi import APIRouter, HTTPException
from .models import SimulatorRequest, SimulatedMonth
from .service import SimulatorService

router = APIRouter()

@router.post("/generate", response_model=SimulatedMonth)
async def generate_data(request: SimulatorRequest):
    try:
        service = SimulatorService()
        return await service.generate_patient_data(request)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
