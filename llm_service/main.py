from nicegui import ui
import httpx
import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import uvicorn
import threading
import time
import random
from datetime import date, timedelta, datetime

# Add project root to Python path to resolve imports
project_root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(project_root))

from Supabase.main import app

# --- Configuration ---
load_dotenv(dotenv_path=project_root / '.env', override=True)
API_BASE_URL = "http://127.0.0.1:8000"
ADMIN_EMAIL = os.environ.get("TEST_ADMIN_EMAIL")
ADMIN_PASSWORD = os.environ.get("TEST_ADMIN_PASSWORD")

TEST_PATIENT_EMAIL = "test.patient.monthly@example.com"
TEST_PATIENT_PASSWORD = "a-secure-password-monthly"
ID_STORAGE_FILE = Path(__file__).resolve().parent / ".monthly_patient_id"

# --- API Client & Helpers ---

async def get_admin_token(log):
    """Logs in as admin and returns the auth token."""
    if not ADMIN_EMAIL or not ADMIN_PASSWORD:
        log.push("ERROR: Admin credentials not found in .env file.")
        ui.notify("Admin credentials (TEST_ADMIN_EMAIL, TEST_ADMIN_PASSWORD) not found in .env file.", color='negative')
        return None

    log.push(f"Attempting admin login for {ADMIN_EMAIL}...")
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{API_BASE_URL}/auth/login",
                json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
                timeout=20.0
            )
            response.raise_for_status()
            access_token = response.json()["access_token"]
            log.push("Admin login successful.")
            return {"Authorization": f"Bearer {access_token}"}
    except (httpx.HTTPStatusError, httpx.RequestError) as e:
        log.push(f"ERROR: Admin login failed: {e}")
        ui.notify(f"Admin login failed: {e}", color='negative')
        return None

async def add_test_patient_data(log, add_button, remove_button):
    """Creates a test patient and seeds one month of data."""
    add_button.disable()
    remove_button.disable()

    if ID_STORAGE_FILE.exists():
        log.push("ERROR: Test patient already exists. Please remove the patient first.")
        ui.notify("Test patient already exists. Please remove the patient first.", color='negative')
        add_button.enable()
        remove_button.enable()
        return

    headers = await get_admin_token(log)
    if not headers:
        add_button.enable()
        remove_button.enable()
        return

    patient_id = None
    try:
        # Step 1: Create the patient
        log.push(f"Creating patient: {TEST_PATIENT_EMAIL}")
        patient_payload = {
            "email": TEST_PATIENT_EMAIL,
            "password": TEST_PATIENT_PASSWORD,
            "name": "Monthly Data Patient",
            "phone_number": "555-0123",
            "date_of_birth": "1985-05-15",
            "gender": "Male"
        }
        async with httpx.AsyncClient() as client:
            response = await client.post(f"{API_BASE_URL}/admin/patients", json=patient_payload, headers=headers, timeout=20.0)
            response.raise_for_status()
            patient_profile = response.json()["profile"]
            patient_id = patient_profile["id"]
            log.push(f"Patient created with ID: {patient_id}")
            ID_STORAGE_FILE.write_text(str(patient_id))

        # Step 2: Seed Daily Logs for one month
        log.push("Seeding one month of daily logs...")
        today = date.today()
        async with httpx.AsyncClient() as client:
            for i in range(30):
                log_date = today - timedelta(days=i)
                for meal_time in ["BREAKFAST", "LUNCH", "DINNER"]:
                    log_payload = {
                        "patient_id": patient_id,
                        "log_date": log_date.isoformat(),
                        "meal_time": meal_time,
                        "glucose_before_meal": round(random.uniform(80, 110), 1),
                        "glucose_after_meal": round(random.uniform(120, 180), 1),
                        "meal_desc": f"A typical {meal_time.lower()} on {log_date.strftime('%A')}."
                    }
                    await client.post(f"{API_BASE_URL}/admin/daily-logs", json=log_payload, headers=headers, timeout=20.0)
                log.push(f"  -> Seeded logs for {log_date.isoformat()}")

        # Step 3: Seed Monitor Data for one month
        log.push("Seeding one month of monitor data...")
        async with httpx.AsyncClient() as client:
            for i in range(30):
                log_date = today - timedelta(days=i)
                # Glucose (3 times a day)
                for hour in [8, 13, 19]:
                    data_payload = {
                        "patient_id": patient_id, "data_type": "GLUCOSE", "value": round(random.uniform(90, 160), 1),
                        "measured_at": datetime(log_date.year, log_date.month, log_date.day, hour, random.randint(0, 59)).isoformat()
                    }
                    await client.post(f"{API_BASE_URL}/admin/monitor-data", json=data_payload, headers=headers, timeout=20.0)
                
                # Blood Pressure (once a day)
                bp_systolic = {"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_SYSTOLIC", "value": round(random.uniform(110, 130), 0), "measured_at": datetime(log_date.year, log_date.month, log_date.day, 9).isoformat()}
                bp_diastolic = {"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_DIASTOLIC", "value": round(random.uniform(70, 85), 0), "measured_at": datetime(log_date.year, log_date.month, log_date.day, 9).isoformat()}
                await client.post(f"{API_BASE_URL}/admin/monitor-data", json=bp_systolic, headers=headers, timeout=20.0)
                await client.post(f"{API_BASE_URL}/admin/monitor-data", json=bp_diastolic, headers=headers, timeout=20.0)
                log.push(f"  -> Seeded monitor data for {log_date.isoformat()}")

        # Add one-off data points
        async with httpx.AsyncClient() as client:
            await client.post(f"{API_BASE_URL}/admin/monitor-data", json={"patient_id": patient_id, "data_type": "HBA1C", "value": round(random.uniform(5.7, 7.5), 1), "measured_at": (today - timedelta(days=28)).isoformat()}, headers=headers)
            await client.post(f"{API_BASE_URL}/admin/monitor-data", json={"patient_id": patient_id, "data_type": "CHOLESTEROL", "value": round(random.uniform(180, 220), 0), "measured_at": (today - timedelta(days=20)).isoformat()}, headers=headers)
            await client.post(f"{API_BASE_URL}/admin/monitor-data", json={"patient_id": patient_id, "data_type": "BMI", "value": round(random.uniform(24, 29), 1), "measured_at": (today - timedelta(days=15)).isoformat()}, headers=headers)
        log.push("Seeded one-off data points (HBA1C, CHOLESTEROL, BMI).")

        log.push("SUCCESS: Test data seeding complete.")
        ui.notify("Test data seeding complete.", color='positive')

    except (httpx.HTTPStatusError, httpx.RequestError) as e:
        error_detail = e.response.text if hasattr(e, 'response') else str(e)
        log.push(f"ERROR: Failed during data seeding: {error_detail}")
        ui.notify(f"An error occurred: {error_detail}", color='negative')
        # Rollback if patient was created
        if patient_id:
            log.push(f"Attempting to roll back and delete patient {patient_id}...")
            try:
                async with httpx.AsyncClient() as client:
                    await client.delete(f"{API_BASE_URL}/admin/patients/{patient_id}", headers=headers, timeout=20.0)
                log.push("Rollback successful.")
                if ID_STORAGE_FILE.exists():
                    ID_STORAGE_FILE.unlink()
            except Exception as rollback_e:
                log.push(f"ERROR: Rollback failed: {rollback_e}")
    finally:
        add_button.enable()
        remove_button.enable()

