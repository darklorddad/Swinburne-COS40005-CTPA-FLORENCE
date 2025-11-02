import os
import sys
from pathlib import Path
import time
import random
from datetime import date, timedelta, datetime
import json
import base64
from supabase import create_client, Client
from textual.app import App, ComposeResult
from textual.containers import Grid, Vertical, Horizontal, Container
from textual.screen import Screen, ModalScreen
from textual.widgets import Button, Header, Footer, Input, RichLog, Label, Static, Checkbox
from textual.reactive import reactive
from textual import work

# Add project root to Python path to resolve imports
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))


# --- Configuration ---
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


# --- Textual App ---

class ModalQuestion(ModalScreen[bool]):
    """A modal screen to ask a yes/no question."""
    def __init__(self, question: str) -> None:
        self.question = question
        super().__init__()

    def compose(self) -> ComposeResult:
        yield Grid(
            Label(self.question, id="question"),
            Button("Yes", variant="primary", id="yes"),
            Button("No", variant="error", id="no"),
            id="dialog",
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "yes":
            self.dismiss(True)
        else:
            self.dismiss(False)

class ModalMessage(ModalScreen):
    """A modal screen to display a message."""
    def __init__(self, message: str, title: str) -> None:
        self.message = message
        self.title = title
        super().__init__()

    def compose(self) -> ComposeResult:
        yield Grid(
            Label(self.title, id="title"),
            Label(self.message, id="message"),
            Button("OK", variant="primary", id="ok"),
            id="dialog",
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        self.dismiss()

class SupabaseAdminApp(App):
    """A Textual app for Supabase administration."""

    CSS_PATH = "supabase_admin_toolkit.css"
    BINDINGS = [("d", "toggle_dark", "Toggle dark mode")]

    supabase_client = reactive[Client | None](None)
    logged_in_email = reactive[str | None](None)

    def compose(self) -> ComposeResult:
        yield Header()
        yield Container(
            RichLog(id="log_output", wrap=True, highlight=True),
            id="log_container"
        )
        yield Footer()

    def on_mount(self) -> None:
        """Called when app starts."""
        self.log_message("Supabase Admin Toolkit started.")
        self.push_screen(LoginScreen())

    def log_message(self, message: str):
        """Helper to print messages to the app's log widget."""
        log = self.query_one(RichLog)
        timestamp = time.strftime('%H:%M:%S')
        log.write(f"[{timestamp}] {message}")

    def action_toggle_dark(self) -> None:
        """An action to toggle dark mode."""
        self.dark = not self.dark

class LoginScreen(Screen):
    """Screen for user login and admin creation."""

    def compose(self) -> ComposeResult:
        yield Grid(
            Label("Admin & Supabase Login", classes="title"),
            Label("Admin Email:"),
            Input(id="admin_email", placeholder="admin@example.com"),
            Label("Admin Password:"),
            Input(id="admin_password", password=True),
            Label("Supabase URL:"),
            Input(id="supabase_url", placeholder="https://<project>.supabase.co"),
            Label("Supabase Service Key:"),
            Input(id="supabase_key", password=True),
            Checkbox("Remember Me", id="remember_me"),
            Button("Login", id="login_button", variant="primary"),
            
            Static(), # Spacer
            
            Label("Admin User Creator (For First-Time Setup)", classes="title"),
            Label("New Admin Email:"),
            Input(id="new_admin_email", placeholder="new.admin@example.com"),
            Label("New Admin Password:"),
            Input(id="new_admin_password", password=True),
            Button("Create Admin User", id="create_admin_button"),
            id="login_grid"
        )

    def on_mount(self) -> None:
        creds = load_credentials()
        if creds:
            self.query_one("#admin_email", Input).value = creds.get('email', '')
            self.query_one("#admin_password", Input).value = creds.get('password', '')
            self.query_one("#supabase_url", Input).value = creds.get('supabase_url', '')
            self.query_one("#supabase_key", Input).value = creds.get('supabase_key', '')
            self.query_one("#remember_me", Checkbox).value = True

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "login_button":
            self.attempt_login()
        elif event.button.id == "create_admin_button":
            self.create_admin_user()

    def set_buttons_disabled(self, disabled: bool):
        self.query_one("#login_button", Button).disabled = disabled
        self.query_one("#create_admin_button", Button).disabled = disabled

    @work(exclusive=True, thread=True)
    def attempt_login(self) -> None:
        self.set_buttons_disabled(True)
        
        email = self.query_one("#admin_email", Input).value
        password = self.query_one("#admin_password", Input).value
        url = self.query_one("#supabase_url", Input).value
        key = self.query_one("#supabase_key", Input).value

        if not all([email, password, url, key]):
            self.app.push_screen(ModalMessage("Please fill in all login fields.", "Error"))
            self.set_buttons_disabled(False)
            return

        jwt_payload = get_jwt_payload(key)
        if jwt_payload.get("role") != "service_role":
            msg = "The provided Supabase key must be a 'service_role' key. Please check your Supabase dashboard."
            self.app.push_screen(ModalMessage(msg, "Incorrect Key Type"))
            self.set_buttons_disabled(False)
            return

        try:
            self.app.log_message("Initializing Supabase client with service key...")
            service_client = create_client(url, key)

            self.app.log_message(f"Verifying admin credentials for {email}...")
            temp_auth_client = create_client(url, key)
            auth_response = temp_auth_client.auth.sign_in_with_password({"email": email, "password": password})

            if auth_response.user.app_metadata.get('role') != 'ADMIN':
                raise Exception("Login successful, but user is not an admin.")

            self.app.supabase_client = service_client
            self.app.logged_in_email = email
            self.app.log_message("Login successful. Unlocking toolkit.")

            if self.query_one("#remember_me", Checkbox).value:
                save_credentials(email, password, url, key)
            else:
                delete_credentials()
            
            self.app.push_screen(ToolsScreen())

        except Exception as e:
            self.app.supabase_client = None
            self.app.logged_in_email = None
            self.app.log_message(f"ERROR: Login failed: {e}")
            self.app.push_screen(ModalMessage(f"Login failed: {e}", "Login Failed"))
        finally:
            self.set_buttons_disabled(False)

    @work(exclusive=True, thread=True)
    def create_admin_user(self) -> None:
        self.set_buttons_disabled(True)
        
        email = self.query_one("#new_admin_email", Input).value
        password = self.query_one("#new_admin_password", Input).value
        url = self.query_one("#supabase_url", Input).value
        key = self.query_one("#supabase_key", Input).value

        if not all([email, password, url, key]):
            self.app.push_screen(ModalMessage("To create an admin, please provide the new admin's credentials and the Supabase URL/Service Key.", "Error"))
            self.set_buttons_disabled(False)
            return

        jwt_payload = get_jwt_payload(key)
        if jwt_payload.get("role") != "service_role":
            self.app.push_screen(ModalMessage("The provided Supabase key must be a 'service_role' key.", "Incorrect Key Type"))
            self.set_buttons_disabled(False)
            return

        self.app.log_message(f"Attempting to create new admin user: {email}")
        try:
            supabase_client = create_client(url, key)
            user_session = supabase_client.auth.admin.create_user({
                "email": email, "password": password, "email_confirm": True, "app_metadata": {"role": "ADMIN"},
            })
            if not user_session.user:
                 raise Exception("User creation returned no user object.")

            self.app.log_message(f"SUCCESS: Admin user {email} created.")
            self.app.push_screen(ModalMessage(f"Admin user '{email}' created successfully.", "Success"))

        except Exception as e:
            error_detail = str(e)
            self.app.log_message(f"ERROR: Failed to create admin user: {e}")
            self.app.push_screen(ModalMessage(f"Failed to create admin user: {error_detail}", "Error"))
        finally:
            self.set_buttons_disabled(False)

class ToolsScreen(Screen):
    """Screen for the main admin tools."""

    def compose(self) -> ComposeResult:
        yield Label(f"Logged in as: {self.app.logged_in_email}", id="logged_in_label")
        yield Horizontal(
            Button("Add Monthly Data Patient", id="add_patient_button", variant="success"),
            Button("Remove Monthly Data Patient", id="remove_patient_button", variant="warning"),
            classes="button_row"
        )
        yield Button("Logout", id="logout_button", variant="error")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "add_patient_button":
            self.add_test_patient_data()
        elif event.button.id == "remove_patient_button":
            self.remove_test_patient_data()
        elif event.button.id == "logout_button":
            self.app.supabase_client = None
            self.app.logged_in_email = None
            self.app.pop_screen()
            self.app.log_message("Logged out.")

    def set_buttons_disabled(self, disabled: bool):
        self.query_one("#add_patient_button", Button).disabled = disabled
        self.query_one("#remove_patient_button", Button).disabled = disabled

    @work(exclusive=True, thread=True)
    def add_test_patient_data(self) -> None:
        self.set_buttons_disabled(True)
        supabase_client = self.app.supabase_client

        if ID_STORAGE_FILE.exists():
            self.app.log_message("ERROR: Test patient already exists. Please remove the patient first.")
            self.app.push_screen(ModalMessage("Test patient already exists (found .monthly_patient_id file). Please remove the patient first.", "Error"))
            self.set_buttons_disabled(False)
            return

        if not supabase_client:
            self.app.push_screen(ModalMessage("Supabase client not initialized. Please log in again.", "Error"))
            self.set_buttons_disabled(False)
            return

        new_user = None
        try:
            self.app.log_message(f"Creating auth user: {TEST_PATIENT_EMAIL}")
            user_session = supabase_client.auth.admin.create_user({
                "email": TEST_PATIENT_EMAIL, "password": TEST_PATIENT_PASSWORD,
                "email_confirm": True, "app_metadata": {"role": "PATIENT"}
            })
            new_user = user_session.user
            if not new_user: raise Exception("Failed to create user in authentication system.")
            self.app.log_message(f"Auth user created with ID: {new_user.id}")

            self.app.log_message("Creating patient profile...")
            profile_data = {
                "user_id": new_user.id, "name": "Monthly Data Patient", "phone_number": "555-0123",
                "date_of_birth": "1985-05-15", "gender": "Male"
            }
            patient_profile_res = supabase_client.table('patient_profiles').insert(profile_data).execute()
            patient_profile = patient_profile_res.data[0]
            patient_id = patient_profile["id"]
            self.app.log_message(f"Patient profile created with ID: {patient_id}")
            ID_STORAGE_FILE.write_text(str(patient_id))

            DEFAULT_THRESHOLDS = [
                {'data_type': 'GLUCOSE', 'min_value': 70.0, 'max_value': 180.0},
                {'data_type': 'HBA1C', 'min_value': 4.0, 'max_value': 7.0},
                {'data_type': 'BMI', 'min_value': 18.5, 'max_value': 24.9},
                {'data_type': 'CHOLESTEROL', 'min_value': 100.0, 'max_value': 199.0},
                {'data_type': 'ECG', 'min_value': 60.0, 'max_value': 100},
                {'data_type': 'BLOOD_PRESSURE_SYSTOLIC', 'min_value': 90.0, 'max_value': 120},
                {'data_type': 'BLOOD_PRESSURE_DIASTOLIC', 'min_value': 60.0, 'max_value': 80}
            ]
            thresholds_to_insert = [{**t, 'patient_id': patient_id} for t in DEFAULT_THRESHOLDS]
            supabase_client.table('patient_thresholds').insert(thresholds_to_insert).execute()
            self.app.log_message("Default thresholds created for patient.")

            self.app.log_message("Seeding one month of daily logs...")
            today = date.today()
            logs = [{"patient_id": patient_id, "log_date": (today - timedelta(days=i)).isoformat(), "meal_time": mt,
                     "glucose_before_meal": round(random.uniform(80, 110), 1),
                     "glucose_after_meal": round(random.uniform(120, 180), 1),
                     "meal_desc": f"A typical {mt.lower()}."} for i in range(30) for mt in ["BREAKFAST", "LUNCH", "DINNER"]]
            supabase_client.table('daily_patient_logs').insert(logs).execute()
            self.app.log_message("-> Seeded all daily logs in one batch.")

            self.app.log_message("Seeding one month of monitor data...")
            monitor_data = []
            for i in range(30):
                d = today - timedelta(days=i)
                for h in [8, 13, 19]:
                    monitor_data.append({"patient_id": patient_id, "data_type": "GLUCOSE", "value": round(random.uniform(90, 160), 1), "measured_at": datetime(d.year, d.month, d.day, h, random.randint(0, 59)).isoformat()})
                monitor_data.extend([
                    {"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_SYSTOLIC", "value": round(random.uniform(110, 130), 0), "measured_at": datetime(d.year, d.month, d.day, 9).isoformat()},
                    {"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_DIASTOLIC", "value": round(random.uniform(70, 85), 0), "measured_at": datetime(d.year, d.month, d.day, 9).isoformat()}
                ])
            monitor_data.extend([
                {"patient_id": patient_id, "data_type": "HBA1C", "value": round(random.uniform(5.7, 7.5), 1), "measured_at": (today - timedelta(days=28)).isoformat()},
                {"patient_id": patient_id, "data_type": "CHOLESTEROL", "value": round(random.uniform(180, 220), 0), "measured_at": (today - timedelta(days=20)).isoformat()},
                {"patient_id": patient_id, "data_type": "BMI", "value": round(random.uniform(24, 29), 1), "measured_at": (today - timedelta(days=15)).isoformat()}
            ])
            supabase_client.table('patient_monitor_data').insert(monitor_data).execute()
            self.app.log_message("-> Seeded all monitor data in one batch.")

            self.app.log_message("SUCCESS: Test data seeding complete.")
            self.app.push_screen(ModalMessage("Test data seeding complete.", "Success"))

        except Exception as e:
            error_detail = str(e)
            self.app.log_message(f"ERROR: Failed during data seeding: {error_detail}")
            self.app.push_screen(ModalMessage(f"An error occurred: {error_detail}", "Error"))
            if new_user:
                self.app.log_message(f"Attempting to roll back and delete auth user {new_user.id}...")
                try:
                    supabase_client.auth.admin.delete_user(new_user.id)
                    self.app.log_message("Rollback successful.")
                    if ID_STORAGE_FILE.exists(): ID_STORAGE_FILE.unlink()
                except Exception as rollback_e:
                    self.app.log_message(f"ERROR: Rollback failed: {rollback_e}")
        finally:
            self.set_buttons_disabled(False)

    @work(exclusive=True, thread=True)
    def remove_test_patient_data(self) -> None:
        self.set_buttons_disabled(True)

        if not ID_STORAGE_FILE.exists():
            self.app.log_message("INFO: No test patient ID found. Nothing to remove.")
            self.app.push_screen(ModalMessage("No test patient ID file found (.monthly_patient_id). Nothing to remove.", "Information"))
            self.set_buttons_disabled(False)
            return

        def check_confirm(confirmed: bool):
            if not confirmed:
                self.set_buttons_disabled(False)
                return
            self.run_deletion()

        self.app.push_screen(ModalQuestion("Are you sure you want to delete the monthly test patient and all their data?"), check_confirm)

    @work(exclusive=True, thread=True)
    def run_deletion(self) -> None:
        supabase_client = self.app.supabase_client
        if not supabase_client:
            self.app.push_screen(ModalMessage("Supabase client not initialized. Please log in again.", "Error"))
            self.set_buttons_disabled(False)
            return

        try:
            patient_id = int(ID_STORAGE_FILE.read_text().strip())
            self.app.log_message(f"Found patient profile ID {patient_id}. Looking up auth user ID...")

            profile_res = supabase_client.table('patient_profiles').select("user_id").eq('id', patient_id).single().execute()
            user_id = profile_res.data.get("user_id")

            if not user_id:
                self.app.log_message(f"WARNING: No auth user linked to patient profile {patient_id}. Deleting profile directly.")
                supabase_client.table('patient_profiles').delete().eq('id', patient_id).execute()
                self.app.log_message(f"Deleted patient profile {patient_id} from database.")
            else:
                self.app.log_message(f"Deleting auth user {user_id}... This will cascade delete the profile and all related data.")
                supabase_client.auth.admin.delete_user(user_id)
                self.app.log_message(f"Auth user {user_id} deleted.")

            self.app.log_message("Verifying cascade deletion...")
            profile_check = supabase_client.table('patient_profiles').select('id', count='exact').eq('id', patient_id).execute()
            
            if profile_check.count == 0:
                self.app.log_message(" -> OK: Patient profile correctly removed via cascade.")
                self.app.log_message("SUCCESS: Deletion complete and verified.")
                self.app.push_screen(ModalMessage(f"Patient with profile ID {patient_id} and all associated data have been deleted.", "Success"))
            else:
                self.app.log_message(f" -> FAILED: Patient profile with ID {patient_id} was NOT deleted.")
                self.app.push_screen(ModalMessage("Deletion command was sent, but the patient profile still exists.", "Verification Failed"))

            ID_STORAGE_FILE.unlink()

        except Exception as e:
            error_detail = str(e)
            if "Expected 1 row, got 0" in error_detail or "PGRST116" in error_detail:
                self.app.log_message(f"INFO: Patient profile not found in database. Removing stale ID file.")
                if ID_STORAGE_FILE.exists(): ID_STORAGE_FILE.unlink()
                self.app.push_screen(ModalMessage("Patient profile was not found. The ID file has been removed.", "Not Found"))
            else:
                self.app.log_message(f"ERROR: Failed to delete patient: {error_detail}")
                self.app.push_screen(ModalMessage(f"Failed to delete patient: {error_detail}", "Error"))
        finally:
            self.set_buttons_disabled(False)

if __name__ == "__main__":
    app = SupabaseAdminApp()
    app.run()
