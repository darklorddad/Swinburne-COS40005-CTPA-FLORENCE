#!/usr/bin/env python3
"""
Quick test to verify the AI backend endpoints are working
"""

import requests
import json

def test_endpoints():
    base_url = "http://localhost:5000/api"
    
    # Test data
    test_data = {
        "patient_id": "test_001",
        "name": "Test Patient",
        "age": 45,
        "condition": "Type 2 Diabetes",
        "glucose_readings": [
            {"value": 120, "timestamp": "2025-10-01T08:00:00", "notes": "Fasting"},
            {"value": 180, "timestamp": "2025-10-01T12:00:00", "notes": "Post-lunch"}
        ],
        "activity_data": [
            {"steps": 8500, "date": "2025-10-01", "caloriesBurned": 320, "activeMinutes": 45}
        ],
        "diet_log": [
            {"mealType": "Breakfast", "timestamp": "2025-10-01T08:30:00", "calories": 350, "carbs": 45}
        ],
        "medications": [
            {"name": "Metformin", "dosage": "500mg", "frequency": "Twice daily", "adherenceRate": 0.95}
        ]
    }
    
    print("Testing AI Backend Endpoints...")
    print("=" * 50)
    
    # Test health check
    try:
        response = requests.get(f"{base_url}/health")
        if response.status_code == 200:
            print("✅ Health check: WORKING")
        else:
            print(f"❌ Health check: FAILED ({response.status_code})")
    except Exception as e:
        print(f"❌ Health check: ERROR - {e}")
    
    # Test recommendations
    try:
        response = requests.post(f"{base_url}/recommendations", json=test_data)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Recommendations: WORKING ({len(data.get('recommendations', []))} recommendations)")
        else:
            print(f"❌ Recommendations: FAILED ({response.status_code})")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"❌ Recommendations: ERROR - {e}")
    
    # Test chatbot
    try:
        response = requests.post(f"{base_url}/chatbot/message", json={
            "message": "What should I do if my glucose is high?",
            "patient_data": test_data
        })
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Chatbot: WORKING - {data.get('message', '')[:50]}...")
        else:
            print(f"❌ Chatbot: FAILED ({response.status_code})")
    except Exception as e:
        print(f"❌ Chatbot: ERROR - {e}")
    
    # Test anomaly detection
    try:
        response = requests.post(f"{base_url}/anomaly-detection", json=test_data)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Anomaly detection: WORKING ({len(data.get('anomalies', []))} anomalies)")
        else:
            print(f"❌ Anomaly detection: FAILED ({response.status_code})")
    except Exception as e:
        print(f"❌ Anomaly detection: ERROR - {e}")
    
    # Test health insights
    try:
        response = requests.post(f"{base_url}/insights", json=test_data)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Health insights: WORKING")
        else:
            print(f"❌ Health insights: FAILED ({response.status_code})")
    except Exception as e:
        print(f"❌ Health insights: ERROR - {e}")
    
    print("\n" + "=" * 50)
    print("Test completed!")

if __name__ == "__main__":
    test_endpoints()
