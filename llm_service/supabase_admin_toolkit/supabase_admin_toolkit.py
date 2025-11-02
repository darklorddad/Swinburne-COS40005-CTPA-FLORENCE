import tkinter as tk
from tkinter import messagebox, scrolledtext, ttk
import httpx
import os
import sys
from pathlib import Path
import uvicorn
import threading
import time
import random
from datetime import date, timedelta, datetime
import json
from supabase import create_client, Client

# Add project root to Python path to resolve imports
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from Supabase.main import app
from Supabase.client import supabase as global_supabase_proxy

# --- Configuration ---
API_BASE_URL = "http://127.0.0.1:8000"
CREDENTIALS_FILE = Path(__file__).resolve().parent / ".admin_creds.json"

TEST_PATIENT_EMAIL = "test.patient.monthly@example.com"
TEST_PATIENT_PASSWORD = "a-secure-password-monthly"
ID_STORAGE_FILE = Path(__file__).resolve().parent / ".monthly_patient_id"

# --- Credential Management ---
def save_credentials(email, password, url, key):
    """Saves admin and Supabase credentials to a local file."""
    try:
        with open(CREDENTIALS_FILE, 'w') as f:
            json.dump({'email': email, 'password': password, 'supabase_url': url, 'supabase_key': key}, f)
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


# --- GUI Helper ---
def log_to_window(log_widget, message):
    """Helper to print messages to the GUI's log widget."""
    log_widget.config(state=tk.NORMAL)
    log_widget.insert(tk.END, f"[{time.strftime('%H:%M:%S')}] {message}\n")
    log_widget.see(tk.END)
    log_widget.config(state=tk.DISABLED)
    log_widget.update_idletasks()

# --- API Logic ---

