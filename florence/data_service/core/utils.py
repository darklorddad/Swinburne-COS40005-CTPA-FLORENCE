import math
from typing import Optional, List, Dict, Any
from datetime import date
from fastapi import HTTPException

def calculate_age(dob_str: Optional[str]) -> Optional[int]:
    """Calculates age from a date of birth string (YYYY-MM-DD)."""
    if not dob_str:
        return None
    try:
        dob = date.fromisoformat(dob_str)
        today = date.today()
        return today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
    except (ValueError, TypeError):
        return None

def create_paginated_response(
    query_response_data: List[Dict[str, Any]],
    query_response_count: Optional[int],
    page: int,
    page_size: int
) -> Dict[str, Any]:
    """Creates a standardized paginated response dictionary."""
    total_items = query_response_count if query_response_count is not None else 0
    total_pages = math.ceil(total_items / page_size) if total_items > 0 else 0

    return {
        "total_items": total_items,
        "total_pages": total_pages,
        "current_page": page,
        "page_size": page_size,
        "data": query_response_data
    }

def ensure_not_empty(update_dict: Dict[str, Any]):
    """Raises an HTTPException if the provided dictionary is empty."""
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")
