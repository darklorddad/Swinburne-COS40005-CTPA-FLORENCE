from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from typing import Union
from .models import ParsedLipidPanel, ParsedHbA1c
from .service import BiometricsService

router = APIRouter()

def get_biometrics_service():
    return BiometricsService()

@router.post("/parse-lab-report")
async def parse_lab_report(
    report_type: str = Form(..., description="Type of report: 'lipid_panel' or 'hba1c'"),
    target_unit: str = Form("mmol/L", description="The unit the app expects (mg/dL or mmol/L)"),
    file: UploadFile = File(...),
    service: BiometricsService = Depends(get_biometrics_service)
):
    # 1. More robust file validation (handles mobile WEBP/HEIC and generic streams)
    content_type = file.content_type or ""
    filename = (file.filename or "").lower()
    
    is_image = content_type.startswith("image/") or filename.endswith(('.png', '.jpg', '.jpeg', '.webp', '.heic'))
    is_pdf = content_type == "application/pdf" or filename.endswith('.pdf')

    if not (is_image or is_pdf):
        print(f"Rejected upload - Type: {content_type}, Name: {filename}") # For Vercel logs
        raise HTTPException(
            status_code=400, 
            detail=f"Invalid file type received ({content_type}). Please upload a valid image or PDF."
        )
    
    # 2. Since we might accept formats the LLM doesn't natively love (like HEIC), 
    # we enforce passing a standard mime type to the service layer just in case.
    safe_mime_type = content_type if content_type.startswith("image/") else "image/jpeg"
    if is_pdf:
        safe_mime_type = "application/pdf"

    content = await file.read()
    
    try:
        return await service.parse_lab_report(
            content, 
            safe_mime_type, 
            report_type, 
            target_unit=target_unit
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process lab report: {str(e)}")
