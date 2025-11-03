import json
import requests # Added for making HTTP requests
from typing import Dict, Any, Callable, List

def get_patient_glucose_level(patient_id: str) -> str:
    """
    Retrieves a simulated glucose level for a given patient using a public random number API.
    Args:
        patient_id (str): The unique identifier for the patient.
    Returns:
        str: A JSON string containing the patient's glucose level or an error message.
    """
    try:
        # Using random.org to get a random integer between 70 and 180 (typical glucose range)
        # This demonstrates a real external API call, though the data is random and not patient-specific.
        response = requests.get("https://www.random.org/integers/?num=1&min=70&max=180&col=1&base=10&format=plain&rnd=new")
        response.raise_for_status() # Raise an exception for HTTP errors
        glucose_value = int(response.text.strip())
        return json.dumps({"patient_id": patient_id, "glucose_level": float(glucose_value), "unit": "mg/dL", "source": "random.org"})
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": f"Failed to fetch glucose level from external API: {e}", "patient_id": patient_id})
    except ValueError:
        return json.dumps({"error": "Failed to parse glucose level from external API response", "patient_id": patient_id})

# Define tool schema for the LLM
TOOLS_SCHEMA: List[Dict[str, Any]] = [
    {
        "type": "function",
        "function": {
            "name": "get_patient_glucose_level",
            "description": "Retrieves a simulated glucose level for a given patient using a public random number API for demonstration.",
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
