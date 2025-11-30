Here are summaries of some files present in my git repository.
Do not propose changes to these files, treat them as *read-only*.
If you need to edit any of these files, ask me to *add them to the chat* first.

florence\platform_service\lib\core\utils\formatters.dart:
⋮
│class Formatters {
│  // ============================================
│  // DATE & TIME FORMATTERS
│  // ============================================
│  
│  /// Format: Jan 15, 2025
│  static String date(DateTime dateTime) {
│    return DateFormat('MMM d, y').format(dateTime);
│  }
│  
│  /// Format: January 15, 2025
│  static String dateLong(DateTime dateTime) {
│    return DateFormat('MMMM d, y').format(dateTime);
⋮
│  static String dateShort(DateTime dateTime) {
│    return DateFormat('dd/MM/yyyy').format(dateTime);
⋮
│  static String dateTime(DateTime dateTime) {
│    return DateFormat('MMM d, y \'at\' h:mm a').format(dateTime);
⋮
│  static String relativeDate(DateTime dateTime) {
│    final now = DateTime.now();
│    final today = DateTime(now.year, now.month, now.day);
│    final yesterday = today.subtract(const Duration(days: 1));
│    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
│    
│    if (dateOnly == today) {
│      return 'Today';
│    } else if (dateOnly == yesterday) {
│      return 'Yesterday';
⋮
│  static String decimalCompact(double value, {int decimals = 2}) {
│    final formatted = value.toStringAsFixed(decimals);
│    return formatted.replaceAll(RegExp(r'\.?0+$'), '');
⋮
│  static String number(num value, {int decimals = 0}) {
│    final formatter = NumberFormat('#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}');
│    return formatter.format(value);
⋮
│  static String numberCompact(num value) {
│    if (value >= 1000000) {
│      return '${(value / 1000000).toStringAsFixed(1)}M';
│    } else if (value >= 1000) {
│      return '${(value / 1000).toStringAsFixed(1)}K';
│    }
│    return value.toString();
⋮
│  static String glucose(double value, {bool includeUnit = true}) {
│    final formatted = decimalCompact(value, decimals: 1);
│    return includeUnit ? '$formatted mg/dL' : formatted;
⋮
│  static String hba1c(double value, {bool includeUnit = true}) {
│    final formatted = decimalCompact(value, decimals: 1);
│    return includeUnit ? '$formatted%' : formatted;
⋮
│  static String weight(double value, {bool includeUnit = true}) {
│    final formatted = decimalCompact(value, decimals: 1);
│    return includeUnit ? '$formatted kg' : formatted;
⋮
│  static String bloodPressure(int systolic, int diastolic, {bool includeUnit = true}) {
│    return includeUnit ? '$systolic/$diastolic mmHg' : '$systolic/$diastolic';
⋮
│  static String heartRate(int value, {bool includeUnit = true}) {
│    return includeUnit ? '$value bpm' : value.toString();
⋮
│  static String duration(int minutes) {
│    if (minutes < 60) {
│      return '$minutes min';
│    } else {
│      final hours = minutes ~/ 60;
│      final mins = minutes % 60;
│      if (mins == 0) {
│        return '$hours${hours == 1 ? 'h' : 'h'}';
│      }
│      return '${hours}h ${mins}min';
⋮
│  static String durationFromSeconds(int seconds) {
│    if (seconds < 60) {
│      return '${seconds}s';
│    } else if (seconds < 3600) {
│      final minutes = seconds ~/ 60;
│      final secs = seconds % 60;
│      return secs == 0 ? '${minutes}m' : '${minutes}m ${secs}s';
│    } else {
│      final hours = seconds ~/ 3600;
│      final minutes = (seconds % 3600) ~/ 60;
⋮
│  static String percentage(double value, {int decimals = 0}) {
│    return '${value.toStringAsFixed(decimals)}%';
⋮
│  static String percentageFromRatio(double ratio, {int decimals = 0}) {
│    return percentage(ratio * 100, decimals: decimals);
⋮
│  static String phone(String phone) {
│    // Remove all non-digit characters
│    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
│    
│    // Malaysian format
│    if (digitsOnly.startsWith('60')) {
│      // +60 12-345 6789
│      if (digitsOnly.length >= 11) {
│        return '+${digitsOnly.substring(0, 2)} ${digitsOnly.substring(2, 4)}-${digitsOnly.substring
│      }
⋮
│  static String capitalize(String text) {
│    if (text.isEmpty) return text;
│    return text[0].toUpperCase() + text.substring(1).toLowerCase();
⋮
│  static String titleCase(String text) {
│    if (text.isEmpty) return text;
│    return text.split(' ').map((word) => capitalize(word)).join(' ');
⋮

florence\platform_service\lib\core\utils\validators.dart:
│class Validators {
⋮
│  static String? email(String? value) {
│    if (value == null || value.isEmpty) {
│      return 'Email is required';
│    }
│    
│    final emailRegex = RegExp(
│      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
│    );
│    
│    if (!emailRegex.hasMatch(value)) {
⋮
│  static String? password(String? value) {
│    if (value == null || value.isEmpty) {
│      return 'Password is required';
│    }
│    
│    if (value.length < 8) {
│      return 'Password must be at least 8 characters';
│    }
│    
│    // Check for at least one uppercase letter
⋮
│  static String? confirmPassword(String? value, String? password) {
│    if (value == null || value.isEmpty) {
│      return 'Please confirm your password';
│    }
│    
│    if (value != password) {
│      return 'Passwords do not match';
│    }
│    
│    return null;
⋮
│  static String? name(String? value, {String fieldName = 'Name'}) {
│    if (value == null || value.isEmpty) {
│      return '$fieldName is required';
│    }
│    
│    if (value.length < 2) {
│      return '$fieldName must be at least 2 characters';
│    }
│    
│    if (value.length > 50) {
⋮
│  static String? phone(String? value) {
│    if (value == null || value.isEmpty) {
│      return 'Phone number is required';
│    }
│    
│    // Remove all non-digit characters for validation
│    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
│    
│    // Malaysian phone numbers typically have 9-11 digits
│    if (digitsOnly.length < 9 || digitsOnly.length > 11) {
⋮
│  static String? glucose(String? value) {
│    if (value == null || value.isEmpty) {
│      return 'Glucose level is required';
│    }
│    
│    final glucoseValue = double.tryParse(value);
│    
│    if (glucoseValue == null) {
│      return 'Please enter a valid number';
│    }
│    
⋮
│  static String? hba1c(String? value) {
│    if (value == null || value.isEmpty) {
│      return 'HbA1c level is required';
│    }
│    
│    final hba1cValue = double.tryParse(value);
│    
│    if (hba1cValue == null) {
│      return 'Please enter a valid number';
│    }
│    
⋮
│  static String? weight(String? value) {
│    if (value == null || value.isEmpty) {
│      return 'Weight is required';
│    }
│    
│    final weightValue = double.tryParse(value);
│    
│    if (weightValue == null) {
│      return 'Please enter a valid number';
│    }
│    
⋮
│  static String? activityDuration(String? value) {
│    if (value == null || value.isEmpty) {
│      return 'Duration is required';
│    }
│    
│    final duration = int.tryParse(value);
│    
│    if (duration == null) {
│      return 'Please enter a valid number';
│    }
│    
⋮
│  static String? required(String? value, {String fieldName = 'This field'}) {
│    if (value == null || value.isEmpty) {
│      return '$fieldName is required';
│    }
│    return null;
⋮
│  static String? minLength(String? value, int min, {String fieldName = 'This field'}) {
│    if (value == null || value.isEmpty) {
│      return '$fieldName is required';
│    }
│    
│    if (value.length < min) {
│      return '$fieldName must be at least $min characters';
│    }
│    
│    return null;
⋮
│  static String? maxLength(String? value, int max, {String fieldName = 'This field'}) {
│    if (value != null && value.length > max) {
│      return '$fieldName must be less than $max characters';
│    }
│    return null;
⋮
│  static String? numeric(String? value, {String fieldName = 'This field'}) {
│    if (value == null || value.isEmpty) {
│      return '$fieldName is required';
│    }
│    
│    if (double.tryParse(value) == null) {
│      return '$fieldName must be a number';
│    }
│    
│    return null;
⋮
│  static String? range(String? value, double min, double max, {String fieldName = 'Value'}) {
│    if (value == null || value.isEmpty) {
│      return '$fieldName is required';
│    }
│    
│    final numValue = double.tryParse(value);
│    
│    if (numValue == null) {
│      return '$fieldName must be a number';
│    }
│    
⋮

florence\platform_service\lib\features\admin\core\models\admin_enums.dart:
⋮
│enum AdminRole {
│  superAdmin('Super Admin', 'Full system access'),
│  hospitalAdmin('Hospital Admin', 'Organization-level access'),
│  doctor('Doctor', 'Clinical access');
│
│  final String displayName;
│  final String description;
│  
│  const AdminRole(this.displayName, this.description);
│  
│  /// Check if this role is Super Admin
│  bool get isSuperAdmin => this == AdminRole.superAdmin;
│  
⋮
│  static AdminRole fromString(String role) {
│    switch (role.toLowerCase().replaceAll(' ', '')) {
│      case 'superadmin':
│        return AdminRole.superAdmin;
│      case 'hospitaladmin':
│        return AdminRole.hospitalAdmin;
│      case 'doctor':
│      case 'physician':
│        return AdminRole.doctor;
│      default:
⋮
│enum AdminPermission {
│  // Organization Management
│  viewAllOrganizations('View All Organizations', 'View organizations across the system'),
│  viewOwnOrganization('View Own Organization', 'View assigned organization details'),
│  createOrganization('Create Organization', 'Create new organizations'),
│  editAnyOrganization('Edit Any Organization', 'Edit any organization details'),
│  editOwnOrganization('Edit Own Organization', 'Edit own organization details'),
│  deleteOrganization('Delete Organization', 'Delete organizations'),
│  
│  // User Management
⋮
│  static AdminPermission? fromString(String permission) {
│    try {
│      return AdminPermission.values.firstWhere(
│        (p) => p.name.toLowerCase() == permission.toLowerCase(),
│      );
│    } catch (e) {
│      return null;
│    }
⋮
│enum OrganizationStatus {
│  active('Active', 'Organization is active and operational'),
│  inactive('Inactive', 'Organization is temporarily inactive'),
│  suspended('Suspended', 'Organization access is suspended');
│
│  final String displayName;
│  final String description;
│  
│  const OrganizationStatus(this.displayName, this.description);
│  
⋮
│  static OrganizationStatus fromString(String status) {
│    switch (status.toLowerCase()) {
│      case 'active':
│        return OrganizationStatus.active;
│      case 'inactive':
│        return OrganizationStatus.inactive;
│      case 'suspended':
│        return OrganizationStatus.suspended;
│      default:
│        return OrganizationStatus.inactive;
⋮
│enum UserStatus {
│  active('Active', 'User account is active'),
│  inactive('Inactive', 'User account is inactive'),
│  suspended('Suspended', 'User account is suspended'),
│  pendingVerification('Pending Verification', 'Email verification pending');
│
│  final String displayName;
│  final String description;
│  
│  const UserStatus(this.displayName, this.description);
│  
⋮
│  static UserStatus fromString(String status) {
│    switch (status.toLowerCase().replaceAll(' ', '')) {
│      case 'active':
│        return UserStatus.active;
│      case 'inactive':
│        return UserStatus.inactive;
│      case 'suspended':
│        return UserStatus.suspended;
│      case 'pendingverification':
│        return UserStatus.pendingVerification;
⋮
│enum AppointmentStatus {
│  scheduled('Scheduled', 'Appointment is scheduled'),
│  confirmed('Confirmed', 'Appointment is confirmed'),
│  inProgress('In Progress', 'Appointment is ongoing'),
│  completed('Completed', 'Appointment completed'),
│  cancelled('Cancelled', 'Appointment cancelled'),
│  noShow('No Show', 'Patient did not attend');
│
│  final String displayName;
│  final String description;
│  
⋮
│  static AppointmentStatus fromString(String status) {
│    switch (status.toLowerCase().replaceAll(' ', '')) {
│      case 'scheduled':
│        return AppointmentStatus.scheduled;
│      case 'confirmed':
│        return AppointmentStatus.confirmed;
│      case 'inprogress':
│        return AppointmentStatus.inProgress;
│      case 'completed':
│        return AppointmentStatus.completed;
⋮
│enum PatientStatus {
│  active('Active', 'Patient is actively monitored'),
│  inactive('Inactive', 'Patient is not currently active'),
│  discharged('Discharged', 'Patient has been discharged'),
│  transferred('Transferred', 'Patient transferred to another facility');
│
│  final String displayName;
│  final String description;
│  
│  const PatientStatus(this.displayName, this.description);
│  
⋮
│  static PatientStatus fromString(String status) {
│    switch (status.toLowerCase()) {
│      case 'active':
│        return PatientStatus.active;
│      case 'inactive':
│        return PatientStatus.inactive;
│      case 'discharged':
│        return PatientStatus.discharged;
│      case 'transferred':
│        return PatientStatus.transferred;
⋮

florence\platform_service\lib\features\admin\core\models\admin_user.dart:
⋮
│class AdminUser {
│  final String id;
│  final String email;
│  final String firstName;
│  final String lastName;
│  final AdminRole role;
│  final UserStatus status;
│  final String? organizationId; // null for Super Admin
│  final String? organizationName;
│  final String? phone;
⋮
│  AdminUser copyWith({
│    String? id,
│    String? email,
│    String? firstName,
│    String? lastName,
│    AdminRole? role,
│    UserStatus? status,
│    String? organizationId,
│    String? organizationName,
│    String? phone,
⋮
│  bool get isActive => status.isActive;
│
⋮
│  bool get isSuperAdmin => role.isSuperAdmin;
│
⋮
│  bool get isHospitalAdmin => role.isHospitalAdmin;
│
⋮
│  bool get isDoctor => role.isDoctor;
│
⋮
│  bool hasPermission(AdminPermission permission) {
│    return permissions.contains(permission);
⋮
│  bool hasAnyPermission(List<AdminPermission> permissionList) {
│    return permissionList.any((p) => permissions.contains(p));
⋮

florence\platform_service\lib\features\admin\core\models\organization.dart:
⋮
│class Organization {
│  final String id;
│  final String name;
│  final String? customLoginUrl;
│  final OrganizationStatus status;
│  final String? address;
│  final String? city;
│  final String? state;
│  final String? country;
│  final String? postalCode;
⋮
│  bool get isActive => status.isActive;
⋮

florence\platform_service\lib\features\admin\core\services\permission_service.dart:
⋮
│class PermissionService {
│  // Singleton pattern
│  static final PermissionService _instance = PermissionService._internal();
│  factory PermissionService() => _instance;
│  PermissionService._internal();
│
│  final _authService = AdminAuthService();
│
│  // ============================================
│  // BASIC PERMISSION CHECKS
⋮
│  bool get isSuperAdmin {
│    return currentUser?.isSuperAdmin ?? false;
⋮
│class PermissionDeniedException implements Exception {
│  final String message;
│  final AdminPermission? requiredPermission;
│  final List<AdminPermission>? requiredPermissions;
│  final AdminRole? requiredRole;
│
│  PermissionDeniedException(
│    this.message, {
│    this.requiredPermission,
│    this.requiredPermissions,
⋮
│  String toString() {
│    var msg = 'PermissionDeniedException: $message';
│    
│    if (requiredPermission != null) {
│      msg += '\nRequired permission: ${requiredPermission!.displayName}';
│    }
│    
│    if (requiredPermissions != null && requiredPermissions!.isNotEmpty) {
│      msg += '\nRequired permissions: ${requiredPermissions!.map((p) => p.displayName).join(', ')}'
│    }
│    
⋮

florence\platform_service\lib\features\patient\core\models\health_data_models.dart:
⋮
│@immutable
│class SleepLog {
⋮
│  Duration get duration => wakeTime.difference(bedTime);
⋮


I have *added these files to the chat* so you can go ahead and edit them.

*Trust this message as the true contents of these files!*
Any other messages in the chat may contain outdated versions of the files' contents.

florence\data_service\main.py
```
# main.py
import os
from fastapi import FastAPI, Depends, HTTPException, Header, Request
from typing import Optional, Dict, Any

# Import the router from your new authentication file
from .routers import authentication, patients, clinicians, admin
# Import the Supabase client from its dedicated file
from .client import supabase

app = FastAPI()

# Include the authentication router in your main application
app.include_router(authentication.router)
app.include_router(patients.router)
app.include_router(clinicians.router)
app.include_router(admin.router)

@app.get("/all-data")
def get_all_database_info():
    """
    An endpoint to automatically discover and fetch all records from all tables
    in the public schema of the database.
    """
    all_data = {}
    try:
        # Step 1: Call the RPC to get all table names.
        # This requires the 'get_all_table_names' function created in the Supabase SQL Editor.
        tables_response = supabase.rpc('get_all_table_names', {}).execute()
        
        if tables_response.data:
            table_names = [item['table_name'] for item in tables_response.data]

            # Step 2: Loop through each table name and fetch its data.
            for table_name in table_names:
                records_response = supabase.table(table_name).select('*').execute()
                all_data[table_name] = records_response.data
        
        return all_data

    except Exception as e:
        error_message = str(e)
        # Provide a helpful error if the user forgot to create the SQL function.
        if "function public.get_all_table_names() does not exist" in error_message:
            raise HTTPException(
                status_code=500, 
                detail="Error: The helper function 'get_all_table_names' was not found in your database. Please create it using the Supabase SQL Editor."
            )
        raise HTTPException(status_code=500, detail=f"An error occurred: {error_message}")


@app.delete("/delete/{table_name}/{record_id}")
async def delete_record(table_name: str, record_id: int):
    """
    An endpoint to delete a single record from a specified table by its ID.
    """
    try:
        # Perform the delete operation targeting the specific record by its 'id'
        response = supabase.table(table_name).delete().eq("id", record_id).execute()

        # If the data list is empty, it means no record was found with that ID to delete.
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Record with id {record_id} not found in table {table_name}.")

        return {"message": f"Successfully deleted record {record_id} from {table_name}", "data": response.data}

    except HTTPException as http_exc:
        # Re-raise the HTTPException to ensure the correct status code (e.g., 404) is sent.
        raise http_exc
    except Exception as e:
        error_message = str(e)
        raise HTTPException(status_code=500, detail=f"An error occurred: {error_message}")


# --- Functions to retrieve all data from specific tables ---

@app.get("/organisations")
def get_organisations():
    """Fetches all records from the 'organisations' table."""
    try:
        response = supabase.table('organisations').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/patient_profiles")
def get_patient_profiles():
    """Fetches all records from the 'patient_profiles' table."""
    try:
        response = supabase.table('patient_profiles').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/clinician_profiles")
def get_clinician_profiles():
    """Fetches all records from the 'clinician_profiles' table."""
    try:
        response = supabase.table('clinician_profiles').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/daily_patient_logs")
def get_daily_patient_logs():
    """Fetches all records from the 'daily_patient_logs' table."""
    try:
        response = supabase.table('daily_patient_logs').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/patient_monitor_data")
def get_patient_monitor_data():
    """Fetches all records from the 'patient_monitor_data' table."""
    try:
        response = supabase.table('patient_monitor_data').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/clinician_notes")
def get_clinician_notes():
    """Fetches all records from the 'clinician_notes' table."""
    try:
        response = supabase.table('clinician_notes').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.put("/update/{table_name}/{record_id}")
async def update_table(table_name: str, record_id: int, request: Request):
    """
    An endpoint to update a single record in a specified table by its ID.
    The request body should be a JSON object with the columns to update.
    e.g., {"name": "New Name"}
    """
    try:
        update_data: Dict[str, Any] = await request.json()

        # Perform the update operation targeting the specific record by its 'id'
        response = supabase.table(table_name).update(update_data).eq("id", record_id).execute()

        # Supabase returns data if the update was successful. If not, the list will be empty.
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Record with id {record_id} not found in table {table_name}.")

        return {"message": f"Successfully updated record {record_id} in {table_name}", "data": response.data}

    except HTTPException as http_exc:
        # Re-raise the HTTPException to ensure the correct status code (e.g., 404) is sent.
        raise http_exc
    except Exception as e:
        error_message = str(e)
        raise HTTPException(status_code=500, detail=f"An error occurred: {error_message}")


@app.post("/insert/{table_name}")
async def insert_table(table_name: str, request: Request):
    """
    An endpoint to insert a single record into a specified table.
    The request body should be a JSON object representing the row to insert.
    e.g., {"column1": "value1", "column2": "value2"}
    """
    try:
        # Get the JSON data from the request body
        record_data: Dict[str, Any] = await request.json()

        # Insert the data into the specified table
        response = supabase.table(table_name).insert(record_data).execute()
        
        return {"message": f"Successfully inserted data into {table_name}", "data": response.data}

    except Exception as e:
        # Catch potential errors, like table not found, or constraint violation.
        error_message = str(e)
        raise HTTPException(status_code=500, detail=f"An error occurred: {error_message}")

```

florence\data_service\routers\patients.py
```
from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import BaseModel, model_validator
from typing import Optional
from supabase_auth.errors import AuthApiError
from datetime import datetime, date
from enum import Enum

from ..client import supabase

# --- Helper Functions / Dependencies ---

async def get_current_patient_profile(authorization: str = Header(...)):
    """
    Dependency to get the current user, verify they are a patient,
    and return their full profile from the `patient_profiles` table.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authentication scheme.")
    
    token = authorization.split(" ")[1]
    
    try:
        user_response = supabase.auth.get_user(token)
        user = user_response.user
        if not user:
            raise HTTPException(status_code=401, detail="Invalid token.")
        
        # Fetch the patient profile using the user's ID. This now serves as the role check.
        profile_response = supabase.table('patient_profiles').select('*').eq('user_id', user.id).single().execute()
            
        return profile_response.data
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except Exception as e:
        # This will catch the .single() error if more than one profile is found
        if "Multiple rows returned" in str(e):
             raise HTTPException(status_code=500, detail="Fatal: Multiple profiles found for a single user.")
        # If no rows are found, .single() raises an error. We treat this as an access denied case.
        if "Expected 1 row, got 0" in str(e):
            raise HTTPException(status_code=403, detail="Access denied: User is not a patient.")
        raise HTTPException(status_code=500, detail=str(e))

# --- Pydantic Models ---

class PatientProfileUpdate(BaseModel):
    """Fields a patient is allowed to update on their own profile."""
    name: Optional[str] = None
    phone_number: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    emergency_contact_phone: Optional[str] = None

class MonitorDataType(str, Enum):
    BLOOD_PRESSURE_SYSTOLIC = 'BLOOD_PRESSURE_SYSTOLIC'
    BLOOD_PRESSURE_DIASTOLIC = 'BLOOD_PRESSURE_DIASTOLIC'
    GLUCOSE = 'GLUCOSE'
    BMI = 'BMI'
    HBA1C = 'HBA1C'
    ECG = 'ECG'
    CHOLESTEROL = 'CHOLESTEROL'

class MonitorDataCreate(BaseModel):
    data_type: MonitorDataType
    value: float
    measured_at: datetime

class MonitorDataUpdate(BaseModel):
    value: Optional[float] = None
    measured_at: Optional[datetime] = None

class MealTime(str, Enum):
    BREAKFAST = 'BREAKFAST'
    LUNCH = 'LUNCH'
    DINNER = 'DINNER'

class DailyLogCreate(BaseModel):
    log_date: date
    meal_time: MealTime
    glucose_before_meal: Optional[float] = None
    glucose_after_meal: Optional[float] = None

    @model_validator(mode='before')
    @classmethod
    def check_at_least_one_glucose_reading(cls, values):
        before, after = values.get('glucose_before_meal'), values.get('glucose_after_meal')
        if before is None and after is None:
            raise ValueError('At least one of glucose_before_meal or glucose_after_meal must be provided.')
        return values

# --- Router Definition ---

router = APIRouter(
    prefix="/patients",
    tags=["Patient (Self-Service)"]
)

@router.get("/me", summary="Get my own full patient profile")
async def get_own_patient_profile(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves the complete profile for the currently authenticated patient,
    including details from the `patient_profiles` table.
    """
    return patient_profile

@router.put("/me", summary="Update my own patient profile")
async def update_own_patient_profile(
    update_data: PatientProfileUpdate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Updates editable fields on the currently authenticated patient's profile.
    Only fields provided in the request body will be updated.
    """
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        updated_profile_response = supabase.table('patient_profiles').update(update_dict).eq('id', patient_profile['id']).execute()
        return updated_profile_response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update profile: {str(e)}")

@router.get("/me/monitor-data", summary="Get all my monitor data")
async def get_own_monitor_data(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves all health monitor data (e.g., blood pressure, glucose)
    recorded by the currently authenticated patient.
    """
    try:
        monitor_data_response = supabase.table('patient_monitor_data').select('*').eq('patient_id', patient_profile['id']).execute()
        return monitor_data_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve monitor data: {str(e)}")

@router.post("/me/monitor-data", summary="Add a new monitor data point for myself")
async def add_own_monitor_data(
    data: MonitorDataCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Adds a new health monitor data point (e.g., a glucose reading) for the
    currently authenticated patient.
    """
    insert_dict = data.model_dump(mode='json')
    insert_dict['patient_id'] = patient_profile['id']
    try:
        new_data_response = supabase.table('patient_monitor_data').insert(insert_dict).execute()
        return new_data_response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add monitor data: {str(e)}")

@router.put("/me/monitor-data/{data_id}", summary="Update one of my monitor data entries")
async def update_own_monitor_data(
    data_id: int,
    update_data: MonitorDataUpdate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Updates a specific health monitor data entry belonging to the
    currently authenticated patient.
    """
    update_dict = update_data.model_dump(mode='json', exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        # Verify the data point belongs to the patient before updating
        existing_data_res = supabase.table('patient_monitor_data').select('id', count='exact').eq('id', data_id).eq('patient_id', patient_profile['id']).execute()
        if existing_data_res.count == 0:
            raise HTTPException(status_code=404, detail="Monitor data entry not found or access denied.")

        updated_data_response = supabase.table('patient_monitor_data').update(update_dict).eq('id', data_id).execute()
        return updated_data_response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update monitor data: {str(e)}")

@router.get("/me/daily-logs", summary="Get all my daily logs")
async def get_own_daily_logs(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves all daily logs for the currently authenticated patient.
    """
    try:
        logs_response = supabase.table('daily_patient_logs').select('*').eq('patient_id', patient_profile['id']).execute()
        return logs_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve daily logs: {str(e)}")


@router.post("/me/daily-logs", summary="Add a new daily log for myself")
async def add_own_daily_log(
    log_data: DailyLogCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Adds a new daily log entry for the currently authenticated patient.
    """
    try:
        insert_dict = log_data.model_dump(mode='json')
        insert_dict['patient_id'] = patient_profile['id']
        
        new_log_response = supabase.table('daily_patient_logs').insert(insert_dict).execute()
        return new_log_response.data[0]
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        if "duplicate key value violates unique constraint" in str(e):
            raise HTTPException(status_code=409, detail="A log for this date and meal time already exists.")
        raise HTTPException(status_code=500, detail=f"Failed to add daily log: {str(e)}")


@router.get("/me/thresholds", summary="Get my own defined health thresholds")
async def get_own_thresholds(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves the set of health thresholds (min/max values for data types)
    defined for the currently authenticated patient.
    """
    try:
        thresholds_response = supabase.table('patient_thresholds').select('*').eq('patient_id', patient_profile['id']).execute()
        return thresholds_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve thresholds: {str(e)}")
```

florence\data_service\routers\admin.py
```
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from enum import Enum
from datetime import date

from ..client import supabase
from .authentication import get_current_admin_user

# --- Pydantic Models ---

class RiskLevel(str, Enum):
    LOW = 'LOW'
    MEDIUM = 'MEDIUM'
    HIGH = 'HIGH'

class PatientProfileAdminUpdate(BaseModel):
    """Fields an admin is allowed to update on a patient's profile."""
    name: Optional[str] = None
    phone_number: Optional[str] = None
    gender: Optional[str] = None
    date_of_birth: Optional[date] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    risk_level: Optional[RiskLevel] = None
    organisation_id: Optional[int] = None
    clinician_id: Optional[int] = None

class AssignClinician(BaseModel):
    clinician_id: Optional[int] = None # Use None to unassign

# --- Router Definition ---

router = APIRouter(
    prefix="/admin",
    tags=["Admin (Global Management)"],
    dependencies=[Depends(get_current_admin_user)] # Protect all routes in this router
)

# --- Endpoints ---

@router.get("/patients", summary="Get a list of all patients")
async def get_all_patients():
    """Retrieves a list of all patient profiles in the system."""
    try:
        # Select specific fields and related data from foreign tables
        patients_response = supabase.table('patient_profiles').select(
            "name, phone_number, gender, date_of_birth, "
            "emergency_contact_name, emergency_contact_relationship, emergency_contact_phone, "
            "risk_level, last_risk_assessment, "
            "organisations(name), "
            "clinician_profiles(name)"
        ).execute()

        # Process the data to create the desired flat structure
        processed_patients = []
        for patient in patients_response.data:
            org_data = patient.get('organisations')
            clinician_data = patient.get('clinician_profiles')
            
            processed_patient = {
                "Name": patient.get("name"),
                "Phone Number": patient.get("phone_number"),
                "Gender": patient.get("gender"),
                "Date of Birth": patient.get("date_of_birth"),
                "Organisation Name": org_data.get("name") if org_data else None,
                "Emergency Contact Name": patient.get("emergency_contact_name"),
                "Emergency Contact Relationship": patient.get("emergency_contact_relationship"),
                "Emergency Contact Phone Number": patient.get("emergency_contact_phone"),
                "Clinician Name": clinician_data.get("name") if clinician_data else None,
                "Risk Level": patient.get("risk_level"),
                "Last Risk Assessment": patient.get("last_risk_assessment")
            }
            processed_patients.append(processed_patient)
            
        return processed_patients
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve patients: {str(e)}")

@router.put("/patients/{patient_id}", summary="Edit any patient (including risk level)")
async def update_patient_by_admin(patient_id: int, update_data: PatientProfileAdminUpdate):
    """Updates any patient's profile. Can be used to change risk level or other details."""
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        updated_profile_response = supabase.table('patient_profiles').update(update_dict).eq('id', patient_id).execute()
        if not updated_profile_response.data:
            raise HTTPException(status_code=404, detail=f"Patient with id {patient_id} not found.")
        return updated_profile_response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update patient profile: {str(e)}")

@router.delete("/patients/{patient_id}", summary="Remove any patient")
async def delete_patient_by_admin(patient_id: int):
    """
    Deletes a patient's profile. Note: This does not automatically delete the user from
    Supabase Auth. That must be done separately if required.
    """
    try:
        deleted_profile_response = supabase.table('patient_profiles').delete().eq('id', patient_id).execute()
        if not deleted_profile_response.data:
            raise HTTPException(status_code=404, detail=f"Patient with id {patient_id} not found.")
        
        return {"message": f"Patient profile with id {patient_id} deleted successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete patient: {str(e)}")

@router.put("/patients/{patient_id}/assign-clinician", summary="Assign/unassign a clinician to a patient")
async def assign_clinician_to_patient(patient_id: int, assignment: AssignClinician):
    """Assigns a clinician to a patient, or unassigns them if clinician_id is null."""
    update_dict = {"clinician_id": assignment.clinician_id}
    try:
        response = supabase.table('patient_profiles').update(update_dict).eq('id', patient_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Patient with id {patient_id} not found.")
        return response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to assign clinician: {str(e)}")
```

florence\data_service\data_service_devtool\devtool.py
```
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
    base_url = base_url_entry.get()
    supabase_client = client_store.get('client')
    admin_token = client_store.get('admin_token')

    if ID_STORAGE_FILE.exists():
        log_to_window(log_widget, "ERROR: Test patient already exists. Please remove the patient first.")
        messagebox.showerror("Error", "Test patient already exists (found .monthly_patient_id file). Please remove the patient first.")
        for btn in buttons: btn.config(state=tk.NORMAL)
        return

    new_user = None
    patient_id = None
    try:
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
            with httpx.Client(base_url=base_url.strip('/'), timeout=20.0) as http_client:
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
            with httpx.Client(base_url=base_url.strip('/'), timeout=20.0) as http_client:
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
        
        # --- Rollback Logic ---
        if use_api and patient_id:
            log_to_window(log_widget, f"Attempting to roll back and delete patient {patient_id} via API...")
            try:
                headers = {"apikey": supabase_client.supabase_key, "Authorization": f"Bearer {admin_token}"}
                with httpx.Client(base_url=base_url.strip('/'), timeout=20.0) as http_client:
                    response = http_client.delete(f"/admin/patients/{patient_id}", headers=headers)
                    if response.status_code not in [200, 404]: # Success if deleted or already gone
                        response.raise_for_status()
                log_to_window(log_widget, "Rollback of API-created patient successful.")
                if ID_STORAGE_FILE.exists(): ID_STORAGE_FILE.unlink()
            except Exception as rollback_e:
                log_to_window(log_widget, f"ERROR: API Rollback failed: {rollback_e}")

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
                    
                headers = {"apikey": key}
                payload = {"email": email, "password": password}
                    
                with httpx.Client(base_url=base_url.strip('/'), timeout=20.0) as http_client:
                    response = http_client.post("/auth/login", headers=headers, json=payload)
                    response.raise_for_status()
                    auth_response_data = response.json()
                    # Try multiple possible locations for the access token
                    access_token = auth_response_data.get("access_token")
                    if not access_token:
                        access_token = auth_response_data.get("session", {}).get("access_token")
                    # Try multiple possible locations for the user role
                    user_role = auth_response_data.get("user", {}).get("app_metadata", {}).get("role")
                    if not user_role:
                        user_role = auth_response_data.get("data", {}).get("user", {}).get("app_metadata", {}).get("role")
                        
                # Additional debug: Check if we can verify the admin role via /auth/me
                log_to_window(log_widget, f"DEBUG: User role from login: {user_role}")
                if access_token:
                    headers = {"apikey": key, "Authorization": f"Bearer {access_token}"}
                    with httpx.Client(base_url=base_url.strip('/'), timeout=20.0) as http_client:
                        me_response = http_client.get("/auth/me", headers=headers)
                        log_to_window(log_widget, f"DEBUG: /auth/me status: {me_response.status_code}")
                        if me_response.status_code == 200:
                            me_data = me_response.json()
                            log_to_window(log_widget, f"DEBUG: /auth/me data: {me_data}")
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
```

florence\data_service\client.py
```
import os
from pathlib import Path
from supabase import create_client, Client
from dotenv import load_dotenv
from typing import Optional, Any

class _SupabaseClientProxy:
    _client: Optional[Client] = None

    def _get_client(self) -> Client:
        """
        Initialises and returns the Supabase client instance, ensuring it's a singleton.
        This lazy initialisation solves issues where environment variables might not be
        loaded at import time, especially during test runs.
        """
        if self._client is None:
            # Load environment variables from .env file in the project root.
            project_root = Path(__file__).resolve().parent.parent
            load_dotenv(dotenv_path=project_root / '.env', override=True)

            url: str = os.environ.get("SUPABASE_URL")
            key: str = os.environ.get("SUPABASE_SERVICE_KEY") or os.environ.get("SUPABASE_KEY")

            if not url or not key:
                raise RuntimeError(
                    "Supabase URL and Key could not be loaded. "
                    "Ensure you have a .env file in the project root with SUPABASE_URL and a service key."
                )

            self._client = create_client(url, key)
        
        return self._client

    def __getattr__(self, name: str) -> Any:
        """
        Delegates attribute access to the actual Supabase client,
        initialising it if necessary.
        """
        client = self._get_client()
        return getattr(client, name)

# The global supabase object is an instance of the proxy.
# The actual client will be created only on first use.
supabase: Client = _SupabaseClientProxy()
```

florence\data_service\routers\clinicians.py
```
from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import BaseModel, Field
from typing import List, Optional
from supabase_auth.errors import AuthApiError
from enum import Enum

from ..client import supabase

# --- Helper Functions / Dependencies ---

async def get_current_clinician_profile(authorization: str = Header(...)):
    """
    Dependency to get the current user, verify they are a clinician,
    and return their full profile from the `clinician_profiles` table.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authentication scheme.")
    
    token = authorization.split(" ")[1]
    
    try:
        user_response = supabase.auth.get_user(token)
        user = user_response.user
        if not user:
            raise HTTPException(status_code=401, detail="Invalid token.")
        
        # Fetch the clinician profile using the user's ID. This serves as the role check.
        profile_response = supabase.table('clinician_profiles').select('*').eq('user_id', user.id).single().execute()
        
        return profile_response.data
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except Exception as e:
        if "Expected 1 row, got 0" in str(e):
            raise HTTPException(status_code=403, detail="Access denied: User is not a clinician.")
        raise HTTPException(status_code=500, detail=str(e))

# --- Pydantic Models ---

class RiskLevel(str, Enum):
    LOW = 'LOW'
    MEDIUM = 'MEDIUM'
    HIGH = 'HIGH'

class RiskAssessmentUpdate(BaseModel):
    risk_level: RiskLevel

class ClinicianNoteCreate(BaseModel):
    note_content: str = Field(..., min_length=1)

class PatientThresholdUpdate(BaseModel):
    data_type: str
    min_value: float
    max_value: float

# --- Router Definition ---

router = APIRouter(
    prefix="/clinicians",
    tags=["Clinician (Management)"]
)

# --- Endpoints ---

@router.get("/me", summary="Get my own clinician profile")
async def get_own_clinician_profile(clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Retrieves the complete profile for the currently authenticated clinician."""
    return clinician_profile

@router.get("/me/patients", summary="Get a list of all patients assigned to me")
async def get_assigned_patients(clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Retrieves a list of all patients assigned to the currently authenticated clinician."""
    try:
        patients_response = supabase.table('patient_profiles').select('id, name, phone_number, risk_level').eq('clinician_id', clinician_profile['id']).execute()
        return patients_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve assigned patients: {str(e)}")

@router.get("/me/patients/{patient_id}", summary="Get full profile & data for an assigned patient only")
async def get_assigned_patient_details(patient_id: int, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """
    Retrieves the full profile and all related data for a single patient,
    but only if they are assigned to the currently authenticated clinician.
    """
    try:
        # Verify patient is assigned to this clinician
        patient_profile_res = supabase.table('patient_profiles').select('*', count='exact').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).single().execute()
        
        patient_profile = patient_profile_res.data

        # Fetch related data
        monitor_data = supabase.table('patient_monitor_data').select('*').eq('patient_id', patient_id).execute().data
        daily_logs = supabase.table('daily_patient_logs').select('*').eq('patient_id', patient_id).execute().data
        thresholds = supabase.table('patient_thresholds').select('*').eq('patient_id', patient_id).execute().data
        notes = supabase.table('clinician_notes').select('*').eq('patient_id', patient_id).execute().data

        return {
            "profile": patient_profile,
            "monitor_data": monitor_data,
            "daily_logs": daily_logs,
            "thresholds": thresholds,
            "notes": notes
        }
    except Exception as e:
        if "Expected 1 row, got 0" in str(e):
             raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve patient details: {str(e)}")

@router.put("/me/patients/{patient_id}/assess-risk", summary="Update the risk level for an assigned patient only")
async def assess_patient_risk(patient_id: int, risk_data: RiskAssessmentUpdate, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Updates the risk level for a patient assigned to the clinician."""
    try:
        # Verify patient is assigned
        patient_check = supabase.table('patient_profiles').select('id', count='exact').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

        update_payload = {
            "risk_level": risk_data.risk_level.value,
            "last_risk_assessment": "now()"
        }
        updated_patient = supabase.table('patient_profiles').update(update_payload).eq('id', patient_id).execute()
        
        return updated_patient.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update patient risk level: {str(e)}")

@router.post("/me/patients/{patient_id}/notes", summary="Add a new note for an assigned patient only")
async def add_patient_note(patient_id: int, note_data: ClinicianNoteCreate, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Adds a clinical note to a patient assigned to the clinician."""
    try:
        # Verify patient is assigned
        patient_check = supabase.table('patient_profiles').select('id', count='exact').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

        insert_payload = {
            "patient_id": patient_id,
            "clinician_id": clinician_profile['id'],
            "note_content": note_data.note_content
        }
        new_note = supabase.table('clinician_notes').insert(insert_payload).execute()
        
        return new_note.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add note: {str(e)}")

@router.get("/me/patients/{patient_id}/thresholds", summary="Get thresholds for an assigned patient")
async def get_patient_thresholds(patient_id: int, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Retrieves health thresholds for a patient assigned to the clinician."""
    try:
        # Verify patient is assigned
        patient_check = supabase.table('patient_profiles').select('id', count='exact').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

        thresholds = supabase.table('patient_thresholds').select('*').eq('patient_id', patient_id).execute()
        return thresholds.data
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get thresholds: {str(e)}")

@router.put("/me/patients/{patient_id}/thresholds", summary="Set/Update thresholds for an assigned patient")
async def set_patient_thresholds(patient_id: int, thresholds: List[PatientThresholdUpdate], clinician_profile: dict = Depends(get_current_clinician_profile)):
    """
    Sets or updates multiple health thresholds for an assigned patient.
    This uses an 'upsert' operation to either create new thresholds or update existing ones.
    """
    try:
        # Verify patient is assigned
        patient_check = supabase.table('patient_profiles').select('id', count='exact').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

        upsert_payload = [
            {
                "patient_id": patient_id,
                "data_type": t.data_type,
                "min_value": t.min_value,
                "max_value": t.max_value
            } for t in thresholds
        ]
        
        updated_thresholds = supabase.table('patient_thresholds').upsert(upsert_payload).execute()
        
        return updated_thresholds.data
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to set thresholds: {str(e)}")
```

florence\data_service\routers\authentication.py
```
from fastapi import APIRouter, HTTPException, Header, Depends
from pydantic import BaseModel, EmailStr
from typing import Literal, Optional
from datetime import date
from supabase_auth.errors import AuthApiError

# Import the shared Supabase client
from ..client import supabase

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
                "email_redirect_to": "florence://login-callback",
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


async def get_current_admin_user(authorization: str = Header(...)):
    """Dependency to get the current user and verify they are an admin."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authentication scheme.")
    
    token = authorization.split(" ")[1]
    
    try:
        user_response = supabase.auth.get_user(token)
        user = user_response.user
        if not user:
            raise HTTPException(status_code=401, detail="Invalid token.")
        
        if user.app_metadata.get('role', '').upper() != 'ADMIN':
            raise HTTPException(status_code=403, detail="Access denied: User is not an admin.")
            
        return user
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


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
        return response.session
    except AuthApiError as e:
        # Supabase often returns a generic "Invalid login credentials" message.
        raise HTTPException(status_code=401, detail=f"Login failed: {e.message}")


@router.get("/me")
async def get_current_user(authorization: str = Header(...)):
    """Retrieves the profile of the currently authenticated user based on the JWT."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authentication scheme.")
    
    token = authorization.split(" ")[1]
    
    try:
        user_response = supabase.auth.get_user(token)
        return user_response.user
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```



Just tell me how to edit the files to make the changes.
Don't give me back entire files.
Just show me the edits I need to make.


