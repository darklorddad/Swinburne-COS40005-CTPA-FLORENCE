import PySimpleGUI as sg
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

def log_to_window(window, message):
    """Helper to print messages to the GUI window's output element."""
    window['-OUTPUT-'].print(f"[{time.strftime('%H:%M:%S')}] {message}")
    window.refresh()

def get_admin_token(window):
    """Logs in as admin and returns the auth token."""
    if not ADMIN_EMAIL or not ADMIN_PASSWORD:
        log_to_window(window, "ERROR: Admin credentials not found in .env file.")
        sg.popup_error("Admin credentials (TEST_ADMIN_EMAIL, TEST_ADMIN_PASSWORD) not found in .env file.")
        return None

    log_to_window(window, f"Attempting admin login for {ADMIN_EMAIL}...")
    try:
        with httpx.Client() as client:
            response = client.post(
                f"{API_BASE_URL}/auth/login",
                json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
                timeout=20.0
            )
            response.raise_for_status()
            access_token = response.json()["access_token"]
            log_to_window(window, "Admin login successful.")
            return {"Authorization": f"Bearer {access_token}"}
    except (httpx.HTTPStatusError, httpx.RequestError) as e:
        log_to_window(window, f"ERROR: Admin login failed: {e}")
        sg.popup_error(f"Admin login failed: {e}")
        return None

def add_test_patient_data(window):
    """Creates a test patient and seeds one month of data."""
    window['-ADD-'].disabled = True
    window['-REMOVE-'].disabled = True
    window.refresh()

    if ID_STORAGE_FILE.exists():
        log_to_window(window, "ERROR: Test patient already exists. Please remove the patient first.")
        sg.popup_error("Test patient already exists (found .monthly_patient_id file). Please remove the patient first.")
        window['-ADD-'].disabled = False
        window['-REMOVE-'].disabled = False
        return

    headers = get_admin_token(window)
    if not headers:
        window['-ADD-'].disabled = False
        window['-REMOVE-'].disabled = False
        return

    patient_id = None
    try:
        # Step 1: Create the patient
        log_to_window(window, f"Creating patient: {TEST_PATIENT_EMAIL}")
        patient_payload = {
            "email": TEST_PATIENT_EMAIL,
            "password": TEST_PATIENT_PASSWORD,
            "name": "Monthly Data Patient",
            "phone_number": "555-0123",
            "date_of_birth": "1985-05-15",
            "gender": "Male"
        }
        with httpx.Client() as client:
            response = client.post(f"{API_BASE_URL}/admin/patients", json=patient_payload, headers=headers, timeout=20.0)
            response.raise_for_status()
            patient_profile = response.json()["profile"]
            patient_id = patient_profile["id"]
            log_to_window(window, f"Patient created with ID: {patient_id}")
            ID_STORAGE_FILE.write_text(str(patient_id))

        # Step 2: Seed Daily Logs for one month
        log_to_window(window, "Seeding one month of daily logs...")
        today = date.today()
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
                with httpx.Client() as client:
                    client.post(f"{API_BASE_URL}/admin/daily-logs", json=log_payload, headers=headers, timeout=20.0)
            log_to_window(window, f"  -> Seeded logs for {log_date.isoformat()}")

        # Step 3: Seed Monitor Data for one month
        log_to_window(window, "Seeding one month of monitor data...")
        for i in range(30):
            log_date = today - timedelta(days=i)
            # Glucose (3 times a day)
            for hour in [8, 13, 19]:
                data_payload = {
                    "patient_id": patient_id, "data_type": "GLUCOSE", "value": round(random.uniform(90, 160), 1),
                    "measured_at": datetime(log_date.year, log_date.month, log_date.day, hour, random.randint(0, 59)).isoformat()
                }
                with httpx.Client() as client:
                    client.post(f"{API_BASE_URL}/admin/monitor-data", json=data_payload, headers=headers, timeout=20.0)
            
            # Blood Pressure (once a day)
            bp_systolic = {"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_SYSTOLIC", "value": round(random.uniform(110, 130), 0), "measured_at": datetime(log_date.year, log_date.month, log_date.day, 9).isoformat()}
            bp_diastolic = {"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_DIASTOLIC", "value": round(random.uniform(70, 85), 0), "measured_at": datetime(log_date.year, log_date.month, log_date.day, 9).isoformat()}
            with httpx.Client() as client:
                client.post(f"{API_BASE_URL}/admin/monitor-data", json=bp_systolic, headers=headers, timeout=20.0)
                client.post(f"{API_BASE_URL}/admin/monitor-data", json=bp_diastolic, headers=headers, timeout=20.0)
            log_to_window(window, f"  -> Seeded monitor data for {log_date.isoformat()}")

        # Add one-off data points
        with httpx.Client() as client:
            client.post(f"{API_BASE_URL}/admin/monitor-data", json={"patient_id": patient_id, "data_type": "HBA1C", "value": round(random.uniform(5.7, 7.5), 1), "measured_at": (today - timedelta(days=28)).isoformat()}, headers=headers)
            client.post(f"{API_BASE_URL}/admin/monitor-data", json={"patient_id": patient_id, "data_type": "CHOLESTEROL", "value": round(random.uniform(180, 220), 0), "measured_at": (today - timedelta(days=20)).isoformat()}, headers=headers)
            client.post(f"{API_BASE_URL}/admin/monitor-data", json={"patient_id": patient_id, "data_type": "BMI", "value": round(random.uniform(24, 29), 1), "measured_at": (today - timedelta(days=15)).isoformat()}, headers=headers)
        log_to_window(window, "Seeded one-off data points (HBA1C, CHOLESTEROL, BMI).")

        log_to_window(window, "SUCCESS: Test data seeding complete.")
        sg.popup("Success", "Test data seeding complete.")

    except (httpx.HTTPStatusError, httpx.RequestError) as e:
        error_detail = e.response.text if hasattr(e, 'response') else str(e)
        log_to_window(window, f"ERROR: Failed during data seeding: {error_detail}")
        sg.popup_error(f"An error occurred: {error_detail}")
        # Rollback if patient was created
        if patient_id:
            log_to_window(window, f"Attempting to roll back and delete patient {patient_id}...")
            try:
                with httpx.Client() as client:
                    client.delete(f"{API_BASE_URL}/admin/patients/{patient_id}", headers=headers, timeout=20.0)
                log_to_window(window, "Rollback successful.")
                if ID_STORAGE_FILE.exists():
                    ID_STORAGE_FILE.unlink()
            except Exception as rollback_e:
                log_to_window(window, f"ERROR: Rollback failed: {rollback_e}")
    finally:
        window['-ADD-'].disabled = False
        window['-REMOVE-'].disabled = False

