import tkinter as tk
from tkinter import messagebox, scrolledtext, ttk
import os
import sys
from pathlib import Path
import threading
import time
import random
from datetime import date, timedelta, datetime
import json
import base64
import httpx
from supabase import create_client, Client

# Add project root to Python path to resolve imports
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))


# --- Configuration ---
CREDENTIALS_FILE = Path(__file__).resolve().parent / ".admin_creds.json"

TEST_PATIENT_EMAIL = "test.patient.monthly@example.com"
TEST_PATIENT_PASSWORD = "a-secure-password-monthly"
ID_STORAGE_FILE = Path(__file__).resolve().parent / ".monthly_patient_id"

# --- Credential Management ---
def save_credentials(email, password, url, key, api_base_url):
    """Saves admin, Supabase, and API URL credentials to a local file."""
    try:
        with open(CREDENTIALS_FILE, 'w') as f:
            json.dump({
                'email': email, 'password': password, 
                'supabase_url': url, 'supabase_key': key,
                'api_base_url': api_base_url
            }, f)
    except Exception as e:
        print(f"Error saving credentials: {e}")

def load_credentials():
    """Loads credentials from a local file if it exists."""
    if CREDENTIALS_FILE.exists():
        try:
            with open(CREDENTIALS_FILE, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading credentials: {e}")
    return {}

def delete_credentials():
    """Deletes the local credentials file."""
    try:
        if CREDENTIALS_FILE.exists():
            CREDENTIALS_FILE.unlink()
    except Exception as e:
        print(f"Error deleting credentials file: {e}")


def get_jwt_payload(token: str) -> dict:
    """Decodes the payload from a JWT without verification."""
    try:
        # A JWT is composed of three parts separated by dots. The payload is the second part.
        payload_part = token.split('.')[1]
        # The payload is Base64Url encoded. We need to add padding if it's missing.
        payload_part += '=' * (-len(payload_part) % 4)
        decoded_payload = base64.urlsafe_b64decode(payload_part)
        return json.loads(decoded_payload)
    except Exception:
        # If decoding fails, it's not a valid JWT or is malformed.
        return {}


# --- GUI Helper ---
def log_to_window(log_widget, message):
    """Helper to print messages to the GUI's log widget."""
    log_widget.config(state=tk.NORMAL)
    log_widget.insert(tk.END, f"[{time.strftime('%H:%M:%S')}] {message}\n")
    log_widget.see(tk.END)
    log_widget.config(state=tk.DISABLED)
    log_widget.update_idletasks()

# --- API Logic ---

def run_all_tests(log_widget, buttons, supabase_client: Client, admin_token: str, base_url: str):
    """Runs a suite of GET requests against parameter-less endpoints to check their status."""
    for btn in buttons: btn.config(state=tk.DISABLED)
    log_to_window(log_widget, "Starting bulk API smoke test...")

    if not base_url:
        messagebox.showerror("Error", "Please provide the API Base URL.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    if not supabase_client:
        messagebox.showerror("Error", "Supabase client not initialized. Please connect again.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    try:
        # 1. Define endpoints
        endpoints = {
            "NO_AUTH": [
                "/all-data", "/organisations", "/patient_profiles", "/clinician_profiles",
                "/daily_patient_logs", "/patient_monitor_data", "/clinician_notes"
            ],
            "ADMIN": [
                "/admin/patients", "/admin/clinicians", "/admin/organisations",
                "/admin/daily-logs", "/admin/monitor-data", "/admin/thresholds"
            ],
            "PATIENT": [
                "/patients/me", "/patients/me/monitor-data", "/patients/me/daily-logs",
                "/patients/me/thresholds"
            ],
            "CLINICIAN": [
                "/clinicians/me", "/clinicians/me/patients"
            ]
        }
        
        tokens = {"ADMIN": None, "PATIENT": None, "CLINICIAN": None}

        # 2. Get Admin token from the connected client
        if not admin_token:
            raise Exception("Could not get admin session. Please connect again.")
        tokens["ADMIN"] = admin_token
        log_to_window(log_widget, "-> Fetched admin token.")

        # 3. Get Patient token
        if not ID_STORAGE_FILE.exists():
            log_to_window(log_widget, "WARNING: Monthly test patient does not exist. Skipping PATIENT endpoints. Use the seeder to create one.")
        else:
            log_to_window(log_widget, f"Logging in as test patient: {TEST_PATIENT_EMAIL}")
            temp_client = create_client(supabase_client.supabase_url, supabase_client.supabase_key)
            patient_session = temp_client.auth.sign_in_with_password({"email": TEST_PATIENT_EMAIL, "password": TEST_PATIENT_PASSWORD})
            tokens["PATIENT"] = patient_session.session.access_token
            log_to_window(log_widget, "-> Fetched patient token.")

        # 4. Get Clinician token (not implemented yet)
        log_to_window(log_widget, "WARNING: Clinician testing is not yet implemented. Skipping CLINICIAN endpoints.")

        # 5. Run tests
        with httpx.Client(base_url=base_url.strip('/')) as http_client:
            log_to_window(log_widget, "\n--- Testing /auth/me ---")
            for role, token in tokens.items():
                if token:
                    headers = {
                        "apikey": supabase_client.supabase_key,
                        "Authorization": f"Bearer {token}"
                    }
                    response = http_client.get("/auth/me", headers=headers)
                    log_to_window(log_widget, f"GET /auth/me with {role} token: {response.status_code}")

            for auth_type, path_list in endpoints.items():
                log_to_window(log_widget, f"\n--- Testing {auth_type} Endpoints ---")
                token = tokens.get(auth_type)
                
                if auth_type not in ["NO_AUTH"] and not token:
                    log_to_window(log_widget, f"Skipping because no {auth_type} token is available.")
                    continue

                headers = {"apikey": supabase_client.supabase_key}
                if token:
                    headers["Authorization"] = f"Bearer {token}"

                for path in path_list:
                    response = http_client.get(path, headers=headers)
                    log_to_window(log_widget, f"GET {path}: {response.status_code}")
                    time.sleep(0.1)

        log_to_window(log_widget, "\nSUCCESS: Bulk API smoke test complete.")
        messagebox.showinfo("Success", "Bulk API smoke test complete. Check the log for details.")

    except Exception as e:
        error_detail = str(e)
        log_to_window(log_widget, f"ERROR: Test run failed: {error_detail}")
        messagebox.showerror("Error", f"An error occurred during the test run: {error_detail}")
    finally:
        for btn in buttons: btn.config(state=tk.NORMAL)


def add_test_patient_data(log_widget, buttons, supabase_client: Client, use_api: bool, base_url: str, admin_token: str):
    """Creates a test patient and seeds one month of data, either via API or direct DB connection."""
    for btn in buttons: btn.config(state=tk.DISABLED)

    if ID_STORAGE_FILE.exists():
        log_to_window(log_widget, "ERROR: Test patient already exists. Please remove the patient first.")
        messagebox.showerror("Error", "Test patient already exists (found .monthly_patient_id file). Please remove the patient first.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    new_user = None
    try:
        patient_id = None
        new_user = None # For rollback on direct DB creation

        if use_api:
            log_to_window(log_widget, "Attempting to create patient via API endpoint...")
            if not all([base_url, admin_token, supabase_client]):
                messagebox.showerror("Error", "API Base URL, Admin Token, and Supabase client are required to use the API endpoint.")
                raise Exception("Missing arguments for API call.")

            headers = { "apikey": supabase_client.supabase_key, "Authorization": f"Bearer {admin_token}" }
            payload = {
                "email": TEST_PATIENT_EMAIL, "password": TEST_PATIENT_PASSWORD, "name": "Monthly Data Patient (API)",
                "phone_number": "555-0123", "date_of_birth": "1985-05-15", "gender": "Male"
            }
            with httpx.Client(base_url=base_url.strip('/')) as http_client:
                response = http_client.post("/admin/patients", headers=headers, json=payload)
                response.raise_for_status()
                patient_profile = response.json().get("profile", {})
                patient_id = patient_profile.get("id")
                if not patient_id: raise Exception("API response did not contain a patient profile ID.")
                log_to_window(log_widget, f"Patient created via API with ID: {patient_id}")
        else:
            log_to_window(log_widget, "Attempting to create patient via direct DB connection...")
            if not supabase_client:
                messagebox.showerror("Error", "Supabase client not initialized. Please connect again.")
                raise Exception("Supabase client not initialized.")
            
            log_to_window(log_widget, f"Creating auth user: {TEST_PATIENT_EMAIL}")
            user_session = supabase_client.auth.admin.create_user({
                "email": TEST_PATIENT_EMAIL, "password": TEST_PATIENT_PASSWORD, "email_confirm": True, "app_metadata": {"role": "PATIENT"}
            })
            new_user = user_session.user
            if not new_user: raise Exception("Failed to create user in authentication system.")
            log_to_window(log_widget, f"Auth user created with ID: {new_user.id}")

            log_to_window(log_widget, "Creating patient profile...")
            profile_data = {"user_id": new_user.id, "name": "Monthly Data Patient", "phone_number": "555-0123", "date_of_birth": "1985-05-15", "gender": "Male"}
            patient_profile_res = supabase_client.table('patient_profiles').insert(profile_data).execute()
            patient_profile = patient_profile_res.data[0]
            patient_id = patient_profile["id"]
            log_to_window(log_widget, f"Patient profile created with ID: {patient_id}")

        # --- Common Data Generation and Seeding ---
        if not patient_id: raise Exception("Could not determine patient ID. Aborting data seeding.")
        ID_STORAGE_FILE.write_text(str(patient_id))

        log_to_window(log_widget, "Generating one month of seed data...")
        today = date.today()
        logs_to_insert = []
        for i in range(30):
            log_date = today - timedelta(days=i)
            for meal_time in ["BREAKFAST", "LUNCH", "DINNER"]:
                logs_to_insert.append({
                    "patient_id": patient_id, "log_date": log_date.isoformat(), "meal_time": meal_time,
                    "glucose_before_meal": round(random.uniform(80, 110), 1), "glucose_after_meal": round(random.uniform(120, 180), 1),
                    "meal_desc": f"A typical {meal_time.lower()}."
                })
        
        monitor_data_to_insert = []
        for i in range(30):
            log_date = today - timedelta(days=i)
            for hour in [8, 13, 19]:
                monitor_data_to_insert.append({"patient_id": patient_id, "data_type": "GLUCOSE", "value": round(random.uniform(90, 160), 1), "measured_at": datetime(log_date.year, log_date.month, log_date.day, hour, random.randint(0, 59)).isoformat()})
            bp_systolic = {"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_SYSTOLIC", "value": round(random.uniform(110, 130), 0), "measured_at": datetime(log_date.year, log_date.month, log_date.day, 9).isoformat()}
            bp_diastolic = {"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_DIASTOLIC", "value": round(random.uniform(70, 85), 0), "measured_at": datetime(log_date.year, log_date.month, log_date.day, 9).isoformat()}
            monitor_data_to_insert.extend([bp_systolic, bp_diastolic])
        monitor_data_to_insert.append({"patient_id": patient_id, "data_type": "HBA1C", "value": round(random.uniform(5.7, 7.5), 1), "measured_at": (today - timedelta(days=28)).isoformat()})
        monitor_data_to_insert.append({"patient_id": patient_id, "data_type": "CHOLESTEROL", "value": round(random.uniform(180, 220), 0), "measured_at": (today - timedelta(days=20)).isoformat()})
        monitor_data_to_insert.append({"patient_id": patient_id, "data_type": "BMI", "value": round(random.uniform(24, 29), 1), "measured_at": (today - timedelta(days=15)).isoformat()})
        log_to_window(log_widget, f"-> Generated {len(logs_to_insert)} daily logs and {len(monitor_data_to_insert)} monitor data points.")

        if use_api:
            log_to_window(log_widget, "Seeding data via API. This may take a moment...")
            headers = { "apikey": supabase_client.supabase_key, "Authorization": f"Bearer {admin_token}" }
            with httpx.Client(base_url=base_url.strip('/')) as http_client:
                for i, log_payload in enumerate(logs_to_insert):
                    response = http_client.post("/admin/daily-logs", headers=headers, json=log_payload)
                    response.raise_for_status()
                    if (i + 1) % 10 == 0: log_to_window(log_widget, f"  -> Seeded {i+1}/{len(logs_to_insert)} daily logs...")
                log_to_window(log_widget, "-> All daily logs seeded.")
                
                for i, data_payload in enumerate(monitor_data_to_insert):
                    response = http_client.post("/admin/monitor-data", headers=headers, json=data_payload)
                    response.raise_for_status()
                    if (i + 1) % 10 == 0: log_to_window(log_widget, f"  -> Seeded {i+1}/{len(monitor_data_to_insert)} monitor data points...")
                log_to_window(log_widget, "-> All monitor data seeded.")
        else:
            # Direct DB seeding also creates default thresholds
            log_to_window(log_widget, "Creating default thresholds for patient...")
            DEFAULT_THRESHOLDS = [
                {'data_type': 'GLUCOSE', 'min_value': 70.0, 'max_value': 180.0}, {'data_type': 'HBA1C', 'min_value': 4.0, 'max_value': 7.0},
                {'data_type': 'BMI', 'min_value': 18.5, 'max_value': 24.9}, {'data_type': 'CHOLESTEROL', 'min_value': 100.0, 'max_value': 199.0},
                {'data_type': 'ECG', 'min_value': 60.0, 'max_value': 100}, {'data_type': 'BLOOD_PRESSURE_SYSTOLIC', 'min_value': 90.0, 'max_value': 120},
                {'data_type': 'BLOOD_PRESSURE_DIASTOLIC', 'min_value': 60.0, 'max_value': 80}
            ]
            thresholds_to_insert = [{**threshold, 'patient_id': patient_id} for threshold in DEFAULT_THRESHOLDS]
            supabase_client.table('patient_thresholds').insert(thresholds_to_insert).execute()
            log_to_window(log_widget, "Default thresholds created for patient.")

            log_to_window(log_widget, "Seeding daily logs and monitor data in bulk...")
            supabase_client.table('daily_patient_logs').insert(logs_to_insert).execute()
            supabase_client.table('patient_monitor_data').insert(monitor_data_to_insert).execute()
            log_to_window(log_widget, "-> Bulk data insertion complete.")

        log_to_window(log_widget, "SUCCESS: Test data seeding complete.")
        messagebox.showinfo("Success", "Test data seeding complete.")

    except Exception as e:
        error_detail = str(e)
        if "User not allowed" in error_detail:
            helpful_message = "This operation requires the Supabase 'service_role' key. Please ensure you have entered the correct key and not the 'anon' key."
            log_to_window(log_widget, f"ERROR: {error_detail}. HINT: Check if you are using the service_role key.")
            messagebox.showerror("Permission Denied", f"Failed during data seeding: {error_detail}\n\n{helpful_message}")
        else:
            log_to_window(log_widget, f"ERROR: Failed during data seeding: {error_detail}")
            messagebox.showerror("Error", f"An error occurred: {error_detail}")
        
        if not use_api and new_user: # Only attempt rollback for direct DB method
            log_to_window(log_widget, f"Attempting to roll back and delete auth user {new_user.id}...")
            try:
                supabase_client.auth.admin.delete_user(new_user.id)
                log_to_window(log_widget, "Rollback successful.")
                if ID_STORAGE_FILE.exists(): ID_STORAGE_FILE.unlink()
            except Exception as rollback_e:
                log_to_window(log_widget, f"ERROR: Rollback failed: {rollback_e}")
    finally:
        for btn in buttons: btn.config(state=tk.NORMAL)

def remove_test_patient_data(log_widget, buttons, supabase_client: Client, use_api: bool, base_url: str, admin_token: str):
    """Finds and removes the test patient and their data, either via API or direct DB connection."""
    for btn in buttons: btn.config(state=tk.DISABLED)

    if not ID_STORAGE_FILE.exists():
        log_to_window(log_widget, "INFO: No test patient ID found. Nothing to remove.")
        messagebox.showinfo("Information", "No test patient ID file found (.monthly_patient_id). Nothing to remove.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    if not messagebox.askyesno("Confirm Deletion", "Are you sure you want to delete the monthly test patient and all their data? This will delete the auth user and all linked database records via cascade."):
        for btn in buttons: btn.config(state=tk.NORMAL)
        return
    
    patient_id_str = ID_STORAGE_FILE.read_text().strip()
    try:
        patient_id = int(patient_id_str)

        if use_api:
            log_to_window(log_widget, f"Attempting to remove patient {patient_id} via API endpoint...")
            if not all([base_url, admin_token, supabase_client]):
                messagebox.showerror("Error", "API Base URL, Admin Token, and Supabase client are required to use the API endpoint.")
                raise Exception("Missing arguments for API call.")

            headers = {
                "apikey": supabase_client.supabase_key,
                "Authorization": f"Bearer {admin_token}"
            }
            with httpx.Client(base_url=base_url.strip('/')) as http_client:
                response = http_client.delete(f"/admin/patients/{patient_id}", headers=headers)
                response.raise_for_status()
            
            log_to_window(log_widget, f"SUCCESS: Patient {patient_id} removed via API.")
            messagebox.showinfo("Success", f"Patient with profile ID {patient_id} has been deleted via the API.")
            ID_STORAGE_FILE.unlink()
        else:
            log_to_window(log_widget, f"Attempting to remove patient {patient_id} via direct DB connection...")
            if not supabase_client:
                messagebox.showerror("Error", "Supabase client not initialized. Please connect again.")
                raise Exception("Supabase client not initialized.")

            # --- Direct DB Deletion Logic ---
            log_to_window(log_widget, f"Found patient profile ID {patient_id}. Looking up auth user ID...")
            profile_res = supabase_client.table('patient_profiles').select("user_id").eq('id', patient_id).single().execute()
            user_id = profile_res.data.get("user_id")

            if not user_id:
                log_to_window(log_widget, f"WARNING: No auth user linked to patient profile {patient_id}. Deleting profile directly.")
                supabase_client.table('patient_profiles').delete().eq('id', patient_id).execute()
                log_to_window(log_widget, f"Deleted patient profile {patient_id} from database.")
            else:
                log_to_window(log_widget, f"Deleting auth user {user_id}... This will cascade delete the profile and all related data.")
                supabase_client.auth.admin.delete_user(user_id)
                log_to_window(log_widget, f"Auth user {user_id} deleted.")

                log_to_window(log_widget, "Verifying cascade deletion...")
                profile_check = supabase_client.table('patient_profiles').select('id', count='exact').eq('id', patient_id).execute()
                if profile_check.count == 0:
                    log_to_window(log_widget, " -> OK: Patient profile correctly removed via cascade.")
                    log_to_window(log_widget, "SUCCESS: Deletion complete and verified.")
                    messagebox.showinfo("Success", f"Patient with profile ID {patient_id} and all associated data have been deleted and verified.")
                else:
                    log_to_window(log_widget, f" -> FAILED: Patient profile with ID {patient_id} was NOT deleted.")
                    messagebox.showwarning("Verification Failed", "Deletion command was sent, but the patient profile still exists. Please check database permissions and cascade settings.")
            
            ID_STORAGE_FILE.unlink()

    except Exception as e:
        error_detail = str(e)
        if "Expected 1 row, got 0" in error_detail or "PGRST116" in error_detail:
            log_to_window(log_widget, f"INFO: Patient profile with ID {patient_id_str} not found in database. Removing stale ID file.")
            ID_STORAGE_FILE.unlink()
            messagebox.showwarning("Not Found", f"Patient with profile ID {patient_id_str} was not found. The ID file has been removed.")
        elif "User not allowed" in error_detail:
            helpful_message = "This operation requires the Supabase 'service_role' key. Please ensure you have entered the correct key and not the 'anon' key."
            log_to_window(log_widget, f"ERROR: {error_detail}. HINT: Check if you are using the service_role key.")
            messagebox.showerror("Permission Denied", f"Failed to delete patient: {error_detail}\n\n{helpful_message}")
        else:
            log_to_window(log_widget, f"ERROR: Failed to delete patient: {error_detail}")
            messagebox.showerror("Error", f"Failed to delete patient: {error_detail}")
    finally:
        for btn in buttons: btn.config(state=tk.NORMAL)

def create_admin_user(log_widget, buttons, email_entry, password_entry, url_entry, key_entry):
    """Creates a new admin user directly using the service key, without needing to be logged in."""
    for btn in buttons: btn.config(state=tk.DISABLED)
    
    email = email_entry.get()
    password = password_entry.get()
    url = url_entry.get()
    key = key_entry.get()

    if not all([email, password, url, key]):
        messagebox.showerror("Error", "To create an admin, please provide the new admin's credentials and the Supabase URL/Service Key in the login form.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    # --- Sanity check the key to ensure it's a service_role key ---
    jwt_payload = get_jwt_payload(key)
    if jwt_payload.get("role") != "service_role":
        warning_msg = (
            "The provided Supabase key must be a 'service_role' key. "
            "Please go to Project Settings > API in your Supabase dashboard and copy the key from the 'service_role' secret."
        )
        messagebox.showwarning("Incorrect Key Type", warning_msg)
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    log_to_window(log_widget, f"Attempting to create new admin user: {email}")
    try:
        # Create a temporary client with the service key to perform the operation
        supabase_client = create_client(url, key)

        user_session = supabase_client.auth.admin.create_user({
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
        error_detail = str(e)
        if "User not allowed" in error_detail:
            helpful_message = "This operation requires the Supabase 'service_role' key. Please ensure you have entered the correct key and not the 'anon' key."
            log_to_window(log_widget, f"ERROR: {error_detail}. HINT: Check if you are using the service_role key.")
            messagebox.showerror("Permission Denied", f"Failed to create admin user: {error_detail}\n\n{helpful_message}")
        else:
            log_to_window(log_widget, f"ERROR: Failed to create admin user: {e}")
            messagebox.showerror("Error", f"Failed to create admin user: {e}")
    finally:
        for btn in buttons: btn.config(state=tk.NORMAL)

# --- GUI Setup ---
def main_gui():
    root = tk.Tk()
    root.title("Supabase DevTool")
    root.geometry("800x600")

    # This will hold the active Supabase client and tokens for the toolkit.
    client_store = {'client': None, 'admin_token': None}

    # --- Main Layout ---
    main_pane = ttk.PanedWindow(root, orient=tk.HORIZONTAL)
    main_pane.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

    # --- Left Pane (Log Output) ---
    log_frame = ttk.LabelFrame(main_pane, text="Log Output", padding=(10, 5))
    main_pane.add(log_frame, weight=1)
    log_widget = scrolledtext.ScrolledText(log_frame, width=50, height=15, wrap=tk.WORD, state=tk.DISABLED)
    log_widget.pack(fill=tk.BOTH, expand=True)

    # --- Right Pane (Interaction) ---
    right_pane = ttk.Frame(main_pane)
    main_pane.add(right_pane, weight=1)

    notebook = ttk.Notebook(right_pane)
    notebook.pack(fill=tk.BOTH, expand=True)

    # --- Configuration Tab ---
    config_tab = ttk.Frame(notebook, padding=10)
    notebook.add(config_tab, text='Configuration')

    # --- Admin Creator Tab ---
    admin_creator_tab = ttk.Frame(notebook, padding=10)
    notebook.add(admin_creator_tab, text='Create Admin')

    # --- Tools Tab (created on connection) ---
    tools_frame = ttk.Frame(notebook, padding=10) # Re-purposing tools_frame as a tab

    # --- Configuration Frame Content ---
    login_content_frame = ttk.LabelFrame(config_tab, text="Connection Configuration", padding=(10, 5))
    login_content_frame.pack(padx=10, pady=10, fill=tk.X)

    ttk.Label(login_content_frame, text="Admin email:").grid(row=0, column=0, sticky=tk.W, pady=2)
    admin_email_entry = ttk.Entry(login_content_frame, width=40)
    admin_email_entry.grid(row=0, column=1, sticky=tk.EW, pady=2)

    ttk.Label(login_content_frame, text="Admin password:").grid(row=1, column=0, sticky=tk.W, pady=2)
    admin_password_entry = ttk.Entry(login_content_frame, show="*", width=40)
    admin_password_entry.grid(row=1, column=1, sticky=tk.EW, pady=2)

    ttk.Label(login_content_frame, text="Supabase URL:").grid(row=2, column=0, sticky=tk.W, pady=2)
    supabase_url_entry = ttk.Entry(login_content_frame, width=40)
    supabase_url_entry.grid(row=2, column=1, sticky=tk.EW, pady=2)

    ttk.Label(login_content_frame, text="Supabase service key:").grid(row=3, column=0, sticky=tk.W, pady=2)
    supabase_key_entry = ttk.Entry(login_content_frame, show="*", width=40)
    supabase_key_entry.grid(row=3, column=1, sticky=tk.EW, pady=2)

    ttk.Label(login_content_frame, text="API base URL:").grid(row=4, column=0, sticky=tk.W, pady=2)
    api_base_url_entry = ttk.Entry(login_content_frame, width=40)
    api_base_url_entry.grid(row=4, column=1, sticky=tk.EW, pady=2)

    remember_me_var = tk.BooleanVar()
    remember_me_check = ttk.Checkbutton(login_content_frame, text="Remember me", variable=remember_me_var)
    remember_me_check.grid(row=5, column=1, sticky=tk.W, pady=5)

    connect_button = ttk.Button(login_content_frame, text="Save and Connect")
    connect_button.grid(row=6, column=0, columnspan=2, pady=10, sticky=tk.EW)
    login_content_frame.columnconfigure(1, weight=1)

    # This list will hold all buttons that should be disabled during operations.
    all_buttons = []

    admin_creator_frame = ttk.LabelFrame(admin_creator_tab, text="Admin User Creator", padding=(10, 5))
    admin_creator_frame.pack(padx=10, pady=10, fill=tk.X)
    ttk.Label(admin_creator_frame, text="Admin email:").grid(row=0, column=0, sticky=tk.W, pady=2)
    new_admin_email_entry = ttk.Entry(admin_creator_frame, width=40)
    new_admin_email_entry.grid(row=0, column=1, sticky=tk.EW, pady=2)
    ttk.Label(admin_creator_frame, text="Admin password:").grid(row=1, column=0, sticky=tk.W, pady=2)
    new_admin_password_entry = ttk.Entry(admin_creator_frame, show="*", width=40)
    new_admin_password_entry.grid(row=1, column=1, sticky=tk.EW, pady=2)
    admin_creator_frame.columnconfigure(1, weight=1)
    create_admin_btn = ttk.Button(admin_creator_frame, text="Create admin user")
    create_admin_btn.grid(row=2, column=0, columnspan=2, pady=10, sticky=tk.EW)
    all_buttons.append(create_admin_btn)

    # --- Tools Frame Content ---
    
    status_bar = ttk.Frame(tools_frame)
    status_bar.pack(fill=tk.X, pady=(0, 10))
    connection_status_label = ttk.Label(status_bar, text="")
    connection_status_label.pack(side=tk.LEFT)
    disconnect_button = ttk.Button(status_bar, text="Disconnect")
    disconnect_button.pack(side=tk.RIGHT)

    seeder_frame = ttk.LabelFrame(tools_frame, text="Monthly Patient Seeder", padding=(10, 5))
    seeder_frame.pack(padx=10, pady=5, fill=tk.X)

    add_patient_btn = ttk.Button(seeder_frame, text="Add monthly data patient")
    add_patient_btn.grid(row=0, column=0, padx=5, pady=5, sticky=tk.EW)
    all_buttons.append(add_patient_btn)

    remove_patient_btn = ttk.Button(seeder_frame, text="Remove monthly data patient")
    remove_patient_btn.grid(row=0, column=1, padx=5, pady=5, sticky=tk.EW)
    all_buttons.append(remove_patient_btn)

    use_api_var = tk.BooleanVar(value=True)
    use_api_check = ttk.Checkbutton(seeder_frame, text="Use API endpoint", variable=use_api_var)
    use_api_check.grid(row=1, column=0, columnspan=2, pady=5)

    seeder_frame.columnconfigure((0, 1), weight=1)

    # --- Bulk API Tester Frame ---
    bulk_api_tester_frame = ttk.LabelFrame(tools_frame, text="Bulk API Smoke Tester", padding=(10, 5))
    bulk_api_tester_frame.pack(padx=10, pady=5, fill=tk.X)

    run_tests_btn = ttk.Button(bulk_api_tester_frame, text="Run all endpoint smoke tests")
    run_tests_btn.pack(pady=5, fill=tk.X)
    all_buttons.append(run_tests_btn)



    # --- Connection Logic ---
    def attempt_connection():
        email = admin_email_entry.get()
        password = admin_password_entry.get()
        url = supabase_url_entry.get()
        key = supabase_key_entry.get()

        if not all([email, password, url, key]):
            messagebox.showerror("Error", "Please fill in all connection fields.")
            return

        # --- Sanity check the key to ensure it's a service_role key ---
        jwt_payload = get_jwt_payload(key)
        if jwt_payload.get("role") != "service_role":
            warning_msg = (
                "The provided Supabase key does not appear to be a 'service_role' key. "
                "This is required for all admin operations in this toolkit.\n\n"
                "Please go to Project Settings > API in your Supabase dashboard and copy the key from the 'service_role' secret."
            )
            messagebox.showwarning("Incorrect Key Type", warning_msg)
            return

        # --- Simplified Connection Logic ---
        try:
            log_to_window(log_widget, "Initializing Supabase client with service key...")
            # 1. Create the main client that will use the service_role key for all admin operations.
            #    This client's auth state will NOT be modified by user login.
            service_client = create_client(url, key)

            log_to_window(log_widget, f"Verifying admin credentials for {email}...")
            # 2. Create a *temporary, separate* client to verify the user's credentials.
            #    Signing in modifies the client's auth state, so we use a disposable one
            #    to avoid overwriting the service_role key on our main client.
            temp_auth_client = create_client(url, key)
            auth_response = temp_auth_client.auth.sign_in_with_password({
                "email": email,
                "password": password
            })

            # 3. Check if the now-authenticated user has the 'ADMIN' role.
            if auth_response.user.app_metadata.get('role') != 'ADMIN':
                raise Exception("Connection successful, but user is not an admin.")

            # 4. If all checks pass, store the *unmodified service-role client* and admin token for the toolkit to use.
            client_store['client'] = service_client
            client_store['admin_token'] = auth_response.session.access_token
            log_to_window(log_widget, "Connection successful. Unlocking DevTool.")

            if remember_me_var.get():
                save_credentials(email, password, url, key, api_base_url_entry.get())
            else:
                delete_credentials()
            
            connection_status_label.config(text=f"Connected as: {email}")
            notebook.add(tools_frame, text='DevTool')
            notebook.select(tools_frame)
            notebook.hide(config_tab)
            notebook.hide(admin_creator_tab)

        except Exception as e:
            # Clear the client on failure to prevent using a partially-logged-in state.
            client_store['client'] = None
            client_store['admin_token'] = None
            log_to_window(log_widget, f"ERROR: Connection failed: {e}")
            messagebox.showerror("Connection Failed", f"Connection failed: {e}")

    def do_disconnect():
        # Clear the stored client and token
        client_store['client'] = None
        client_store['admin_token'] = None
        
        connection_status_label.config(text="")
        admin_password_entry.delete(0, tk.END)
        # Don't clear the service key, as it's annoying to re-paste.
        # supabase_key_entry.delete(0, tk.END) 
        
        notebook.forget(tools_frame)
        notebook.add(config_tab)
        notebook.add(admin_creator_tab)
        notebook.select(config_tab)
        log_to_window(log_widget, "Disconnected.")

    # --- Initial State & Button Commands ---
    connect_button.config(command=lambda: threading.Thread(target=attempt_connection, daemon=True).start())
    disconnect_button.config(command=do_disconnect)
    
    add_patient_btn.config(command=lambda: threading.Thread(target=add_test_patient_data, args=(log_widget, all_buttons, client_store['client'], use_api_var.get(), api_base_url_entry.get(), client_store.get('admin_token')), daemon=True).start())
    remove_patient_btn.config(command=lambda: threading.Thread(target=remove_test_patient_data, args=(log_widget, all_buttons, client_store['client'], use_api_var.get(), api_base_url_entry.get(), client_store.get('admin_token')), daemon=True).start())
    run_tests_btn.config(command=lambda: threading.Thread(target=run_all_tests, args=(log_widget, all_buttons, client_store['client'], client_store.get('admin_token'), api_base_url_entry.get()), daemon=True).start())
    create_admin_btn.config(command=lambda: threading.Thread(target=create_admin_user, args=(log_widget, all_buttons, new_admin_email_entry, new_admin_password_entry, supabase_url_entry, supabase_key_entry), daemon=True).start())

    # Load credentials and set initial view
    creds = load_credentials()
    if creds:
        admin_email_entry.insert(0, creds.get('email', ''))
        admin_password_entry.insert(0, creds.get('password', ''))
        supabase_url_entry.insert(0, creds.get('supabase_url', ''))
        supabase_key_entry.insert(0, creds.get('supabase_key', ''))
        api_base_url_entry.delete(0, tk.END)
        api_base_url_entry.insert(0, creds.get('api_base_url', 'http://127.0.0.1:8000'))
        remember_me_var.set(True)

    root.mainloop()

# --- Main Execution ---
if __name__ == "__main__":
    main_gui()
