from fastapi import APIRouter, HTTPException, Header, Depends, status
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, EmailStr
from typing import Literal, Optional
from datetime import date, datetime, timedelta
from supabase_auth.errors import AuthApiError
from jose import JWTError, jwt

# Import the shared Supabase client
from ..client import supabase

# --- JWT Configuration ---
SECRET_KEY = "a_very_secret_key_that_should_be_in_env_vars" # IMPORTANT: Move to .env in production
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 # 1 day

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

class UserRegistration(BaseModel):
    email: EmailStr
    password: str
    role: Literal['PATIENT', 'CLINICIAN']
    name: str
    phone_number: Optional[str] = None
    # Clinician specific
    organisation_id: Optional[int] = None
    # Patient specific
    gender: Optional[str] = None
    date_of_birth: Optional[date] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    emergency_contact_phone: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class TokenExchange(BaseModel):
    refresh_token: str


class AdminRegistration(BaseModel):
    email: EmailStr
    password: str


DEFAULT_THRESHOLDS = [
    {'data_type': 'GLUCOSE', 'min_value': 70.0, 'max_value': 180.0},
    {'data_type': 'HBA1C', 'min_value': 4.0, 'max_value': 7.0},
    {'data_type': 'BMI', 'min_value': 18.5, 'max_value': 24.9},
    {'data_type': 'CHOLESTEROL', 'min_value': 100.0, 'max_value': 199.0},
    {'data_type': 'ECG', 'min_value': 60.0, 'max_value': 100},
    {'data_type': 'BLOOD_PRESSURE_SYSTOLIC', 'min_value': 90.0, 'max_value': 120},
    {'data_type': 'BLOOD_PRESSURE_DIASTOLIC', 'min_value': 60.0, 'max_value': 80}

    # NOTE: BLOOD_PRESSURE is not added by default because its value (e.g., "120/80")
    # doesn't fit the `min_value`/`max_value` NUMERIC columns in the `patient_thresholds` table.
    # A clinician or admin should set this manually based on a specific metric (e.g., Systolic only).
    # NOTE: ECG is also not added as its result is typically qualitative (e.g., "Normal Sinus Rhythm")
    # and does not have a simple numeric min/max threshold.
]

# --- Helper Functions ---
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

@router.post("/register")
async def register_user(user_data: UserRegistration):
    if user_data.role == 'CLINICIAN' and user_data.organisation_id is None:
        raise HTTPException(status_code=400, detail="Organisation ID is required for clinicians.")

    new_user = None
    try:
        user_session = supabase.auth.sign_up({
            "email": user_data.email,
            "password": user_data.password,
            "options": {
                # IMPORTANT: This now points to YOUR backend
                "email_redirect_to": "http://10.191.69.105:8000/auth/confirm",
                "data": {
                    "role": user_data.role
                }
            }
        })
        new_user = user_session.user
        if not new_user:
            raise HTTPException(status_code=500, detail="Failed to create user in authentication system.")

    except AuthApiError as e:
        raise HTTPException(status_code=400, detail=f"User registration failed: {e.message}")
    
    try:
        if user_data.role == 'PATIENT':
            profile_data = {
                "user_id": new_user.id, "name": user_data.name, "phone_number": user_data.phone_number,
                "gender": user_data.gender,
                "date_of_birth": user_data.date_of_birth.isoformat() if user_data.date_of_birth else None,
                "emergency_contact_name": user_data.emergency_contact_name,
                "emergency_contact_relationship": user_data.emergency_contact_relationship,
                "emergency_contact_phone": user_data.emergency_contact_phone,
            }
            patient_profile = supabase.table('patient_profiles').insert(profile_data).execute().data[0]
            
            thresholds_to_insert = [
                {**threshold, 'patient_id': patient_profile['id']} for threshold in DEFAULT_THRESHOLDS
            ]
            supabase.table('patient_thresholds').insert(thresholds_to_insert).execute()

        elif user_data.role == 'CLINICIAN':
            profile_data = {
                "user_id": new_user.id, "name": user_data.name, "phone_number": user_data.phone_number,
                "organisation_id": user_data.organisation_id,
            }
            supabase.table('clinician_profiles').insert(profile_data).execute()
        
        return {"message": f"{user_data.role.capitalize()} registered successfully. Please check your email for verification."}

    except Exception as e:
        if new_user:
            supabase.auth.admin.delete_user(new_user.id)
        raise HTTPException(status_code=500, detail=f"Failed to create user profile: {str(e)}")


