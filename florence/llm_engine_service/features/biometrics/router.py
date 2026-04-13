from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from typing import Union
from .models import ParsedLipidPanel, ParsedHbA1c
from .service import BiometricsService

router = APIRouter()

def get_biometrics_service():
    return BiometricsService()

@router.post("/parse-lab-report", response_model=Union[ParsedLipidPanel, ParsedHbA1c])
async def parse_lab_report(
    report_type: str = Form(..., description="Type of report: 'lipid_panel' or 'hba1c'"),
    file: UploadFile = File(...),
    service: BiometricsService = Depends(get_biometrics_service)
):
    allowed_types = ["image/jpeg", "image/png", "application/pdf"]
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="Invalid file type. Please upload an image or PDF.")
    
    content = await file.read()
    
    try:
        return await service.parse_lab_report(content, file.content_type, report_type)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process lab report: {str(e)}")
