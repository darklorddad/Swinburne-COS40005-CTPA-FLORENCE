import tkinter as tk
from tkinter import messagebox, scrolledtext, ttk
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
from Supabase.client import supabase # For admin creation

# --- Configuration ---
load_dotenv(dotenv_path=project_root / '.env', override=True)
API_BASE_URL = "http://127.0.0.1:8000"
ADMIN_EMAIL = os.environ.get("TEST_ADMIN_EMAIL")
ADMIN_PASSWORD = os.environ.get("TEST_ADMIN_PASSWORD")

TEST_PATIENT_EMAIL = "test.patient.monthly@example.com"
TEST_PATIENT_PASSWORD = "a-secure-password-monthly"
ID_STORAGE_FILE = Path(__file__).resolve().parent / ".monthly_patient_id"

# --- GUI Helper ---
def log_to_window(log_widget, message):
    """Helper to print messages to the GUI's log widget."""
    log_widget.config(state=tk.NORMAL)
    log_widget.insert(tk.END, f"[{time.strftime('%H:%M:%S')}] {message}\n")
    log_widget.see(tk.END)
    log_widget.config(state=tk.DISABLED)
    log_widget.update_idletasks()

# --- API Logic ---

def get_admin_token(log_widget):
    """Logs in as admin and returns the auth token."""
    if not ADMIN_EMAIL or not ADMIN_PASSWORD:
        log_to_window(log_widget, "ERROR: Admin credentials not found in .env file.")
        messagebox.showerror("Error", "Admin credentials (TEST_ADMIN_EMAIL, TEST_ADMIN_PASSWORD) not found in .env file.")
        return None

    log_to_window(log_widget, f"Attempting admin login for {ADMIN_EMAIL}...")
    try:
        with httpx.Client() as client:
            response = client.post(
                f"{API_BASE_URL}/auth/login",
                json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
                timeout=20.0
            )
            response.raise_for_status()
            access_token = response.json()["access_token"]
            log_to_window(log_widget, "Admin login successful.")
            return {"Authorization": f"Bearer {access_token}"}
    except (httpx.HTTPStatusError, httpx.RequestError) as e:
        log_to_window(log_widget, f"ERROR: Admin login failed: {e}")
        messagebox.showerror("Login Failed", f"Admin login failed: {e}")
        return None

