import os
import requests

def create_test_accounts():
    # Get Supabase configuration from environment variables
    SUPABASE_URL = os.environ.get('SUPABASE_URL')
    SUPABASE_SERVICE_ROLE_KEY = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')

    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError("Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables")

    # Set up headers for Admin API access
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }

    # Create admin user
    admin_user_data = {
        "email": "admin@test.com",
        "password": "test1234",
        "email_confirm": True,
        "user_metadata": {
            "role": "admin",
            "first_name": "Test",
            "last_name": "Admin"
        }
    }

    print("Creating admin user...")
    admin_response = requests.post(
        f"{SUPABASE_URL}/auth/v1/admin/users",
        headers=headers,
        json=admin_user_data
    )
    
    if admin_response.status_code == 201:
        print(f"✅ Admin user created successfully: {admin_response.json()['email']}")
    else:
        print(f"❌ Failed to create admin user: {admin_response.json()}")

    # Create clinician user
    clinician_user_data = {
        "email": "clinician@test.com",
        "password": "test1234",
        "email_confirm": True,
        "user_metadata": {
            "role": "clinician",
            "first_name": "Test",
            "last_name": "Clinician"
        }
    }

    print("Creating clinician user...")
    clinician_response = requests.post(
        f"{SUPABASE_URL}/auth/v1/admin/users",
        headers=headers,
        json=clinician_user_data
    )
    
    if clinician_response.status_code == 201:
        print(f"✅ Clinician user created successfully: {clinician_response.json()['email']}")
    else:
        print(f"❌ Failed to create clinician user: {clinician_response.json()}")

    print("\nTest accounts created!")
    print("Login credentials:")
    print("Admin - Email: admin@test.com, Password: test1234")
    print("Clinician - Email: clinician@test.com, Password: test1234")

if __name__ == "__main__":
    create_test_accounts()
