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
project_root = Path(__file__).resolve().parent.parent.parent.parent
sys.path.insert(0, str(project_root))


# --- Configuration ---
CREDENTIALS_FILE = Path(__file__).resolve().parent / ".admin_creds.json"

TEST_PATIENT_EMAIL = "test.patient.monthly@example.com"
TEST_PATIENT_PASSWORD = "a-secure-password-monthly"
ID_STORAGE_FILE = Path(__file__).resolve().parent / ".monthly_patient_id"

# --- Credential Management ---
def save_credentials(email, password, url, key, api_base_url, mode):
    """Saves configuration to a local file."""
    try:
        with open(CREDENTIALS_FILE, 'w') as f:
            json.dump({
                'email': email,
                'password': password,
                'supabase_url': url, 'supabase_key': key,
                'api_base_url': api_base_url,
                'mode': mode
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

def run_all_tests(log_widget, buttons, client_store: dict, base_url_entry: ttk.Entry):
    """Runs a suite of GET requests against parameter-less endpoints to check their status."""
    for btn in buttons: btn.config(state=tk.DISABLED)
    log_to_window(log_widget, "Starting bulk API smoke test...")

    supabase_client = client_store.get('client')
    admin_token = client_store.get('admin_token')
    base_url = base_url_entry.get()

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
            # Debug: log the client_store state
            log_to_window(log_widget, f"DEBUG: client_store keys: {list(client_store.keys())}")
            log_to_window(log_widget, f"DEBUG: admin_token value: {admin_token}")
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
        with httpx.Client(base_url=base_url.strip('/'), timeout=20.0) as http_client:
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


def add_test_patient_data(log_widget, buttons, client_store: dict, mode_var: tk.StringVar, base_url_entry: ttk.Entry):
    """Creates a test patient and seeds one month of data, either via API or direct DB connection."""
    for btn in buttons: btn.config(state=tk.DISABLED)

    use_api = mode_var.get() == "API"
    base_url = base_url_entry.get().strip('/')
    supabase_client = client_store.get('client')
    admin_token = client_store.get('admin_token')

    if ID_STORAGE_FILE.exists():
        log_to_window(log_widget, "ERROR: Test patient already exists. Please remove the patient first.")
        messagebox.showerror("Error", "Test patient already exists (found .monthly_patient_id file). Please remove the patient first.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    new_user = None
    patient_id = None
    patient_token = None # To store the new patient's token
    try:
        new_user = None # For rollback on direct DB creation

        if use_api:
            log_to_window(log_widget, "Attempting to create patient via API endpoint...")
            if not all([base_url, supabase_client]):
                messagebox.showerror("Error", "API Base URL and Supabase client are required to use the API endpoint.")
                raise Exception("Missing arguments for API call.")

            # Step 1: Create patient via the public /auth/register endpoint
            headers = { "apikey": supabase_client.supabase_key }
            payload = {
                "email": TEST_PATIENT_EMAIL, "password": TEST_PATIENT_PASSWORD, "role": "PATIENT",
                "name": "Monthly Data Patient (API)", "phone_number": "555-0123", "date_of_birth": "1985-05-15", "gender": "Male"
            }
            with httpx.Client(base_url=base_url, timeout=20.0) as http_client:
                response = http_client.post("/auth/register", headers=headers, json=payload)
                response.raise_for_status()
                log_to_window(log_widget, "Patient registered successfully.")

                # Step 2: Log in as the new patient to get their token and ID
                login_payload = {"email": TEST_PATIENT_EMAIL, "password": TEST_PATIENT_PASSWORD}
                login_response = http_client.post("/auth/login", headers=headers, json=login_payload)
                login_response.raise_for_status()
                patient_token = login_response.json().get("access_token")
                if not patient_token: raise Exception("Failed to get patient access token after login.")
                log_to_window(log_widget, "Logged in as new patient.")

                # Step 3: Get the patient's profile to find their ID
                patient_headers = {**headers, "Authorization": f"Bearer {patient_token}"}
                profile_response = http_client.get("/patients/me", headers=patient_headers)
                profile_response.raise_for_status()
                patient_profile = profile_response.json()
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
                    "glucose_before_meal": round(random.uniform(80, 110), 1), "glucose_after_meal": round(random.uniform(120, 180), 1)
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
            log_to_window(log_widget, "Seeding data via API using patient's own token. This may take a moment...")
            # Use the patient's own token for the seeding requests
            patient_headers = { "apikey": supabase_client.supabase_key, "Authorization": f"Bearer {patient_token}" }
            with httpx.Client(base_url=base_url, timeout=30.0) as http_client:
                for i, log_payload in enumerate(logs_to_insert):
                    # Remove patient_id as it's inferred from the token by the endpoint
                    log_payload.pop("patient_id", None)
                    response = http_client.post("/patients/me/daily-logs", headers=patient_headers, json=log_payload)
                    response.raise_for_status()
                    if (i + 1) % 10 == 0: log_to_window(log_widget, f"  -> Seeded {i+1}/{len(logs_to_insert)} daily logs...")
                log_to_window(log_widget, "-> All daily logs seeded.")
                
                for i, data_payload in enumerate(monitor_data_to_insert):
                    # Remove patient_id as it's inferred from the token by the endpoint
                    data_payload.pop("patient_id", None)
                    response = http_client.post("/patients/me/monitor-data", headers=patient_headers, json=data_payload)
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
        
        # --- Rollback Logic ---
        # API rollback is harder now because we don't have the user ID easily.
        # We rely on the 'remove' button which finds the user by email.
        if use_api and patient_id:
             log_to_window(log_widget, "Rollback: Seeding failed. Use the 'Remove monthly data patient' button to clean up.")
             if ID_STORAGE_FILE.exists(): ID_STORAGE_FILE.unlink() # remove partial success file

        elif not use_api and new_user: # Only attempt rollback for direct DB method
            log_to_window(log_widget, f"Attempting to roll back and delete auth user {new_user.id}...")
            try:
                supabase_client.auth.admin.delete_user(new_user.id)
                log_to_window(log_widget, "Rollback successful.")
                if ID_STORAGE_FILE.exists(): ID_STORAGE_FILE.unlink()
            except Exception as rollback_e:
                log_to_window(log_widget, f"ERROR: Rollback failed: {rollback_e}")
    finally:
        for btn in buttons: btn.config(state=tk.NORMAL)

def remove_test_patient_data(log_widget, buttons, client_store: dict, mode_var: tk.StringVar, base_url_entry: ttk.Entry):
    """Finds and removes the test patient and their data, either via API or direct DB connection."""
    for btn in buttons: btn.config(state=tk.DISABLED)

    use_api = mode_var.get() == "API"
    base_url = base_url_entry.get()
    supabase_client = client_store.get('client')
    admin_token = client_store.get('admin_token')

    if not messagebox.askyesno("Confirm Action", "This will attempt to remove the monthly test patient, their data and any orphaned auth user associated with them. Continue?"):
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    try:
        # If the ID file exists, we can use either API or Direct mode.
        if ID_STORAGE_FILE.exists():
            patient_id_str = ID_STORAGE_FILE.read_text().strip()
            patient_id = int(patient_id_str)

            if use_api:
                log_to_window(log_widget, f"Attempting to remove patient {patient_id} via API endpoint...")
                if not all([base_url, admin_token, supabase_client]):
                    raise Exception("API Base URL, Admin Token, and Supabase client are required.")

                headers = {"apikey": supabase_client.supabase_key, "Authorization": f"Bearer {admin_token}"}
                with httpx.Client(base_url=base_url.strip('/'), timeout=20.0) as http_client:
                    response = http_client.delete(f"/admin/patients/{patient_id}", headers=headers)
                    response.raise_for_status()
                
                log_to_window(log_widget, f"SUCCESS: Patient {patient_id} removed via API.")
                messagebox.showinfo("Success", f"Patient with profile ID {patient_id} has been deleted via the API.")
            else: # Direct DB mode
                log_to_window(log_widget, f"Attempting to remove patient {patient_id} via direct DB connection...")
                if not supabase_client: raise Exception("Supabase client not initialized.")

                log_to_window(log_widget, f"Found patient profile ID {patient_id}. Looking up auth user ID...")
                profile_res = supabase_client.table('patient_profiles').select("user_id").eq('id', patient_id).single().execute()
                user_id = profile_res.data.get("user_id")

                if not user_id:
                    log_to_window(log_widget, f"WARNING: No auth user linked to patient profile {patient_id}. Deleting profile directly.")
                    supabase_client.table('patient_profiles').delete().eq('id', patient_id).execute()
                else:
                    log_to_window(log_widget, f"Deleting auth user {user_id}... This will cascade delete the profile and all related data.")
                    supabase_client.auth.admin.delete_user(user_id)
                
                log_to_window(log_widget, "SUCCESS: Deletion complete.")
                messagebox.showinfo("Success", f"Patient with profile ID {patient_id} and all associated data have been deleted.")
            
            ID_STORAGE_FILE.unlink()

        # If the ID file does NOT exist, we can only clean up in Direct mode.
        else:
            log_to_window(log_widget, "INFO: No patient ID file found. Checking for orphaned auth user by email...")
            if use_api:
                log_to_window(log_widget, "INFO: Cannot check for orphaned users in API mode without a patient ID. Nothing to do.")
                messagebox.showinfo("Information", "Cannot check for orphaned users in API mode without a patient ID. Nothing to do.")
                return

            if not supabase_client: raise Exception("Supabase client not initialized.")

            log_to_window(log_widget, f"Searching for user with email: {TEST_PATIENT_EMAIL}")
            users_res = supabase_client.auth.admin.list_users()
            
            user_to_delete = next((user for user in users_res if user.email == TEST_PATIENT_EMAIL), None)
            
            if user_to_delete:
                log_to_window(log_widget, f"Found orphaned auth user with ID {user_to_delete.id}. Deleting...")
                supabase_client.auth.admin.delete_user(user_to_delete.id)
                log_to_window(log_widget, "SUCCESS: Orphaned auth user deleted.")
                messagebox.showinfo("Success", "An orphaned test patient auth user was found and deleted. You can now try seeding the data again.")
            else:
                log_to_window(log_widget, "INFO: No orphaned auth user found with that email. Nothing to remove.")
                messagebox.showinfo("Information", "No test patient ID file or orphaned auth user was found. Nothing to remove.")

    except Exception as e:
        error_detail = str(e)
        if "Expected 1 row, got 0" in error_detail or "PGRST116" in error_detail:
            log_to_window(log_widget, f"INFO: Patient profile not found in database. Removing stale ID file.")
            if ID_STORAGE_FILE.exists(): ID_STORAGE_FILE.unlink()
            messagebox.showwarning("Not Found", "Patient profile was not found. The ID file has been removed.")
        elif "User not allowed" in error_detail:
            helpful_message = "This operation requires the Supabase 'service_role' key. Please ensure you have entered the correct key and not the 'anon' key."
            log_to_window(log_widget, f"ERROR: {error_detail}. HINT: Check if you are using the service_role key.")
            messagebox.showerror("Permission Denied", f"Failed to delete patient: {error_detail}\n\n{helpful_message}")
        else:
            log_to_window(log_widget, f"ERROR: Failed to delete patient: {error_detail}")
            messagebox.showerror("Error", f"Failed to delete patient: {error_detail}")
    finally:
        for btn in buttons: btn.config(state=tk.NORMAL)

def create_admin_user(log_widget, buttons, email_entry, password_entry, client_store: dict, base_url_entry: ttk.Entry, supabase_url_entry: ttk.Entry, supabase_key_entry: ttk.Entry):
    """Creates a new admin user. Uses API if logged in, otherwise uses Direct DB."""
    for btn in buttons: btn.config(state=tk.DISABLED)
    
    email = email_entry.get()
    password = password_entry.get()

    base_url = base_url_entry.get()
    supabase_url = supabase_url_entry.get()
    supabase_key = supabase_key_entry.get()

    supabase_client = client_store.get('client')
    admin_token = client_store.get('admin_token')

    if not all([email, password]):
        messagebox.showerror("Error", "Please provide an email and password for the new admin.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    log_to_window(log_widget, f"Attempting to create new admin user: {email}")
    try:
        # If logged in (admin token exists), use the protected API endpoint.
        if admin_token and supabase_client:
            log_to_window(log_widget, "-> Logged in. Using API endpoint.")
            if not base_url:
                raise Exception("API Base URL is required to create admin via API.")
            
            headers = { "apikey": supabase_client.supabase_key, "Authorization": f"Bearer {admin_token}" }
            payload = {
                "email": email,
                "password": password
            }
            
            log_to_window(log_widget, f"DEBUG: Making API request to {base_url}/auth/register_admin")
            log_to_window(log_widget, f"DEBUG: Headers: { {k: v[:50] + '...' if k == 'Authorization' else v for k, v in headers.items()} }")
            log_to_window(log_widget, f"DEBUG: Payload: {payload}")
            
            with httpx.Client(base_url=base_url.strip('/'), timeout=20.0) as http_client:
                response = http_client.post("/auth/register_admin", headers=headers, json=payload)
                log_to_window(log_widget, f"DEBUG: Response status: {response.status_code}")
                log_to_window(log_widget, f"DEBUG: Response body: {response.text}")
                response.raise_for_status()
        # If not logged in, use a direct DB connection with the provided service key.
        else:
            log_to_window(log_widget, "-> Not logged in. Using direct database connection.")
            if not all([supabase_url, supabase_key]):
                raise Exception("Supabase URL and Service Key are required for direct DB connection.")
            
            # Create a temporary client for this operation
            temp_client = create_client(supabase_url, supabase_key)
            
            user_session = temp_client.auth.admin.create_user({
                "email": email,
                "password": password,
                "email_confirm": True,
                "app_metadata": {"role": "ADMIN"},
            })
            if not user_session.user:
                raise Exception("User creation returned no user object.")

        log_to_window(log_widget, f"SUCCESS: Admin user {email} created.")
        messagebox.showinfo("Success", f"Admin user '{email}' created successfully.")
        email_entry.delete(0, tk.END)
        password_entry.delete(0, tk.END)

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
    root.title("Supabase Service DevTool")
    root.geometry("960x540")

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

    # --- UI Variables ---
    mode_var = tk.StringVar(value="API")
    remember_me_var = tk.BooleanVar()

    # --- Tab Definitions ---
    login_tab = ttk.Frame(notebook, padding=10)
    config_tab = ttk.Frame(notebook, padding=10)
    admin_creator_tab = ttk.Frame(notebook, padding=10)
    tools_frame = ttk.Frame(notebook, padding=10) # This will be the DevTool tab

    notebook.add(login_tab, text='Login')
    notebook.add(config_tab, text='Configuration')
    notebook.add(admin_creator_tab, text='Create Admin')
    # The DevTool tab is added after login

    # --- Login Tab Content ---
    login_content_frame = ttk.LabelFrame(login_tab, text="Login", padding=(10, 5))
    login_content_frame.pack(padx=10, pady=10, fill=tk.X)

    ttk.Label(login_content_frame, text="Email:").grid(row=0, column=0, sticky=tk.W, pady=2)
    admin_email_entry = ttk.Entry(login_content_frame, width=40)
    admin_email_entry.grid(row=0, column=1, sticky=tk.EW, pady=2)

    ttk.Label(login_content_frame, text="Password:").grid(row=1, column=0, sticky=tk.W, pady=2)
    admin_password_entry = ttk.Entry(login_content_frame, show="*", width=40)
    admin_password_entry.grid(row=1, column=1, sticky=tk.EW, pady=2)
    
    remember_me_check = ttk.Checkbutton(login_content_frame, text="Remember me", variable=remember_me_var)
    remember_me_check.grid(row=2, column=1, sticky=tk.W, pady=5)

    login_button = ttk.Button(login_content_frame, text="Login")
    login_button.grid(row=3, column=0, columnspan=2, pady=10, sticky=tk.EW)
    login_content_frame.columnconfigure(1, weight=1)

    # --- Configuration Tab Content ---
    config_content_frame = ttk.LabelFrame(config_tab, text="Connection and Mode Configuration", padding=(10, 5))
    config_content_frame.pack(padx=10, pady=10, fill=tk.X)

    ttk.Label(config_content_frame, text="Supabase URL:").grid(row=0, column=0, sticky=tk.W, pady=2)
    supabase_url_entry = ttk.Entry(config_content_frame, width=40)
    supabase_url_entry.grid(row=0, column=1, sticky=tk.EW, pady=2)

    ttk.Label(config_content_frame, text="Supabase service key:").grid(row=1, column=0, sticky=tk.W, pady=2)
    supabase_key_entry = ttk.Entry(config_content_frame, show="*", width=40)
    supabase_key_entry.grid(row=1, column=1, sticky=tk.EW, pady=2)

    ttk.Label(config_content_frame, text="API base URL:").grid(row=2, column=0, sticky=tk.W, pady=2)
    api_base_url_entry = ttk.Entry(config_content_frame, width=40)
    api_base_url_entry.grid(row=2, column=1, sticky=tk.EW, pady=2)

    # Mode selection
    ttk.Label(config_content_frame, text="Operation mode:").grid(row=3, column=0, sticky=tk.W, pady=5)
    mode_frame = ttk.Frame(config_content_frame)
    mode_frame.grid(row=3, column=1, sticky=tk.EW)
    api_mode_radio = ttk.Radiobutton(mode_frame, text="API", variable=mode_var, value="API")
    api_mode_radio.pack(side=tk.LEFT, padx=5)
    direct_mode_radio = ttk.Radiobutton(mode_frame, text="Direct DB", variable=mode_var, value="Direct")
    direct_mode_radio.pack(side=tk.LEFT, padx=5)

    save_config_button = ttk.Button(config_content_frame, text="Save configuration")
    save_config_button.grid(row=4, column=0, columnspan=2, pady=10, sticky=tk.EW)
    config_content_frame.columnconfigure(1, weight=1)

    # --- Admin Creator Tab Content ---
    admin_creator_frame = ttk.LabelFrame(admin_creator_tab, text="Create Admin User", padding=(10, 5))
    admin_creator_frame.pack(padx=10, pady=10, fill=tk.X)
    ttk.Label(admin_creator_frame, text="Email:").grid(row=0, column=0, sticky=tk.W, pady=2)
    new_admin_email_entry = ttk.Entry(admin_creator_frame, width=40)
    new_admin_email_entry.grid(row=0, column=1, sticky=tk.EW, pady=2)
    ttk.Label(admin_creator_frame, text="Password:").grid(row=1, column=0, sticky=tk.W, pady=2)
    new_admin_password_entry = ttk.Entry(admin_creator_frame, show="*", width=40)
    new_admin_password_entry.grid(row=1, column=1, sticky=tk.EW, pady=2)
    admin_creator_frame.columnconfigure(1, weight=1)
    create_admin_btn = ttk.Button(admin_creator_frame, text="Create admin user")
    create_admin_btn.grid(row=2, column=0, columnspan=2, pady=10, sticky=tk.EW)

    # This list will hold all buttons that should be disabled during operations.
    all_buttons = [create_admin_btn]

    # --- Tools Frame Content ---
    
    status_bar = ttk.Frame(tools_frame)
    status_bar.pack(fill=tk.X, pady=(0, 10))
    connection_status_label = ttk.Label(status_bar, text="")
    connection_status_label.pack(side=tk.LEFT)
    logout_button = ttk.Button(status_bar, text="Logout")
    logout_button.pack(side=tk.RIGHT)

    seeder_frame = ttk.LabelFrame(tools_frame, text="Monthly Patient Seeder", padding=(10, 5))
    seeder_frame.pack(padx=10, pady=5, fill=tk.X)

    add_patient_btn = ttk.Button(seeder_frame, text="Add monthly data patient")
    add_patient_btn.grid(row=0, column=0, padx=5, pady=5, sticky=tk.EW)
    all_buttons.append(add_patient_btn)

    remove_patient_btn = ttk.Button(seeder_frame, text="Remove monthly data patient")
    remove_patient_btn.grid(row=0, column=1, padx=5, pady=5, sticky=tk.EW)
    all_buttons.append(remove_patient_btn)

    seeder_frame.columnconfigure((0, 1), weight=1)

    # --- Bulk API Tester Frame ---
    bulk_api_tester_frame = ttk.LabelFrame(tools_frame, text="Bulk API Smoke Tester", padding=(10, 5))
    bulk_api_tester_frame.pack(padx=10, pady=5, fill=tk.X)

    run_tests_btn = ttk.Button(bulk_api_tester_frame, text="Run all endpoint smoke tests")
    run_tests_btn.pack(pady=5, fill=tk.X)
    all_buttons.append(run_tests_btn)



    # --- Logic for UI interaction ---
    def do_save_config():
        """Saves the current configuration fields to the credentials file."""
        url = supabase_url_entry.get()
        key = supabase_key_entry.get()
        api_url = api_base_url_entry.get()
        mode = mode_var.get()
        email = admin_email_entry.get()
        
        # Only save the password if "Remember me" is checked.
        password = admin_password_entry.get() if remember_me_var.get() else ""

        if not all([url, key, api_url]):
            messagebox.showwarning("Warning", "Some configuration fields are empty, but saving anyway.")
        
        save_credentials(email, password, url, key, api_url, mode)
        log_to_window(log_widget, "Configuration saved.")
        messagebox.showinfo("Success", "Configuration has been saved.")

    def attempt_login():
        email = admin_email_entry.get()
        password = admin_password_entry.get()
        url = supabase_url_entry.get()
        key = supabase_key_entry.get()

        if not all([email, password, url, key]):
            messagebox.showerror("Error", "Please fill in all login and configuration fields.")
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

        # --- Simplified Login Logic ---
        try:
            log_to_window(log_widget, "Initialising Supabase client with service key...")
            service_client = create_client(url, key)

            user_role = None
            access_token = None
            mode = mode_var.get()
            base_url = api_base_url_entry.get()

            if mode == "API":
                log_to_window(log_widget, f"Verifying admin credentials for {email} via API...")
                if not base_url:
                    raise Exception("API Base URL is required for API mode.")
                    
                payload = {"email": email, "password": password}
                    
                with httpx.Client(base_url=base_url.strip('/'), timeout=20.0) as http_client:
                    # Step 1: Log in to get the backend's access token
                    # Public endpoints like /login do not require an apikey header.
                    response = http_client.post("/auth/login", json=payload)
                    response.raise_for_status()
                    auth_response_data = response.json()
                    access_token = auth_response_data.get("access_token")
                    if not access_token:
                        raise Exception("Login response did not contain an access_token.")
                        
                    # Step 2: Use the token to call /auth/me and get the user's role
                    auth_headers = {
                        "Authorization": f"Bearer {access_token}",
                        "apikey": key
                    }
                    me_response = http_client.get("/auth/me", headers=auth_headers)
                    me_response.raise_for_status() # Will raise an error if token is invalid
                    me_data = me_response.json()
                    user_role = me_data.get("app_metadata", {}).get("role")
                    log_to_window(log_widget, f"Verified role from /auth/me endpoint: {user_role}")
            else: # Direct mode
                log_to_window(log_widget, f"Verifying admin credentials for {email} via direct connection...")
                temp_auth_client = create_client(url, key)
                auth_response = temp_auth_client.auth.sign_in_with_password({
                    "email": email,
                    "password": password
                })
                user_role = auth_response.user.app_metadata.get('role')
                access_token = auth_response.session.access_token

            if user_role != 'ADMIN':
                raise Exception("Login successful, but user is not an admin.")

            client_store['client'] = service_client
            client_store['admin_token'] = access_token
            log_to_window(log_widget, "Login successful. Unlocking DevTool.")
            log_to_window(log_widget, f"DEBUG: Set admin_token: {access_token is not None}")

            # Save credentials if "Remember me" is checked
            if remember_me_var.get():
                save_credentials(email, password, url, key, api_base_url_entry.get(), mode_var.get())
            else:
                # Otherwise, save config but clear the password
                save_credentials(email, "", url, key, api_base_url_entry.get(), mode_var.get())
            
            connection_status_label.config(text=f"Connected as: {email} (Mode: {mode_var.get()})")
            notebook.add(tools_frame, text='DevTool')
            notebook.select(tools_frame)
            notebook.forget(login_tab)

        except httpx.HTTPStatusError as e:
            client_store['client'] = None
            client_store['admin_token'] = None
            error_message = f"Login failed: {e}"
            if e.response.status_code == 422:
                try:
                    detail = e.response.json().get('detail', [])
                    if isinstance(detail, list) and any("valid email address" in item.get('msg', '').lower() for item in detail):
                        error_message = "Login failed: Invalid email format. Please provide a valid email address."
                except Exception:
                    pass # Stick with the default message
            log_to_window(log_widget, f"ERROR: {error_message}")
            messagebox.showerror("Login Failed", error_message)
        except Exception as e:
            client_store['client'] = None
            client_store['admin_token'] = None
            log_to_window(log_widget, f"ERROR: Login failed: {e}")
            messagebox.showerror("Login Failed", f"Login failed: {e}")

    def do_logout():
        client_store['client'] = None
        client_store['admin_token'] = None
        
        connection_status_label.config(text="")
        admin_password_entry.delete(0, tk.END)
        
        notebook.forget(tools_frame)
        # Re-show the login tab
        notebook.insert(0, login_tab, text='Login')
        notebook.select(login_tab)
        log_to_window(log_widget, "Logged out.")

    # --- Initial State & Button Commands ---
    login_button.config(command=lambda: threading.Thread(target=attempt_login, daemon=True).start())
    save_config_button.config(command=do_save_config)
    logout_button.config(command=do_logout)
    
    add_patient_btn.config(command=lambda: threading.Thread(target=add_test_patient_data, args=(log_widget, all_buttons, client_store, mode_var, api_base_url_entry), daemon=True).start())
    remove_patient_btn.config(command=lambda: threading.Thread(target=remove_test_patient_data, args=(log_widget, all_buttons, client_store, mode_var, api_base_url_entry), daemon=True).start())
    run_tests_btn.config(command=lambda: threading.Thread(target=run_all_tests, args=(log_widget, all_buttons, client_store, api_base_url_entry), daemon=True).start())
    create_admin_btn.config(command=lambda: threading.Thread(target=create_admin_user, args=(log_widget, all_buttons, new_admin_email_entry, new_admin_password_entry, client_store, api_base_url_entry, supabase_url_entry, supabase_key_entry), daemon=True).start())

    # Load credentials and set initial view
    creds = load_credentials()
    if creds:
        admin_email_entry.insert(0, creds.get('email', ''))
        if creds.get('password'):
            admin_password_entry.insert(0, creds.get('password'))
            remember_me_var.set(True)
        supabase_url_entry.insert(0, creds.get('supabase_url', ''))
        supabase_key_entry.insert(0, creds.get('supabase_key', ''))
        api_base_url_entry.insert(0, creds.get('api_base_url', 'http://127.0.0.1:8000'))
        mode_var.set(creds.get('mode', 'API'))

    root.mainloop()

# --- Main Execution ---
if __name__ == "__main__":
    main_gui()