def add_test_patient_data(log_widget, buttons, supabase_client: Client):
    """Creates a test patient and seeds one month of data."""
    for btn in buttons: btn.config(state=tk.DISABLED)

    if ID_STORAGE_FILE.exists():
        log_to_window(log_widget, "ERROR: Test patient already exists. Please remove the patient first.")
        messagebox.showerror("Error", "Test patient already exists (found .monthly_patient_id file). Please remove the patient first.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    if not supabase_client:
        messagebox.showerror("Error", "Supabase client not initialized. Please log in again.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    patient_id = None
    new_user = None
    try:
        # Step 1: Create the user in Supabase Auth using the service key
        log_to_window(log_widget, f"Creating auth user: {TEST_PATIENT_EMAIL}")
        user_session = supabase_client.auth.admin.create_user({
            "email": TEST_PATIENT_EMAIL,
            "password": TEST_PATIENT_PASSWORD,
            "email_confirm": True,
            "app_metadata": {"role": "PATIENT"}
        })
        new_user = user_session.user
        if not new_user:
            raise Exception("Failed to create user in authentication system.")
        
        log_to_window(log_widget, f"Auth user created with ID: {new_user.id}")

        # Step 2: Create the patient profile
        log_to_window(log_widget, "Creating patient profile...")
        profile_data = {
            "user_id": new_user.id,
            "name": "Monthly Data Patient",
            "phone_number": "555-0123",
            "date_of_birth": "1985-05-15",
            "gender": "Male"
        }
        patient_profile_res = supabase_client.table('patient_profiles').insert(profile_data).execute()
        patient_profile = patient_profile_res.data[0]
        patient_id = patient_profile["id"]
        log_to_window(log_widget, f"Patient profile created with ID: {patient_id}")
        ID_STORAGE_FILE.write_text(str(patient_id))

        # Step 3: Create default thresholds
        DEFAULT_THRESHOLDS = [
            {'data_type': 'GLUCOSE', 'min_value': 70.0, 'max_value': 180.0},
            {'data_type': 'HBA1C', 'min_value': 4.0, 'max_value': 7.0},
            {'data_type': 'BMI', 'min_value': 18.5, 'max_value': 24.9},
            {'data_type': 'CHOLESTEROL', 'min_value': 100.0, 'max_value': 199.0},
            {'data_type': 'ECG', 'min_value': 60.0, 'max_value': 100},
            {'data_type': 'BLOOD_PRESSURE_SYSTOLIC', 'min_value': 90.0, 'max_value': 120},
            {'data_type': 'BLOOD_PRESSURE_DIASTOLIC', 'min_value': 60.0, 'max_value': 80}
        ]
        thresholds_to_insert = [
            {**threshold, 'patient_id': patient_id} for threshold in DEFAULT_THRESHOLDS
        ]
        supabase_client.table('patient_thresholds').insert(thresholds_to_insert).execute()
        log_to_window(log_widget, "Default thresholds created for patient.")

        # Step 4: Seed Daily Logs (batched for performance)
        log_to_window(log_widget, "Seeding one month of daily logs...")
        today = date.today()
        logs_to_insert = []
        for i in range(30):
            log_date = today - timedelta(days=i)
            for meal_time in ["BREAKFAST", "LUNCH", "DINNER"]:
                logs_to_insert.append({
                    "patient_id": patient_id, "log_date": log_date.isoformat(), "meal_time": meal_time,
                    "glucose_before_meal": round(random.uniform(80, 110), 1),
                    "glucose_after_meal": round(random.uniform(120, 180), 1),
                    "meal_desc": f"A typical {meal_time.lower()}."
                })
        supabase_client.table('daily_patient_logs').insert(logs_to_insert).execute()
        log_to_window(log_widget, "-> Seeded all daily logs in one batch.")

        # Step 5: Seed Monitor Data (batched for performance)
        log_to_window(log_widget, "Seeding one month of monitor data...")
        monitor_data_to_insert = []
        for i in range(30):
            log_date = today - timedelta(days=i)
            for hour in [8, 13, 19]:
                monitor_data_to_insert.append({
                    "patient_id": patient_id, "data_type": "GLUCOSE", "value": round(random.uniform(90, 160), 1),
                    "measured_at": datetime(log_date.year, log_date.month, log_date.day, hour, random.randint(0, 59)).isoformat()
                })
            
            bp_systolic = {"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_SYSTOLIC", "value": round(random.uniform(110, 130), 0), "measured_at": datetime(log_date.year, log_date.month, log_date.day, 9).isoformat()}
            bp_diastolic = {"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_DIASTOLIC", "value": round(random.uniform(70, 85), 0), "measured_at": datetime(log_date.year, log_date.month, log_date.day, 9).isoformat()}
            monitor_data_to_insert.extend([bp_systolic, bp_diastolic])
        
        monitor_data_to_insert.append({"patient_id": patient_id, "data_type": "HBA1C", "value": round(random.uniform(5.7, 7.5), 1), "measured_at": (today - timedelta(days=28)).isoformat()})
        monitor_data_to_insert.append({"patient_id": patient_id, "data_type": "CHOLESTEROL", "value": round(random.uniform(180, 220), 0), "measured_at": (today - timedelta(days=20)).isoformat()})
        monitor_data_to_insert.append({"patient_id": patient_id, "data_type": "BMI", "value": round(random.uniform(24, 29), 1), "measured_at": (today - timedelta(days=15)).isoformat()})
        
        supabase_client.table('patient_monitor_data').insert(monitor_data_to_insert).execute()
        log_to_window(log_widget, "-> Seeded all monitor data in one batch.")

        log_to_window(log_widget, "SUCCESS: Test data seeding complete.")
        messagebox.showinfo("Success", "Test data seeding complete.")

    except Exception as e:
        error_detail = str(e)
        log_to_window(log_widget, f"ERROR: Failed during data seeding: {error_detail}")
        messagebox.showerror("Error", f"An error occurred: {error_detail}")
        if new_user:
            log_to_window(log_widget, f"Attempting to roll back and delete auth user {new_user.id}...")
            try:
                supabase_client.auth.admin.delete_user(new_user.id)
                log_to_window(log_widget, "Rollback successful.")
                if ID_STORAGE_FILE.exists(): ID_STORAGE_FILE.unlink()
            except Exception as rollback_e:
                log_to_window(log_widget, f"ERROR: Rollback failed: {rollback_e}")
    finally:
        for btn in buttons: btn.config(state=tk.NORMAL)

def remove_test_patient_data(log_widget, buttons, supabase_client: Client):
    """Finds and removes the test patient and their data by deleting the auth user."""
    for btn in buttons: btn.config(state=tk.DISABLED)

    if not ID_STORAGE_FILE.exists():
        log_to_window(log_widget, "INFO: No test patient ID found. Nothing to remove.")
        messagebox.showinfo("Information", "No test patient ID file found (.monthly_patient_id). Nothing to remove.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    if not messagebox.askyesno("Confirm Deletion", "Are you sure you want to delete the monthly test patient and all their data? This will delete the auth user and all linked database records via cascade."):
        for btn in buttons: btn.config(state=tk.NORMAL)
        return
    
    if not supabase_client:
        messagebox.showerror("Error", "Supabase client not initialized. Please log in again.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    try:
        patient_id = int(ID_STORAGE_FILE.read_text().strip())
        log_to_window(log_widget, f"Found patient profile ID {patient_id}. Looking up auth user ID...")

        # Step 1: Get the user_id from the patient profile
        profile_res = supabase_client.table('patient_profiles').select("user_id").eq('id', patient_id).single().execute()
        user_id = profile_res.data.get("user_id")

        if not user_id:
            log_to_window(log_widget, f"WARNING: No auth user linked to patient profile {patient_id}. Deleting profile directly.")
            # Fallback for orphaned profiles
            supabase_client.table('patient_profiles').delete().eq('id', patient_id).execute()
            log_to_window(log_widget, f"Deleted patient profile {patient_id} from database.")
        else:
            # Step 2: Delete the auth user. The database's ON DELETE CASCADE will handle the rest.
            log_to_window(log_widget, f"Deleting auth user {user_id}... This will cascade delete the profile and all related data.")
            supabase_client.auth.admin.delete_user(user_id)
            log_to_window(log_widget, f"SUCCESS: Auth user {user_id} deleted, and database records removed via cascade.")
        
        ID_STORAGE_FILE.unlink()
        messagebox.showinfo("Success", f"Patient with profile ID {patient_id} and all associated data have been deleted.")

    except Exception as e:
        error_detail = str(e)
        # Catch specific error if patient not found
        if "Expected 1 row, got 0" in error_detail:
            log_to_window(log_widget, f"INFO: Patient profile with ID {patient_id} not found in database. Removing stale ID file.")
            ID_STORAGE_FILE.unlink()
            messagebox.showwarning("Not Found", f"Patient with profile ID {patient_id} was not found. The ID file has been removed.")
        else:
            log_to_window(log_widget, f"ERROR: Failed to delete patient: {error_detail}")
            messagebox.showerror("Error", f"Failed to delete patient: {error_detail}")
    finally:
        for btn in buttons: btn.config(state=tk.NORMAL)

def create_admin_user(log_widget, buttons, email_entry, password_entry, supabase_client: Client):
    """Creates a new admin user directly using the service key."""
    for btn in buttons: btn.config(state=tk.DISABLED)
    
    email = email_entry.get()
    password = password_entry.get()

    if not email or not password:
        messagebox.showerror("Error", "Please enter both email and password for the new admin.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return
    
    if not supabase_client:
        messagebox.showerror("Error", "Supabase client not initialized. Please log in again.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    log_to_window(log_widget, f"Attempting to create new admin user: {email}")
    try:
        # Use the Supabase client with service key to create an admin
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
        log_to_window(log_widget, f"ERROR: Failed to create admin user: {e}")
        messagebox.showerror("Error", f"Failed to create admin user: {e}")
    finally:
        for btn in buttons: btn.config(state=tk.NORMAL)

# --- GUI Setup ---
def main_gui():
    root = tk.Tk()
    root.title("Supabase Admin Toolkit")
    root.geometry("600x650")

    # This will hold the dynamic Supabase client and server thread
    supabase_client_store = {'client': None}
    server_thread_store = {'thread': None}

    # --- Main Frames ---
    login_frame = ttk.Frame(root, padding=10)
    tools_frame = ttk.Frame(root, padding=10)

    # --- Login Frame Content ---
    login_content_frame = ttk.LabelFrame(login_frame, text="Admin & Supabase Login", padding=(10, 5))
    login_content_frame.pack(padx=10, pady=10, fill=tk.X)

    ttk.Label(login_content_frame, text="Admin Email:").grid(row=0, column=0, sticky=tk.W, pady=2)
    admin_email_entry = ttk.Entry(login_content_frame, width=40)
    admin_email_entry.grid(row=0, column=1, sticky=tk.EW, pady=2)

    ttk.Label(login_content_frame, text="Admin Password:").grid(row=1, column=0, sticky=tk.W, pady=2)
    admin_password_entry = ttk.Entry(login_content_frame, show="*", width=40)
    admin_password_entry.grid(row=1, column=1, sticky=tk.EW, pady=2)

    ttk.Label(login_content_frame, text="Supabase URL:").grid(row=2, column=0, sticky=tk.W, pady=2)
    supabase_url_entry = ttk.Entry(login_content_frame, width=40)
    supabase_url_entry.grid(row=2, column=1, sticky=tk.EW, pady=2)

    ttk.Label(login_content_frame, text="Supabase Service Key:").grid(row=3, column=0, sticky=tk.W, pady=2)
    supabase_key_entry = ttk.Entry(login_content_frame, show="*", width=40)
    supabase_key_entry.grid(row=3, column=1, sticky=tk.EW, pady=2)

    remember_me_var = tk.BooleanVar()
    remember_me_check = ttk.Checkbutton(login_content_frame, text="Remember Me", variable=remember_me_var)
    remember_me_check.grid(row=4, column=1, sticky=tk.W, pady=5)

    login_button = ttk.Button(login_content_frame, text="Login")
    login_button.grid(row=5, column=0, columnspan=2, pady=10, sticky=tk.EW)
    login_content_frame.columnconfigure(1, weight=1)

    # --- Tools Frame Content ---
    all_buttons = []
    
    status_bar = ttk.Frame(tools_frame)
    status_bar.pack(fill=tk.X, pady=(0, 10))
    logged_in_label = ttk.Label(status_bar, text="")
    logged_in_label.pack(side=tk.LEFT)
    logout_button = ttk.Button(status_bar, text="Logout")
    logout_button.pack(side=tk.RIGHT)

    seeder_frame = ttk.LabelFrame(tools_frame, text="Monthly Patient Seeder", padding=(10, 5))
    seeder_frame.pack(padx=10, pady=5, fill=tk.X)
    add_patient_btn = ttk.Button(seeder_frame, text="Add Monthly Data Patient")
    add_patient_btn.pack(side=tk.LEFT, padx=5, pady=5, expand=True, fill=tk.X)
    all_buttons.append(add_patient_btn)
    remove_patient_btn = ttk.Button(seeder_frame, text="Remove Monthly Data Patient")
    remove_patient_btn.pack(side=tk.LEFT, padx=5, pady=5, expand=True, fill=tk.X)
    all_buttons.append(remove_patient_btn)

    admin_creator_frame = ttk.LabelFrame(tools_frame, text="Admin User Creator (Direct DB Access)", padding=(10, 5))
    admin_creator_frame.pack(padx=10, pady=5, fill=tk.X)
    ttk.Label(admin_creator_frame, text="New Admin Email:").grid(row=0, column=0, sticky=tk.W, pady=2)
    new_admin_email_entry = ttk.Entry(admin_creator_frame, width=40)
    new_admin_email_entry.grid(row=0, column=1, sticky=tk.EW, pady=2)
    ttk.Label(admin_creator_frame, text="New Admin Password:").grid(row=1, column=0, sticky=tk.W, pady=2)
    new_admin_password_entry = ttk.Entry(admin_creator_frame, show="*", width=40)
    new_admin_password_entry.grid(row=1, column=1, sticky=tk.EW, pady=2)
    admin_creator_frame.columnconfigure(1, weight=1)
    create_admin_btn = ttk.Button(admin_creator_frame, text="Create Admin User")
    create_admin_btn.grid(row=2, column=0, columnspan=2, pady=10, sticky=tk.EW)
    all_buttons.append(create_admin_btn)

    # --- Log Output (Common to both frames) ---
    log_frame = ttk.LabelFrame(root, text="Log Output", padding=(10, 5))
    log_widget = scrolledtext.ScrolledText(log_frame, height=15, wrap=tk.WORD, state=tk.DISABLED)
    log_widget.pack(fill=tk.BOTH, expand=True)

    # --- Login/Logout Logic ---
    def attempt_login():
        email = admin_email_entry.get()
        password = admin_password_entry.get()
        url = supabase_url_entry.get()
        key = supabase_key_entry.get()

        if not all([email, password, url, key]):
            messagebox.showerror("Error", "Please fill in all login fields.")
            return

        # --- Self-contained server and client logic ---
        try:
            # 1. Create a client instance with credentials from the GUI.
            log_to_window(log_widget, "Initializing Supabase client...")
            server_client = create_client(url, key)
            
            # 2. Monkey-patch the global proxy object that the FastAPI app will use.
            #    This bypasses the .env loading mechanism in Supabase/client.py.
            global_supabase_proxy._client = server_client
            log_to_window(log_widget, "Client injected into global proxy for background server.")
        except Exception as e:
            log_to_window(log_widget, f"ERROR: Supabase client initialization failed: {e}")
            messagebox.showerror("Initialization Failed", f"Could not initialize Supabase client. Check URL and Key. Error: {e}")
            return

        # 3. Start the server if it's not already running. It will now use the injected client.
        if server_thread_store['thread'] is None:
            log_to_window(log_widget, "Starting FastAPI server in background...")
            server_thread = threading.Thread(target=run_fastapi_server, daemon=True)
            server_thread.start()
            server_thread_store['thread'] = server_thread
            time.sleep(3) # Give server time to start
            log_to_window(log_widget, "Server should be running.")
        
        log_to_window(log_widget, f"Attempting login for {email}...")
        try:
            # 4. Verify admin credentials against the running server.
            with httpx.Client() as client:
                response = client.post(f"{API_BASE_URL}/auth/login", json={"email": email, "password": password}, timeout=10.0)
                response.raise_for_status()
            
            log_to_window(log_widget, "Login successful. Unlocking toolkit.")
            # 5. Store the client for the toolkit's direct use.
            supabase_client_store['client'] = server_client
            
            if remember_me_var.get():
                save_credentials(email, password, url, key)
            else:
                delete_credentials()
            
            logged_in_label.config(text=f"Logged in as: {email}")
            login_frame.pack_forget()
            log_frame.pack_forget()
            tools_frame.pack(fill=tk.BOTH, expand=True)
            log_frame.pack(padx=10, pady=(0, 10), fill=tk.BOTH, expand=True)

        except (httpx.HTTPStatusError, httpx.RequestError) as e:
            log_to_window(log_widget, f"ERROR: Login failed: {e}")
            messagebox.showerror("Login Failed", f"Login failed: {e}")

    def do_logout():
        supabase_client_store['client'] = None
        logged_in_label.config(text="")
        admin_password_entry.delete(0, tk.END)
        supabase_key_entry.delete(0, tk.END)
        tools_frame.pack_forget()
        log_frame.pack_forget()
        login_frame.pack(fill=tk.BOTH, expand=True)
        log_frame.pack(padx=10, pady=(0, 10), fill=tk.BOTH, expand=True)
        log_to_window(log_widget, "Logged out.")

    # --- Initial State & Button Commands ---
    login_button.config(command=lambda: threading.Thread(target=attempt_login, daemon=True).start())
    logout_button.config(command=do_logout)
    
    add_patient_btn.config(command=lambda: threading.Thread(target=add_test_patient_data, args=(log_widget, all_buttons, supabase_client_store['client']), daemon=True).start())
    remove_patient_btn.config(command=lambda: threading.Thread(target=remove_test_patient_data, args=(log_widget, all_buttons, supabase_client_store['client']), daemon=True).start())
    create_admin_btn.config(command=lambda: threading.Thread(target=create_admin_user, args=(log_widget, all_buttons, new_admin_email_entry, new_admin_password_entry, supabase_client_store['client']), daemon=True).start())

    # Load credentials and set initial view
    creds = load_credentials()
    if creds:
        admin_email_entry.insert(0, creds.get('email', ''))
        admin_password_entry.insert(0, creds.get('password', ''))
        supabase_url_entry.insert(0, creds.get('supabase_url', ''))
        supabase_key_entry.insert(0, creds.get('supabase_key', ''))
        remember_me_var.set(True)

    login_frame.pack(fill=tk.BOTH, expand=True)
    log_frame.pack(padx=10, pady=(0, 10), fill=tk.BOTH, expand=True)

    root.mainloop()

# --- Main Execution ---
def run_fastapi_server():
    """Runs the FastAPI server using uvicorn in a separate thread."""
    config = uvicorn.Config(app, host="127.0.0.1", port=8000, log_level="warning")
    server = uvicorn.Server(config)
    server.run()

if __name__ == "__main__":
    main_gui()
