import json
from typing import Dict, Any, Callable, List

def get_patient_glucose_level(patient_id: str) -> str:
    """
    Retrieves the current glucose level for a given patient.
    Args:
        patient_id (str): The unique identifier for the patient.
    Returns:
        str: A JSON string containing the patient's glucose level or an error message.
    """
    # Simulate fetching data
    if patient_id == "patient123":
        return json.dumps({"patient_id": patient_id, "glucose_level": 120, "unit": "mg/dL"})
    elif patient_id == "patient456":
        return json.dumps({"patient_id": patient_id, "glucose_level": 95, "unit": "mg/dL"})
    else:
        return json.dumps({"error": "Patient not found", "patient_id": patient_id})

# Define tool schema for the LLM
TOOLS_SCHEMA: List[Dict[str, Any]] = [
    {
        "type": "function",
        "function": {
            "name": "get_patient_glucose_level",
            "description": "Retrieves the current glucose level for a given patient.",
            "parameters": {
                "type": "object",
                "properties": {
                    "patient_id": {
                        "type": "string",
                        "description": "The unique identifier for the patient (e.g., 'patient123', 'patient456')."
                    }
                },
                "required": ["patient_id"]
            }
        }
    }
]

# Map tool names to actual functions
AVAILABLE_TOOLS: Dict[str, Callable] = {
    "get_patient_glucose_level": get_patient_glucose_level
}