def remove_test_patient_data(window):
    """Finds and removes the test patient and their data."""
    window['-ADD-'].disabled = True
    window['-REMOVE-'].disabled = True
    window.refresh()

    if not ID_STORAGE_FILE.exists():
        log_to_window(window, "INFO: No test patient ID found. Nothing to remove.")
        sg.popup("Information", "No test patient ID file found (.monthly_patient_id). Nothing to remove.")
        window['-ADD-'].disabled = False
        window['-REMOVE-'].disabled = False
        return

    if not sg.popup_yes_no("Are you sure you want to delete the monthly test patient and all their data?", title="Confirm Deletion"):
        window['-ADD-'].disabled = False
        window['-REMOVE-'].disabled = False
        return

    headers = get_admin_token(window)
    if not headers:
        window['-ADD-'].disabled = False
        window['-REMOVE-'].disabled = False
        return

    try:
        patient_id = ID_STORAGE_FILE.read_text().strip()
        log_to_window(window, f"Found patient ID {patient_id}. Attempting deletion...")

        with httpx.Client() as client:
            response = client.delete(f"{API_BASE_URL}/admin/patients/{patient_id}", headers=headers, timeout=30.0)
            response.raise_for_status()
        
        log_to_window(window, f"SUCCESS: Patient {patient_id} and all associated data deleted.")
        ID_STORAGE_FILE.unlink() # Clean up the ID file
        sg.popup("Success", f"Patient {patient_id} and all associated data have been deleted.")

    except (httpx.HTTPStatusError, httpx.RequestError) as e:
        error_detail = e.response.text if hasattr(e, 'response') else str(e)
        log_to_window(window, f"ERROR: Failed to delete patient: {error_detail}")
        sg.popup_error(f"Failed to delete patient: {error_detail}")
    except FileNotFoundError:
        log_to_window(window, "ERROR: ID storage file not found during deletion.")
    finally:
        window['-ADD-'].disabled = False
        window['-REMOVE-'].disabled = False

# --- GUI Layout ---
def main():
    sg.theme('SystemDefault')

    layout = [
        [sg.Text("Test Data Seeder", font=("Helvetica", 16))],
        [sg.Text("Use this tool to add or remove a test patient with one month of sample data.")],
        [sg.HorizontalSeparator()],
        [
            sg.Button("Add Monthly Data Patient", key='-ADD-', size=(25, 2)),
            sg.Button("Remove Monthly Data Patient", key='-REMOVE-', size=(25, 2), button_color=('white', 'firebrick3'))
        ],
        [sg.HorizontalSeparator()],
        [sg.Text("Log Output:")],
        [sg.Output(size=(80, 20), key='-OUTPUT-')]
    ]

    window = sg.Window("Data Seeder", layout, finalize=True)

    # --- Event Loop ---
    while True:
        event, values = window.read()
        if event == sg.WIN_CLOSED:
            break
        if event == '-ADD-':
            # Run in a thread to keep the GUI responsive
            threading.Thread(target=add_test_patient_data, args=(window,), daemon=True).start()
        if event == '-REMOVE-':
            threading.Thread(target=remove_test_patient_data, args=(window,), daemon=True).start()

    window.close()

# --- Main Execution ---
if __name__ == "__main__":
    def run_server():
        """Runs the FastAPI server using uvicorn."""
        uvicorn.run(app, host="127.0.0.1", port=8000, log_level="warning")

    # Start the server in a daemon thread
    server_thread = threading.Thread(target=run_server, daemon=True)
    server_thread.start()
    print("Starting FastAPI server in background...")
    time.sleep(3) # Give server time to start
    print("Server should be running. Launching GUI.")

    main()
