Here are summaries of some files present in my git repository.
Do not propose changes to these files, treat them as *read-only*.
If you need to edit any of these files, ask me to *add them to the chat* first.

Stale\AI-Integration-branch\DeepSeek.py:
⋮
│api_token = "cpk_1c9adce1fd244f5e879cc45afa88c5c4.986b31f04b5056388f96ddf6cbf9f8fe.Osipc4tDlSGc01vC
│
⋮
│url = "https://llm.chutes.ai/v1/chat/completions"
│
⋮
│headers = {
│    "Authorization": f"Bearer {api_token}",
│    "Content-Type": "application/json",
⋮
│data = {
│    "model": "deepseek-ai/DeepSeek-V3.1",
│    "messages": [
│        {
│            "role": "user",
│            "content": "Tell me a 250 word story."
│        }
│    ],
│    "stream": True,
│    "max_tokens": 1024,
⋮

florence\llm_chatbot_service\models\chat.py:
⋮
│class ChatMessage(BaseModel):
⋮
│class DeepSeekChoice(BaseModel):
⋮
│class DeepSeekUsage(BaseModel):
⋮

florence\platform_service\lib\core\config\environment.dart:
⋮
│class Environment {
│  // ==================== FEATURE FLAGS ====================
│
│  /// Enable Supabase backend integration
│  /// Set to true when ready to connect to Supabase
│  static const bool enableSupabase = true;
│
│  /// Enable AI features (via Microservice)
│  /// Set to true to use AI-powered recommendations and chatbot
│  static const bool enableAI = true;
│
⋮
│  static bool isFeatureEnabled(String feature) {
│    switch (feature) {
│      case 'supabase':
│        return enableSupabase;
│      case 'ai':
│        return enableAI;
│      case 'automation':
│        return enableAutomation;
│      case 'analytics':
│        return enableAnalytics;
⋮
│  static String get modeDescription {
│    if (enableSupabase) return 'Production Mode (Supabase Connected)';
│    if (useMockData) return 'Demo Mode (Mock Data)';
│    return 'Development Mode';
⋮
│  static bool get isProduction => appEnvironment == 'production';
│
⋮
│  static bool get isDevelopment => appEnvironment == 'development';
│
⋮
│  static bool get isConfigured {
│    return supabaseUrl != 'https://<your-project-ref>.supabase.co' &&
│           supabaseAnonKey != '<your-anon-key>';
⋮

florence\platform_service\lib\core\services\api_service.dart:
⋮
│class ApiService {
│  Future<Map<String, String>> _getHeaders() async {
│    final headers = {
│      'Content-Type': 'application/json',
│      'apikey': Environment.supabaseAnonKey,
│    };
│
│    // Get the token directly from the current Supabase session
│    final currentToken = supabase.auth.currentSession?.accessToken;
│
│    if (currentToken != null) {
⋮
│  Future<dynamic> get(String endpoint) async {
│    try {
│      var response = await http.get(
│        Uri.parse('${Environment.apiUrl}$endpoint'),
│        headers: await _getHeaders(),
│      );
│
│      if (response.statusCode == 401) {
│        try {
│          await supabase.auth.refreshSession();
⋮
│  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
│    try {
│      var response = await http.post(
│        Uri.parse('${Environment.apiUrl}$endpoint'),
│        headers: await _getHeaders(),
│        body: jsonEncode(data),
│      );
│
│      if (response.statusCode == 401) {
│        try {
⋮
│  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
│    try {
│      var response = await http.put(
│        Uri.parse('${Environment.apiUrl}$endpoint'),
│        headers: await _getHeaders(),
│        body: jsonEncode(data),
│      );
│
│      if (response.statusCode == 401) {
│        try {
⋮
│  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
│    try {
│      final response = await http.patch(
│        Uri.parse('${Environment.apiUrl}$endpoint'),
│        headers: await _getHeaders(),
│        body: jsonEncode(data),
│      );
│      return _processResponse(response);
│    } catch (e) {
│      debugPrint('API PATCH Error ($endpoint): $e');
⋮
│  Future<dynamic> delete(String endpoint) async {
│    try {
│      final response = await http.delete(
│        Uri.parse('${Environment.apiUrl}$endpoint'),
│        headers: await _getHeaders(),
│      );
│      return _processResponse(response);
│    } catch (e) {
│      debugPrint('API DELETE Error ($endpoint): $e');
│      rethrow;
⋮
│  dynamic _processResponse(http.Response response) {
│    debugPrint('API Response (${response.request?.method} ${response.request?.url.path}): ${respons
│    if (response.statusCode >= 200 && response.statusCode < 300) {
│      if(response.body.isEmpty) return null;
│      return jsonDecode(response.body);
│    } else {
│      final errorBody = jsonDecode(response.body);
│      final errorMessage = errorBody['detail'] ?? 'An API error occurred.';
│      debugPrint('API Error Body: ${response.body}');
│      throw Exception(errorMessage);
⋮

florence\platform_service\lib\core\services\notifications\notification_models.dart:
⋮
│enum NotificationType {
│  alert,        // Critical alerts (hypo/hyper)
│  reminder,     // Reminders (medication, activity)
│  educational,  // Educational tips
│  motivational, // Motivational messages
│  summary,      // Health summaries
│  achievement,  // Achievements and milestones
⋮
│enum NotificationPriority {
│  critical,
│  high,
│  medium,
│  low,
⋮
│@immutable
│class HealthNotification {
⋮
│  String get typeLabel {
│    switch (type) {
│      case NotificationType.alert:
│        return 'Alert';
│      case NotificationType.reminder:
│        return 'Reminder';
│      case NotificationType.educational:
│        return 'Tip';
│      case NotificationType.motivational:
│        return 'Encouragement';
⋮
│  bool get requiresAction => priority == NotificationPriority.critical;
│
⋮
│  factory HealthNotification.fromJson(Map<String, dynamic> json) {
│    return HealthNotification(
│      id: json['id'] as String,
│      type: NotificationType.values.firstWhere(
│        (e) => e.name == json['type'],
│      ),
│      priority: NotificationPriority.values.firstWhere(
│        (e) => e.name == json['priority'],
│      ),
│      title: json['title'] as String,
⋮

florence\platform_service\lib\core\services\notifications\notification_service.dart:
⋮
│class NotificationService with ChangeNotifier {
│  final PatternDetectionService _patternService = PatternDetectionService();
│
│  // Singleton pattern
│  static final NotificationService _instance = NotificationService._internal();
│  factory NotificationService() => _instance;
│  NotificationService._internal() {
│    if (Environment.enableAutomation) {
│      _startAutomationMonitoring();
│    }
⋮
│  void markAsRead(String id) {
│    final index = _notifications.indexWhere((n) => n.id == id);
│    if (index != -1) {
│      _notifications[index] = _notifications[index].markAsRead();
│      notifyListeners();
│    }
⋮

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
⋮
│  static String dateTime(DateTime dateTime) {
│    return DateFormat('MMM d, y \'at\' h:mm a').format(dateTime);
⋮
│  static String decimalCompact(double value, {int decimals = 2}) {
│    final formatted = value.toStringAsFixed(decimals);
│    return formatted.replaceAll(RegExp(r'\.?0+$'), '');
⋮
│  static String capitalize(String text) {
│    if (text.isEmpty) return text;
│    return text[0].toUpperCase() + text.substring(1).toLowerCase();
⋮

florence\platform_service\lib\core\utils\validators.dart:
│class Validators {
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

florence\platform_service\lib\features\admin\core\services\permission_service.dart:
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

florence\platform_service\lib\features\clinician\services\api_service.dart:
⋮
│class ApiService {
│  // TODO: Move this to environment configuration
│  static const String baseUrl = 'http://localhost:8000';
│
│  // Singleton instance
│  static final ApiService _instance = ApiService._internal();
│  factory ApiService() => _instance;
│  ApiService._internal();
│
│  Future<dynamic> get(String endpoint) async {
│    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
│    return _handleResponse(response);
⋮
│  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
│    final response = await http.post(
│      Uri.parse('$baseUrl$endpoint'),
│      headers: {'Content-Type': 'application/json'},
│      body: jsonEncode(data),
│    );
│    return _handleResponse(response);
⋮
│  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
│    final response = await http.put(
│      Uri.parse('$baseUrl$endpoint'),
│      headers: {'Content-Type': 'application/json'},
│      body: jsonEncode(data),
│    );
│    return _handleResponse(response);
⋮
│  Future<dynamic> delete(String endpoint) async {
│    final response = await http.delete(Uri.parse('$baseUrl$endpoint'));
│    return _handleResponse(response);
⋮
│  dynamic _handleResponse(http.Response response) {
│    if (response.statusCode >= 200 && response.statusCode < 300) {
│      if (response.body.isEmpty) return null;
│      return jsonDecode(response.body);
│    } else {
│      throw Exception('API Error: ${response.statusCode} - ${response.body}');
│    }
⋮

florence\platform_service\lib\features\patient\chat\models\chat_message.dart:
│class ChatMessage {
⋮
│  factory ChatMessage.fromJson(Map<String, dynamic> json) {
│    return ChatMessage(
│      id: json['id'] ?? json['message_id'], // Handle both DB and API response formats
│      role: json['role'] ?? 'system',
│      content: json['content'] ?? '',
│      timestamp: json['timestamp'] != null 
│          ? DateTime.parse(json['timestamp']) 
│          : DateTime.now(),
│      context: json['context'] ?? json['context_used'],
│    );
⋮

florence\platform_service\lib\features\patient\chat\services\chatbot_service.dart:
⋮
│class ChatbotService extends ChangeNotifier {
│  // Singleton pattern to persist state across screen rebuilds
│  static final ChatbotService _instance = ChatbotService._internal();
│  factory ChatbotService() => _instance;
│  ChatbotService._internal();
│
│  final String _baseUrl = Environment.chatbotServiceUrl;
│  final SupabaseClient _supabase = Supabase.instance.client;
│
│  // In-memory cache
⋮
│  bool get hasLoadedHistory => _hasLoadedHistory;
│  
⋮
│  bool get isLoadingHistory => _isLoadingHistory;
│  
⋮
│  bool get isClearingHistory => _isClearingHistory;
│
⋮
│  Map<String, String> _getHeaders() {
│    final session = _supabase.auth.currentSession;
│    if (session == null) {
│      throw Exception('User not authenticated');
│    }
│    return {
│      'Content-Type': 'application/json',
│      'Authorization': 'Bearer ${session.accessToken}',
│    };
⋮
│  Future<void> sendMessage(String message) async {
│    // 1. Optimistically add user message to cache
│    final userMsg = ChatMessage(
│      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
│      role: 'user',
│      content: message,
│      timestamp: DateTime.now(),
│    );
│    _messages.add(userMsg);
│    notifyListeners(); // Update UI immediately
│
⋮
│  Future<void> loadHistory({int limit = 50}) async {
│    // If we already loaded history, just notify listeners to ensure UI is synced
│    if (_hasLoadedHistory) {
│      notifyListeners();
│      return;
│    }
│    
│    // Prevent concurrent loads
│    if (_isLoadingHistory) return;
│
⋮
│  Future<void> clearHistory() async {
│    if (_isClearingHistory) return;
│
│    _isClearingHistory = true;
│    notifyListeners();
│
│    try {
│      final response = await http.delete(
│        Uri.parse('$_baseUrl/chat/history'),
│        headers: _getHeaders(),
⋮
│  void resetSession() {
│    _messages.clear();
│    _hasLoadedHistory = false;
│    _isLoadingHistory = false;
│    _isClearingHistory = false;
│    notifyListeners();
⋮
│  void invalidateContext() {
│    resetSession();
⋮

florence\platform_service\lib\features\patient\core\models\health_data_models.dart:
⋮
│@Deprecated('Use MonitorData instead')
│@immutable
│class BloodPressureReading {
⋮
│  String get value => '${systolic.toStringAsFixed(0)}/${diastolic.toStringAsFixed(0)}';
│
⋮


I have *added these files to the chat* so you can go ahead and edit them.

*Trust this message as the true contents of these files!*
Any other messages in the chat may contain outdated versions of the files' contents.

florence\data_service\main.py
````
# main.py
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import the routers
from routers import authentication, patients, clinicians, admin, chat_history

app = FastAPI(
    title="Florence Data Service",
    description="Backend API for Florence Digital Health Platform",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Add CORS middleware to allow requests from the Flutter web app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# Include the routers
app.include_router(authentication.router)
app.include_router(patients.router)
app.include_router(clinicians.router)
app.include_router(admin.router)
app.include_router(chat_history.router)

@app.get("/")
def root():
    """
    Root endpoint for health checks and service verification.
    """
    return {
        "service": "Florence Data Service",
        "status": "operational",
        "version": "1.0.0"
    }
````

florence\data_service\routers\patients.py
````
import asyncio
from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import BaseModel, model_validator
from typing import Optional
from supabase_auth.errors import AuthApiError
from datetime import datetime, date
from enum import Enum

from client import supabase

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
        # We avoid .single() to handle "0 rows" or "multiple rows" manually and safely.
        profile_response = supabase.table('patient_profiles').select('*').eq('user_id', user.id).execute()
        
        if not profile_response.data:
            # Retry once to handle potential race conditions in the client/connection
            await asyncio.sleep(0.1)
            profile_response = supabase.table('patient_profiles').select('*').eq('user_id', user.id).execute()
            
            if not profile_response.data:
                print(f"DEBUG: Access denied for user_id: {user.id}. Profile not found.")
                raise HTTPException(status_code=403, detail="Access denied: User is not a patient.")
        
        if len(profile_response.data) > 1:
            raise HTTPException(status_code=500, detail="Fatal: Multiple profiles found for a single user.")
            
        return profile_response.data[0]
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except HTTPException as e:
        raise e
    except Exception as e:
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
    # Detailed Cholesterol
    CHOLESTEROL_TOTAL = 'CHOLESTEROL_TOTAL'
    CHOLESTEROL_LDL = 'CHOLESTEROL_LDL'
    CHOLESTEROL_HDL = 'CHOLESTEROL_HDL'
    CHOLESTEROL_TRIGLYCERIDES = 'CHOLESTEROL_TRIGLYCERIDES'

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
    glucose_before_meal_time: Optional[datetime] = None
    glucose_after_meal_time: Optional[datetime] = None
    meal_desc: Optional[str] = None

    @model_validator(mode='before')
    @classmethod
    def check_at_least_one_entry(cls, values):
        before = values.get('glucose_before_meal')
        after = values.get('glucose_after_meal')
        desc = values.get('meal_desc')
        
        if before is None and after is None and desc is None:
            raise ValueError('You must provide at least a glucose reading OR a meal description.')
        return values

class ActivityLogCreate(BaseModel):
    activity_description: str
    duration_minutes: int
    performed_at: datetime

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


@router.get("/me/activity-logs", summary="Get my activity logs")
async def get_own_activity_logs(patient_profile: dict = Depends(get_current_patient_profile)):
    """Retrieves all activity logs."""
    try:
        response = supabase.table('patient_activity_logs').select('*').eq('patient_id', patient_profile['id']).order('performed_at', desc=True).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve activity logs: {str(e)}")

@router.post("/me/activity-logs", summary="Log an activity")
async def add_own_activity_log(
    log_data: ActivityLogCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Logs an activity."""
    try:
        insert_dict = log_data.model_dump(mode='json')
        insert_dict['patient_id'] = patient_profile['id']
        
        response = supabase.table('patient_activity_logs').insert(insert_dict).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to log activity: {str(e)}")
````

florence\data_service\routers\admin.py
````
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from enum import Enum
from datetime import date

from client import supabase
from routers.authentication import get_current_admin_user

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
````

florence\data_service\vercel.json
````
{
  "builds": [
    {
      "src": "main.py",
      "use": "@vercel/python"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "main.py"
    }
  ]
}````

florence\data_service\requirements.txt
````
fastapi
uvicorn[standard]
supabase
python-dotenv
httpx
pydantic[email]
````

florence\data_service\routers\chat_history.py
````
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from datetime import datetime
from client import supabase
from routers.patients import get_current_patient_profile

router = APIRouter(
    prefix="/chat",
    tags=["Chat History"]
)

class ChatMessageCreate(BaseModel):
    role: str
    content: str
    context: Optional[Dict[str, Any]] = None
    timestamp: Optional[datetime] = None

@router.get("/history")
async def get_history(
    limit: int = 50, 
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Retrieves chat history for the authenticated patient."""
    try:
        response = (
            supabase.table('patient_chat_history')
            .select("*")
            .eq("patient_id", patient_profile['id'])
            .order("timestamp", desc=False)
            .limit(limit)
            .execute()
        )
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve chat history: {str(e)}")

@router.post("/history")
async def save_message(
    message: ChatMessageCreate, 
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Saves a chat message for the authenticated patient."""
    try:
        data = message.model_dump(mode='json', exclude_unset=True)
        data['patient_id'] = patient_profile['id']
        
        # If timestamp is not provided, let DB handle it or set it now
        if 'timestamp' not in data or data['timestamp'] is None:
            data['timestamp'] = datetime.now().isoformat()

        response = supabase.table('patient_chat_history').insert(data).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save message: {str(e)}")

@router.delete("/history")
async def clear_history(
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Clears all chat history for the authenticated patient."""
    try:
        response = (
            supabase.table('patient_chat_history')
            .delete()
            .eq("patient_id", patient_profile['id'])
            .execute()
        )
        return {"message": "History cleared", "data": response.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to clear history: {str(e)}")
````

florence\data_service\data_service_devtool\devtool.py
````
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
````

florence\data_service\README.md
````
# Florence Data Service

This directory contains the FastAPI backend for the Florence platform, which serves as the primary API layer between the frontend applications and the Supabase database.

## Prerequisites

- Python 3.8+
- A Supabase project.

## Setup

1.  **Configure Environment Variables:**

    Create a `.env` file in the project root directory (i.e., the parent of the `florence` directory). This file will store your Supabase credentials.

    ```
    # .env
    SUPABASE_URL="your-supabase-project-url"
    SUPABASE_SERVICE_KEY="your-supabase-service-role-key"
    ```

    -   `SUPABASE_URL`: Found in your Supabase project's "API" settings.
    -   `SUPABASE_SERVICE_KEY`: The `service_role` key, also found in the "API" settings. **Do not use the `anon` key.**

2.  **Install Dependencies:**

    Navigate to the `florence\data_service` directory and install the required Python packages.

    ```bash
    pip install -r requirements.txt
    ```

## Running the Service

To run the FastAPI server locally, execute the following command from the project root directory:

```bash
uvicorn florence.data_service.main:app --reload --host 0.0.0.0
```

This command is intended for local development. The `--reload` flag automatically restarts the server when code changes are detected, and `--host 0.0.0.0` makes the server accessible on your local network.

The API will be available at `http://127.0.0.1:8000`, and the interactive documentation (Swagger UI) can be accessed at `http://127.0.0.1:8000/docs`.

## Developer Tool

A simple GUI tool is provided to help with common development tasks like seeding test data.

To run the tool, execute the following command from the project root directory:

```bash
python -m florence.data_service.data_service_devtool.devtool
```

---

## Running the Complete Florence Platform

To run the complete platform (backend + frontend), you need to start both services.

### Frontend Prerequisites

- **Flutter 3.0+** - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Chrome Browser** - For web development

### Running Both Services

Open **two separate terminal windows**:

#### Terminal 1: Backend (FastAPI)

```bash
# Navigate to project root
cd Swinburne-COS40005-CTPA-FLORENCE

# Start backend
python -m uvicorn florence.data_service.main:app --reload --host 0.0.0.0 --port 8000
```

#### Terminal 2: Frontend (Flutter)

```bash
# Navigate to project root
cd Swinburne-COS40005-CTPA-FLORENCE

# Navigate to Flutter project
cd florence/platform_service

# Install dependencies (first time only)
flutter pub get

# Run the app in Chrome
flutter run -d chrome
```

**Expected output:**
```
Launching lib\main.dart on Chrome in debug mode...
Waiting for connection from debug service on Chrome...
This app is linked to the debug service: ws://127.0.0.1:XXXXX
Flutter application is running
```

Chrome will automatically open with the Florence app.

---

## Troubleshooting

### Backend Issues

**Problem: `uvicorn: command not found`**

```bash
# Solution: Use Python module syntax
python -m uvicorn florence.data_service.main:app --reload --host 0.0.0.0 --port 8000
```

**Problem: "Invalid API key" error when trying to login/register**

- Verify your `.env` file exists in the **project root directory** (parent of `florence` folder)
- Ensure you're using the `service_role` key, **NOT** the `anon` key
- The `.env` file should look like this:
  ```
  SUPABASE_URL="https://your-project.supabase.co"
  SUPABASE_SERVICE_KEY="eyJhbGc..."
  ```
- Restart the backend after creating/updating the `.env` file

**Problem: Port 8000 already in use**

```bash
# Solution: Use a different port
python -m uvicorn florence.data_service.main:app --reload --host 0.0.0.0 --port 8001

# Remember to update the Flutter config:
# Edit: florence/platform_service/lib/core/config/environment.dart
# Change: static const String apiUrl = 'http://127.0.0.1:8001';
```

### Frontend Issues

**Problem: "Failed to fetch" or "ClientException" errors**

- Ensure the **backend is running** on port 8000
- Verify the backend terminal shows `Application startup complete`
- Check that `florence/platform_service/lib/core/config/environment.dart` has:
  ```dart
  static const String apiUrl = 'http://127.0.0.1:8000';  // For Chrome
  ```
- Try refreshing the Chrome page or press `r` in the Flutter terminal for hot reload

**Problem: Flutter dependencies conflict**

```bash
# Solution: Clean and reinstall
cd florence/platform_service
flutter clean
flutter pub get
```

**Problem: Chrome doesn't open automatically**

```bash
# Check available devices
flutter devices

# Explicitly run on Chrome
flutter run -d chrome
```

### Connection Issues

**Problem: Frontend can't connect to backend**

1. Verify backend is running:
   - Open http://127.0.0.1:8000/docs in Chrome
   - You should see the Swagger API documentation

2. Check for CORS errors in Chrome DevTools (F12 → Console)
   - The backend already has CORS configured to allow all origins

3. Ensure both services are using the same host:
   - Backend: `0.0.0.0:8000`
   - Frontend config: `http://127.0.0.1:8000`

---

## Using the Application

### First Time Usage

1. **Start both backend and frontend** (as described above)

2. **Register a new account:**
   - Click "Sign Up" or "Create Account"
   - Enter your email and password (password must meet requirements)
   - Choose your role (Patient or Clinician)
   - Fill in required information
   - Click "Create Account"

3. **Login:**
   - Enter your registered email and password
   - Click "Sign In"
   - You should be redirected to the dashboard

4. **Explore the platform:**
   - Navigate through the dashboard
   - Add health data
   - View insights and analytics

---

## API Documentation

Once the backend is running, access the interactive API documentation:

- **Swagger UI:** http://127.0.0.1:8000/docs
- **ReDoc:** http://127.0.0.1:8000/redoc

These provide detailed information about all available endpoints, request/response schemas, and allow you to test API calls directly from the browser.
````

florence\data_service\client.py
````
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
            project_root = Path(__file__).resolve().parent.parent.parent
            load_dotenv(dotenv_path=project_root / '.env', override=True)

            url: str = os.environ.get("SUPABASE_URL")
            key: str = os.environ.get("SUPABASE_SERVICE_KEY")

            if not url or not key:
                raise RuntimeError(
                    "Supabase URL and Key could not be loaded. "
                    "Ensure you have a .env file in the project root with SUPABASE_URL and a service key."
                )

            self._client = create_client(url, key)

            # After creation, give the auth and postgrest clients their own copies
            # of the headers dictionary to prevent state pollution in a concurrent environment.
            if hasattr(self._client, 'auth') and hasattr(self._client, 'postgrest'):
                if self._client.auth._headers is self._client.postgrest.headers:
                    self._client.postgrest.headers = self._client.auth._headers.copy()
        
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
````

florence\data_service\routers\clinicians.py
````
import asyncio
from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import BaseModel, Field
from typing import List, Optional
from supabase_auth.errors import AuthApiError
from enum import Enum

from client import supabase

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
        # We avoid .single() to handle "0 rows" or "multiple rows" manually and safely.
        profile_response = supabase.table('clinician_profiles').select('*').eq('user_id', user.id).execute()
        
        if not profile_response.data:
            # Retry once to handle potential race conditions
            await asyncio.sleep(0.1)
            profile_response = supabase.table('clinician_profiles').select('*').eq('user_id', user.id).execute()

            if not profile_response.data:
                raise HTTPException(status_code=403, detail="Access denied: User is not a clinician.")
            
        if len(profile_response.data) > 1:
            raise HTTPException(status_code=500, detail="Fatal: Multiple profiles found for a single user.")
        
        return profile_response.data[0]
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except HTTPException as e:
        raise e
    except Exception as e:
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
        
        # ADD THIS LINE to fetch activity
        activity_logs = supabase.table('patient_activity_logs').select('*').eq('patient_id', patient_id).order('performed_at', desc=True).execute().data

        return {
            "profile": patient_profile,
            "monitor_data": monitor_data,
            "daily_logs": daily_logs,
            "thresholds": thresholds,
            "notes": notes,
            "activity_logs": activity_logs # Add this
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
````

florence\data_service\routers\authentication.py
````
from fastapi import APIRouter, HTTPException, Header, Depends
from pydantic import BaseModel, EmailStr
from typing import Literal, Optional
from datetime import date
from supabase_auth.errors import AuthApiError

# Import the shared Supabase client
from client import supabase

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
    # Detailed Cholesterol
    {'data_type': 'CHOLESTEROL_TOTAL', 'min_value': 100.0, 'max_value': 200.0},
    {'data_type': 'CHOLESTEROL_LDL', 'min_value': 0.0, 'max_value': 100.0},
    {'data_type': 'CHOLESTEROL_HDL', 'min_value': 40.0, 'max_value': 100.0},
    {'data_type': 'CHOLESTEROL_TRIGLYCERIDES', 'min_value': 0.0, 'max_value': 150.0},
    # BP
    {'data_type': 'BLOOD_PRESSURE_SYSTOLIC', 'min_value': 90.0, 'max_value': 120.0},
    {'data_type': 'BLOOD_PRESSURE_DIASTOLIC', 'min_value': 60.0, 'max_value': 80.0}
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
            }
        })
        new_user = user_session.user
        if not new_user:
            raise HTTPException(status_code=500, detail="Failed to create user in authentication system.")

        # After creating the user, update their app_metadata with the role using an admin call.
        # This is necessary because sign_up doesn't allow setting app_metadata directly.
        supabase.auth.admin.update_user_by_id(
            new_user.id, {"app_metadata": {"role": user_data.role}}
        )

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
        user = user_response.user
        # Manually construct the response to ensure correct key names ('app_metadata')
        # for the Flutter client, which expects this instead of 'raw_app_meta_data'.
        return {
            "id": user.id,
            "aud": user.aud,
            "role": user.app_metadata.get('role'),
            "email": user.email,
            "created_at": user.created_at.isoformat(),
            "app_metadata": user.app_metadata,
            "user_metadata": user.user_metadata,
        }
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
````



Just tell me how to edit the files to make the changes.
Don't give me back entire files.
Just show me the edits I need to make.