@router.get("/confirm", response_class=HTMLResponse)
async def confirm_email_redirect():
    """
    Serves a simple HTML page with JavaScript to capture the auth tokens from the URL fragment
    and redirect to the mobile app's deep link.
    """
    return """
    <html>
        <head>
            <title>Confirming Email...</title>
            <script>
                // This script runs in the user's browser after Supabase redirects them here.
                // It reads the access_token and refresh_token from the URL fragment (#)
                // and immediately redirects to the app's custom URL scheme.
                try {
                    const hash = window.location.hash.substring(1);
                    window.location.replace(`florence://login-callback#${hash}`);
                } catch (e) {
                    document.body.innerText = "Error: Could not redirect back to the app. Please open the app manually.";
                }
            </script>
        </head>
        <body>
            <p>Redirecting you back to the Florence app...</p>
        </body>
    </html>
    """


async def get_current_user_id_from_token(authorization: str = Header(...)):
    """
    New dependency to validate our backend's JWT and return the user ID (sub).
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authentication scheme.")
    token = authorization.split(" ")[1]

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        return user_id
    except JWTError:
        raise credentials_exception
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


async def get_current_admin_user(user_id: str = Depends(get_current_user_id_from_token)):
    """Dependency to get the current user ID from the token and verify they are an admin."""
    try:
        user_response = supabase.auth.admin.get_user_by_id(user_id)
        user = user_response.user
        if not user:
            raise HTTPException(status_code=401, detail="User not found.")

        if user.app_metadata.get('role', '').upper() != 'ADMIN':
            raise HTTPException(status_code=403, detail="Access denied: User is not an admin.")

        return user
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred while verifying admin status: {str(e)}")


@router.post("/register_admin", dependencies=[Depends(get_current_admin_user)])
async def register_admin(user_data: AdminRegistration):
    """Registers a new admin user. This endpoint is protected and only accessible by other admins."""
    try:
        supabase.auth.admin.create_user({
            "email": user_data.email,
            "password": user_data.password,
            "email_confirm": True,
            "app_metadata": {"role": "ADMIN"},
        })
        return {"message": "Admin registered successfully."}
    except AuthApiError as e:
        raise HTTPException(status_code=400, detail=f"Admin registration failed: {e.message}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")


@router.post("/login")
async def login_user(credentials: UserLogin):
    """Logs in a user and returns a session object with an access token."""
    try:
        response = supabase.auth.sign_in_with_password({
            "email": credentials.email,
            "password": credentials.password
        })

        # Instead of returning Supabase session, create and return our OWN JWT
        user_id = response.user.id
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        backend_access_token = create_access_token(
            data={"sub": user_id}, expires_delta=access_token_expires
        )
        return {"access_token": backend_access_token, "token_type": "bearer"}

    except AuthApiError as e:
        # Supabase often returns a generic "Invalid login credentials" message.
        raise HTTPException(status_code=401, detail=f"Login failed: {e.message}")


@router.post("/token")
async def exchange_refresh_token(token_data: TokenExchange):
    """
    Exchanges a Supabase refresh token (from an email link) for our backend's own JWT.
    """
    try:
        session_response = supabase.auth.refresh_session(token_data.refresh_token)
        user_id = session_response.user.id

        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        backend_access_token = create_access_token(
            data={"sub": user_id}, expires_delta=access_token_expires
        )
        return {"access_token": backend_access_token, "token_type": "bearer"}
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid refresh token: {e.message}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")




@router.get("/me")
async def get_current_user(user_id: str = Depends(get_current_user_id_from_token)):
    """Retrieves the profile of the currently authenticated user based on the JWT."""
    try:
        user_response = supabase.auth.admin.get_user_by_id(user_id)
        return user_response.user
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