def add_test_patient_data(log_widget, buttons):
    """Creates a test patient and seeds one month of data."""
    for btn in buttons: btn.config(state=tk.DISABLED)

    if ID_STORAGE_FILE.exists():
        log_to_window(log_widget, "ERROR: Test patient already exists. Please remove the patient first.")
        messagebox.showerror("Error", "Test patient already exists (found .monthly_patient_id file). Please remove the patient first.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    headers = get_admin_token(log_widget)
    if not headers:
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    patient_id = None
    try:
        # Step 1: Create the patient
        log_to_window(log_widget, f"Creating patient: {TEST_PATIENT_EMAIL}")
        patient_payload = {
            "email": TEST_PATIENT_EMAIL, "password": TEST_PATIENT_PASSWORD, "name": "Monthly Data Patient",
            "phone_number": "555-0123", "date_of_birth": "1985-05-15", "gender": "Male"
        }
        with httpx.Client() as client:
            response = client.post(f"{API_BASE_URL}/admin/patients", json=patient_payload, headers=headers, timeout=20.0)
            response.raise_for_status()
            patient_profile = response.json()["profile"]
            patient_id = patient_profile["id"]
            log_to_window(log_widget, f"Patient created with ID: {patient_id}")
            ID_STORAGE_FILE.write_text(str(patient_id))

        # Step 2: Seed Daily Logs
        log_to_window(log_widget, "Seeding one month of daily logs...")
        today = date.today()
        with httpx.Client() as client:
            for i in range(30):
                log_date = today - timedelta(days=i)
                for meal_time in ["BREAKFAST", "LUNCH", "DINNER"]:
                    log_payload = {
                        "patient_id": patient_id, "log_date": log_date.isoformat(), "meal_time": meal_time,
                        "glucose_before_meal": round(random.uniform(80, 110), 1),
                        "glucose_after_meal": round(random.uniform(120, 180), 1),
                        "meal_desc": f"A typical {meal_time.lower()}."
                    }
                    client.post(f"{API_BASE_URL}/admin/daily-logs", json=log_payload, headers=headers, timeout=20.0)
                log_to_window(log_widget, f"  -> Seeded logs for {log_date.isoformat()}")

        # Step 3: Seed Monitor Data
        log_to_window(log_widget, "Seeding one month of monitor data...")
        with httpx.Client() as client:
            for i in range(30):
                log_date = today - timedelta(days=i)
                for hour in [8, 13, 19]:
                    data_payload = {
                        "patient_id": patient_id, "data_type": "GLUCOSE", "value": round(random.uniform(90, 160), 1),
                        "measured_at": datetime(log_date.year, log_date.month, log_date.day, hour, random.randint(0, 59)).isoformat()
                    }
                    client.post(f"{API_BASE_URL}/admin/monitor-data", json=data_payload, headers=headers, timeout=20.0)
                
                bp_systolic = {"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_SYSTOLIC", "value": round(random.uniform(110, 130), 0), "measured_at": datetime(log_date.year, log_date.month, log_date.day, 9).isoformat()}
                bp_diastolic = {"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_DIASTOLIC", "value": round(random.uniform(70, 85), 0), "measured_at": datetime(log_date.year, log_date.month, log_date.day, 9).isoformat()}
                client.post(f"{API_BASE_URL}/admin/monitor-data", json=bp_systolic, headers=headers, timeout=20.0)
                client.post(f"{API_BASE_URL}/admin/monitor-data", json=bp_diastolic, headers=headers, timeout=20.0)
                log_to_window(log_widget, f"  -> Seeded monitor data for {log_date.isoformat()}")

        # Add one-off data points
        with httpx.Client() as client:
            client.post(f"{API_BASE_URL}/admin/monitor-data", json={"patient_id": patient_id, "data_type": "HBA1C", "value": round(random.uniform(5.7, 7.5), 1), "measured_at": (today - timedelta(days=28)).isoformat()}, headers=headers)
            client.post(f"{API_BASE_URL}/admin/monitor-data", json={"patient_id": patient_id, "data_type": "CHOLESTEROL", "value": round(random.uniform(180, 220), 0), "measured_at": (today - timedelta(days=20)).isoformat()}, headers=headers)
            client.post(f"{API_BASE_URL}/admin/monitor-data", json={"patient_id": patient_id, "data_type": "BMI", "value": round(random.uniform(24, 29), 1), "measured_at": (today - timedelta(days=15)).isoformat()}, headers=headers)
        log_to_window(log_widget, "Seeded one-off data points (HBA1C, CHOLESTEROL, BMI).")

        log_to_window(log_widget, "SUCCESS: Test data seeding complete.")
        messagebox.showinfo("Success", "Test data seeding complete.")

    except (httpx.HTTPStatusError, httpx.RequestError) as e:
        error_detail = e.response.text if hasattr(e, 'response') else str(e)
        log_to_window(log_widget, f"ERROR: Failed during data seeding: {error_detail}")
        messagebox.showerror("Error", f"An error occurred: {error_detail}")
        if patient_id:
            log_to_window(log_widget, f"Attempting to roll back and delete patient {patient_id}...")
            try:
                with httpx.Client() as client:
                    client.delete(f"{API_BASE_URL}/admin/patients/{patient_id}", headers=headers, timeout=20.0)
                log_to_window(log_widget, "Rollback successful.")
                if ID_STORAGE_FILE.exists(): ID_STORAGE_FILE.unlink()
            except Exception as rollback_e:
                log_to_window(log_widget, f"ERROR: Rollback failed: {rollback_e}")
    finally:
        for btn in buttons: btn.config(state=tk.NORMAL)

def remove_test_patient_data(log_widget, buttons):
    """Finds and removes the test patient and their data."""
    for btn in buttons: btn.config(state=tk.DISABLED)

    if not ID_STORAGE_FILE.exists():
        log_to_window(log_widget, "INFO: No test patient ID found. Nothing to remove.")
        messagebox.showinfo("Information", "No test patient ID file found (.monthly_patient_id). Nothing to remove.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    if not messagebox.askyesno("Confirm Deletion", "Are you sure you want to delete the monthly test patient and all their data?"):
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    headers = get_admin_token(log_widget)
    if not headers:
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    try:
        patient_id = ID_STORAGE_FILE.read_text().strip()
        log_to_window(log_widget, f"Found patient ID {patient_id}. Attempting deletion...")

        with httpx.Client() as client:
            response = client.delete(f"{API_BASE_URL}/admin/patients/{patient_id}", headers=headers, timeout=30.0)
            response.raise_for_status()
        
        log_to_window(log_widget, f"SUCCESS: Patient {patient_id} and all associated data deleted.")
        ID_STORAGE_FILE.unlink()
        messagebox.showinfo("Success", f"Patient {patient_id} and all associated data have been deleted.")

    except (httpx.HTTPStatusError, httpx.RequestError) as e:
        error_detail = e.response.text if hasattr(e, 'response') else str(e)
        log_to_window(log_widget, f"ERROR: Failed to delete patient: {error_detail}")
        messagebox.showerror("Error", f"Failed to delete patient: {error_detail}")
    except FileNotFoundError:
        log_to_window(log_widget, "ERROR: ID storage file not found during deletion.")
    finally:
        for btn in buttons: btn.config(state=tk.NORMAL)

def create_admin_user(log_widget, buttons, email_entry, password_entry):
    """Creates a new admin user directly using the service key."""
    for btn in buttons: btn.config(state=tk.DISABLED)
    
    email = email_entry.get()
    password = password_entry.get()

    if not email or not password:
        messagebox.showerror("Error", "Please enter both email and password for the new admin.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    log_to_window(log_widget, f"Attempting to create new admin user: {email}")
    try:
        # Use the Supabase client with service key to create an admin
        user_session = supabase.auth.admin.create_user({
            "email": email,
            "password": password,
            "email_confirm": True,
            "app_metadata": {"role": "ADMIN"},
        })
        
        if not user_session.user:
             raise Exception("User creation returned no user object.")

        log_to_window(log_widget, f"SUCCESS: Admin user {email} created.")
        messagebox.showinfo("Success", f"Admin user '{email}' created successfully.")

    except Exception as e:
        log_to_window(log_widget, f"ERROR: Failed to create admin user: {e}")
        messagebox.showerror("Error", f"Failed to create admin user: {e}")
    finally:
        for btn in buttons: btn.config(state=tk.NORMAL)

# --- GUI Setup ---
def main_gui():
    root = tk.Tk()
    root.title("Data Seeder & Admin Tool")
    
    all_buttons = []

    # --- Patient Seeder Frame ---
    seeder_frame = ttk.LabelFrame(root, text="Monthly Patient Seeder", padding=(10, 5))
    seeder_frame.pack(padx=10, pady=10, fill=tk.X)
    
    add_patient_btn = ttk.Button(seeder_frame, text="Add Monthly Data Patient")
    add_patient_btn.pack(side=tk.LEFT, padx=5, pady=5, expand=True, fill=tk.X)
    all_buttons.append(add_patient_btn)

    remove_patient_btn = ttk.Button(seeder_frame, text="Remove Monthly Data Patient")
    remove_patient_btn.pack(side=tk.LEFT, padx=5, pady=5, expand=True, fill=tk.X)
    all_buttons.append(remove_patient_btn)

    # --- Admin Creator Frame ---
    admin_frame = ttk.LabelFrame(root, text="Admin User Creator", padding=(10, 5))
    admin_frame.pack(padx=10, pady=(0, 10), fill=tk.X)

    ttk.Label(admin_frame, text="New Admin Email:").grid(row=0, column=0, sticky=tk.W, pady=2)
    new_admin_email_entry = ttk.Entry(admin_frame, width=40)
    new_admin_email_entry.grid(row=0, column=1, sticky=tk.EW, pady=2)

    ttk.Label(admin_frame, text="New Admin Password:").grid(row=1, column=0, sticky=tk.W, pady=2)
    new_admin_password_entry = ttk.Entry(admin_frame, show="*", width=40)
    new_admin_password_entry.grid(row=1, column=1, sticky=tk.EW, pady=2)
    
    admin_frame.columnconfigure(1, weight=1)

    create_admin_btn = ttk.Button(admin_frame, text="Create Admin User")
    create_admin_btn.grid(row=2, column=0, columnspan=2, pady=10, sticky=tk.EW)
    all_buttons.append(create_admin_btn)

    # --- Log Output ---
    log_frame = ttk.LabelFrame(root, text="Log Output", padding=(10, 5))
    log_frame.pack(padx=10, pady=(0, 10), fill=tk.BOTH, expand=True)
    
    log_widget = scrolledtext.ScrolledText(log_frame, height=15, wrap=tk.WORD, state=tk.DISABLED)
    log_widget.pack(fill=tk.BOTH, expand=True)

    # --- Button Commands ---
    add_patient_btn.config(command=lambda: threading.Thread(target=add_test_patient_data, args=(log_widget, all_buttons), daemon=True).start())
    remove_patient_btn.config(command=lambda: threading.Thread(target=remove_test_patient_data, args=(log_widget, all_buttons), daemon=True).start())
    create_admin_btn.config(command=lambda: threading.Thread(target=create_admin_user, args=(log_widget, all_buttons, new_admin_email_entry, new_admin_password_entry), daemon=True).start())

    root.mainloop()

# --- Main Execution ---
def run_fastapi_server():
    """Runs the FastAPI server using uvicorn in a separate thread."""
    config = uvicorn.Config(app, host="127.0.0.1", port=8000, log_level="warning")
    server = uvicorn.Server(config)
    server.run()

if __name__ == "__main__":
    # Start the FastAPI server in a daemon thread so it shuts down with the GUI
    fastapi_thread = threading.Thread(target=run_fastapi_server, daemon=True)
    fastapi_thread.start()
    print("Starting FastAPI server in background...")
    time.sleep(3) # Give server time to start
    print("Server should be running. Launching GUI.")

    main_gui()