async def remove_test_patient_data(log, add_button, remove_button):
    """Finds and removes the test patient and their data."""
    add_button.disable()
    remove_button.disable()

    if not ID_STORAGE_FILE.exists():
        log.push("INFO: No test patient ID found. Nothing to remove.")
        ui.notify("No test patient ID file found. Nothing to remove.", color='info')
        add_button.enable()
        remove_button.enable()
        return

    with ui.dialog() as dialog, ui.card():
        ui.label('Are you sure you want to delete the monthly test patient and all their data?')
        with ui.row():
            ui.button('Yes', on_click=lambda: dialog.submit('yes'))
            ui.button('No', on_click=lambda: dialog.submit('no'))
    
    result = await dialog
    if result != 'yes':
        add_button.enable()
        remove_button.enable()
        return

    headers = await get_admin_token(log)
    if not headers:
        add_button.enable()
        remove_button.enable()
        return

    try:
        patient_id = ID_STORAGE_FILE.read_text().strip()
        log.push(f"Found patient ID {patient_id}. Attempting deletion...")

        async with httpx.AsyncClient() as client:
            response = await client.delete(f"{API_BASE_URL}/admin/patients/{patient_id}", headers=headers, timeout=30.0)
            response.raise_for_status()
        
        log.push(f"SUCCESS: Patient {patient_id} and all associated data deleted.")
        ID_STORAGE_FILE.unlink() # Clean up the ID file
        ui.notify(f"Patient {patient_id} and all associated data have been deleted.", color='positive')

    except (httpx.HTTPStatusError, httpx.RequestError) as e:
        error_detail = e.response.text if hasattr(e, 'response') else str(e)
        log.push(f"ERROR: Failed to delete patient: {error_detail}")
        ui.notify(f"Failed to delete patient: {error_detail}", color='negative')
    except FileNotFoundError:
        log.push("ERROR: ID storage file not found during deletion.")
    finally:
        add_button.enable()
        remove_button.enable()

# --- GUI Layout ---
@ui.page('/')
def main_page():
    ui.label('Test Data Seeder').classes('text-h4')
    ui.label('Use this tool to add or remove a test patient with one month of sample data.')
    
    with ui.row().classes('w-full justify-center q-my-md'):
        add_button = ui.button('Add Monthly Data Patient', on_click=lambda: add_test_patient_data(log, add_button, remove_button))
        remove_button = ui.button('Remove Monthly Data Patient', on_click=lambda: remove_test_patient_data(log, add_button, remove_button), color='red')

    ui.label('Log Output').classes('text-h6')
    log = ui.log(max_lines=50).classes('w-full h-96')

# --- Main Execution ---
def run_fastapi_server():
    """Runs the FastAPI server using uvicorn in a separate thread."""
    config = uvicorn.Config(app, host="127.0.0.1", port=8000, log_level="warning")
    server = uvicorn.Server(config)
    server.run()

if __name__ in {"__main__", "__mp_main__"}:
    # Start the FastAPI server in a daemon thread so it shuts down with the GUI
    fastapi_thread = threading.Thread(target=run_fastapi_server, daemon=True)
    fastapi_thread.start()
    print("Starting FastAPI server in background...")
    time.sleep(3) # Give server time to start
    print("Server should be running. Launching GUI.")

    ui.run(title="Data Seeder", reload=False)
