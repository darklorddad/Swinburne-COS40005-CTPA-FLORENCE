import tkinter as tk
from tkinter import messagebox, scrolledtext
import httpx
import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from json import JSONDecodeError

# Add project root to Python path to resolve imports
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

# Load environment variables from .env file
load_dotenv(dotenv_path=project_root / '.env', override=True)

# --- Configuration ---
API_BASE_URL = "http://127.0.0.1:8000"
ADMIN_EMAIL = os.environ.get("TEST_ADMIN_EMAIL", "") # Pre-fill from .env if available

# --- Login Logic ---
def attempt_login():
    """Handles the login button click event."""
    email = email_entry.get()
    password = password_entry.get()

    if not email or not password:
        messagebox.showerror("Error", "Please enter both email and password.")
        return

    # Update status text
    status_text.config(state=tk.NORMAL)
    status_text.delete(1.0, tk.END)
    status_text.insert(tk.END, f"Attempting login for {email}...\n")
    status_text.config(state=tk.DISABLED)
    root.update_idletasks()

    try:
        # Make the API call
        with httpx.Client() as client:
            response = client.post(
                f"{API_BASE_URL}/auth/login",
                json={"email": email, "password": password},
                timeout=10.0
            )
            response.raise_for_status() # Raise an exception for 4xx/5xx errors

        # On success, display the token
        data = response.json()
        access_token = data.get("access_token")
        
        status_text.config(state=tk.NORMAL)
        status_text.insert(tk.END, "Login successful!\n\n")
        status_text.insert(tk.END, "Access Token:\n")
        status_text.insert(tk.END, access_token)
        status_text.config(state=tk.DISABLED)

    except httpx.HTTPStatusError as e:
        # Handle API errors (e.g., wrong password)
        try:
            error_detail = e.response.json().get("detail", e.response.text)
        except JSONDecodeError:
            error_detail = e.response.text
        messagebox.showerror("Login Failed", f"Error: {e.response.status_code}\n{error_detail}")
        status_text.config(state=tk.NORMAL)
        status_text.insert(tk.END, f"Login failed: {error_detail}\n")
        status_text.config(state=tk.DISABLED)
    except httpx.RequestError as e:
        # Handle connection errors
        messagebox.showerror("Connection Error", f"Could not connect to the API.\nIs the server running at {API_BASE_URL}?\n\nDetails: {e}")
        status_text.config(state=tk.NORMAL)
        status_text.insert(tk.END, f"Connection error: {e}\n")
        status_text.config(state=tk.DISABLED)
    except Exception as e:
        # Handle other unexpected errors
        messagebox.showerror("An Error Occurred", str(e))
        status_text.config(state=tk.NORMAL)
        status_text.insert(tk.END, f"An unexpected error occurred: {e}\n")
        status_text.config(state=tk.DISABLED)


# --- GUI Setup ---
root = tk.Tk()
root.title("Admin Login Test")
root.geometry("500x400")

main_frame = tk.Frame(root, padx=10, pady=10)
main_frame.pack(fill=tk.BOTH, expand=True)

# Email
tk.Label(main_frame, text="Admin Email:").pack(anchor=tk.W)
email_entry = tk.Entry(main_frame, width=50)
email_entry.pack(fill=tk.X, pady=(0, 10))
email_entry.insert(0, ADMIN_EMAIL)

# Password
tk.Label(main_frame, text="Password:").pack(anchor=tk.W)
password_entry = tk.Entry(main_frame, show="*", width=50)
password_entry.pack(fill=tk.X, pady=(0, 10))

# Login Button
login_button = tk.Button(main_frame, text="Login", command=attempt_login)
login_button.pack(pady=10)

# Status/Result Text Area
tk.Label(main_frame, text="Status / Token:").pack(anchor=tk.W)
status_text = scrolledtext.ScrolledText(main_frame, height=10, wrap=tk.WORD)
status_text.pack(fill=tk.BOTH, expand=True)
status_text.config(state=tk.DISABLED)

# --- Main Loop ---
if __name__ == "__main__":
    root.mainloop()
