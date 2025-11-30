Here are summaries of some files present in my git repository.
Do not propose changes to these files, treat them as *read-only*.
If you need to edit any of these files, ask me to *add them to the chat* first.

florence\data_service\routers\patients.py:
⋮
│class MonitorDataType(str, Enum):
⋮

florence\llm_chatbot_service\models\chat.py:
⋮
│class ChatMessage(BaseModel):
⋮
│class DeepSeekChoice(BaseModel):
⋮
│class DeepSeekUsage(BaseModel):
⋮

florence\llm_chatbot_service\models\health.py:
⋮
│class MonitorData(BaseModel):
⋮
│class ActivityLog(BaseModel):
⋮

florence\platform_service\lib\config\admin_theme.dart:
⋮
│class AdminTheme {
│  // ============================================
│  // PRIMARY COLORS - Professional & Authoritative
│  // ============================================
│
│  static const Color primaryIndigo = Color(0xFF3F51B5); // Deep Blue/Indigo
│  static const Color primaryDark = Color(0xFF303F9F);
│  static const Color primaryLight = Color(0xFF7986CB);
│  static const Color accentTeal = Color(0xFF009688);
│
⋮
│  static Color getRoleColor(String role) {
│    switch (role.toLowerCase()) {
│      case 'super admin':
│      case 'superadmin':
│        return superAdminColor;
│      case 'hospital admin':
│      case 'hospitaladmin':
│        return hospitalAdminColor;
│      case 'doctor':
│      case 'physician':
⋮
│  static Color getOrgStatusColor(String status) {
│    switch (status.toLowerCase()) {
│      case 'active':
│        return orgActiveColor;
│      case 'inactive':
│        return orgInactiveColor;
│      case 'suspended':
│        return orgSuspendedColor;
│      default:
│        return textSecondaryColor;
⋮
│  static Color getStatusColor(String status) {
│    switch (status.toLowerCase()) {
│      case 'success':
│      case 'active':
│      case 'completed':
│      case 'approved':
│        return successColor;
│      case 'warning':
│      case 'pending':
│      case 'in progress':
⋮
│  static Color getChartColor(int index) {
│    final colors = [
│      chartBlue,
│      chartGreen,
│      chartYellow,
│      chartRed,
│      chartPurple,
│      chartOrange,
│    ];
│    return colors[index % colors.length];
⋮
│  static Widget getRoleBadge(String role) {
│    return Container(
│      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
│      decoration: BoxDecoration(
│        color: getRoleColor(role).withValues(alpha: 0.1),
│        borderRadius: BorderRadius.circular(4),
│        border: Border.all(
│          color: getRoleColor(role).withValues(alpha: 0.3),
│          width: 1,
│        ),
⋮
│  static Widget getStatusBadge(String status) {
│    return Container(
│      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
│      decoration: BoxDecoration(
│        color: getStatusColor(status).withValues(alpha: 0.1),
│        borderRadius: BorderRadius.circular(4),
│        border: Border.all(
│          color: getStatusColor(status).withValues(alpha: 0.3),
│          width: 1,
│        ),
⋮

florence\platform_service\lib\config\routes.dart:
⋮
│class AppRoutes {
│  // Route names
│  static const String splash = '/';
│  static const String login = '/login';
│  static const String register = '/register';
│  static const String onboarding = '/onboarding';
│
│  // Main app routes
│  static const String dashboard = '/dashboard';
│  static const String trends = '/trends';
⋮

florence\platform_service\lib\config\theme.dart:
⋮
│class AppTheme {
│  // ============================================
│  // COLOR PALETTE
│  // ============================================
│
│  // Primary Colors
│  static const Color primaryBlue = Color(0xFF2563EB);
│  static const Color primaryGreen = Color(0xFF10B981);
│  static const Color primaryRed = Color(0xFFEF4444);
│
⋮
│  static Color getBorderColor(BuildContext context) {
│    return Theme.of(context).brightness == Brightness.dark
│        ? midnightBorder
│        : borderColor;
⋮
│  static Color getGlucoseColor(double value, double min, double max) {
│    if (value < min) return glucoseLow;
│    if (value > max) return glucoseHigh;
│    return glucoseNormal;
⋮
│  static Color getStatusColor(String status) {
│    switch (status.toLowerCase()) {
│      case 'success':
│        return successColor;
│      case 'warning':
│        return warningColor;
│      case 'error':
│      case 'danger':
│        return errorColor;
│      case 'info':
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
⋮

florence\platform_service\lib\core\services\notifications\notification_models.dart:
⋮
│@immutable
│class HealthNotification {
⋮
│  HealthNotification copyWith({
│    String? id,
│    NotificationType? type,
│    NotificationPriority? priority,
│    String? title,
│    String? message,
│    DateTime? createdAt,
│    bool? isRead,
│    DateTime? readAt,
│    String? actionUrl,
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
⋮
│  static AdminRole fromString(String role) {
│    switch (role.toLowerCase().replaceAll(' ', '')) {
│      case 'admin':
│      case 'superadmin':
│        return AdminRole.superAdmin;
│      case 'hospitaladmin':
│        return AdminRole.hospitalAdmin;
│      case 'doctor':
│      case 'physician':
│        return AdminRole.doctor;
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
│  /// Check if organization is active
│  bool get isActive => this == OrganizationStatus.active;
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
│  bool get isActive => this == UserStatus.active;
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
│  bool get isActive => this == PatientStatus.active;
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
│  bool hasPermission(AdminPermission permission) {
│    return permissions.contains(permission);
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

florence\platform_service\lib\features\clinician\models\health_data.dart:
│class GlucoseReading {
⋮
│class BloodPressureReading {
│  final DateTime timestamp;
│  final double systolic;
│  final double diastolic;
│  
│  BloodPressureReading({
│    required this.timestamp,
│    required this.systolic,
│    required this.diastolic,
│  });
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
⋮

florence\platform_service\lib\features\clinician\theme\app_theme.dart:
⋮
│class AppTheme {
│  // Patient dashboard color palette
│  static const Color primaryColor = Color(0xFF2F70F8); // Primary blue from patient dashboard
│  static const Color secondaryColor = Color(0xFF1A73E8); // Secondary blue
│  static const Color accentColor = Color(0xFFF59E0B); // Amber/Orange
│  
│  static const Color highRiskColor = Color(0xFFF44336); // Red
│  static const Color mediumRiskColor = Color(0xFFFFC107); // Yellow/Amber
│  static const Color lowRiskColor = Color(0xFF4CAF50); // Green
│  static const Color automatedActionColor = Color(0xFF9C27B0); // Purple for automated actions
│  
⋮
│  static Color getRiskColor(String riskLevel) {
│    switch (riskLevel.toLowerCase()) {
│      case 'high':
│        return highRiskColor;
│      case 'medium':
│        return mediumRiskColor;
│      case 'low':
│        return lowRiskColor;
│      default:
│        return Colors.grey;
⋮

florence\platform_service\lib\shared\widgets\card_widgets.dart:
⋮
│class BaseCard extends StatelessWidget {
│  final Widget child;
│  final EdgeInsetsGeometry? padding;
│  final EdgeInsetsGeometry? margin;
│  final Color? color;
│  final double? elevation;
│  final VoidCallback? onTap;
│  final BorderRadius? borderRadius;
│  
│  const BaseCard({
⋮

florence\platform_service\tools\patient_generator.dart:
⋮
│class GlucoseReading {
│  final DateTime timestamp;
│  final double value;
│  final String context;
│
│  GlucoseReading({
│    required this.timestamp,
│    required this.value,
│    required this.context,
│  });
⋮


I have *added these files to the chat* so you can go ahead and edit them.

*Trust this message as the true contents of these files!*
Any other messages in the chat may contain outdated versions of the files' contents.

florence\platform_service\lib\features\patient\trends\screens\pattern_detail_screen.dart
```
/// Pattern Detail Screen for FLORENCE Digital Health Platform
/// Shows detailed information about a detected health pattern

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/services/automation/pattern_detection_service.dart';
import '../../core/services/data_ingestion_service.dart';
import '../../core/models/health_data_models.dart';
import '../../../../core/utils/formatters.dart';

/// Detail screen for a specific detected pattern
class PatternDetailScreen extends StatefulWidget {
  final DetectedPattern pattern;

  const PatternDetailScreen({
    super.key,
    required this.pattern,
  });

  @override
  State<PatternDetailScreen> createState() => _PatternDetailScreenState();
}

class _PatternDetailScreenState extends State<PatternDetailScreen> {
  final DataIngestionService _dataService = DataIngestionService();
  List<GlucoseReading> _relatedReadings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatternData();
  }

  Future<void> _loadPatternData() async {
    setState(() => _isLoading = true);

    try {
      // Get glucose readings related to this pattern
      final allReadings = _dataService.allGlucoseReadings;
      _relatedReadings = allReadings
          .where((r) => widget.pattern.dataPointIds.contains(r.id))
          .toList();

      // Sort by timestamp
      _relatedReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      debugPrint('Error loading pattern data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pattern.typeLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share pattern details
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pattern Overview Card
                  _buildOverviewCard(),
                  const SizedBox(height: 16),

                  // Data Timeline
                  _buildSectionHeader('Data Timeline'),
                  const SizedBox(height: 12),
                  _buildTimelineCard(),
                  const SizedBox(height: 16),

                  // Mini Chart
                  _buildSectionHeader('Glucose Trend'),
                  const SizedBox(height: 12),
                  _buildChartCard(),
                  const SizedBox(height: 16),

                  // AI Explanation
                  _buildSectionHeader('AI Analysis'),
                  const SizedBox(height: 12),
                  _buildAIExplanationCard(),
                  const SizedBox(height: 16),

                  // Action Steps
                  _buildSectionHeader('Recommended Actions'),
                  const SizedBox(height: 12),
                  _buildActionStepsCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Build pattern overview card
  Widget _buildOverviewCard() {
    final severityConfig = _getPatternSeverityConfig(widget.pattern.severity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: severityConfig['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: severityConfig['color'],
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        severityConfig['icon'],
                        color: severityConfig['color'],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        severityConfig['label'],
                        style: TextStyle(
                          color: severityConfig['color'],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Detected ${_formatPatternTime(widget.pattern.detectedAt)}',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              widget.pattern.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Metadata
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildMetadataItem(
                  Icons.data_usage,
                  '${_relatedReadings.length} readings',
                ),
                _buildMetadataItem(
                  Icons.date_range,
                  _getDateRange(),
                ),
                if (widget.pattern.requiresAction)
                  _buildMetadataItem(
                    Icons.warning_amber,
                    'Action Required',
                    color: AppTheme.warningColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build timeline card
  Widget _buildTimelineCard() {
    if (_relatedReadings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No data points available',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _relatedReadings.map((reading) {
            return _buildTimelineItem(reading);
          }).toList(),
        ),
      ),
    );
  }

  /// Build timeline item
  Widget _buildTimelineItem(GlucoseReading reading) {
    final isNormal = reading.isNormal;
    final color = isNormal
        ? AppTheme.primaryGreen
        : reading.value > 180
            ? AppTheme.errorColor
            : AppTheme.warningColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Time indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),

          // Time
          SizedBox(
            width: 80,
            child: Text(
              DateFormat('h:mm a').format(reading.timestamp),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),

          // Glucose value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              '${reading.value.toStringAsFixed(0)} mg/dL',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Context
          Expanded(
            child: Text(
              reading.context,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build chart card
  Widget _buildChartCard() {
    if (_relatedReadings.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No chart data available',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => const SizedBox.shrink(),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < _relatedReadings.length) {
                        final reading = _relatedReadings[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('HH:mm').format(reading.timestamp),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (_relatedReadings.length - 1).toDouble(),
              minY: 70,
              maxY: 250,
              lineBarsData: [
                LineChartBarData(
                  spots: _relatedReadings.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value.value,
                    );
                  }).toList(),
                  isCurved: true,
                  color: AppTheme.primaryBlue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final reading = _relatedReadings[index];
                      final color = reading.isNormal
                          ? AppTheme.primaryGreen
                          : reading.value > 180
                              ? AppTheme.errorColor
                              : AppTheme.warningColor;

                      return FlDotCirclePainter(
                        radius: 4,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build AI explanation card
  Widget _buildAIExplanationCard() {
    return Card(
      color: AppTheme.primaryBlue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI-Powered Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pattern-specific explanation
            Text(
              _getAIExplanation(),
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build action steps card
  Widget _buildActionStepsCard() {
    final actions = _getRecommendedActions();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...actions.asMap().entries.map((entry) {
              return _buildActionStep(entry.key + 1, entry.value);
            }),
          ],
        ),
      ),
    );
  }

  /// Build single action step
  Widget _buildActionStep(int number, Map<String, dynamic> action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Action content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      action['icon'],
                      size: 20,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action['title'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  action['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build metadata item
  Widget _buildMetadataItem(IconData icon, String text, {Color? color}) {
    final effectiveColor = color ?? AppTheme.textSecondaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: effectiveColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: effectiveColor,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  /// Get pattern severity configuration
  Map<String, dynamic> _getPatternSeverityConfig(PatternSeverity severity) {
    switch (severity) {
      case PatternSeverity.critical:
        return {
          'color': AppTheme.errorColor,
          'icon': Icons.error,
          'label': 'Critical',
        };
      case PatternSeverity.high:
        return {
          'color': AppTheme.warningColor,
          'icon': Icons.warning_amber,
          'label': 'High Priority',
        };
      case PatternSeverity.medium:
        return {
          'color': Colors.orange,
          'icon': Icons.info,
          'label': 'Medium Priority',
        };
      case PatternSeverity.low:
        return {
          'color': AppTheme.primaryBlue,
          'icon': Icons.info_outline,
          'label': 'Low Priority',
        };
    }
  }

  /// Get date range string
  String _getDateRange() {
    if (_relatedReadings.isEmpty) return 'No data';
    if (_relatedReadings.length == 1) {
      return DateFormat('MMM d, h:mm a').format(_relatedReadings.first.timestamp);
    }

    final first = _relatedReadings.first.timestamp;
    final last = _relatedReadings.last.timestamp;

    if (first.day == last.day) {
      return '${DateFormat('MMM d').format(first)}, ${DateFormat('h:mm a').format(first)} - ${DateFormat('h:mm a').format(last)}';
    } else {
      return '${DateFormat('MMM d').format(first)} - ${DateFormat('MMM d').format(last)}';
    }
  }

  /// Format pattern detection time
  String _formatPatternTime(DateTime time) {
    return Formatters.timeAgo(time);
  }

  /// Get AI explanation based on pattern type
  String _getAIExplanation() {
    switch (widget.pattern.type) {
      case PatternType.glucoseSpike:
        return 'Our AI detected a rapid increase in your glucose levels. This spike pattern typically occurs after consuming high-carb meals or during periods of stress. Understanding the timing and triggers of these spikes can help you make better dietary choices.';

      case PatternType.glucoseDrop:
        return 'A concerning drop in glucose levels was identified by our AI. This pattern may indicate excessive insulin, inadequate food intake, or increased physical activity. It\'s important to monitor for symptoms of hypoglycemia and take preventive action.';

      case PatternType.postMealSpike:
        return 'Your glucose levels show elevated post-meal readings. Our AI analysis suggests this is related to meal composition and timing. Managing carbohydrate intake and meal spacing can help reduce these spikes.';

      case PatternType.consecutiveHigh:
        return 'Our AI detected multiple consecutive high readings, indicating sustained hyperglycemia. This pattern suggests the need to review your medication regimen, dietary habits, and physical activity level with your healthcare provider.';

      case PatternType.highVariability:
        return 'Your glucose levels show significant fluctuations throughout the day. Our AI identifies this as high variability, which can be more harmful than consistently elevated levels. Focus on regular meal timing, consistent carb portions, and stress management.';

      case PatternType.lowActivity:
        return 'Based on your activity data, our AI noticed decreased physical movement correlating with this glucose pattern. Regular physical activity is crucial for glucose management. Even small increases in daily movement can make a significant difference.';

      case PatternType.missedMedication:
        return 'Our AI detected potential medication non-adherence based on glucose patterns and logged medication data. Consistent medication timing is essential for stable glucose control. Consider setting reminders or using a pill organizer.';

      default:
        return 'Our AI has analyzed your glucose data and identified this pattern as noteworthy. Understanding your unique patterns helps you make informed decisions about your diabetes management.';
    }
  }

  /// Get recommended actions based on pattern
  List<Map<String, dynamic>> _getRecommendedActions() {
    switch (widget.pattern.type) {
      case PatternType.glucoseSpike:
        return [
          {
            'icon': Icons.restaurant,
            'title': 'Review Recent Meals',
            'description':
                'Identify high-carb foods that triggered the spike and consider portion control or healthier alternatives.',
          },
          {
            'icon': Icons.directions_walk,
            'title': 'Take a Short Walk',
            'description':
                'A 10-15 minute walk after meals can help lower blood glucose levels naturally.',
          },
          {
            'icon': Icons.water_drop,
            'title': 'Stay Hydrated',
            'description':
                'Drink plenty of water to help your body flush out excess glucose.',
          },
        ];

      case PatternType.glucoseDrop:
        return [
          {
            'icon': Icons.fastfood,
            'title': 'Have a Fast-Acting Carb',
            'description':
                'If feeling symptoms, consume 15g of fast-acting carbs like glucose tablets or juice.',
          },
          {
            'icon': Icons.access_time,
            'title': 'Check Meal Timing',
            'description':
                'Ensure you\'re eating regular meals and snacks to prevent drops between meals.',
          },
          {
            'icon': Icons.medical_services,
            'title': 'Review Medication',
            'description':
                'Discuss with your doctor if you experience frequent lows - medication adjustment may be needed.',
          },
        ];

      case PatternType.consecutiveHigh:
        return [
          {
            'icon': Icons.phone_in_talk,
            'title': 'Contact Healthcare Provider',
            'description':
                'Sustained high readings require professional evaluation - schedule an appointment soon.',
          },
          {
            'icon': Icons.local_drink,
            'title': 'Increase Water Intake',
            'description':
                'Drink more water throughout the day to help manage elevated glucose levels.',
          },
          {
            'icon': Icons.fitness_center,
            'title': 'Increase Physical Activity',
            'description':
                'Add more movement to your day - even light activity can help lower glucose.',
          },
        ];

      case PatternType.lowActivity:
        return [
          {
            'icon': Icons.directions_walk,
            'title': 'Start Small',
            'description':
                'Begin with 10-minute walks after meals and gradually increase duration.',
          },
          {
            'icon': Icons.alarm,
            'title': 'Set Movement Reminders',
            'description':
                'Schedule regular breaks to stand and move throughout the day.',
          },
          {
            'icon': Icons.group,
            'title': 'Find an Activity Buddy',
            'description':
                'Exercise with a friend or family member for motivation and accountability.',
          },
        ];

      default:
        return [
          {
            'icon': Icons.monitor_heart,
            'title': 'Continue Monitoring',
            'description':
                'Keep tracking your glucose levels to identify additional patterns.',
          },
          {
            'icon': Icons.book,
            'title': 'Log Related Factors',
            'description':
                'Record meals, activities, and medications to understand pattern triggers.',
          },
          {
            'icon': Icons.support_agent,
            'title': 'Discuss with Care Team',
            'description':
                'Share this pattern information with your healthcare provider at your next visit.',
          },
        ];
    }
  }
}
```

florence\platform_service\lib\features\patient\dashboard\screens\activity_detail_screen.dart
```
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityLogsProvider);
    final monitorAsync = ref.watch(monitorDataProvider);

    // Data Color: Green (Movement as Medicine)
    final Color dataColor = AppTheme.primaryGreen;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Analytics'),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.getBorderColor(context),
            height: 1.0,
          ),
        ),
      ),
      body: activityAsync.when(
        data: (logs) {
          return monitorAsync.when(
            data: (monitorData) {
              // Sort logs: Newest first
              final sortedLogs = List<ActivityLog>.from(logs)
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

              // Filter glucose for impact analysis
              final glucoseReadings = monitorData
                  .where((d) => d.dataType == MonitorDataType.GLUCOSE)
                  .toList();

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    ref.refresh(activityLogsProvider.future),
                    ref.refresh(monitorDataProvider.future),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 1. Daily Volume
                      _DailyVolumeCard(
                        logs: sortedLogs, 
                        dataColor: dataColor
                      ),
                      const SizedBox(height: 20),

                      // 2. Streak Heatmap
                      _StreakHeatmap(
                        logs: sortedLogs,
                        dataColor: dataColor,
                      ),
                      const SizedBox(height: 20),

                      // 3. Weekly Consistency
                      _WeeklyConsistencyChart(
                        logs: sortedLogs, 
                        dataColor: dataColor
                      ),
                      const SizedBox(height: 20),

                      // 4. Activity Timing (Last 28 Days)
                      _ActivityTimingChart(
                        logs: sortedLogs, 
                        dataColor: dataColor
                      ),
                      const SizedBox(height: 20),

                      // 5. History List (Consistent Design)
                      _ActivityHistoryList(
                        logs: sortedLogs,
                        glucoseReadings: glucoseReadings,
                        dataColor: dataColor,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading health data: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading activity: $err')),
      ),
    );
  }
}

// ============================================================================
// STREAK HEATMAP (GitHub Style)
// ============================================================================

class _StreakHeatmap extends StatelessWidget {
  final List<ActivityLog> logs;
  final Color dataColor;

  const _StreakHeatmap({
    required this.logs,
    required this.dataColor,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Prepare Data: Map Date -> Total Minutes
    final Map<int, int> activityMap = {};
    
    // We want to show the last 28 days (4 weeks)
    final now = DateTime.now();

    for (var log in logs) {
      // CRITICAL FIX: Convert UTC timestamp to Local Device Time before grouping
      final localTime = log.timestamp.toLocal();
      
      // Normalize to midnight local time
      final dateKey = DateTime(localTime.year, localTime.month, localTime.day).millisecondsSinceEpoch;
      activityMap[dateKey] = (activityMap[dateKey] ?? 0) + log.duration;
    }

    // 2. Calculate Current Streak
    int currentStreak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);
    
    // Check today
    if ((activityMap[checkDate.millisecondsSinceEpoch] ?? 0) > 0) {
      currentStreak++;
    }
    
    // Check backwards
    while (true) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if ((activityMap[checkDate.millisecondsSinceEpoch] ?? 0) > 0) {
        currentStreak++;
      } else {
        break;
      }
    }

    return _ActivityCard(
      title: 'Activity Streak',
      icon: Icons.local_fire_department,
      infoText: 'Your consistency over the last 28 days.\n\n'
                'Current Streak: $currentStreak days\n\n'
                'Darker colors indicate longer duration.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$currentStreak',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: currentStreak > 0 ? const Color(0xFFF59E0B) : AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAY STREAK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondaryColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentStreak > 0 ? 'Keep it up!' : 'Start moving today!',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // The Heatmap Grid (7 Columns x 4 Rows)
          Column(
            children: [
              // Days of Week Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map((d) => Expanded(
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 28,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  // FIX: Align grid to Monday to match headers (M T W T F S S)
                  // 1. Find the Monday of the current week
                  // We strip time from 'now' to ensure clean day calculations
                  final today = DateTime(now.year, now.month, now.day);
                  final currentWeekday = today.weekday; // 1=Mon...7=Sun
                  final startOfCurrentWeek = today.subtract(Duration(days: currentWeekday - 1));
                  
                  // 2. Go back 3 weeks to get the Monday of the first row
                  final startDate = startOfCurrentWeek.subtract(const Duration(days: 21));
                  
                  // 3. Calculate specific date for this cell
                  final date = startDate.add(Duration(days: index));
                  
                  // 4. Handle Future Dates (Empty cells)
                  final isFuture = date.isAfter(today);

                  if (isFuture) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.3)),
                      ),
                    );
                  }

                  // Key matches the Local midnight format used in the loop above
                  final key = date.millisecondsSinceEpoch;
                  final minutes = activityMap[key] ?? 0;

                  Color cellColor;
                  if (minutes == 0) {
                    cellColor = AppTheme.textSecondaryColor.withOpacity(0.1);
                  } else if (minutes < 20) {
                    cellColor = dataColor.withOpacity(0.4);
                  } else if (minutes < 45) {
                    cellColor = dataColor.withOpacity(0.7);
                  } else {
                    cellColor = dataColor;
                  }

                  return Tooltip(
                    message: '${DateFormat('MMM d').format(date)}: ${minutes}m',
                    child: Container(
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
              const SizedBox(width: 4),
              _LegendBox(color: AppTheme.textSecondaryColor.withOpacity(0.1)),
              const SizedBox(width: 2),
              _LegendBox(color: dataColor.withOpacity(0.4)),
              const SizedBox(width: 2),
              _LegendBox(color: dataColor.withOpacity(0.7)),
              const SizedBox(width: 2),
              _LegendBox(color: dataColor),
              const SizedBox(width: 4),
              Text('More', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendBox extends StatelessWidget {
  final Color color;
  const _LegendBox({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ============================================================================
// 1. DAILY VOLUME (Big Number)
// ============================================================================

class _DailyVolumeCard extends StatelessWidget {
  final List<ActivityLog> logs;
  final Color dataColor;

  const _DailyVolumeCard({required this.logs, required this.dataColor});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayLogs = logs.where((log) => 
      log.timestamp.year == now.year && 
      log.timestamp.month == now.month && 
      log.timestamp.day == now.day
    ).toList();
    
    final totalMinutes = todayLogs.fold(0, (sum, log) => sum + log.duration);
    final sessionCount = todayLogs.length;

    // Use Grey if 0, otherwise Green
    final displayColor = totalMinutes > 0 ? dataColor : AppTheme.textSecondaryColor;

    return _ActivityCard(
      title: 'Today\'s Movement',
      icon: Icons.timer,
      infoText: 'Total duration of physical activity recorded today.\n\n'
                'Consistent daily movement helps regulate blood pressure and glucose levels.',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$totalMinutes',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: displayColor,
              fontSize: 64,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'minutes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'across $sessionCount sessions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. WEEKLY CONSISTENCY CHART
// ============================================================================

class _WeeklyConsistencyChart extends StatelessWidget {
  final List<ActivityLog> logs;
  final Color dataColor;

  const _WeeklyConsistencyChart({required this.logs, required this.dataColor});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final Map<int, int> dailyTotals = {};
    
    for (int i = 0; i < 7; i++) {
      final d = startOfWeek.add(Duration(days: i));
      final dayKey = d.year * 10000 + d.month * 100 + d.day;
      dailyTotals[dayKey] = 0;
    }

    for (var log in logs) {
      final d = log.timestamp;
      final dayKey = d.year * 10000 + d.month * 100 + d.day;
      if (dailyTotals.containsKey(dayKey)) {
        dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + log.duration;
      }
    }

    final sortedKeys = dailyTotals.keys.toList()..sort();
    final maxMinutes = dailyTotals.values.isNotEmpty 
        ? dailyTotals.values.reduce(math.max).toDouble() 
        : 60.0;
    
    final maxY = maxMinutes > 0 ? (maxMinutes / 10).ceil() * 10.0 + 10 : 60.0;

    final barGroups = sortedKeys.asMap().entries.map((entry) {
      final index = entry.key;
      final minutes = dailyTotals[entry.value]!;
      
      // Visual Logic: Green if > 0, Grey if 0
      final barColor = minutes > 0 
          ? dataColor 
          : AppTheme.textSecondaryColor.withOpacity(0.3);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: minutes > 0 ? minutes.toDouble() : (maxY * 0.05), // Small bump for 0
            color: barColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              // Increased opacity for better visibility against white background
              color: AppTheme.textSecondaryColor.withOpacity(0.15),
            ),
          ),
        ],
        showingTooltipIndicators: minutes > 0 ? [0] : [],
      );
    }).toList();

    return _ActivityCard(
      title: 'Weekly Consistency',
      icon: Icons.bar_chart,
      infoText: 'Total active minutes per day for the current week (Mon-Sun).',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (val, meta) {
                    if (val < 0 || val >= 7) return const SizedBox();
                    final date = startOfWeek.add(Duration(days: val.toInt()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('E').format(date)[0],
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
            barTouchData: BarTouchData(
              enabled: false,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.transparent,
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 4,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  // Don't show tooltip for empty dummy bars
                  final originalVal = dailyTotals.values.toList()[group.x.toInt()];
                  if (originalVal == 0) return null;

                  return BarTooltipItem(
                    rod.toY.toInt().toString(),
                    TextStyle(
                      color: dataColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. ACTIVITY TIMING (Time of Day Analysis)
// ============================================================================

class _ActivityTimingChart extends StatelessWidget {
  final List<ActivityLog> logs;
  final Color dataColor;

  const _ActivityTimingChart({required this.logs, required this.dataColor});

  @override
  Widget build(BuildContext context) {
    // Filter last 28 days
    final cutoff = DateTime.now().subtract(const Duration(days: 28));
    final recentLogs = logs.where((l) => l.timestamp.isAfter(cutoff)).toList();

    double morning = 0; // 5-11
    double midday = 0;  // 11-17
    double evening = 0; // 17-22
    double night = 0;   // 22-5

    for (var log in recentLogs) {
      final h = log.timestamp.hour;
      if (h >= 5 && h < 11) morning += log.duration;
      else if (h >= 11 && h < 17) midday += log.duration;
      else if (h >= 17 && h < 22) evening += log.duration;
      else night += log.duration;
    }

    final total = morning + midday + evening + night;
    if (total == 0) {
      return _ActivityCard(
        title: 'Activity Timing',
        icon: Icons.schedule,
        infoText: 'When you are most active.',
        child: const Padding(
          padding: EdgeInsets.all(20), 
          child: Center(child: Text('No activity in the last 28 days'))
        ),
      );
    }

    final maxVal = [morning, midday, evening, night].reduce(math.max);
    final maxY = maxVal > 0 ? (maxVal / 10).ceil() * 10.0 + 10 : 60.0;

    final dataPoints = [
      _TimingPoint('Morning', morning, 0),
      _TimingPoint('Midday', midday, 1),
      _TimingPoint('Evening', evening, 2),
      _TimingPoint('Night', night, 3),
    ];

    return _ActivityCard(
      title: 'Activity Timing',
      icon: Icons.schedule,
      infoText: 'Distribution of your activity by time of day (Last 28 Days).\n\n'
                '• Morning: Great for setting daily glucose trend.\n'
                '• Evening: Helps lower post-dinner spikes.',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.1), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (val, meta) {
                    if (val < 0 || val >= 4) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        dataPoints[val.toInt()].label,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: dataPoints.map((point) {
              // Visual Logic: Green if > 0, Grey if 0
              final barColor = point.value > 0 
                  ? dataColor 
                  : AppTheme.textSecondaryColor.withOpacity(0.3);

              return BarChartGroupData(
                x: point.index,
                barRods: [
                  BarChartRodData(
                    toY: point.value > 0 ? point.value : (maxY * 0.05),
                    color: barColor,
                    width: 24,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: AppTheme.textSecondaryColor.withOpacity(0.15),
                    ),
                  ),
                ],
              );
            }).toList(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                tooltipMargin: 4,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (dataPoints[group.x.toInt()].value == 0) return null;
                  return BarTooltipItem(
                    '${rod.toY.toInt()}m',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimingPoint {
  final String label;
  final double value;
  final int index;
  _TimingPoint(this.label, this.value, this.index);
}

// ============================================================================
// 4. HISTORY & GLUCOSE IMPACT (CONSISTENT LAYOUT)
// ============================================================================

class _ActivityHistoryList extends StatefulWidget {
  final List<ActivityLog> logs;
  final List<MonitorData> glucoseReadings;
  final Color dataColor;

  const _ActivityHistoryList({
    required this.logs,
    required this.glucoseReadings,
    required this.dataColor,
  });

  @override
  State<_ActivityHistoryList> createState() => _ActivityHistoryListState();
}

class _ActivityHistoryListState extends State<_ActivityHistoryList> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    final totalItems = widget.logs.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    if (totalPages == 0) _currentPage = 0;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = totalItems > 0 ? widget.logs.sublist(start, end) : <ActivityLog>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              if (totalPages > 1)
                Row(
                  children: [
                    IconButton(onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null, icon: const Icon(Icons.chevron_left)),
                    Text('${_currentPage + 1}/$totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null, icon: const Icon(Icons.chevron_right)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (currentItems.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No activity logs found'))
          else
            ...currentItems.map((log) => _buildLogItem(context, log)),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, ActivityLog log) {
    // CALCULATE GLUCOSE IMPACT
    double? startGlucose;
    double? endGlucose;
    final activityTime = log.timestamp;
    
    // 1. Start Reading: [Time - 60min] to [Time + 10min]
    final beforeReadings = widget.glucoseReadings.where((r) => 
      r.measuredAt.isBefore(activityTime.add(const Duration(minutes: 10))) && 
      r.measuredAt.isAfter(activityTime.subtract(const Duration(minutes: 60)))
    ).toList();
    
    if (beforeReadings.isNotEmpty) {
      beforeReadings.sort((a, b) => 
        (a.measuredAt.difference(activityTime).abs()).compareTo(b.measuredAt.difference(activityTime).abs())
      );
      startGlucose = beforeReadings.first.value;
    }

    // 2. End Reading: [Time + 30min] to [Time + 150min]
    final afterReadings = widget.glucoseReadings.where((r) => 
      r.measuredAt.isAfter(activityTime.add(const Duration(minutes: 30))) && 
      r.measuredAt.isBefore(activityTime.add(const Duration(minutes: 150)))
    ).toList();
    
    if (afterReadings.isNotEmpty) {
      afterReadings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt)); 
      endGlucose = afterReadings.last.value;
    }

    double? impact;
    if (startGlucose != null && endGlucose != null) {
      impact = endGlucose - startGlucose; 
    }

    // Determine Status Text & Color based on Impact
    String statusText = 'COMPLETED';
    Color statusColor = AppTheme.primaryGreen; // Default positive for activity

    if (impact != null) {
      if (impact < 0) {
        statusText = 'GLUCOSE ⬇ ${impact.abs().toInt()}';
        statusColor = AppTheme.primaryGreen;
      } else if (impact > 0) {
        statusText = 'GLUCOSE ⬆ ${impact.toInt()}';
        statusColor = AppTheme.warningColor;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.midnightSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 8, 
            offset: const Offset(0, 2)
          )
        ],
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT: Value (Duration) + Unit + Type
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${log.duration}',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 20,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                log.type, // Activity Description
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          // RIGHT: Status Badge + Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('dd/MM/yy HH:mm').format(log.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER WRAPPER
// ============================================================================

class _ActivityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget child;

  // We ignore passing themeColor here to enforce Blue Headers (Consistency)
  // But we can use a default if needed.
  
  const _ActivityCard({
    required this.title, 
    required this.icon, 
    required this.infoText, 
    required this.child,
  });

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            // Info dialog also uses Primary Blue for consistency
            Icon(icon, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(infoText, style: Theme.of(context).textTheme.bodyMedium),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                // Always use Primary Blue for the Header Icon to match other screens
                child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () => _showInfoDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
```

florence\platform_service\lib\features\patient\dashboard\screens\diet_detail_screen.dart
```
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

/// Diet Analytics Screen (formerly MealImpactScreen)
class DietAnalyticsScreen extends ConsumerWidget {
  const DietAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(dailyPatientLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Analytics'),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.getBorderColor(context),
            height: 1.0,
          ),
        ),
      ),
      body: logsAsync.when(
        data: (logs) {
          // Sort logs descending by date
          final sortedLogs = List<DailyPatientLog>.from(logs)
            ..sort((a, b) => b.logDate.compareTo(a.logDate));

          return RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(dailyPatientLogsProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. Statistics
                  _DietStatsSection(logs: sortedLogs),
                  const SizedBox(height: 20),

                  // 2. Traffic Light Calendar (New Section)
                  _TrafficLightCalendar(logs: sortedLogs),
                  const SizedBox(height: 20),

                  // 3. Impact Chart
                  _DietImpactChart(logs: sortedLogs),
                  const SizedBox(height: 20),

                  // 4. History List
                  _DietHistoryList(logs: sortedLogs),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading diet data: $err')),
      ),
    );
  }
}

// ============================================================================
// 1. DIET STATISTICS
// ============================================================================

class _DietStatsSection extends StatelessWidget {
  final List<DailyPatientLog> logs;

  const _DietStatsSection({required this.logs});

  @override
  Widget build(BuildContext context) {
    // 1. Total logs
    final total = logs.length;

    // 2. Avg Spike
    double totalSpike = 0;
    int spikeCount = 0;
    for (var log in logs) {
      if (log.glucoseBeforeMeal != null && log.glucoseAfterMeal != null) {
        totalSpike += (log.glucoseAfterMeal! - log.glucoseBeforeMeal!);
        spikeCount++;
      }
    }
    final avgSpike = spikeCount > 0 ? totalSpike / spikeCount : 0.0;

    // 3. Most Frequent Meal Type
    final typeCounts = <String, int>{};
    for (var log in logs) {
      final t = log.mealTime.toUpperCase();
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }
    
    String topType = '-';
    if (typeCounts.isNotEmpty) {
      topType = typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      // Capitalize format
      if (topType.isNotEmpty) {
        topType = topType[0].toUpperCase() + topType.substring(1).toLowerCase();
      }
    }

    return _DietCard(
      title: 'Overview',
      icon: Icons.analytics_outlined,
      infoText: 'Key statistics from your meal logs.\n\n'
                ' Avg Spike: Average rise in glucose after meals.\n'
                ' Top Meal: Most frequently logged meal time.',
      child: Row(
        children: [
          Expanded(
            child: _buildStatBox(
              context, 
              'Total Logs', 
              '$total', 
              'meals', 
              AppTheme.primaryGreen
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatBox(
              context, 
              'Avg Spike', 
              avgSpike > 0 ? '+${avgSpike.toStringAsFixed(0)}' : '--', 
              'mg/dL', 
              avgSpike > 50 ? AppTheme.errorColor : (avgSpike > 30 ? AppTheme.warningColor : AppTheme.primaryGreen)
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatBox(
              context, 
              'Top Meal', 
              topType, 
              '', 
              AppTheme.primaryGreen
            )
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String title, String value, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10, 
              fontWeight: FontWeight.bold
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value, 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: color
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit, 
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. DIET IMPACT CHART (Avg Spike by Type)
// ============================================================================

class _DietImpactChart extends StatelessWidget {
  final List<DailyPatientLog> logs;

  const _DietImpactChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    // Filter last 28 days
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 28));
    final recentLogs = logs.where((l) => l.logDate.isAfter(cutoff)).toList();

    // Calculate avg spike per meal type
    final dataMap = <String, List<double>>{
      'BREAKFAST': [],
      'LUNCH': [],
      'DINNER': []
    };

    for (var log in recentLogs) {
      if (log.glucoseBeforeMeal != null && log.glucoseAfterMeal != null) {
        final spike = log.glucoseAfterMeal! - log.glucoseBeforeMeal!;
        if (dataMap.containsKey(log.mealTime)) {
          dataMap[log.mealTime]!.add(spike);
        }
      }
    }

    final categories = ['BREAKFAST', 'LUNCH', 'DINNER'];
    final barGroups = <BarChartGroupData>[];
    double maxVal = 0;

    for (int i = 0; i < categories.length; i++) {
      final type = categories[i];
      final spikes = dataMap[type]!;
      double avg = 0;
      if (spikes.isNotEmpty) {
        avg = spikes.reduce((a, b) => a + b) / spikes.length;
      }
      if (avg > maxVal) maxVal = avg;

      // Color logic
      Color barColor = AppTheme.primaryGreen;
      if (avg > 50) barColor = AppTheme.errorColor;
      else if (avg > 30) barColor = AppTheme.warningColor;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: avg > 0 ? avg : 2, // Minimal height if 0 or negative to show empty
              color: spikes.isEmpty ? AppTheme.textSecondaryColor.withOpacity(0.2) : barColor,
              width: 24,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            )
          ],
          showingTooltipIndicators: spikes.isNotEmpty ? [0] : [],
        )
      );
    }

    return _DietCard(
      title: 'Glucose Impact',
      icon: Icons.bar_chart,
      infoText: 'Average glucose spike by meal time (Last 28 Days).\n\n'
                ' Height represents the rise in glucose (mg/dL).\n'
                ' Green: Stable (<30)\n'
                ' Orange: Moderate (30-50)\n'
                ' Red: High (>50)',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: math.max(maxVal * 1.2, 60),
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    if (val < 0 || val >= 3) return const SizedBox();
                    final labels = ['Breakfast', 'Lunch', 'Dinner'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[val.toInt()],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondaryColor
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5)),
            ),
            barGroups: barGroups,
            barTouchData: BarTouchData(
              enabled: false,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.transparent,
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 4,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (dataMap[categories[group.x.toInt()]]!.isEmpty) return null;
                  return BarTooltipItem(
                    '+${rod.toY.toInt()}',
                    TextStyle(
                      color: rod.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. HISTORY LIST
// ============================================================================

class _DietHistoryList extends StatefulWidget {
  final List<DailyPatientLog> logs;

  const _DietHistoryList({required this.logs});

  @override
  State<_DietHistoryList> createState() => _DietHistoryListState();
}

class _DietHistoryListState extends State<_DietHistoryList> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    final totalItems = widget.logs.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    if (totalPages == 0) _currentPage = 0;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = totalItems > 0 ? widget.logs.sublist(start, end) : <DailyPatientLog>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              if (totalPages > 1)
                Row(
                  children: [
                    IconButton(onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null, icon: const Icon(Icons.chevron_left)),
                    Text('${_currentPage + 1}/$totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null, icon: const Icon(Icons.chevron_right)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (currentItems.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No meals logged yet'))
          else
            ...currentItems.map((log) => _buildLogItem(context, log)),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, DailyPatientLog log) {
    // Calculate spike and determine color/text
    String valueText = 'Logged';
    String unitText = '';
    Color statusColor = AppTheme.primaryGreen;
    String? deltaText;

    if (log.glucoseBeforeMeal != null && log.glucoseAfterMeal != null) {
      final spike = log.glucoseAfterMeal! - log.glucoseBeforeMeal!;
      
      // Show range instead of just delta
      valueText = '${log.glucoseBeforeMeal!.toInt()} → ${log.glucoseAfterMeal!.toInt()}';
      unitText = 'mg/dL';
      
      // Delta text
      deltaText = (spike > 0 ? '+' : '') + '${spike.toInt()}';

      if (spike > 50) statusColor = AppTheme.errorColor;
      else if (spike > 30) statusColor = AppTheme.warningColor;
      else statusColor = AppTheme.primaryGreen;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayMealTime = log.mealTime.isNotEmpty 
        ? log.mealTime[0].toUpperCase() + log.mealTime.substring(1).toLowerCase()
        : log.mealTime;

    final mealName = log.mealDesc != null && log.mealDesc!.isNotEmpty 
        ? log.mealDesc! 
        : displayMealTime;

    // Use specific time if available, otherwise fallback to logDate
    final displayDate = log.glucoseBeforeMealTime ?? log.logDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.midnightSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 8, 
            offset: const Offset(0, 2)
          )
        ],
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT: Value & Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      valueText,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (unitText.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        unitText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mealName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // RIGHT: Delta/Type & Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (deltaText != null) ...[
                    Text(
                      displayMealTime,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (deltaText != null ? statusColor : AppTheme.primaryGreen).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (deltaText != null ? statusColor : AppTheme.primaryGreen).withOpacity(0.3), 
                        width: 1
                      ),
                    ),
                    child: Text(
                      deltaText ?? displayMealTime,
                      style: TextStyle(
                        color: deltaText != null ? statusColor : AppTheme.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('dd/MM/yy HH:mm').format(displayDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER WRAPPER
// ============================================================================

class _DietCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget child;

  const _DietCard({
    required this.title, 
    required this.icon, 
    required this.infoText, 
    required this.child,
  });

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(infoText, style: Theme.of(context).textTheme.bodyMedium),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () => _showInfoDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// TRAFFIC LIGHT CALENDAR
// ============================================================================

class _TrafficLightCalendar extends StatelessWidget {
  final List<DailyPatientLog> logs;

  const _TrafficLightCalendar({required this.logs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Prepare Data: Map Date -> Max Spike for that day
    final Map<int, double> dayMaxSpike = {};
    final Map<int, int> dayLogCount = {};

    for (var log in logs) {
      // FIX: Convert to Local Time to ensure alignment with UI
      final localDate = log.logDate.toLocal();
      final dateKey = DateTime(localDate.year, localDate.month, localDate.day).millisecondsSinceEpoch;
      
      // Count logs
      dayLogCount[dateKey] = (dayLogCount[dateKey] ?? 0) + 1;

      // Calculate spike
      if (log.glucoseBeforeMeal != null && log.glucoseAfterMeal != null) {
        final spike = log.glucoseAfterMeal! - log.glucoseBeforeMeal!;
        
        // Keep the HIGHEST spike of the day (worst case scenario dictates the color)
        if (!dayMaxSpike.containsKey(dateKey) || spike > dayMaxSpike[dateKey]!) {
          dayMaxSpike[dateKey] = spike;
        }
      } else {
        // Logged but no glucose data? Treat as 0 spike (Green) if not already set
        dayMaxSpike.putIfAbsent(dateKey, () => 0);
      }
    }

    // 2. Logic to Align Grid to Monday
    final currentWeekday = today.weekday; // 1=Mon...7=Sun
    final startOfCurrentWeek = today.subtract(Duration(days: currentWeekday - 1));
    final startDate = startOfCurrentWeek.subtract(const Duration(days: 21)); // Go back 3 weeks

    return _DietCard(
      title: 'Consistency Calendar',
      icon: Icons.calendar_view_month,
      infoText: 'A 4-week view of your diet control.\n\n'
                '• Green: Controlled (Max spike < 30)\n'
                '• Yellow: Moderate (Max spike 30-50)\n'
                '• Red: High Spike (Max spike > 50)\n'
                '• Grey: No meals logged',
      child: Column(
        children: [
          // Days of Week Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          
          // The Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 28,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final date = startDate.add(Duration(days: index));
              
              // Handle Future Dates (Hide Cell)
              if (date.isAfter(today)) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.3), width: 1),
                  ),
                );
              }

              final dateKey = date.millisecondsSinceEpoch;
              final hasLog = dayLogCount.containsKey(dateKey);
              final maxSpike = dayMaxSpike[dateKey];

              Color cellColor;
              Color textColor;
              String tooltip;

              if (!hasLog) {
                cellColor = Colors.transparent;
                textColor = AppTheme.textSecondaryColor.withOpacity(0.5);
                tooltip = 'No logs';
              } else if (maxSpike == null) {
                // Logged but no glucose data
                cellColor = AppTheme.primaryBlue.withOpacity(0.2);
                textColor = AppTheme.primaryBlue;
                tooltip = 'Meal logged (No Glucose)';
              } else if (maxSpike > 50) {
                cellColor = AppTheme.errorColor;
                textColor = Colors.white;
                tooltip = 'High Spike: +${maxSpike.toInt()}';
              } else if (maxSpike > 30) {
                cellColor = AppTheme.warningColor;
                textColor = Colors.white;
                tooltip = 'Moderate: +${maxSpike.toInt()}';
              } else {
                cellColor = AppTheme.primaryGreen;
                textColor = Colors.white;
                tooltip = 'Stable: +${maxSpike.toInt()}';
              }

              // Highlight "Today"
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

              return Tooltip(
                message: '${DateFormat('MMM d').format(date)}\n$tooltip',
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                    border: !hasLog 
                      ? Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5), width: 1)
                      : (isToday ? Border.all(color: AppTheme.textPrimaryColor, width: 2) : null),
                  ),
                  alignment: Alignment.center,
                  child: hasLog ? Text(
                    '${date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ) : Text(
                    '${date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppTheme.primaryGreen, label: 'Good'),
              const SizedBox(width: 16),
              _LegendDot(color: AppTheme.warningColor, label: 'Fair'),
              const SizedBox(width: 16),
              _LegendDot(color: AppTheme.errorColor, label: 'High Spike'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
```

florence\platform_service\lib\features\patient\trends\services\health_summary_service.dart
```
/// Health Summary Service for FLORENCE Digital Health Platform
/// Generates AI-powered health summaries

import '../../../../core/config/environment.dart';
import '../../../patient/core/services/data_ingestion_service.dart';
import '../../../patient/core/models/health_data_models.dart';

/// Health summary period
enum SummaryPeriod {
  daily,
  weekly,
  monthly,
  custom,
}

/// AI-generated health summary
class AISummary {
  final String id;
  final SummaryPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final String narrative; // AI-generated summary
  final HealthSummary statistics;
  final List<String> insights;
  final List<String> achievements;
  final List<String> areasForImprovement;
  final DateTime generatedAt;

  const AISummary({
    required this.id,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.narrative,
    required this.statistics,
    required this.insights,
    this.achievements = const [],
    this.areasForImprovement = const [],
    required this.generatedAt,
  });

  String get periodLabel {
    switch (period) {
      case SummaryPeriod.daily:
        return 'Daily';
      case SummaryPeriod.weekly:
        return 'Weekly';
      case SummaryPeriod.monthly:
        return 'Monthly';
      case SummaryPeriod.custom:
        return 'Custom';
    }
  }
}

/// Service for generating health summaries
class HealthSummaryService {
  final DataIngestionService _dataService = DataIngestionService();

  // Singleton pattern
  static final HealthSummaryService _instance = HealthSummaryService._internal();
  factory HealthSummaryService() => _instance;
  HealthSummaryService._internal();

  /// Generate AI-powered health summary
  Future<AISummary> generateSummary({
    required DateTime startDate,
    required DateTime endDate,
    SummaryPeriod period = SummaryPeriod.weekly,
  }) async {
    // Get health statistics
    final statistics = _dataService.getHealthSummary(
      startDate: startDate,
      endDate: endDate,
    );

    // Extract insights
    final insights = _extractInsights(statistics);
    final achievements = _extractAchievements(statistics);
    final improvements = _extractImprovements(statistics);

    String narrative;

    // AI Summary generation temporarily disabled as DeepSeekService is removed
    narrative = _generateRuleBasedNarrative(statistics, period);

    return AISummary(
      id: 'summary_${DateTime.now().millisecondsSinceEpoch}',
      period: period,
      startDate: startDate,
      endDate: endDate,
      narrative: narrative,
      statistics: statistics,
      insights: insights,
      achievements: achievements,
      areasForImprovement: improvements,
      generatedAt: DateTime.now(),
    );
  }

  /// Generate weekly summary (convenience method)
  Future<AISummary> generateWeeklySummary() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));
    return generateSummary(
      startDate: startDate,
      endDate: endDate,
      period: SummaryPeriod.weekly,
    );
  }

  /// Generate monthly summary
  Future<AISummary> generateMonthlySummary() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    return generateSummary(
      startDate: startDate,
      endDate: endDate,
      period: SummaryPeriod.monthly,
    );
  }

  /// Generate rule-based narrative
  String _generateRuleBasedNarrative(HealthSummary stats, SummaryPeriod period) {
    final buffer = StringBuffer();

    // Overall assessment
    final overallScore = _calculateOverallScore(stats);
    if (overallScore >= 80) {
      buffer.writeln('Great ${period.name} performance! Your diabetes management is on track.');
    } else if (overallScore >= 60) {
      buffer.writeln('Good ${period.name} progress with room for improvement.');
    } else {
      buffer.writeln('This ${period.name} shows areas that need attention.');
    }

    buffer.writeln();

    // Glucose control
    if (stats.timeInRange >= 70) {
      buffer.writeln('✓ Excellent glucose control with ${stats.timeInRange.toStringAsFixed(0)}% time in range.');
    } else if (stats.timeInRange >= 50) {
      buffer.writeln('• Time in range at ${stats.timeInRange.toStringAsFixed(0)}% - working towards 70% goal.');
    } else {
      buffer.writeln('⚠ Time in range is ${stats.timeInRange.toStringAsFixed(0)}%. Focus on consistent carb portions and timing.');
    }

    // Activity
    if (stats.totalActivityMinutes >= 150) {
      buffer.writeln('✓ Met activity goal with ${stats.totalActivityMinutes} minutes!');
    } else {
      buffer.writeln('• Activity: ${stats.totalActivityMinutes} minutes. Aim for 150 minutes/week.');
    }

    // Medication adherence
    if (stats.medicationAdherence >= 0.9) {
      buffer.writeln('✓ Excellent medication adherence.');
    } else if (stats.medicationAdherence >= 0.8) {
      buffer.writeln('• Good medication adherence. Stay consistent!');
    } else {
      buffer.writeln('⚠ Medication adherence needs attention. Consider setting reminders.');
    }

    return buffer.toString();
  }

  /// Extract insights from data
  List<String> _extractInsights(HealthSummary stats) {
    final insights = <String>[];

    // Glucose patterns
    if (stats.hyperEvents > stats.hypoEvents * 2) {
      insights.add('More high than low events - consider reducing carb portions');
    } else if (stats.hypoEvents > 3) {
      insights.add('Frequent low glucose - discuss medication timing with doctor');
    }

    // Variability
    if (stats.glucoseStdDev > 50) {
      insights.add('High glucose variability - more consistent meal timing may help');
    } else {
      insights.add('Good glucose stability');
    }

    // Activity correlation
    if (stats.totalActivityMinutes > Environment.activityTargetWeekly &&
        stats.timeInRange > 70) {
      insights.add('Your activity is positively impacting glucose control');
    }

    // Estimated A1c
    if (stats.estimatedA1c < 7.0) {
      insights.add('Estimated A1c (${stats.estimatedA1c.toStringAsFixed(1)}%) is at target!');
    } else {
      insights.add('Estimated A1c is ${stats.estimatedA1c.toStringAsFixed(1)}% - room for improvement');
    }

    return insights;
  }

  /// Extract achievements
  List<String> _extractAchievements(HealthSummary stats) {
    final achievements = <String>[];

    if (stats.timeInRange >= 70) {
      achievements.add('70%+ Time in Range');
    }

    if (stats.hypoEvents == 0) {
      achievements.add('Zero Hypoglycemia Events');
    }

    if (stats.medicationAdherence >= 0.95) {
      achievements.add('Outstanding Medication Adherence');
    }

    if (stats.totalActivityMinutes >= 150) {
      achievements.add('Met Weekly Activity Goal');
    }

    if (stats.averageSleepHours >= 7 && stats.averageSleepHours <= 9) {
      achievements.add('Healthy Sleep Duration');
    }

    return achievements;
  }

  /// Extract areas for improvement
  List<String> _extractImprovements(HealthSummary stats) {
    final improvements = <String>[];

    if (stats.timeInRange < 70) {
      improvements.add('Increase time in range (currently ${stats.timeInRange.toStringAsFixed(0)}%)');
    }

    if (stats.totalActivityMinutes < 150) {
      improvements.add('Add ${150 - stats.totalActivityMinutes} more minutes of activity');
    }

    if (stats.medicationAdherence < 0.8) {
      improvements.add('Improve medication consistency');
    }

    if (stats.glucoseStdDev > 50) {
      improvements.add('Reduce glucose variability through consistent timing');
    }

    if (stats.averageSleepHours < 7) {
      improvements.add('Increase sleep to 7-9 hours nightly');
    }

    return improvements;
  }

  /// Calculate overall performance score
  int _calculateOverallScore(HealthSummary stats) {
    int score = 0;

    // Time in range (0-30 points)
    if (stats.timeInRange >= 70) score += 30;
    else if (stats.timeInRange >= 50) score += 20;
    else score += 10;

    // Hypo events (0-20 points)
    if (stats.hypoEvents == 0) score += 20;
    else if (stats.hypoEvents <= 2) score += 15;
    else if (stats.hypoEvents <= 5) score += 10;

    // Activity (0-20 points)
    if (stats.totalActivityMinutes >= 150) score += 20;
    else if (stats.totalActivityMinutes >= 150 * 0.7) score += 15;
    else score += 5;

    // Medication adherence (0-20 points)
    if (stats.medicationAdherence >= 0.9) score += 20;
    else if (stats.medicationAdherence >= 0.8) score += 15;
    else if (stats.medicationAdherence >= 0.7) score += 10;

    // Variability (0-10 points)
    if (stats.glucoseStdDev <= 40) score += 10;
    else if (stats.glucoseStdDev <= 50) score += 7;
    else score += 3;

    return score;
  }
}
```

florence\platform_service\lib\features\patient\dashboard\widgets\health_summary_card.dart
```
import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../config/theme.dart';

/// Health Summary Card (Hero Card)
/// Displays the latest glucose reading with visual indicator
class HealthSummaryCard extends StatelessWidget {
  final double latestGlucose;
  final DateTime timestamp;
  final VoidCallback? onTap;
  
  const HealthSummaryCard({
    super.key,
    required this.latestGlucose,
    required this.timestamp,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final glucoseColor = _getGlucoseColor(latestGlucose);
    final glucoseStatus = _getGlucoseStatus(latestGlucose);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              glucoseColor,
              glucoseColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: glucoseColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Glucose',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    glucoseStatus,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Glucose value
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  latestGlucose.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 56,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  'mg/dL',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Timestamp
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  Formatters.timeAgo(timestamp),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action hint
            Row(
              children: [
                Text(
                  'View trends',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Get glucose color based on value
  Color _getGlucoseColor(double value) {
    if (value < 70) {
      return AppTheme.glucoseLow;
    } else if (value > 180) {
      return AppTheme.glucoseHigh;
    } else {
      return AppTheme.glucoseNormal;
    }
  }
  
  /// Get glucose status text
  String _getGlucoseStatus(double value) {
    if (value < 70) {
      return 'Low';
    } else if (value > 180) {
      return 'High';
    } else {
      return 'Normal';
    }
  }
}
```

florence\platform_service\lib\features\patient\dashboard\widgets\health_metric_card.dart
```
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';

class HealthMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String status;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const HealthMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.timestamp,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              Helpers.darken(color, 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildValue(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildValue(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 4),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Last updated: ${Formatters.timeAgo(timestamp)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
        ),
      ],
    );
  }

}
```

florence\platform_service\lib\features\patient\dashboard\screens\dashboard_screen.dart
```
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/notification_bell.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../main.dart';
import '../widgets/health_metric_card.dart';
import '../widgets/biometrics_section.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/health_metric_card.dart';
import '../providers/dashboard_providers.dart'; // Added
import '../../core/models/health_data_models.dart';

/// Home Dashboard Screen
/// Main hub showing health summary, quick actions, and insights
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _userName;
  bool _hasShownWelcomeMessage = false;
  int _loadUserRetries = 0;

  // Services
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Load user data
  Future<void> _loadUserData() async {
    try {
      // Fetch the full profile from the backend API
      final profile = await _apiService.get('/patients/me');
      if (mounted) {
        setState(() {
          _userName = profile['name'] as String? ?? 'Patient';
          _loadUserRetries = 0; // Reset on success
        });
      }
    } catch (e) {
      debugPrint('Error loading user data for dashboard: $e');

      final user = supabase.auth.currentUser;
      final isNewUser = user != null &&
          user.createdAt != null &&
          DateTime.now().difference(DateTime.parse(user.createdAt!)).inMinutes < 2;

      // If it's a new user and the profile isn't found yet, retry up to 2 times.
      if (isNewUser && e.toString().contains('Access denied') && _loadUserRetries < 2) {
        _loadUserRetries++;
        debugPrint('Dashboard: Patient profile not found for new user. Retry attempt #$_loadUserRetries...');
        await Future.delayed(const Duration(seconds: 3));
        await _loadUserData(); // Recursive retry
      } else {
        // Fallback to a generic name if API fails after retries or for other errors
        if (mounted) {
          setState(() {
            _userName = 'Patient';
          });
        }
      }
    }
  }

  /// Handle refresh
  Future<void> _handleRefresh() async {
    // This invalidates the state, forcing a re-fetch from the repositories
    ref.invalidate(monitorDataProvider);
    ref.invalidate(latestActivityProvider);
    ref.invalidate(patientThresholdsProvider);
    ref.invalidate(dailyPatientLogsProvider);
    // Wait for them to rebuild
    await Future.wait([
       ref.read(monitorDataProvider.future),
       ref.read(latestActivityProvider.future),
       ref.read(patientThresholdsProvider.future),
       ref.read(dailyPatientLogsProvider.future),
    ]);
  }

  /// Show quick log modal
  void _showQuickLogModal() {
    Helpers.showBottomSheet(context, child: _QuickLogModal());
  }

  @override
  Widget build(BuildContext context) {
    // Watch Riverpod providers
    final monitorData = ref.watch(monitorDataProvider).valueOrNull ?? [];
    final activity = ref.watch(latestActivityProvider).valueOrNull;
    final thresholds = ref.watch(patientThresholdsProvider).valueOrNull ?? [];
    final mealLogs = ref.watch(dailyPatientLogsProvider).valueOrNull ?? [];

    // Determine latest meal
    DailyPatientLog? latestMeal;
    if (mealLogs.isNotEmpty) {
      final sortedMeals = List<DailyPatientLog>.from(mealLogs);
      sortedMeals.sort((a, b) {
        final dateComp = a.logDate.compareTo(b.logDate);
        if (dateComp != 0) return dateComp;
        return _getMealTimePriority(a.mealTime).compareTo(_getMealTimePriority(b.mealTime));
      });
      latestMeal = sortedMeals.last;
    }
    
    // Define consistent spacing
    const double spacing = 20.0;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        edgeOffset: 0,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(spacing),
          children: [
            // AI Insight (Main Card)
            AIInsightCard(
              insight: 'Your glucose levels are most stable after morning walks. Consider a 15-minute walk after breakfast!',
              onTap: () => AppRoutes.push(context, AppRoutes.recommendations),
            ),
            const SizedBox(height: spacing),

            // Biometrics Section (Loaded via Riverpod)
            BiometricsSection(
              monitorData: monitorData,
              latestActivity: activity,
              latestMeal: latestMeal,
              thresholds: thresholds,
            ),
            const SizedBox(height: spacing),

            // Quick actions
            QuickActionsGrid(
              onLogGlucose: () => AppRoutes.push(context, AppRoutes.logGlucose),
              onLogMeal: () => AppRoutes.push(context, AppRoutes.logMeal),
              onLogActivity: () => AppRoutes.push(context, AppRoutes.logActivity),
              onLogMedication: () => AppRoutes.push(context, AppRoutes.logMedication),
            ),
            const SizedBox(height: spacing),
          ],
        ),
      ),
    );
  }


  /// Build app bar
  AppBar _buildAppBar(BuildContext context) {
    final monitorDataAsync = ref.watch(monitorDataProvider);
    final activityAsync = ref.watch(latestActivityProvider);
    final isLoading = monitorDataAsync.isLoading || activityAsync.isLoading;
    final borderColor = AppTheme.getBorderColor(context);

    return AppBar(
      title: InkWell(
        onTap: _handleRefresh,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text('Florence'),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _showQuickLogModal,
          tooltip: 'Quick Log',
        ),
        const NotificationBell(),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () => AppRoutes.push(context, AppRoutes.chat),
          tooltip: 'AI Health Assistant',
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => AppRoutes.push(context, AppRoutes.profile),
          tooltip: 'Profile',
        ),
      ],
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2.0),
        child: isLoading
            ? const LinearProgressIndicator(minHeight: 2.0)
            : Container(
                color: borderColor,
                height: 1.0,
              ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  int _getMealTimePriority(String time) {
    switch (time.toUpperCase()) {
      case 'BREAKFAST': return 1;
      case 'LUNCH': return 2;
      case 'DINNER': return 3;
      default: return 0;
    }
  }
}


/// Quick log modal
class _QuickLogModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Quick Log',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Action buttons
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _QuickLogButton(
                icon: Icons.water_drop,
                label: 'Glucose',
                color: AppTheme.primaryRed,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logGlucose);
                },
              ),
              _QuickLogButton(
                icon: Icons.monitor_heart,
                label: 'Blood Pressure',
                color: AppTheme.primaryRed,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logBloodPressure);
                },
              ),
              _QuickLogButton(
                icon: Icons.bloodtype,
                label: 'Cholesterol',
                color: AppTheme.accentPurple,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logCholesterol);
                },
              ),
              _QuickLogButton(
                icon: Icons.height,
                label: 'BMI',
                color: AppTheme.primaryGreen,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logBmi);
                },
              ),
              _QuickLogButton(
                icon: Icons.restaurant,
                label: 'Meal',
                color: AppTheme.mealColor,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logMeal);
                },
              ),
              _QuickLogButton(
                icon: Icons.directions_run,
                label: 'Activity',
                color: AppTheme.activityColor,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logActivity);
                },
              ),
              _QuickLogButton(
                icon: Icons.medication,
                label: 'Medication',
                color: AppTheme.medicationColor,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logMedication);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Quick log button widget
class _QuickLogButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickLogButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


```

florence\platform_service\lib\features\patient\dashboard\widgets\quick_stats_grid.dart
```
import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';

/// Quick Stats Grid
/// Displays key health metrics in a grid layout
class QuickStatsGrid extends StatelessWidget {
  final double averageGlucose;
  final double hba1c;
  final BloodPressureReading? bloodPressure;
  final double cholesterol;
  final double bmi;
  final int todayReadings;

  const QuickStatsGrid({
    super.key,
    required this.averageGlucose,
    required this.hba1c,
    required this.bloodPressure,
    required this.cholesterol,
    required this.bmi,
    required this.todayReadings,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          label: 'Avg Glucose',
          value: averageGlucose > 0 ? averageGlucose.toStringAsFixed(0) : '--',
          unit: 'mg/dL',
          icon: Icons.show_chart,
          color: AppTheme.primaryBlue,
        ),
        StatCard(
          label: 'HbA1c',
          value: hba1c > 0 ? hba1c.toStringAsFixed(1) : '--',
          unit: '%',
          icon: Icons.pie_chart,
          color: AppTheme.primaryGreen,
        ),
        StatCard(
          label: 'Blood Pressure',
          value: bloodPressure?.value ?? '--',
          unit: 'mmHg',
          icon: Icons.monitor_heart,
          color: AppTheme.primaryRed,
        ),
        StatCard(
          label: 'Cholesterol',
          value: cholesterol > 0 ? cholesterol.toStringAsFixed(0) : '--',
          unit: 'mg/dL',
          icon: Icons.bloodtype,
          color: AppTheme.accentPurple,
        ),
        StatCard(
          label: 'BMI',
          value: bmi > 0 ? bmi.toStringAsFixed(1) : '--',
          unit: '',
          icon: Icons.height,
          color: AppTheme.activityColor,
        ),
        StatCard(
          label: 'Today\'s Logs',
          value: todayReadings.toString(),
          unit: 'readings',
          icon: Icons.water_drop_outlined,
          color: AppTheme.mealColor,
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: 4),
              Text(unit, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
```

florence\platform_service\lib\features\patient\dashboard\screens\cholesterol_detail_screen.dart
```
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class CholesterolDetailScreen extends ConsumerWidget {
  const CholesterolDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorAsync = ref.watch(monitorDataProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cholesterol Analytics'),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.getBorderColor(context),
            height: 1.0,
          ),
        ),
      ),
      body: monitorAsync.when(
        data: (dataList) {
          final readings = _processReadings(dataList);
          
          // Sort by date ascending
          readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          final thresholds = thresholdsAsync.value ?? [];
          
          // Get thresholds (Nullable)
          final ldlThreshold = _getThreshold(thresholds, MonitorDataType.CHOLESTEROL_LDL);
          final hdlThreshold = _getThreshold(thresholds, MonitorDataType.CHOLESTEROL_HDL);
          final totalThreshold = _getThreshold(thresholds, MonitorDataType.CHOLESTEROL_TOTAL);
          final triThreshold = _getThreshold(thresholds, MonitorDataType.CHOLESTEROL_TRIGLYCERIDES);
          
          // Construct composite latest reading from most recent available data points
          _CholesterolReading? latest;
          if (readings.isNotEmpty) {
            double? lastTotal, lastLdl, lastHdl, lastTri;
            DateTime lastDate = readings.last.timestamp;
            
            for (var r in readings.reversed) {
              if (lastTotal == null && r.total != null) lastTotal = r.total;
              if (lastLdl == null && r.ldl != null) lastLdl = r.ldl;
              if (lastHdl == null && r.hdl != null) lastHdl = r.hdl;
              if (lastTri == null && r.triglycerides != null) lastTri = r.triglycerides;
            }
            latest = _CholesterolReading(
              timestamp: lastDate,
              total: lastTotal,
              ldl: lastLdl,
              hdl: lastHdl,
              triglycerides: lastTri,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
               await Future.wait([
                 ref.refresh(monitorDataProvider.future),
                 ref.refresh(patientThresholdsProvider.future),
               ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. Ratio Donut & Targets (Overview)
                  _RatioSection(
                    reading: latest,
                    total: totalThreshold,
                    ldl: ldlThreshold,
                    hdl: hdlThreshold,
                    tri: triThreshold,
                  ),
                  const SizedBox(height: 20),
                  
                  // 3. Bullet Graph (LDL Target)
                  _LdlTargetSection(reading: latest, target: ldlThreshold?.maxValue),
                  const SizedBox(height: 20),

                  // 4. Stacked Bar (Composition)
                  _CompositionSection(readings: readings),
                  const SizedBox(height: 20),
                  
                  // 5. History
                  _HistorySection(readings: readings, thresholds: thresholds),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  HealthThreshold? _getThreshold(List<HealthThreshold> thresholds, MonitorDataType type) {
    try {
      return thresholds.firstWhere((t) => t.dataType == type);
    } catch (_) {
      return null;
    }
  }

  List<_CholesterolReading> _processReadings(List<MonitorData> data) {
    final Map<String, _CholesterolReading> grouped = {};

    for (var d in data) {
      // Filter relevant types
      if (d.dataType != MonitorDataType.CHOLESTEROL_TOTAL &&
          d.dataType != MonitorDataType.CHOLESTEROL_LDL &&
          d.dataType != MonitorDataType.CHOLESTEROL_HDL &&
          d.dataType != MonitorDataType.CHOLESTEROL_TRIGLYCERIDES) {
        continue;
      }

      // Group by exact timestamp to split different times on same day
      final key = d.measuredAt.toIso8601String();
      
      if (!grouped.containsKey(key)) {
        grouped[key] = _CholesterolReading(timestamp: d.measuredAt);
      }
      
      final current = grouped[key]!;
      
      switch (d.dataType) {
        case MonitorDataType.CHOLESTEROL_TOTAL:
          grouped[key] = current.copyWith(total: d.value);
          break;
        case MonitorDataType.CHOLESTEROL_LDL:
          grouped[key] = current.copyWith(ldl: d.value);
          break;
        case MonitorDataType.CHOLESTEROL_HDL:
          grouped[key] = current.copyWith(hdl: d.value);
          break;
        case MonitorDataType.CHOLESTEROL_TRIGLYCERIDES:
          grouped[key] = current.copyWith(triglycerides: d.value);
          break;
        default:
          break;
      }
    }
    
    return grouped.values.toList();
  }
}

class _CholesterolReading {
  final DateTime timestamp;
  final double? total;
  final double? ldl;
  final double? hdl;
  final double? triglycerides;

  _CholesterolReading({
    required this.timestamp,
    this.total,
    this.ldl,
    this.hdl,
    this.triglycerides,
  });

  _CholesterolReading copyWith({
    DateTime? timestamp,
    double? total,
    double? ldl,
    double? hdl,
    double? triglycerides,
  }) {
    return _CholesterolReading(
      timestamp: timestamp ?? this.timestamp,
      total: total ?? this.total,
      ldl: ldl ?? this.ldl,
      hdl: hdl ?? this.hdl,
      triglycerides: triglycerides ?? this.triglycerides,
    );
  }

  double get ratio {
    if (total != null && hdl != null && hdl! > 0) {
      return total! / hdl!;
    }
    return 0.0;
  }
}

// ============================================================================
// 1. RATIO DONUT & TARGETS (OVERVIEW)
// ============================================================================

class _RatioSection extends StatelessWidget {
  final _CholesterolReading? reading;
  final HealthThreshold? total;
  final HealthThreshold? ldl;
  final HealthThreshold? hdl;
  final HealthThreshold? tri;

  const _RatioSection({
    this.reading,
    this.total,
    this.ldl,
    this.hdl,
    this.tri,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = reading?.ratio ?? 0.0;
    // Use non-HDL cholesterol as the "bad" portion for the chart representation
    // Total = HDL + Non-HDL. So Non-HDL = Total - HDL.
    final valTotal = reading?.total ?? 0.0;
    final valHdl = reading?.hdl ?? 0.0;
    final valNonHdl = (valTotal > valHdl) ? valTotal - valHdl : 0.0;
    
    final hasData = ratio > 0;

    String statusText;
    Color statusColor;

    if (ratio == 0) {
      statusText = "No Data";
      statusColor = AppTheme.textSecondaryColor;
    } else if (total != null && hdl != null) {
      // Only evaluate if we have targets
      if (ratio < 3.5) {
        statusText = "Excellent";
        statusColor = AppTheme.primaryGreen;
      } else if (ratio < 5.0) {
        statusText = "Good";
        statusColor = AppTheme.primaryBlue;
      } else {
        statusText = "High Risk";
        statusColor = AppTheme.errorColor;
      }
    } else {
      statusText = "Recorded";
      statusColor = AppTheme.primaryBlue;
    }

    return _CholesterolCard(
      title: 'Cholesterol Ratio',
      icon: Icons.pie_chart,
      infoText: 'Ratio = Total Cholesterol / HDL.\n\n'
                '• Chart: Comparing HDL (Good) vs Non-HDL (Bad).\n'
                '• Goal: A lower ratio is better (Target < 5.0).\n\n'
                '${total != null ? "• Total Target: ${total!.minValue.toInt()}-${total!.maxValue.toInt()}\n" : ""}'
                '${ldl != null ? "• LDL Target: ${ldl!.minValue.toInt()}-${ldl!.maxValue.toInt()}\n" : ""}'
                '${hdl != null ? "• HDL Target: ${hdl!.minValue.toInt()}-${hdl!.maxValue.toInt()}\n" : ""}'
                '${tri != null ? "• Triglycerides: ${tri!.minValue.toInt()}-${tri!.maxValue.toInt()}" : ""}',
      child: Column(
        children: [
          // TARGET RANGES (Consistent with Glucose/BP style)
          InkWell(
            onTap: () => Navigator.of(context).pushNamed('/profile'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.track_changes,
                            size: 18,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Target Ranges',
                            style: TextStyle(
                              color: AppTheme.primaryGreen.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Targets List
                  _buildMiniTargetRow('Total', total != null ? '${total!.minValue.toInt()} - ${total!.maxValue.toInt()} mg/dL' : 'Not Set', AppTheme.primaryGreen),
                  const SizedBox(height: 4),
                  _buildMiniTargetRow('LDL', ldl != null ? '${ldl!.minValue.toInt()} - ${ldl!.maxValue.toInt()} mg/dL' : 'Not Set', AppTheme.primaryGreen),
                  const SizedBox(height: 4),
                  _buildMiniTargetRow('HDL', hdl != null ? '${hdl!.minValue.toInt()} - ${hdl!.maxValue.toInt()} mg/dL' : 'Not Set', AppTheme.primaryGreen),
                  const SizedBox(height: 4),
                  _buildMiniTargetRow('Triglycerides', tri != null ? '${tri!.minValue.toInt()} - ${tri!.maxValue.toInt()} mg/dL' : 'Not Set', AppTheme.primaryGreen),
                ],
              ),
            ),
          ),

          // Ratio Chart
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hasData)
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: [
                        // HDL (Good)
                        PieChartSectionData(
                          value: valHdl,
                          color: AppTheme.primaryGreen,
                          radius: 25,
                          showTitle: false,
                        ),
                        // Non-HDL (Bad)
                        PieChartSectionData(
                          value: valNonHdl > 0 ? valNonHdl : 1,
                          color: AppTheme.errorColor,
                          radius: 25,
                          showTitle: false,
                        ),
                      ],
                    ),
                  )
                else
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      sections: [
                        PieChartSectionData(
                          value: 1,
                          color: Colors.grey.shade200,
                          radius: 25,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ratio',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      ratio > 0 ? ratio.toStringAsFixed(1) : '--',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasData)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem('HDL (Good)', AppTheme.primaryGreen),
                  const SizedBox(width: 16),
                  _LegendItem('Non-HDL', AppTheme.errorColor),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniTargetRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// ============================================================================
// 2. BULLET GRAPH (LDL vs TARGET)
// ============================================================================

class _LdlTargetSection extends StatelessWidget {
  final _CholesterolReading? reading;
  final double? target;

  const _LdlTargetSection({this.reading, this.target});

  @override
  Widget build(BuildContext context) {
    if (target == null) {
      return _CholesterolCard(
        title: 'LDL Performance',
        icon: Icons.track_changes,
        infoText: 'Set an LDL target to view performance.',
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No LDL target set')),
        ),
      );
    }

    final ldl = reading?.ldl ?? 0.0;
    final double maxScale = math.max(200.0, target! * 1.5);
    
    return _CholesterolCard(
      title: 'LDL Performance',
      icon: Icons.track_changes,
      infoText: 'Your "Bad" Cholesterol (LDL) compared to the target limit.\n\n'
                '• Indicator: Your Level\n'
                '• Vertical Line: Target Limit (< ${target!.toInt()})\n'
                '• Goal: Keep the indicator in the green zone.',
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Custom Gauge
          SizedBox(
            height: 80,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final targetPos = (target! / maxScale) * width;
                final actualPos = (ldl / maxScale) * width;
                
                return Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Background Track (Ranges)
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 30,
                          child: Row(
                            children: [
                              // Green Zone
                              Container(
                                width: targetPos,
                                color: AppTheme.primaryGreen.withOpacity(0.2),
                              ),
                              // Yellow Zone (Next 30mg/dL)
                              Container(
                                width: (30 / maxScale) * width,
                                color: AppTheme.warningColor.withOpacity(0.2),
                              ),
                              // Red Zone
                              Expanded(
                                child: Container(
                                  color: AppTheme.errorColor.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // 2. Target Line
                    Positioned(
                      left: targetPos - 1, 
                      top: 15, 
                      child: Column(
                        children: [
                          Container(
                            width: 2,
                            height: 40,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Max\n${target!.toInt()}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. User Value Marker
                    if (ldl > 0)
                      Positioned(
                        left: (actualPos - 20).clamp(0, width - 40),
                        top: -10,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (ldl > target!) ? AppTheme.errorColor : AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              ),
                              child: Text(
                                '${ldl.toInt()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: (ldl > target!) ? AppTheme.errorColor : AppTheme.primaryGreen,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. STACKED BAR CHART (COMPOSITION)
// ============================================================================

class _CompositionSection extends StatefulWidget {
  final List<_CholesterolReading> readings;

  const _CompositionSection({required this.readings});

  @override
  State<_CompositionSection> createState() => _CompositionSectionState();
}

class _CompositionSectionState extends State<_CompositionSection> {
  String _selectedRange = '6M';
  final List<String> _ranges = ['6M', '1Y', 'ALL'];

  String _getRangeLabel(String range) {
    switch (range) {
      case '6M':
        return 'Half Year';
      case '1Y':
        return 'Yearly';
      case 'ALL':
        return 'All Time';
      default:
        return range;
    }
  }

  List<_CholesterolReading> _filterData() {
    final validData = widget.readings.where((r) => (r.hdl ?? 0) + (r.ldl ?? 0) + (r.triglycerides ?? 0) > 0).toList();
    if (validData.isEmpty || _selectedRange == 'ALL') return validData;
    
    final now = DateTime.now();
    final duration = _selectedRange == '6M' ? const Duration(days: 180) : const Duration(days: 365);
    final cutoff = now.subtract(duration);
    return validData.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayData = _filterData();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _CholesterolCard(
      title: 'Cholesterol Breakdown',
      icon: Icons.bar_chart,
      infoText: 'Composition of your cholesterol levels over time.\n\n'
                '• Green (Bottom): HDL (Good)\n'
                '• Red (Middle): LDL (Bad)\n'
                '• Orange (Top): Triglycerides',
      child: Column(
        children: [
          // Timeline Selector
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: _ranges.map((range) {
                final isSelected = _selectedRange == range;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRange = range),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRangeLabel(range),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                            ? Colors.white 
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (displayData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No detailed data available'),
            )
          else
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() >= displayData.length) return const SizedBox();
                          final date = displayData[val.toInt()].timestamp;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM d').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  barGroups: displayData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final r = entry.value;
                    final hdl = r.hdl ?? 0;
                    final ldl = r.ldl ?? 0;
                    final tri = r.triglycerides ?? 0;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: hdl + ldl + tri,
                          width: 16,
                          borderRadius: BorderRadius.circular(2),
                          rodStackItems: [
                            BarChartRodStackItem(0, hdl, AppTheme.primaryGreen),
                            BarChartRodStackItem(hdl, hdl + ldl, AppTheme.errorColor),
                            BarChartRodStackItem(hdl + ldl, hdl + ldl + tri, Colors.orange),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem('HDL', AppTheme.primaryGreen),
              const SizedBox(width: 16),
              _LegendItem('LDL', AppTheme.errorColor),
              const SizedBox(width: 16),
              _LegendItem('Triglycerides', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. HISTORY LIST
// ============================================================================

class _HistorySection extends StatefulWidget {
  final List<_CholesterolReading> readings;
  final List<HealthThreshold> thresholds;

  const _HistorySection({required this.readings, required this.thresholds});

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  Color _getStatusColor(double? value, MonitorDataType type) {
    if (value == null) return AppTheme.textSecondaryColor;
    
    try {
      final t = widget.thresholds.firstWhere((t) => t.dataType == type);
      
      if (type == MonitorDataType.CHOLESTEROL_HDL) {
        // HDL: Higher is better. Low is bad.
        return value < t.minValue ? AppTheme.errorColor : AppTheme.primaryGreen;
      } else {
        // LDL/Total/Tri: Lower is better. High is bad.
        return value > t.maxValue ? AppTheme.errorColor : AppTheme.primaryGreen;
      }
    } catch (_) {
      // No threshold found: Return neutral color
      return AppTheme.textPrimaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    // Reverse data to show latest first
    final reversed = widget.readings.reversed.toList();
    
    final totalItems = reversed.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    if (totalPages == 0) _currentPage = 0;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = totalItems > 0 ? reversed.sublist(start, end) : <_CholesterolReading>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              // Pagination Controls
              if (totalPages > 0)
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                      icon: const Icon(Icons.chevron_left),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${_currentPage + 1}/$totalPages',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                      icon: const Icon(Icons.chevron_right),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (currentItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No records found'),
            )
          else
            ...currentItems.map((r) {
              // Helper to safely get threshold values
              double? getLimit(MonitorDataType type, {bool isMin = false}) {
                try {
                  final t = widget.thresholds.firstWhere((t) => t.dataType == type);
                  return isMin ? t.minValue : t.maxValue;
                } catch (_) {
                  return null;
                }
              }

              final maxTotal = getLimit(MonitorDataType.CHOLESTEROL_TOTAL);
              final maxLdl = getLimit(MonitorDataType.CHOLESTEROL_LDL);
              final minHdl = getLimit(MonitorDataType.CHOLESTEROL_HDL, isMin: true);
              final maxTri = getLimit(MonitorDataType.CHOLESTEROL_TRIGLYCERIDES);

              // Determine status based on priority (LDL > Total > Tri > HDL)
              String statusText = 'RECORDED';
              Color statusColor = AppTheme.primaryBlue;

              // Only apply "Good" status if we actually have thresholds to compare against
              if (maxLdl != null || maxTotal != null || maxTri != null || minHdl != null) {
                 statusText = 'DESIRABLE';
                 statusColor = AppTheme.primaryGreen;
              }

              if (maxLdl != null && r.ldl != null && r.ldl! > maxLdl) {
                statusText = 'HIGH LDL';
                statusColor = AppTheme.errorColor;
              } else if (maxTotal != null && r.total != null && r.total! > maxTotal) {
                statusText = 'HIGH TOTAL';
                statusColor = AppTheme.errorColor;
              } else if (maxTri != null && r.triglycerides != null && r.triglycerides! > maxTri) {
                statusText = 'HIGH TRI';
                statusColor = AppTheme.errorColor;
              } else if (minHdl != null && r.hdl != null && r.hdl! < minHdl) {
                statusText = 'RISK HDL';
                statusColor = AppTheme.errorColor;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.midnightSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Top Row: Total Value + Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Total Value
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              r.total != null ? r.total!.toInt().toString() : (r.ldl != null ? r.ldl!.toInt().toString() : '--'),
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 20,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              r.total != null ? 'Total mg/dL' : 'LDL mg/dL',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                        // Right: Status & Date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('dd/MM/yy HH:mm').format(r.timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  
                    const SizedBox(height: 12),
                  
                    // Bottom Row: Detailed Breakdown
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black12 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniValue('LDL', r.ldl, _getStatusColor(r.ldl, MonitorDataType.CHOLESTEROL_LDL)),
                          _ContainerDivider(),
                          _MiniValue('HDL', r.hdl, _getStatusColor(r.hdl, MonitorDataType.CHOLESTEROL_HDL)),
                          _ContainerDivider(),
                          _MiniValue('Triglycerides', r.triglycerides, _getStatusColor(r.triglycerides, MonitorDataType.CHOLESTEROL_TRIGLYCERIDES)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MiniValue extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;

  const _MiniValue(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value != null ? '${value!.toInt()}' : '--',
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
            ),
            if (value != null) ...[
              const SizedBox(width: 2),
              Text(
                'mg/dL',
                style: TextStyle(fontSize: 9, color: AppTheme.textSecondaryColor),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ContainerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20, 
      width: 1, 
      color: AppTheme.getBorderColor(context).withOpacity(0.5)
    );
  }
}

// ============================================================================
// HELPERS
// ============================================================================

class _CholesterolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget child;

  const _CholesterolCard({
    required this.title,
    required this.icon,
    required this.infoText,
    required this.child,
  });

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title, 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(infoText, style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () => _showInfoDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, 
          height: 12, 
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
      ],
    );
  }
}
```

florence\platform_service\lib\features\patient\dashboard\screens\glucose_detail_screen.dart
```
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class GlucoseDetailScreen extends ConsumerWidget {
  final int patientId;

  const GlucoseDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glucoseAsync = ref.watch(monitorDataProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);
    final dailyLogsAsync = ref.watch(dailyPatientLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Glucose Analytics'),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.getBorderColor(context),
            height: 1.0,
          ),
        ),
      ),
      body: glucoseAsync.when(
        data: (dataList) {
          return dailyLogsAsync.when(
            data: (mealLogs) {
              // 1. Global Data Prep
              final directReadings = dataList
                  .where((d) => d.dataType == MonitorDataType.GLUCOSE)
                  .toList();

              // Convert meal log glucose entries to MonitorData ONLY if time exists
              final mealReadings = <MonitorData>[];
              for (var meal in mealLogs) {
                if (meal.glucoseBeforeMeal != null && meal.glucoseBeforeMealTime != null) {
                  mealReadings.add(MonitorData(
                    id: -1 * meal.id, // Negative ID to differentiate
                    patientId: 0,
                    dataType: MonitorDataType.GLUCOSE,
                    value: meal.glucoseBeforeMeal!,
                    measuredAt: meal.glucoseBeforeMealTime!,
                  ));
                }
                
                if (meal.glucoseAfterMeal != null && meal.glucoseAfterMealTime != null) {
                  mealReadings.add(MonitorData(
                    id: (-1 * meal.id) - 1,
                    patientId: 0,
                    dataType: MonitorDataType.GLUCOSE,
                    value: meal.glucoseAfterMeal!,
                    measuredAt: meal.glucoseAfterMealTime!,
                  ));
                }
              }

              final allReadings = [...directReadings, ...mealReadings];

              // Sort ascending for charts logic (Timeline needs X-axis increasing)
              allReadings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

              final thresholds = thresholdsAsync.value ?? [];
              
              // Check if user actually has a set threshold
              HealthThreshold? userThreshold;
              try {
                userThreshold = thresholds.firstWhere((t) => t.dataType == MonitorDataType.GLUCOSE);
              } catch (_) {}

              final isDefault = userThreshold == null;
              
              // Use user's threshold or safe default
              final effectiveThreshold = userThreshold;

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    ref.refresh(monitorDataProvider.future),
                    ref.refresh(patientThresholdsProvider.future),
                    ref.refresh(dailyPatientLogsProvider.future),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Statistics
                    _StatisticsSection(
                      readings: allReadings, 
                      threshold: effectiveThreshold,
                      isDefault: isDefault,
                    ),
                    const SizedBox(height: 20),

                    // 2. Annotated Line Chart
                    _GlucoseTrendsSection(
                      allReadings: allReadings,
                      threshold: effectiveThreshold,
                      isDefault: isDefault,
                    ),
                    const SizedBox(height: 20),

                    // 3. Time in Range
                    _TimeInRangeSection(
                      allReadings: allReadings,
                      threshold: effectiveThreshold,
                      isDefault: isDefault,
                    ),
                    const SizedBox(height: 20),

                    // 4. Modal Day
                    _ModalDaySection(
                      allReadings: allReadings,
                      threshold: effectiveThreshold,
                      isDefault: isDefault,
                    ),
                    const SizedBox(height: 20),

                    // 5. History List
                    _HistorySection(
                      allReadings: allReadings, // Pass sorted list, we will reverse it inside
                      thresholds: thresholds,
                    ),
                    
                    // Bottom Spacing to match Dashboard
                    const SizedBox(height: 24),
                  ],
                ),
              ));
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading logs: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading glucose: $err')),
      ),
    );
  }
}

/// Reusable Wrapper with Styled Info
class _ChartSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget Function(String range, List<MonitorData> filteredData) builder;
  final List<MonitorData> allData;
  final List<String> ranges; // Internal keys: 1D, 7D, 14D, 30D

  const _ChartSection({
    required this.title,
    required this.icon,
    required this.infoText,
    required this.builder,
    required this.allData,
    this.ranges = const ['1D', '7D', '14D', '30D'],
  });

  @override
  State<_ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<_ChartSection> {
  late String _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.ranges.contains('7D') ? '7D' : widget.ranges.first;
    if (widget.ranges.contains('1D')) _selectedRange = '1D';
  }

  List<MonitorData> _filterData() {
    if (widget.allData.isEmpty) return [];
    final now = DateTime.now();
    Duration duration;
    switch (_selectedRange) {
      case '7D': duration = const Duration(days: 7); break;
      case '14D': duration = const Duration(days: 14); break;
      case '30D': duration = const Duration(days: 30); break;
      case '1D':
      default: duration = const Duration(hours: 24); break;
    }
    final cutoff = now.subtract(duration);
    return widget.allData.where((d) => d.measuredAt.isAfter(cutoff)).toList();
  }

  String _getRangeLabel(String key) {
    switch (key) {
      case '1D': return 'Daily';
      case '7D': return 'Weekly';
      case '14D': return 'Bi-Weekly';
      case '30D': return 'Monthly';
      default: return key;
    }
  }

  void _showInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(widget.icon, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(widget.infoText, style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    final filteredData = _filterData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () => _showInfoDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Timeline Tabs
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: widget.ranges.map((range) {
                final isSelected = _selectedRange == range;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRange = range),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRangeLabel(range),
                        style: TextStyle(
                          fontSize: 11, // Smaller text to fit words
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                            ? Colors.white 
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Content
          widget.builder(_selectedRange, filteredData),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION 1: STATISTICS SUMMARY
// ============================================================================

class _StatisticsSection extends StatelessWidget {
  final List<MonitorData> readings;
  final HealthThreshold? threshold;
  final bool isDefault;

  const _StatisticsSection({
    required this.readings, 
    this.threshold,
    this.isDefault = false,
  });

  Map<String, dynamic> _calculateStats(List<MonitorData> data) {
    if (data.isEmpty) return {'avg': 0.0, 'gmi': 0.0, 'cv': 0.0};
    final values = data.map((e) => e.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - avg, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = math.sqrt(variance);
    final cv = (stdDev / avg) * 100;
    final gmi = 3.31 + (0.02392 * avg);
    return {'avg': avg, 'gmi': gmi, 'cv': cv};
  }

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Overview',
      icon: Icons.analytics_outlined,
      infoText: 'Key statistics derived from your glucose readings.\n\n'
                '• Average: Mean glucose level.\n'
                '• GMI: Glucose Management Indicator (Estimated A1c).\n'
                '• CV: Coefficient of Variation. Target < 36% for stable control.\n'
                '• Target: Your configured safe range.',
      allData: readings,
      builder: (range, data) {
        final stats = _calculateStats(data);
        return Column(
          children: [
            // Target Range Display
            InkWell(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.track_changes,
                              size: 18,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Target Range',
                              style: TextStyle(
                                color: AppTheme.primaryGreen.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppTheme.primaryGreen.withOpacity(0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (threshold != null)
                      _buildMiniTargetRow(
                        'Glucose',
                        '${threshold!.minValue.toInt()} - ${threshold!.maxValue.toInt()} mg/dL',
                        AppTheme.primaryGreen,
                      )
                    else
                      _buildMiniTargetRow(
                        'Glucose',
                        'Not Set',
                        AppTheme.textSecondaryColor,
                      ),
                  ],
                ),
              ),
            ),
            // Statistics Row
            Row(
              children: [
                Expanded(child: _buildStatBox(context, 'Average', '${(stats['avg'] as double).toStringAsFixed(0)}', 'mg/dL', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, 'GMI', '${(stats['gmi'] as double).toStringAsFixed(1)}', '%', Colors.purple)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, 'Variability', '${(stats['cv'] as double).toStringAsFixed(1)}', '%', threshold != null ? ((stats['cv'] as double) < 36 ? AppTheme.successColor : AppTheme.warningColor) : AppTheme.textSecondaryColor)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniTargetRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String title, String value, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 2),
              Text(unit, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION 2: ANNOTATED GLUCOSE TRENDS
// ============================================================================

class _GlucoseTrendsSection extends StatelessWidget {
  final List<MonitorData> allReadings;
  final HealthThreshold? threshold;
  final bool isDefault;

  const _GlucoseTrendsSection({
    required this.allReadings,
    this.threshold,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Glucose Trends',
      icon: Icons.show_chart,
      infoText: 'Visualizes your glucose readings over time.\n\n'
                '• Y-Axis: Glucose (mg/dL)\n'
                '• X-Axis: Time\n'
                '• Green Band: Readings within your target safe zone.',
      allData: allReadings,
      builder: (range, data) {
        // Determine X-Axis range
        double minX, maxX;
        if (data.isNotEmpty) {
          minX = data.first.measuredAt.millisecondsSinceEpoch.toDouble();
          maxX = data.last.measuredAt.millisecondsSinceEpoch.toDouble();
          if (minX == maxX) { minX -= 3600000; maxX += 3600000; }
        } else {
          // Default X range if no data
          final now = DateTime.now();
          Duration d = const Duration(hours: 24);
          if (range == '7D') d = const Duration(days: 7);
          else if (range == '14D') d = const Duration(days: 14);
          else if (range == '30D') d = const Duration(days: 30);
          minX = now.subtract(d).millisecondsSinceEpoch.toDouble();
          maxX = now.millisecondsSinceEpoch.toDouble();
        }

        // Determine Y-Axis range
        double minY = threshold != null ? (threshold!.minValue - 20).clamp(0, double.infinity) : 60;
        double maxY = threshold != null ? threshold!.maxValue + 40 : 200;
        
        if (data.isNotEmpty) {
          double dataMin = data.map((e) => e.value).reduce(math.min);
          double dataMax = data.map((e) => e.value).reduce(math.max);
          minY = math.min(minY, dataMin - 10);
          maxY = math.max(maxY, dataMax + 10);
        }

        // Snap to grid (50) to ensure equal spacing
        minY = (minY / 50).floor() * 50.0;
        maxY = (maxY / 50).ceil() * 50.0;
        if (maxY == minY) maxY += 50;

        // Centering Logic

        return Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: minX, maxX: maxX, minY: minY, maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                    getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, 
                        interval: (maxX - minX) / 4, 
                        getTitlesWidget: (val, _) {
                          if (val == minX || val == maxX) return const SizedBox(); // Hide start/end
                          final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                          final fmt = range == '1D' ? DateFormat('HH:mm') : DateFormat('MM/dd');
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(fmt.format(date), style: const TextStyle(fontSize: 9)));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  // 1. Safe Zone Background (Green Band)
                  rangeAnnotations: threshold != null ? RangeAnnotations(
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(
                        y1: threshold!.minValue, 
                        y2: threshold!.maxValue, 
                        color: AppTheme.primaryGreen.withOpacity(0.1)
                      )
                    ],
                  ) : null,
                  
                  // 2. Dotted Lines for Thresholds (Matches Trends)
                  extraLinesData: threshold != null ? ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(y: threshold!.minValue, color: AppTheme.primaryGreen.withOpacity(0.8), strokeWidth: 1, dashArray: [4, 4]),
                      HorizontalLine(y: threshold!.maxValue, color: AppTheme.primaryGreen.withOpacity(0.8), strokeWidth: 1, dashArray: [4, 4]),
                    ],
                  ) : null,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                      isCurved: true,
                      color: AppTheme.primaryBlue,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 3, // Visible dots
                          color: AppTheme.primaryBlue,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppTheme.primaryBlue.withOpacity(0.1), AppTheme.primaryBlue.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          const FlLine(color: AppTheme.textSecondaryColor, strokeWidth: 1),
                          FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppTheme.primaryBlue, strokeColor: Colors.white)),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toInt()}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (threshold != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12, runSpacing: 8, alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem('Safe Zone', AppTheme.primaryGreen.withOpacity(0.5), isBox: true),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  static Widget _emptyTitle(double value, TitleMeta meta) => const SizedBox.shrink();
}

// ============================================================================
// SECTION 3: TIME IN RANGE
// ============================================================================

class _TimeInRangeSection extends StatelessWidget {
  final List<MonitorData> allReadings;
  final HealthThreshold? threshold;
  final bool isDefault;

  const _TimeInRangeSection({
    required this.allReadings, 
    this.threshold,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Time in Range',
      icon: Icons.track_changes_outlined,
      infoText: 'Percentage of time your glucose is within target.\n\n'
                'Goal: Keep "In Range" (Green) above 70%.',
      allData: allReadings,
      builder: (range, data) {
        if (threshold == null) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Set target to view time in range.')));
        }

        final total = data.length;
        final lows = data.where((r) => r.value < threshold!.minValue).length;
        final highs = data.where((r) => r.value > threshold!.maxValue).length;
        final inRange = total - lows - highs;
        
        final lowPct = total > 0 ? (lows / total) * 100 : 0.0;
        final highPct = total > 0 ? (highs / total) * 100 : 0.0;
        final inPct = total > 0 ? (inRange / total) * 100 : 0.0;

        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 36,
                child: total == 0 
                  ? Container(color: Colors.grey.shade200) // Empty state
                  : Row(
                      children: [
                        if (lowPct > 0) Expanded(flex: (lowPct * 10).toInt(), child: Container(color: AppTheme.errorColor)),
                        if (inPct > 0) Expanded(flex: (inPct * 10).toInt(), child: Container(color: AppTheme.primaryGreen)),
                        if (highPct > 0) Expanded(flex: (highPct * 10).toInt(), child: Container(color: AppTheme.errorColor)),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTIRLegend(context, 'Low', lowPct, AppTheme.errorColor),
                _buildTIRLegend(context, 'In Range', inPct, AppTheme.primaryGreen, isBig: true),
                _buildTIRLegend(context, 'High', highPct, AppTheme.errorColor),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTIRLegend(BuildContext context, String label, double val, Color color, {bool isBig = false}) {
    return Column(
      children: [
        Text(
          '${val.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: isBig ? 20 : 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ============================================================================
// SECTION 4: MODAL DAY
// ============================================================================

class _ModalDaySection extends StatelessWidget {
  final List<MonitorData> allReadings;
  final HealthThreshold? threshold;
  final bool isDefault;

  const _ModalDaySection({
    required this.allReadings, 
    this.threshold,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Daily Patterns',
      icon: Icons.auto_graph_outlined,
      infoText: 'Overlays multiple days onto a single 24h axis to spot recurring patterns.\n\n'
                '• Y-Axis: Glucose (mg/dL)\n'
                '• X-Axis: Hour of day (0-24)\n'
                '• Green Band: Readings within your target safe zone.',
      allData: allReadings,
      builder: (range, data) {
        final Map<int, List<FlSpot>> lines = {};
        for (var r in data) {
          final key = r.measuredAt.day;
          final x = r.measuredAt.hour + (r.measuredAt.minute / 60.0);
          lines.putIfAbsent(key, () => []).add(FlSpot(x, r.value));
        }
        List<LineChartBarData> chartLines = [];
        lines.forEach((_, spots) {
          spots.sort((a, b) => a.x.compareTo(b.x));
          chartLines.add(LineChartBarData(
            spots: spots, 
            isCurved: true, 
            color: AppTheme.textSecondaryColor.withOpacity(0.3), 
            barWidth: 1.5, 
            dotData: const FlDotData(show: false)
          ));
        });

        // CRITICAL FIX: If no data, add an empty series to force chart lines/grid to render
        if (chartLines.isEmpty) {
          chartLines.add(LineChartBarData(
            spots: [], // No dummy points, just an empty series
            color: Colors.transparent,
          ));
        }

        return Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: 0, maxX: 24, minY: 40, maxY: 250,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true, // Enabled vertical grid
                    horizontalInterval: 50,
                    verticalInterval: 6,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                    getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    // Hide Y Axis Labels
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 6, getTitlesWidget: (v, _) {
                        if (v == 0 || v == 24) return const SizedBox(); // Hide first & last
                        return Text('${v.toInt()}:00', style: const TextStyle(fontSize: 9));
                      }),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    // Hide Right Axis Labels
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  rangeAnnotations: threshold != null ? RangeAnnotations(
                    horizontalRangeAnnotations: [HorizontalRangeAnnotation(y1: threshold!.minValue, y2: threshold!.maxValue, color: AppTheme.primaryGreen.withOpacity(0.1))],
                  ) : null,
                  extraLinesData: threshold != null ? ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(y: threshold!.minValue, color: AppTheme.primaryGreen.withOpacity(0.8), strokeWidth: 1, dashArray: [4, 4]),
                      HorizontalLine(y: threshold!.maxValue, color: AppTheme.primaryGreen.withOpacity(0.8), strokeWidth: 1, dashArray: [4, 4]),
                    ],
                  ) : null,
                  lineBarsData: chartLines,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Legend
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (threshold != null) ...[
                _buildLegendItem('Safe Zone', AppTheme.primaryGreen.withOpacity(0.5), isBox: true),
                const SizedBox(width: 12),
              ],
              _buildLegendItem('Daily Traces', AppTheme.textSecondaryColor, isDashed: false),
            ]),
          ],
        );
      },
    );
  }
}

// ============================================================================
// SECTION 5: HISTORY
// ============================================================================

class _HistorySection extends StatefulWidget {
  final List<MonitorData> allReadings;
  final List<HealthThreshold> thresholds;

  const _HistorySection({required this.allReadings, required this.thresholds});

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    // Data is passed sorted ASC by parent. Reverse it here for Latest First.
    final sortedReadings = widget.allReadings.reversed.toList();

    final totalItems = sortedReadings.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = sortedReadings.sublist(start, end);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24)),
                  const SizedBox(width: 12),
                  Text('History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              // Navigation arrows
              Row(children: [
                IconButton(onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null, icon: const Icon(Icons.chevron_left)),
                Text('${_currentPage + 1}/$totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null, icon: const Icon(Icons.chevron_right)),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          ...currentItems.map((item) {
            // Unique Status Logic for Glucose
            // LOW (< Min) = Critical/Red
            // HIGH (> Max) = Warning/Amber
            // NORMAL = Green
            
            String statusText;
            Color statusColor;
            
            // Get threshold from backend data (no fallback)
            HealthThreshold? t;
            try {
              t = widget.thresholds.firstWhere((t) => t.dataType == MonitorDataType.GLUCOSE);
            } catch (_) {}

            if (t != null) {
              if (item.value < t.minValue) {
                statusText = 'LOW';
                statusColor = AppTheme.errorColor;
              } else if (item.value > t.maxValue) {
                statusText = 'HIGH';
                statusColor = AppTheme.errorColor;
              } else {
                statusText = 'NORMAL';
                statusColor = AppTheme.primaryGreen;
              }
            } else {
              statusText = 'RECORDED';
              statusColor = AppTheme.primaryBlue;
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.midnightSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03), 
                    blurRadius: 8, 
                    offset: const Offset(0, 2)
                  )
                ],
                border: Border.all(
                  color: statusColor.withOpacity(0.3), 
                  width: 1
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Value
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        item.value.toStringAsFixed(0),
                        style: TextStyle(
                          fontWeight: FontWeight.normal, 
                          fontSize: 20,
                          color: AppTheme.textPrimaryColor
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'mg/dL', 
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12
                        )
                      ),
                    ],
                  ),
                  
                  // Right: Date and Status Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          statusText, 
                          style: TextStyle(
                            color: statusColor, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd/MM/yy HH:mm').format(item.measuredAt), 
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor
                        )
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// --- GLOBAL HELPERS ---

Widget _buildLegendItem(String label, Color color, {bool isBox = false, bool isDashed = false}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (isBox)
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))
      else if (isDashed)
        Container(width: 2, height: 12, color: color)
      else
        Container(width: 12, height: 2, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10)),
    ],
  );
}
```

florence\platform_service\lib\features\patient\logging\screens\log_bmi_screen.dart
```
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';

/// Log BMI Screen
class LogBmiScreen extends StatefulWidget {
  const LogBmiScreen({super.key});

  @override
  State<LogBmiScreen> createState() => _LogBmiScreenState();
}

class _LogBmiScreenState extends State<LogBmiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  double? _calculatedBmi;

  @override
  void initState() {
    super.initState();
    _heightController.addListener(_calculateBmi);
    _weightController.addListener(_calculateBmi);
  }

  @override
  void dispose() {
    _heightController.removeListener(_calculateBmi);
    _weightController.removeListener(_calculateBmi);
    _heightController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateBmi() {
    final heightCm = double.tryParse(_heightController.text);
    final weightKg = double.tryParse(_weightController.text);

    if (heightCm != null && heightCm > 0 && weightKg != null && weightKg > 0) {
      final heightM = heightCm / 100;
      setState(() {
        _calculatedBmi = weightKg / (heightM * heightM);
      });
    } else {
      setState(() {
        _calculatedBmi = null;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _calculatedBmi == null) {
      if (_calculatedBmi == null) {
        Helpers.showError(context, 'Please enter valid height and weight to calculate BMI.');
      }
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);

    try {
      await _apiService.post('/patients/me/monitor-data', {
        'data_type': 'BMI',
        'value': _calculatedBmi,
        'measured_at': _selectedDateTime.toIso8601String(),
      });

      if (mounted) {
        Helpers.showSuccess(context, 'BMI logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log BMI: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log BMI'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildInputSection(),
              const SizedBox(height: 24),
              if (_calculatedBmi != null) ...[
                _buildBmiResultCard(),
                const SizedBox(height: 24),
              ],
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Save Reading',
                onPressed: (_isLoading || _calculatedBmi == null) ? null : _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return const BaseCard(
      child: Row(
        children: [
          Icon(Icons.height, color: AppTheme.primaryGreen, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Body Mass Index (BMI) is a measure of body fat based on height and weight.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Measurements',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Height (cm)',
                  hint: 'e.g., 175',
                  controller: _heightController,
                  validator: (value) =>
                      Validators.minLength(value, 1, fieldName: 'Height'),
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.height),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Weight (kg)',
                  hint: 'e.g., 70',
                  controller: _weightController,
                  validator: (value) =>
                      Validators.minLength(value, 1, fieldName: 'Weight'),
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.scale),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBmiResultCard() {
    final bmiCategory = Helpers.getBMICategory(_calculatedBmi!);
    return BaseCard(
      child: Column(
        children: [
          Text(
            'Your BMI',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _calculatedBmi!.toStringAsFixed(1),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            bmiCategory,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Measurement Date',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Formatters.date(_selectedDateTime),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return CustomTextField(
      label: 'Notes (Optional)',
      hint: 'e.g., Morning measurement',
      controller: _notesController,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
}
```

florence\platform_service\lib\features\patient\trends\screens\meal_impact_screen.dart
```
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';

/// Meal Impact Analysis Screen
/// Shows how different foods affect glucose levels
class MealImpactScreen extends StatefulWidget {
  const MealImpactScreen({super.key});

  @override
  State<MealImpactScreen> createState() => _MealImpactScreenState();
}

class _MealImpactScreenState extends State<MealImpactScreen> {
  bool _isLoading = false;
  String _selectedMealType = 'All';

  // Meal type filter options
  final List<String> _mealTypes = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  // Mock meal impact data
  List<MealImpact> _allMealImpacts = [];
  List<MealImpact> _filteredMealImpacts = [];

  @override
  void initState() {
    super.initState();
    _loadMealImpactData();
  }

  /// Load meal impact data
  Future<void> _loadMealImpactData() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Load real data from Supabase
      // For now, generate mock data
      _generateMockMealData();

      // Filter by meal type
      _filterMealsByType();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error loading meal impact data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Generate mock meal impact data
  void _generateMockMealData() {
    _allMealImpacts = [
      // Breakfast foods
      MealImpact(
        foodName: 'Oatmeal with Berries',
        mealType: 'Breakfast',
        beforeGlucose: 95,
        afterGlucose: 125,
        glucoseSpike: 30,
        frequency: 12,
        averageCarbs: 45,
      ),
      MealImpact(
        foodName: 'Scrambled Eggs & Toast',
        mealType: 'Breakfast',
        beforeGlucose: 92,
        afterGlucose: 110,
        glucoseSpike: 18,
        frequency: 15,
        averageCarbs: 25,
      ),
      MealImpact(
        foodName: 'Pancakes with Syrup',
        mealType: 'Breakfast',
        beforeGlucose: 88,
        afterGlucose: 175,
        glucoseSpike: 87,
        frequency: 3,
        averageCarbs: 85,
      ),
      MealImpact(
        foodName: 'Greek Yogurt with Nuts',
        mealType: 'Breakfast',
        beforeGlucose: 90,
        afterGlucose: 105,
        glucoseSpike: 15,
        frequency: 10,
        averageCarbs: 20,
      ),

      // Lunch foods
      MealImpact(
        foodName: 'Grilled Chicken Salad',
        mealType: 'Lunch',
        beforeGlucose: 102,
        afterGlucose: 118,
        glucoseSpike: 16,
        frequency: 18,
        averageCarbs: 15,
      ),
      MealImpact(
        foodName: 'Turkey Sandwich (Whole Wheat)',
        mealType: 'Lunch',
        beforeGlucose: 98,
        afterGlucose: 135,
        glucoseSpike: 37,
        frequency: 14,
        averageCarbs: 40,
      ),
      MealImpact(
        foodName: 'Pasta with Marinara',
        mealType: 'Lunch',
        beforeGlucose: 105,
        afterGlucose: 182,
        glucoseSpike: 77,
        frequency: 5,
        averageCarbs: 75,
      ),
      MealImpact(
        foodName: 'Quinoa Bowl with Veggies',
        mealType: 'Lunch',
        beforeGlucose: 100,
        afterGlucose: 128,
        glucoseSpike: 28,
        frequency: 8,
        averageCarbs: 35,
      ),

      // Dinner foods
      MealImpact(
        foodName: 'Salmon with Broccoli',
        mealType: 'Dinner',
        beforeGlucose: 108,
        afterGlucose: 122,
        glucoseSpike: 14,
        frequency: 16,
        averageCarbs: 10,
      ),
      MealImpact(
        foodName: 'Steak with Sweet Potato',
        mealType: 'Dinner',
        beforeGlucose: 112,
        afterGlucose: 145,
        glucoseSpike: 33,
        frequency: 10,
        averageCarbs: 30,
      ),
      MealImpact(
        foodName: 'Pizza (2 slices)',
        mealType: 'Dinner',
        beforeGlucose: 110,
        afterGlucose: 195,
        glucoseSpike: 85,
        frequency: 4,
        averageCarbs: 70,
      ),
      MealImpact(
        foodName: 'Stir-fry with Brown Rice',
        mealType: 'Dinner',
        beforeGlucose: 105,
        afterGlucose: 138,
        glucoseSpike: 33,
        frequency: 12,
        averageCarbs: 45,
      ),

      // Snacks
      MealImpact(
        foodName: 'Apple with Almond Butter',
        mealType: 'Snack',
        beforeGlucose: 95,
        afterGlucose: 108,
        glucoseSpike: 13,
        frequency: 20,
        averageCarbs: 20,
      ),
      MealImpact(
        foodName: 'Protein Bar',
        mealType: 'Snack',
        beforeGlucose: 102,
        afterGlucose: 125,
        glucoseSpike: 23,
        frequency: 15,
        averageCarbs: 25,
      ),
      MealImpact(
        foodName: 'Chocolate Cookies',
        mealType: 'Snack',
        beforeGlucose: 98,
        afterGlucose: 165,
        glucoseSpike: 67,
        frequency: 6,
        averageCarbs: 55,
      ),
      MealImpact(
        foodName: 'Carrot Sticks with Hummus',
        mealType: 'Snack',
        beforeGlucose: 100,
        afterGlucose: 110,
        glucoseSpike: 10,
        frequency: 18,
        averageCarbs: 12,
      ),
    ];

    // Sort by glucose spike (ascending)
    _allMealImpacts.sort((a, b) => a.glucoseSpike.compareTo(b.glucoseSpike));
  }

  /// Filter meals by selected type
  void _filterMealsByType() {
    if (_selectedMealType == 'All') {
      _filteredMealImpacts = List.from(_allMealImpacts);
    } else {
      _filteredMealImpacts = _allMealImpacts
          .where((meal) => meal.mealType == _selectedMealType)
          .toList();
    }
  }

  /// Change meal type filter
  void _changeMealType(String mealType) {
    setState(() {
      _selectedMealType = mealType;
      _filterMealsByType();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bestFoods = _filteredMealImpacts.take(5).toList();
    final worstFoods = _filteredMealImpacts.reversed.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Impact Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog();
            },
            tooltip: 'Information',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMealImpactData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Meal type filter
                    _buildMealTypeFilter(),
                    const SizedBox(height: 24),

                    // Summary stats
                    _buildSummaryStats(),
                    const SizedBox(height: 24),

                    // Before/After comparison chart
                    _buildComparisonChart(),
                    const SizedBox(height: 24),

                    // Best foods section
                    _buildBestFoodsSection(bestFoods),
                    const SizedBox(height: 24),

                    // Worst foods section
                    _buildWorstFoodsSection(worstFoods),
                    const SizedBox(height: 24),

                    // Complete food ranking
                    _buildCompleteRanking(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build meal type filter
  Widget _buildMealTypeFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _mealTypes.length,
        itemBuilder: (context, index) {
          final mealType = _mealTypes[index];
          final isSelected = mealType == _selectedMealType;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(mealType),
              selected: isSelected,
              onSelected: (_) => _changeMealType(mealType),
              selectedColor: AppTheme.primaryBlue,
              backgroundColor: AppTheme.backgroundColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build summary statistics
  Widget _buildSummaryStats() {
    final avgSpike = _filteredMealImpacts.isEmpty
        ? 0.0
        : _filteredMealImpacts
                .map((m) => m.glucoseSpike)
                .reduce((a, b) => a + b) /
            _filteredMealImpacts.length;

    final totalMeals = _filteredMealImpacts.length;
    final goodMeals =
        _filteredMealImpacts.where((m) => m.glucoseSpike <= 30).length;
    final badMeals =
        _filteredMealImpacts.where((m) => m.glucoseSpike > 50).length;

    return BaseCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            'Avg Spike',
            '${avgSpike.toStringAsFixed(0)} mg/dL',
            Icons.trending_up,
            AppTheme.infoColor,
          ),
          _buildStatColumn(
            'Total Meals',
            totalMeals.toString(),
            Icons.restaurant,
            AppTheme.textPrimaryColor,
          ),
          _buildStatColumn(
            'Good Choices',
            goodMeals.toString(),
            Icons.check_circle,
            AppTheme.successColor,
          ),
          _buildStatColumn(
            'Need Caution',
            badMeals.toString(),
            Icons.warning,
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build before/after comparison chart
  Widget _buildComparisonChart() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before vs After Glucose',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'How your glucose changes after eating',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: ResponsiveHelper.getResponsiveCardChartHeight(context),
            child: _filteredMealImpacts.isEmpty
                ? Center(
                    child: Text(
                      'No meal data for this category',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 220,
                      minY: 0,
                      groupsSpace: 12,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final meal = _filteredMealImpacts[group.x.toInt()];
                            final isBefore = rodIndex == 0;
                            return BarTooltipItem(
                              '${meal.foodName}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: isBefore
                                      ? 'Before: ${meal.beforeGlucose} mg/dL'
                                      : 'After: ${meal.afterGlucose} mg/dL',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) => const SizedBox.shrink(),
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= _filteredMealImpacts.length) {
                                return const SizedBox();
                              }
                              final meal = _filteredMealImpacts[value.toInt()];
                              final words = meal.foodName.split(' ');
                              final shortName = words.length > 2
                                  ? '${words[0]} ${words[1]}'
                                  : meal.foodName;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  shortName,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.borderColor,
                            strokeWidth: 1,
                          );
                        },
                        drawVerticalLine: false,
                      ),
                      barGroups: _filteredMealImpacts
                          .take(8) // Show only first 8 for readability
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final meal = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: meal.beforeGlucose.toDouble(),
                              color: AppTheme.infoColor,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: meal.afterGlucose.toDouble(),
                              color: _getGlucoseSpikeColor(meal.glucoseSpike),
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Before', AppTheme.infoColor),
              const SizedBox(width: 24),
              _buildLegendItem('After (Good)', AppTheme.successColor),
              const SizedBox(width: 24),
              _buildLegendItem('After (High)', AppTheme.errorColor),
            ],
          ),
        ],
      ),
    );
  }

  /// Build best foods section
  Widget _buildBestFoodsSection(List<MealImpact> bestFoods) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.thumb_up,
                  color: AppTheme.successColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best Choices',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Foods with minimal glucose impact',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...bestFoods.map((meal) => _buildFoodRankingCard(meal, true)),
        ],
      ),
    );
  }

  /// Build worst foods section
  Widget _buildWorstFoodsSection(List<MealImpact> worstFoods) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.thumb_down,
                  color: AppTheme.errorColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Caution',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Foods causing large glucose spikes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...worstFoods.map((meal) => _buildFoodRankingCard(meal, false)),
        ],
      ),
    );
  }

  /// Build complete ranking section
  Widget _buildCompleteRanking() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Food Ranking',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'All foods sorted by glucose impact',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ..._filteredMealImpacts.map((meal) {
            final rank = _filteredMealImpacts.indexOf(meal) + 1;
            return _buildCompactFoodCard(meal, rank);
          }),
        ],
      ),
    );
  }

  /// Build food ranking card
  Widget _buildFoodRankingCard(MealImpact meal, bool isGood) {
    final color = isGood ? AppTheme.successColor : AppTheme.errorColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${meal.glucoseSpike.toInt()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${meal.beforeGlucose} → ${meal.afterGlucose} mg/dL',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${meal.averageCarbs}g carbs • Eaten ${meal.frequency}x',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            isGood ? Icons.trending_down : Icons.trending_up,
            color: color,
          ),
        ],
      ),
    );
  }

  /// Build compact food card for complete ranking
  Widget _buildCompactFoodCard(MealImpact meal, int rank) {
    final color = _getGlucoseSpikeColor(meal.glucoseSpike);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${meal.mealType} • ${meal.averageCarbs}g carbs',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+${meal.glucoseSpike}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Get color based on glucose spike
  Color _getGlucoseSpikeColor(int spike) {
    if (spike <= 30) return AppTheme.successColor;
    if (spike <= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  /// Show information dialog
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Meal Impact'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This analysis shows how different foods affect your glucose levels.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Glucose Spike: The difference between your glucose level before and after eating.'),
              SizedBox(height: 8),
              Text('Good Choices: Foods causing spikes of 30 mg/dL or less.'),
              SizedBox(height: 8),
              Text('Need Caution: Foods causing spikes over 50 mg/dL.'),
              SizedBox(height: 12),
              Text(
                'Use this information to make better food choices and maintain stable glucose levels.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Meal Impact Data Model
class MealImpact {
  final String foodName;
  final String mealType;
  final int beforeGlucose;
  final int afterGlucose;
  final int glucoseSpike;
  final int frequency;
  final int averageCarbs;

  MealImpact({
    required this.foodName,
    required this.mealType,
    required this.beforeGlucose,
    required this.afterGlucose,
    required this.glucoseSpike,
    required this.frequency,
    required this.averageCarbs,
  });
}
```

florence\platform_service\lib\features\patient\logging\screens\log_cholesterol_screen.dart
```
import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';

/// Log Cholesterol Screen
class LogCholesterolScreen extends StatefulWidget {
  const LogCholesterolScreen({super.key});

  @override
  State<LogCholesterolScreen> createState() => _LogCholesterolScreenState();
}

class _LogCholesterolScreenState extends State<LogCholesterolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cholesterolController = TextEditingController();
  final _notesController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _cholesterolController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);

    try {
      await _apiService.post('/patients/me/monitor-data', {
        'data_type': 'CHOLESTEROL',
        'value': double.parse(_cholesterolController.text),
        'measured_at': _selectedDateTime.toIso8601String(),
      });

      if (mounted) {
        Helpers.showSuccess(context, 'Cholesterol logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log cholesterol: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Cholesterol'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildInputSection(),
              const SizedBox(height: 24),
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Save Reading',
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return const BaseCard(
      child: Row(
        children: [
          Icon(Icons.bloodtype, color: AppTheme.accentPurple, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keep track of your cholesterol levels for a healthy heart.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return BaseCard(
      child: CustomTextField(
        label: 'Total Cholesterol (mg/dL)',
        hint: 'e.g., 190',
        controller: _cholesterolController,
        validator: (value) =>
            Validators.minLength(value, 1, fieldName: 'Total Cholesterol'),
        keyboardType: TextInputType.number,
        prefixIcon: const Icon(Icons.bloodtype_outlined),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Date',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.accentPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Formatters.date(_selectedDateTime),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return CustomTextField(
      label: 'Notes (Optional)',
      hint: 'e.g., Fasting test',
      controller: _notesController,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
}
```

florence\platform_service\lib\features\patient\logging\screens\log_meal_screen.dart
```
import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';

/// Log Meal Screen
/// Allows users to record meals and food intake
class LogMealScreen extends StatefulWidget {
  const LogMealScreen({super.key});

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mealNameController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  String _selectedMealType = 'Breakfast';
  
  // Meal type options
  final List<Map<String, dynamic>> _mealTypeOptions = [
    {'name': 'Breakfast', 'icon': Icons.wb_sunny},
    {'name': 'Lunch', 'icon': Icons.wb_cloudy},
    {'name': 'Dinner', 'icon': Icons.nightlight},
    {'name': 'Snack', 'icon': Icons.cookie},
  ];
  
  @override
  void dispose() {
    _mealNameController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  /// Handle save
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);
    
    try {
      // TODO: Save to Supabase
      // await mealService.saveMeal({
      //   'name': _mealNameController.text.trim(),
      //   'meal_type': _selectedMealType,
      //   'carbs': double.tryParse(_carbsController.text),
      //   'protein': double.tryParse(_proteinController.text),
      //   'fat': double.tryParse(_fatController.text),
      //   'timestamp': _selectedDateTime.toIso8601String(),
      //   'notes': _notesController.text.trim(),
      // });
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Helpers.showSuccess(context, 'Meal logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log meal');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Show date time picker
  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      
      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  /// Calculate total calories
  int _calculateCalories() {
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;
    
    return ((carbs * 4) + (protein * 4) + (fat * 9)).round();
  }
  
  @override
  Widget build(BuildContext context) {
    final totalCalories = _calculateCalories();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Meal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Helpers.showInfo(context, 'Meal history coming soon');
            },
            tooltip: 'View History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              _buildInfoCard(),
              const SizedBox(height: 24),
              
              // Meal type selection
              _buildMealTypeSection(),
              const SizedBox(height: 24),
              
              // Meal name
              _buildMealNameSection(),
              const SizedBox(height: 24),
              
              // Date and time
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              
              // Macros section
              _buildMacrosSection(totalCalories),
              const SizedBox(height: 24),
              
              // Notes
              _buildNotesSection(),
              const SizedBox(height: 32),
              
              // Save button
              PrimaryButton(
                text: 'Save Meal',
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build info card
  Widget _buildInfoCard() {
    return BaseCard(
      // backgroundColor: AppTheme.mealColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.restaurant,
            color: AppTheme.mealColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Log your meals to understand how food affects your glucose',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mealColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build meal type section
  Widget _buildMealTypeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: _mealTypeOptions.map((option) {
              final isSelected = option['name'] == _selectedMealType;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedMealType = option['name']);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.mealColor
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.mealColor
                              : AppTheme.borderColor,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            option['icon'],
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondaryColor,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            option['name'],
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimaryColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  /// Build meal name section
  Widget _buildMealNameSection() {
    return CustomTextField(
      label: 'Meal Name',
      hint: 'e.g., Chicken rice, Oatmeal with fruits',
      controller: _mealNameController,
      validator: (value) => Validators.name(value, fieldName: 'Meal name'),
      textCapitalization: TextCapitalization.sentences,
      prefixIcon: const Icon(Icons.restaurant_menu),
    );
  }
  
  /// Build date time section
  Widget _buildDateTimeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date & Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: AppTheme.mealColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.date(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          Formatters.time(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build macros section
  Widget _buildMacrosSection(int totalCalories) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nutrition (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (totalCalories > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.mealColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalCalories kcal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mealColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Carbs (g)',
                  hint: '0',
                  controller: _carbsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Protein (g)',
                  hint: '0',
                  controller: _proteinController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Fat (g)',
                  hint: '0',
                  controller: _fatController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build notes section
  Widget _buildNotesSection() {
    return CustomTextField(
      label: 'Notes (Optional)',
      hint: 'How did you feel? Any reactions?',
      controller: _notesController,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
}
```

florence\platform_service\lib\features\patient\recommendations\screens\recommendations_screen.dart
```
import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import 'recommendation_detail_screen.dart';
import '../services/recommendation_engine.dart';
import '../models/recommendation_models.dart';

/// Health Insights Screen
/// Displays AI-generated health insights with explainability
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  bool _isLoading = false;
  bool _isGenerating = false;

  // Recommendation engine
  final RecommendationEngine _engine = RecommendationEngine();

  // Recommendations data
  List<HealthRecommendation> _insights = [];

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  /// Load insights
  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);

    try {
      // Get all cached recommendations from engine
      // For the insights view, we might want to show all active ones, or even history if relevant.
      // For now, let's show active ones as "Current Insights".
      final allRecs = _engine.allRecommendations;
      
      if (allRecs.isEmpty) {
        await _generateNewInsights();
      } else {
        _insights = allRecs.where((r) => r.isActive).toList();
      }
    } catch (e) {
      debugPrint('Error loading insights: $e');
      if (mounted) {
        Helpers.showError(context, 'Failed to load insights');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Generate new AI insights
  Future<void> _generateNewInsights() async {
    setState(() => _isGenerating = true);

    try {
      final newRecs = await _engine.generateRecommendations(daysToAnalyze: 7);

      if (mounted) {
        setState(() {
          _insights = _engine.allRecommendations.where((r) => r.isActive).toList();
        });

        if (newRecs.isNotEmpty) {
          Helpers.showSuccess(
            context,
            'Found ${newRecs.length} new insights',
          );
        }
      }
    } catch (e) {
      debugPrint('Error generating insights: $e');
      if (mounted) {
        Helpers.showError(context, 'Failed to generate insights');
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Insights'),
        actions: [
          IconButton(
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isGenerating
                ? null
                : () async {
                    await _generateNewInsights();
                  },
            tooltip: 'Refresh Insights',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _insights.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _generateNewInsights,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _insights.length,
                    itemBuilder: (context, index) {
                      return _buildInsightCard(_insights[index]);
                    },
                  ),
                ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No insights yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need more data to generate insights for you.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _generateNewInsights,
            child: const Text('Analyze Now'),
          ),
        ],
      ),
    );
  }

  /// Build insight card
  Widget _buildInsightCard(HealthRecommendation insight) {
    return BaseCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecommendationDetailScreen(recommendation: insight),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _buildCategoryIcon(insight.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      _formatTime(insight.generatedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ],
                ),
              ),
              if (insight.priority == RecommendationPriority.high || 
                  insight.priority == RecommendationPriority.urgent)
                _buildPriorityBadge(insight.priority),
            ],
          ),
          const SizedBox(height: 16),

          // Main Description
          Text(
            insight.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),

          // Explainability Section (Why this matters)
          if (insight.explanation != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Why this insight?',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight.explanation!.rationale,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (insight.explanation!.expectedImpact.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, size: 16, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight.explanation!.expectedImpact,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build category icon
  Widget _buildCategoryIcon(RecommendationCategory category) {
    final config = _getCategoryConfig(category);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        config['icon'],
        color: config['color'],
        size: 24,
      ),
    );
  }

  /// Build priority badge
  Widget _buildPriorityBadge(RecommendationPriority priority) {
    final config = _getPriorityConfig(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config['color']),
      ),
      child: Text(
        config['label'],
        style: TextStyle(
          color: config['color'],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Get category configuration
  Map<String, dynamic> _getCategoryConfig(RecommendationCategory category) {
    switch (category) {
      case RecommendationCategory.meal:
        return {'icon': Icons.restaurant, 'color': AppTheme.mealColor};
      case RecommendationCategory.activity:
        return {'icon': Icons.directions_run, 'color': AppTheme.activityColor};
      case RecommendationCategory.sleep:
        return {'icon': Icons.bedtime, 'color': const Color(0xFF9C27B0)};
      case RecommendationCategory.timing:
        return {'icon': Icons.access_time, 'color': AppTheme.primaryBlue};
      case RecommendationCategory.lifestyle:
        return {'icon': Icons.self_improvement, 'color': const Color(0xFF00BCD4)};
      case RecommendationCategory.medication:
        return {'icon': Icons.medication, 'color': AppTheme.medicationColor};
    }
  }

  /// Get priority configuration
  Map<String, dynamic> _getPriorityConfig(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.urgent:
        return {'label': 'URGENT', 'color': const Color(0xFFD32F2F)};
      case RecommendationPriority.high:
        return {'label': 'IMPORTANT', 'color': AppTheme.warningColor};
      case RecommendationPriority.medium:
        return {'label': 'MEDIUM', 'color': AppTheme.infoColor};
      case RecommendationPriority.low:
        return {'label': 'LOW', 'color': AppTheme.textSecondaryColor};
    }
  }

  /// Format time
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return Formatters.date(time);
  }
}```

florence\platform_service\lib\features\patient\chat\screens\chat_screen.dart
```
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../core/config/environment.dart';
import '../services/chatbot_service.dart';
import '../models/chat_message.dart';

/// Chat Screen - AI Health Assistant
/// Conversational interface for health questions and guidance
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatbotService = ChatbotService(); // Uses the singleton instance
  
  bool _isTyping = false;

  // Suggested questions
  final List<String> _suggestedQuestions = [
    "How is my glucose trending?",
    "Any insights on my sleep?",
    "What should I eat for lunch?",
    "Am I meeting my activity goals?",
  ];
  
  @override
  void initState() {
    super.initState();
    // Listen to service updates (e.g. when background messages arrive)
    _chatbotService.addListener(_onServiceUpdate);
    
    // Initialize typing state based on current messages
    // If the last message is from the user, it means we are waiting for AI response
    if (_chatbotService.messages.isNotEmpty) {
      _isTyping = _chatbotService.messages.last.isUser;
    }
    
    _initializeChat();
  }

  @override
  void dispose() {
    _chatbotService.removeListener(_onServiceUpdate);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Called whenever the service notifies of changes
  void _onServiceUpdate() {
    if (mounted) {
      setState(() {
        // The UI rebuilds using _chatbotService.messages directly
        // We check if the last message is from user to determine typing state
        if (_chatbotService.messages.isNotEmpty) {
          _isTyping = _chatbotService.messages.last.isUser;
        } else {
          _isTyping = false;
        }
      });
      
      // Scroll to bottom on new messages if not loading
      if (_chatbotService.messages.isNotEmpty && 
          !_chatbotService.isLoadingHistory && 
          !_chatbotService.isClearingHistory) {
        _scrollToBottom();
      }
    }
  }

  /// Initialize chat: check cache or fetch history
  Future<void> _initializeChat() async {
    // If not loaded and not currently loading, trigger load
    if (!_chatbotService.hasLoadedHistory && !_chatbotService.isLoadingHistory) {
      await _loadHistory();
    }
  }

  /// Load chat history from service
  Future<void> _loadHistory() async {
    try {
      await _chatbotService.loadHistory();
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to sync chat history');
      }
    }
  }

  /// Confirm and clear history
  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to delete all chat history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatbotService.clearHistory();
        if (mounted) {
          Helpers.showInfo(context, 'Chat history cleared');
        }
      } catch (e) {
        if (mounted) {
          Helpers.showError(context, 'Failed to clear history');
        }
      }
    }
  }
  
  /// Send message
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final messageText = text.trim();
    _messageController.clear();

    // We don't manually add to a local list anymore.
    // We call the service, which updates its list and notifies us.
    
    try {
      await _chatbotService.sendMessage(messageText);
    } catch (e) {
      if (mounted) {
        // The service has already removed the message from the list
        Helpers.showError(context, "Failed to send message. Please try again.");
      }
    }
  }

  /// Scroll to bottom
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  /// Send suggested question
  void _sendSuggestedQuestion(String question) {
    _messageController.text = question;
    _sendMessage(question);
  }
  
  /// Show info dialog
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Health Assistant'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your AI assistant can help you:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('✓ Understand glucose patterns'),
              Text('✓ Get meal recommendations'),
              Text('✓ Receive activity suggestions'),
              Text('✓ Interpret your health data'),
              Text('✓ Get personalized insights'),
              SizedBox(height: 16),
              Text(
                'Note: This is an AI assistant. Always consult your healthcare provider for medical decisions.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final messages = _chatbotService.messages;
    final isLoading = _chatbotService.isLoadingHistory;
    final isClearing = _chatbotService.isClearingHistory;
    
    final showLoading = isLoading || isClearing;
    final loadingText = isClearing 
        ? 'Clearing conversation history...' 
        : 'Syncing conversation history...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: showLoading ? null : _confirmClearHistory,
            tooltip: 'Clear History',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'About AI Assistant',
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggested questions (only show if history is empty and not loading)
          if (!showLoading && messages.isEmpty) 
            _buildSuggestedQuestions(),
          
          // Chat messages area
          Expanded(
            child: showLoading
                ? _buildLoadingState(loadingText)
                : messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(messages),
          ),
          
          // Typing indicator
          if (_isTyping && !showLoading) _buildTypingIndicator(),
          
          // Input area
          _buildInputArea(isEnabled: !showLoading),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build suggested questions
  Widget _buildSuggestedQuestions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Suggested questions:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestedQuestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(_suggestedQuestions[index]),
                    onPressed: () => _sendSuggestedQuestion(
                      _suggestedQuestions[index],
                    ),
                    backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about your health!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }
  
  /// Build messages list
  Widget _buildMessagesList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _buildMessageBubble(message);
      },
    );
  }
  
  /// Build single message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primaryBlue
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
              ),
              child: MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: message.isUser
                            ? Colors.white
                            : AppTheme.textPrimaryColor,
                        height: 1.4,
                      ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: message.isUser
                        ? Colors.white
                        : AppTheme.textPrimaryColor,
                  ),
                  listBullet: TextStyle(
                    color: message.isUser
                        ? Colors.white
                        : AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build typing indicator
  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build single typing dot
  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.3 + (0.7 * value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.textSecondaryColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
  
  /// Build input area
  Widget _buildInputArea({required bool isEnabled}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: SafeArea(
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: AbsorbPointer(
            absorbing: !isEnabled,
            child: Row(
              children: [
                // Text input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: isEnabled ? 'Ask me anything...' : 'Connecting...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: _sendMessage,
                          ),
                        ),
                        // Microphone button (placeholder)
                        IconButton(
                          icon: Icon(
                            Icons.mic_outlined,
                            color: AppTheme.textSecondaryColor,
                          ),
                          onPressed: () {
                            Helpers.showInfo(context, 'Voice input coming soon');
                          },
                          tooltip: 'Voice input',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Send button
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_messageController.text),
                    tooltip: 'Send',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Format timestamp
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
```

florence\platform_service\lib\features\patient\chat\models\chat_message.dart
```
class ChatMessage {
  final String? id;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  ChatMessage({
    this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.context,
  });

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? json['message_id'], // Handle both DB and API response formats
      role: json['role'] ?? 'system',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      context: json['context'] ?? json['context_used'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }
}
```

florence\platform_service\lib\features\patient\chat\services\chatbot_service.dart
```
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/environment.dart';
import '../models/chat_message.dart';

class ChatbotService extends ChangeNotifier {
  // Singleton pattern to persist state across screen rebuilds
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();

  final String _baseUrl = Environment.chatbotServiceUrl;
  final SupabaseClient _supabase = Supabase.instance.client;

  // In-memory cache
  final List<ChatMessage> _messages = [];
  bool _hasLoadedHistory = false;
  
  // Operation states
  bool _isLoadingHistory = false;
  bool _isClearingHistory = false;

  /// Get read-only view of cached messages
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  
  /// Check if history has been fetched in this session
  bool get hasLoadedHistory => _hasLoadedHistory;
  
  /// Check if history is currently loading
  bool get isLoadingHistory => _isLoadingHistory;
  
  /// Check if history is currently being cleared
  bool get isClearingHistory => _isClearingHistory;

  /// Get headers with the current user's JWT
  Map<String, String> _getHeaders() {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('User not authenticated');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  /// Send a message to the Python Chatbot Service
  /// Updates the local cache with both the user's message and the AI's response
  Future<void> sendMessage(String message) async {
    // 1. Optimistically add user message to cache
    final userMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    notifyListeners(); // Update UI immediately

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/message'),
        headers: _getHeaders(),
        body: jsonEncode({
          'message': message,
          'include_history': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMsg = ChatMessage.fromJson(data);
        
        // 2. Add AI response to cache
        _messages.add(aiMsg);
        notifyListeners(); // Update UI with response
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      // On failure, remove the optimistic message so the user knows it failed
      // (or in a more advanced app, mark it as 'error')
      _messages.remove(userMsg);
      notifyListeners(); // Update UI to remove failed message
      throw Exception('Error communicating with chatbot service: $e');
    }
  }

  /// Retrieve conversation history from the Python Chatbot Service
  /// Populates the local cache
  Future<void> loadHistory({int limit = 50}) async {
    // If we already loaded history, just notify listeners to ensure UI is synced
    if (_hasLoadedHistory) {
      notifyListeners();
      return;
    }
    
    // Prevent concurrent loads
    if (_isLoadingHistory) return;

    _isLoadingHistory = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/history?limit=$limit'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesJson = data['messages'];
        
        _messages.clear();
        _messages.addAll(
          messagesJson.map((json) => ChatMessage.fromJson(json)).toList(),
        );
        
        _hasLoadedHistory = true;
      } else {
        throw Exception('Failed to load history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading chat history: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Clear conversation history
  Future<void> clearHistory() async {
    if (_isClearingHistory) return;

    _isClearingHistory = true;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/chat/history'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        _messages.clear();
      } else {
        throw Exception('Failed to clear history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error clearing history: $e');
    } finally {
      _isClearingHistory = false;
      notifyListeners();
    }
  }

  /// Reset session state (clears local cache without API call)
  void resetSession() {
    _messages.clear();
    _hasLoadedHistory = false;
    _isLoadingHistory = false;
    _isClearingHistory = false;
    notifyListeners();
  }

  /// Invalidate context (used by PatientProfileService)
  void invalidateContext() {
    resetSession();
  }
}
```

florence\platform_service\lib\features\patient\recommendations\models\recommendation_models.dart
```
/// Recommendation Models for FLORENCE Digital Health Platform
/// AI-generated health recommendations with explainability

import 'package:flutter/foundation.dart';

/// Recommendation category
enum RecommendationCategory {
  meal,
  activity,
  sleep,
  medication,
  lifestyle,
  timing,
}

/// Recommendation priority
enum RecommendationPriority {
  urgent,
  high,
  medium,
  low,
}

/// Recommendation status
enum RecommendationStatus {
  active,
  completed,
  dismissed,
}

/// Health Recommendation Model
@immutable
class HealthRecommendation {
  final String id;
  final RecommendationCategory category;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final RecommendationStatus status;
  final DateTime generatedAt;
  final DateTime? expiresAt;
  final RecommendationExplanation? explanation;
  final List<String> actionItems;
  final Map<String, dynamic>? dataSources; // References to triggering data

  const HealthRecommendation({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.generatedAt,
    this.expiresAt,
    this.explanation,
    this.actionItems = const [],
    this.dataSources,
  });

  String get categoryLabel {
    switch (category) {
      case RecommendationCategory.meal:
        return 'Meal';
      case RecommendationCategory.activity:
        return 'Activity';
      case RecommendationCategory.sleep:
        return 'Sleep';
      case RecommendationCategory.medication:
        return 'Medication';
      case RecommendationCategory.lifestyle:
        return 'Lifestyle';
      case RecommendationCategory.timing:
        return 'Timing';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case RecommendationPriority.urgent:
        return 'Urgent';
      case RecommendationPriority.high:
        return 'High';
      case RecommendationPriority.medium:
        return 'Medium';
      case RecommendationPriority.low:
        return 'Low';
    }
  }

  String get statusLabel {
    switch (status) {
      case RecommendationStatus.active:
        return 'Active';
      case RecommendationStatus.completed:
        return 'Completed';
      case RecommendationStatus.dismissed:
        return 'Dismissed';
    }
  }

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isActive => status == RecommendationStatus.active && !isExpired;

  HealthRecommendation copyWith({
    String? id,
    RecommendationCategory? category,
    String? title,
    String? description,
    RecommendationPriority? priority,
    RecommendationStatus? status,
    DateTime? generatedAt,
    DateTime? expiresAt,
    RecommendationExplanation? explanation,
    List<String>? actionItems,
    Map<String, dynamic>? dataSources,
  }) {
    return HealthRecommendation(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      generatedAt: generatedAt ?? this.generatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      explanation: explanation ?? this.explanation,
      actionItems: actionItems ?? this.actionItems,
      dataSources: dataSources ?? this.dataSources,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'generatedAt': generatedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'explanation': explanation?.toJson(),
      'actionItems': actionItems,
      'dataSources': dataSources,
    };
  }

  factory HealthRecommendation.fromJson(Map<String, dynamic> json) {
    return HealthRecommendation(
      id: json['id'] as String,
      category: RecommendationCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      priority: RecommendationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      status: RecommendationStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      explanation: json['explanation'] != null
          ? RecommendationExplanation.fromJson(json['explanation'])
          : null,
      actionItems: (json['actionItems'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dataSources: json['dataSources'] as Map<String, dynamic>?,
    );
  }
}

/// Explanation for why a recommendation was generated
@immutable
class RecommendationExplanation {
  final String rationale; // Why this recommendation
  final List<DataPoint> triggeringData; // What data triggered it
  final List<String> evidenceLinks; // Links to relevant patterns
  final String expectedImpact; // What will improve if followed

  const RecommendationExplanation({
    required this.rationale,
    required this.triggeringData,
    this.evidenceLinks = const [],
    required this.expectedImpact,
  });

  Map<String, dynamic> toJson() {
    return {
      'rationale': rationale,
      'triggeringData': triggeringData.map((d) => d.toJson()).toList(),
      'evidenceLinks': evidenceLinks,
      'expectedImpact': expectedImpact,
    };
  }

  factory RecommendationExplanation.fromJson(Map<String, dynamic> json) {
    return RecommendationExplanation(
      rationale: json['rationale'] as String,
      triggeringData: (json['triggeringData'] as List<dynamic>)
          .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      evidenceLinks: (json['evidenceLinks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      expectedImpact: json['expectedImpact'] as String,
    );
  }
}

/// Data point that triggered a recommendation
@immutable
class DataPoint {
  final String type; // e.g., "glucose_reading", "meal", "activity"
  final String description; // Human-readable description
  final String value; // The actual value
  final DateTime timestamp;

  const DataPoint({
    required this.type,
    required this.description,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      type: json['type'] as String,
      description: json['description'] as String,
      value: json['value'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Recommendation generation context
class RecommendationContext {
  final List<Map<String, dynamic>> glucoseReadings;
  final List<Map<String, dynamic>> meals;
  final List<Map<String, dynamic>> activities;
  final Map<String, dynamic> summary;
  final DateTime analysisStart;
  final DateTime analysisEnd;

  RecommendationContext({
    required this.glucoseReadings,
    required this.meals,
    required this.activities,
    required this.summary,
    required this.analysisStart,
    required this.analysisEnd,
  });

  Map<String, dynamic> toJson() {
    return {
      'glucoseReadings': glucoseReadings,
      'meals': meals,
      'activities': activities,
      'summary': summary,
      'analysisStart': analysisStart.toIso8601String(),
      'analysisEnd': analysisEnd.toIso8601String(),
    };
  }
}
```

florence\platform_service\lib\features\patient\recommendations\screens\recommendation_detail_screen.dart
```
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../models/recommendation_models.dart';

/// Recommendation Detail Screen
/// Shows full details of a recommendation with explanation and action steps
class RecommendationDetailScreen extends StatefulWidget {
  final HealthRecommendation recommendation;

  const RecommendationDetailScreen({
    super.key,
    required this.recommendation,
  });

  @override
  State<RecommendationDetailScreen> createState() =>
      _RecommendationDetailScreenState();
}

class _RecommendationDetailScreenState
    extends State<RecommendationDetailScreen> {
  bool _isLoading = false;

  // Mock related data
  final List<Map<String, dynamic>> _relatedData = [
    {
      'type': 'Glucose Reading',
      'value': '195 mg/dL',
      'timestamp': DateTime.now().subtract(const Duration(hours: 26)),
      'note': 'After dinner',
    },
    {
      'type': 'Meal Log',
      'value': 'Pasta with bread',
      'timestamp': DateTime.now().subtract(const Duration(hours: 28)),
      'note': 'High carbs',
    },
    {
      'type': 'Glucose Reading',
      'value': '178 mg/dL',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'note': 'After dinner',
    },
  ];

  /// Mark as done
  Future<void> _markAsDone() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Update in Supabase
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Helpers.showSuccess(context, 'Marked as done! Great job! 🎉');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to mark as done');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Dismiss recommendation
  Future<void> _dismiss() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Dismiss Recommendation',
      message: 'Are you sure you want to dismiss this recommendation?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Update in Supabase
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Helpers.showInfo(context, 'Recommendation dismissed');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to dismiss');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Snooze for 1 day
  Future<void> _snooze() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Update in Supabase
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Helpers.showSuccess(context, 'Snoozed for 1 day');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to snooze');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = widget.recommendation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendation'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header section
            _buildHeader(recommendation),

            // Why This Matters section
            _buildWhyThisMattersSection(recommendation),

            // Action Steps section
            _buildActionStepsSection(recommendation),

            // Related Data section
            _buildRelatedDataSection(),

            const SizedBox(height: 100), // Space for fixed buttons
          ],
        ),
      ),
      // Fixed action buttons at bottom
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  /// Build header section
  Widget _buildHeader(HealthRecommendation recommendation) {
    final categoryConfig = _getCategoryConfig(recommendation.category);
    final priorityConfig = _getPriorityConfig(recommendation.priority);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryConfig['color'].withOpacity(0.1),
            categoryConfig['color'].withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Category icon (large)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: categoryConfig['color'].withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              categoryConfig['icon'],
              size: 48,
              color: categoryConfig['color'],
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            recommendation.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Priority badge and date
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: priorityConfig['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: priorityConfig['color'],
                    width: 1.5,
                  ),
                ),
                child: Text(
                  priorityConfig['label'],
                  style: TextStyle(
                    color: priorityConfig['color'],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Generated ${_formatTime(recommendation.generatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Why This Matters section
  Widget _buildWhyThisMattersSection(HealthRecommendation recommendation) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BaseCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 24,
                  color: AppTheme.infoColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Why This Matters',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Full explanation
            Text(
              _getFullExplanation(recommendation),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
            ),

            const SizedBox(height: 20),

            // Supporting chart (mini)
            _buildMiniChart(recommendation),
          ],
        ),
      ),
    );
  }

  /// Build Action Steps section
  Widget _buildActionStepsSection(HealthRecommendation recommendation) {
    final steps = _getActionSteps(recommendation);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BaseCard(
        // backgroundColor: AppTheme.primaryBlue.withOpacity(0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    size: 24,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Action Steps',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Step-by-step instructions
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step number
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Step text
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          step,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    height: 1.5,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Build Related Data section
  Widget _buildRelatedDataSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BaseCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 24,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'This recommendation is based on:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List of data points
            ..._relatedData.map((data) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getDataIcon(data['type']),
                      size: 20,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data['type'],
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                data['value'],
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                Formatters.dateTime(data['timestamp']),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                              ),
                              Text(
                                data['note'],
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Build mini chart
  Widget _buildMiniChart(HealthRecommendation recommendation) {
    // Mock data for the mini chart
    final spots = [
      const FlSpot(0, 120),
      const FlSpot(1, 145),
      const FlSpot(2, 195), // Spike
      const FlSpot(3, 165),
      const FlSpot(4, 118),
      const FlSpot(5, 142),
      const FlSpot(6, 188), // Another spike
    ];

    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your dinner glucose pattern',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: 80,
                maxY: 220,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primaryBlue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: spot.y > 180
                              ? AppTheme.glucoseHigh
                              : AppTheme.primaryBlue,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mark as Done button (primary)
            PrimaryButton(
              text: 'Mark as Done',
              onPressed: _isLoading ? null : _markAsDone,
              isLoading: _isLoading,
              width: double.infinity,
            ),
            const SizedBox(height: 8),

            // Secondary actions row
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : _dismiss,
                    child: const Text('Dismiss'),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: AppTheme.borderColor,
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : _snooze,
                    child: const Text('Snooze for 1 day'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get full explanation based on recommendation
  String _getFullExplanation(HealthRecommendation recommendation) {
    switch (recommendation.category) {
      case RecommendationCategory.meal:
        return 'Based on your glucose data from the past week, we\'ve noticed a pattern of elevated blood glucose levels following dinner. Your post-dinner readings have been averaging 195 mg/dL, which is significantly above your target range of 70-180 mg/dL.\n\nHigh-carbohydrate meals, especially those consumed later in the evening, can lead to prolonged glucose elevation and affect your overnight levels. Reducing your carb intake at dinner can help stabilize your glucose and improve your overall diabetes management.';

      case RecommendationCategory.activity:
        return 'Our analysis shows that on days when you walk in the morning, your glucose levels remain more stable throughout the day. Morning exercise has several benefits: it improves insulin sensitivity, helps lower fasting glucose, and sets a positive tone for the rest of the day.\n\nConsistent morning activity has been shown to reduce glucose variability by up to 20% and can significantly improve long-term diabetes outcomes. Your data specifically shows a 15% improvement in time-in-range on days you exercise in the morning.';

      case RecommendationCategory.timing:
        return 'Your glucose tracking reveals that eating lunch earlier in the day leads to better post-meal glucose control. When you eat before 1 PM, your average post-lunch glucose is 135 mg/dL compared to 165 mg/dL when eating after 1 PM.\n\nThis pattern suggests your body\'s insulin sensitivity is higher earlier in the day, which is common. Shifting your meal timing to align with your body\'s natural rhythms can significantly improve your glucose management without changing what you eat.';

      case RecommendationCategory.sleep:
        return 'Your overnight glucose data shows significant improvement when you maintain a consistent bedtime around 10 PM. Irregular sleep patterns can disrupt your body\'s hormonal balance, affecting insulin sensitivity and glucose regulation.\n\nConsistent sleep helps regulate cortisol and growth hormone, both of which impact blood glucose. Your data shows 15% better overnight glucose stability when you sleep by 10 PM compared to later bedtimes.';

      case RecommendationCategory.lifestyle:
        return 'We\'ve observed that your glucose readings are consistently better on days when you log water intake, suggesting proper hydration. Adequate hydration helps your kidneys flush out excess glucose and improves insulin sensitivity.\n\nDehydration can cause glucose to become more concentrated in your bloodstream, leading to higher readings. Your well-hydrated days show an average of 8% lower glucose levels compared to days with less water intake.';

      case RecommendationCategory.medication:
        return 'Medication adherence is crucial for effective diabetes management. Setting a consistent reminder can help ensure you take your medication at the optimal time, maximizing its effectiveness.\n\nYour medication works best when taken at regular intervals. Consistent timing helps maintain stable glucose levels and reduces the risk of both highs and lows.';

      default:
        return recommendation.description;
    }
  }

  /// Get action steps based on recommendation
  List<String> _getActionSteps(HealthRecommendation recommendation) {
    switch (recommendation.category) {
      case RecommendationCategory.meal:
        return [
          'Reduce your carbohydrate portion at dinner by 25-30%. For example, if you usually have 1 cup of rice, try reducing to ¾ cup.',
          'Add more non-starchy vegetables to fill your plate. Aim for half your plate to be vegetables like broccoli, spinach, or cauliflower.',
          'Include lean protein (chicken, fish, tofu) with every dinner to slow down glucose absorption.',
          'Consider eating dinner at least 3 hours before bedtime to allow glucose levels to stabilize.',
          'Track your post-dinner glucose 2 hours after eating to monitor improvements.',
        ];

      case RecommendationCategory.activity:
        return [
          'Set an alarm for 8:00 AM daily as a reminder to start your morning walk.',
          'Start with a 20-minute walk at a comfortable pace. You don\'t need to go fast - consistency matters more than intensity.',
          'Walk outside if weather permits, or use a treadmill as an alternative. Indoor walking videos work too!',
          'Check your glucose before and after walking to see the immediate impact (usually drops 20-30 mg/dL).',
          'Gradually increase to 30-40 minutes as it becomes part of your routine.',
        ];

      case RecommendationCategory.timing:
        return [
          'Gradually shift your lunch time earlier by 15 minutes each week until you\'re eating before 1 PM.',
          'Prepare your lunch the night before or in the morning to remove barriers to eating earlier.',
          'If you work, consider adjusting your lunch break schedule with your employer or team.',
          'Log your post-lunch glucose at 2 hours to track the improvement from this change.',
          'Aim for consistency - try to eat lunch at the same time every day.',
        ];

      case RecommendationCategory.sleep:
        return [
          'Set a reminder at 9:30 PM to begin your bedtime routine.',
          'Create a relaxing wind-down routine: dim lights, avoid screens, read or listen to calming music.',
          'Keep your bedroom cool (65-68°F) and dark for optimal sleep quality.',
          'Avoid large meals or high-carb snacks 3 hours before bed to prevent overnight glucose spikes.',
          'Check your morning fasting glucose to see improvements from consistent sleep timing.',
        ];

      case RecommendationCategory.lifestyle:
        return [
          'Start your day by drinking a full glass (8 oz) of water upon waking.',
          'Carry a reusable water bottle with you throughout the day as a visual reminder.',
          'Set hourly reminders on your phone to take a few sips of water.',
          'Aim for at least 8 glasses (64 oz) of water daily, more if you\'re active or in hot weather.',
          'Use the app\'s water logging feature to track your intake and see the correlation with your glucose levels.',
        ];

      case RecommendationCategory.medication:
        return [
          'Set a daily alarm on your phone for 7:00 PM as a medication reminder.',
          'Place your medication in a visible location where you\'ll see it at the scheduled time.',
          'Use a pill organizer to prepare your medication for the week ahead.',
          'Log your medication intake in the app to help track adherence.',
          'If you miss a dose, consult your healthcare provider about what to do - don\'t double up without guidance.',
        ];

      default:
        return [
          'Review this recommendation carefully.',
          'Start implementing the suggested changes gradually.',
          'Track your progress in the app.',
          'Consult with your healthcare provider if you have questions.',
        ];
    }
  }

  /// Get category configuration
  Map<String, dynamic> _getCategoryConfig(RecommendationCategory category) {
    switch (category) {
      case RecommendationCategory.meal:
        return {'icon': Icons.restaurant, 'color': AppTheme.mealColor};
      case RecommendationCategory.activity:
        return {'icon': Icons.directions_run, 'color': AppTheme.activityColor};
      case RecommendationCategory.sleep:
        return {'icon': Icons.bedtime, 'color': const Color(0xFF9C27B0)};
      case RecommendationCategory.timing:
        return {'icon': Icons.access_time, 'color': AppTheme.primaryBlue};
      case RecommendationCategory.lifestyle:
        return {'icon': Icons.self_improvement, 'color': const Color(0xFF00BCD4)};
      case RecommendationCategory.medication:
        return {'icon': Icons.medication, 'color': AppTheme.medicationColor};
    }
  }

  /// Get priority configuration
  Map<String, dynamic> _getPriorityConfig(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.urgent:
        return {'label': 'URGENT', 'color': const Color(0xFFD32F2F)};
      case RecommendationPriority.high:
        return {'label': 'HIGH', 'color': AppTheme.warningColor};
      case RecommendationPriority.medium:
        return {'label': 'MEDIUM', 'color': AppTheme.infoColor};
      case RecommendationPriority.low:
        return {'label': 'LOW', 'color': AppTheme.textSecondaryColor};
    }
  }

  /// Get data icon
  IconData _getDataIcon(String type) {
    switch (type) {
      case 'Glucose Reading':
        return Icons.water_drop;
      case 'Meal Log':
        return Icons.restaurant;
      case 'Activity':
        return Icons.directions_run;
      case 'Medication':
        return Icons.medication;
      default:
        return Icons.analytics;
    }
  }

  /// Format time
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return Formatters.date(time);
    }
  }
}```

florence\platform_service\lib\features\patient\summaries\screens\weekly_summaries_screen.dart
```
/// Weekly Summaries Screen for FLORENCE Digital Health Platform
/// Displays weekly health summaries with trends and AI insights

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../core/providers/health_data_provider.dart';
import '../../core/models/health_data_models.dart';

/// Weekly summaries screen
class WeeklySummariesScreen extends StatefulWidget {
  const WeeklySummariesScreen({super.key});

  @override
  State<WeeklySummariesScreen> createState() => _WeeklySummariesScreenState();
}

class _WeeklySummariesScreenState extends State<WeeklySummariesScreen> {
  int _weeksBack = 0; // 0 = this week, 1 = last week, etc.
  final int _maxWeeksBack = 12; // Show up to 12 weeks of history

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Summaries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share summary
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: Consumer<HealthDataProvider>(
        builder: (context, healthData, child) {
          final summary = _getWeeklySummary(healthData);

          return RefreshIndicator(
            onRefresh: () async {
              await healthData.refreshData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Week selector
                  _buildWeekSelector(),
                  const SizedBox(height: 16),

                  // Overview card
                  _buildOverviewCard(summary),
                  const SizedBox(height: 16),

                  // Glucose metrics
                  _buildSectionHeader('Glucose Control'),
                  const SizedBox(height: 12),
                  _buildGlucoseMetricsCard(summary),
                  const SizedBox(height: 16),

                  // Activity & nutrition
                  _buildSectionHeader('Lifestyle'),
                  const SizedBox(height: 12),
                  _buildLifestyleCard(summary),
                  const SizedBox(height: 16),

                  // Medication adherence
                  _buildSectionHeader('Medication Adherence'),
                  const SizedBox(height: 12),
                  _buildMedicationCard(healthData),
                  const SizedBox(height: 16),

                  // Week comparison chart
                  _buildSectionHeader('Trends'),
                  const SizedBox(height: 12),
                  _buildTrendsCard(healthData),
                  const SizedBox(height: 16),

                  // AI insights
                  _buildSectionHeader('AI Insights'),
                  const SizedBox(height: 12),
                  _buildAIInsightsCard(summary),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build week selector
  Widget _buildWeekSelector() {
    final weekStart = _getWeekStart();
    final weekEnd = _getWeekEnd();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _weeksBack < _maxWeeksBack
                  ? () {
                      setState(() => _weeksBack++);
                    }
                  : null,
              tooltip: 'Previous week',
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _weeksBack == 0
                        ? 'This Week'
                        : _weeksBack == 1
                            ? 'Last Week'
                            : '$_weeksBack weeks ago',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _weeksBack > 0
                  ? () {
                      setState(() => _weeksBack--);
                    }
                  : null,
              tooltip: 'Next week',
            ),
          ],
        ),
      ),
    );
  }

  /// Build overview card
  Widget _buildOverviewCard(HealthSummary summary) {
    final avgGlucose = summary.averageGlucose;
    final timeInRange = summary.timeInRange;

    // Simple status based on time in range
    String status;
    Color statusColor;
    IconData statusIcon;

    if (timeInRange >= 70) {
      status = 'Excellent';
      statusColor = AppTheme.primaryGreen;
      statusIcon = Icons.check_circle;
    } else if (timeInRange >= 50) {
      status = 'Good';
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.info;
    } else {
      status = 'Needs Attention';
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.warning;
    }

    return Card(
      color: statusColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOverviewStat(
                  'Avg Glucose',
                  '${avgGlucose.toStringAsFixed(0)} mg/dL',
                  Icons.water_drop,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                _buildOverviewStat(
                  'Time in Range',
                  '${timeInRange.toStringAsFixed(0)}%',
                  Icons.track_changes,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build overview stat
  Widget _buildOverviewStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// Build glucose metrics card
  Widget _buildGlucoseMetricsCard(HealthSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetricRow(
              'Average Glucose',
              '${summary.averageGlucose.toStringAsFixed(0)} mg/dL',
              Icons.water_drop,
              AppTheme.primaryBlue,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Time in Range',
              '${summary.timeInRange.toStringAsFixed(0)}%',
              Icons.track_changes,
              AppTheme.primaryGreen,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Total Readings',
              '${summary.totalReadings}',
              Icons.assessment,
              AppTheme.accentPurple,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Readings/Day',
              '${(summary.totalReadings / 7).toStringAsFixed(1)}',
              Icons.calendar_today,
              AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  /// Build lifestyle card
  Widget _buildLifestyleCard(HealthSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetricRow(
              'Activity Minutes',
              '${summary.totalActivityMinutes}',
              Icons.directions_run,
              AppTheme.activityColor,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Minutes/Day',
              '${(summary.totalActivityMinutes / 7).toStringAsFixed(1)}',
              Icons.timer,
              AppTheme.activityColor,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Total Meals',
              '${summary.totalMeals}',
              Icons.restaurant,
              AppTheme.mealColor,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Average Carbs',
              '${summary.averageCarbs.toStringAsFixed(0)}g',
              Icons.grain,
              AppTheme.mealColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Build medication card
  Widget _buildMedicationCard(HealthDataProvider healthData) {
    final adherence = healthData.getMedicationAdherence();

    Color color;
    IconData icon;
    String status;

    if (adherence >= 80) {
      color = AppTheme.primaryGreen;
      icon = Icons.check_circle;
      status = 'Excellent';
    } else if (adherence >= 60) {
      color = AppTheme.warningColor;
      icon = Icons.info;
      status = 'Good';
    } else {
      color = AppTheme.errorColor;
      icon = Icons.warning;
      status = 'Needs Improvement';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${adherence.toStringAsFixed(0)}% Adherence',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build trends card
  Widget _buildTrendsCard(HealthDataProvider healthData) {
    // Get last 4 weeks of data for comparison
    final weeks = <Map<String, dynamic>>[];

    for (int i = 3; i >= 0; i--) {
      final weekEnd = DateTime.now().subtract(Duration(days: (i * 7) + (_weeksBack * 7)));
      final weekStart = weekEnd.subtract(const Duration(days: 6));

      final summary = healthData.getHealthSummary(
        startDate: weekStart,
        endDate: weekEnd,
      );

      weeks.add({
        'label': i == 0 && _weeksBack == 0 ? 'This' : 'Wk ${4 - i}',
        'avgGlucose': summary.averageGlucose,
        'timeInRange': summary.timeInRange,
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Average Glucose (Last 4 Weeks)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 200,
                  minY: 70,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < weeks.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                weeks[value.toInt()]['label'],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weeks.asMap().entries.map((entry) {
                    final avgGlucose = entry.value['avgGlucose'] as double;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: avgGlucose,
                          color: AppTheme.primaryBlue,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build AI insights card
  Widget _buildAIInsightsCard(HealthSummary summary) {
    final insights = _generateAIInsights(summary);

    return Card(
      color: AppTheme.primaryBlue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI-Powered Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 7, right: 12),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          insight,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Build metric row
  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Get week start date
  DateTime _getWeekStart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysToSubtract = (now.weekday % 7) + (_weeksBack * 7);
    return today.subtract(Duration(days: daysToSubtract));
  }

  /// Get week end date
  DateTime _getWeekEnd() {
    return _getWeekStart().add(const Duration(days: 6, hours: 23, minutes: 59));
  }

  /// Get weekly summary
  HealthSummary _getWeeklySummary(HealthDataProvider healthData) {
    return healthData.getHealthSummary(
      startDate: _getWeekStart(),
      endDate: _getWeekEnd(),
    );
  }

  /// Generate AI insights
  List<String> _generateAIInsights(HealthSummary summary) {
    final insights = <String>[];

    // Time in range insight
    if (summary.timeInRange >= 70) {
      insights.add(
        'Excellent glucose control! Your time in range of ${summary.timeInRange.toStringAsFixed(0)}% is well above the 70% target.',
      );
    } else if (summary.timeInRange >= 50) {
      insights.add(
        'Your time in range is ${summary.timeInRange.toStringAsFixed(0)}%. Consider reviewing meal timing and portions to reach the 70% target.',
      );
    } else {
      insights.add(
        'Time in range needs improvement at ${summary.timeInRange.toStringAsFixed(0)}%. Work with your healthcare team to adjust your management plan.',
      );
    }

    // Activity insight
    final avgActivityPerDay = summary.totalActivityMinutes / 7;
    if (avgActivityPerDay >= 30) {
      insights.add(
        'Great job staying active! You averaged ${avgActivityPerDay.toStringAsFixed(0)} minutes per day.',
      );
    } else if (avgActivityPerDay >= 15) {
      insights.add(
        'You\'re moving ${avgActivityPerDay.toStringAsFixed(0)} minutes/day. Try to gradually increase to 30 minutes for optimal glucose control.',
      );
    } else {
      insights.add(
        'Physical activity is key to glucose management. Start with 10-minute walks after meals.',
      );
    }

    // Reading frequency insight
    final avgReadingsPerDay = summary.totalReadings / 7;
    if (avgReadingsPerDay >= 4) {
      insights.add(
        'Consistent monitoring with ${avgReadingsPerDay.toStringAsFixed(1)} readings/day helps you understand your patterns.',
      );
    } else {
      insights.add(
        'More frequent glucose checks (aim for 4+ daily) provide better insights into your diabetes management.',
      );
    }

    return insights;
  }
}
```

florence\platform_service\lib\features\patient\dashboard\screens\hba1c_detail_screen.dart
```
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class HbA1cDetailScreen extends ConsumerWidget {
  const HbA1cDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorAsync = ref.watch(monitorDataProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HbA1c Analytics'),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.getBorderColor(context),
            height: 1.0,
          ),
        ),
      ),
      body: monitorAsync.when(
        data: (dataList) {
          final readings = dataList
              .where((d) => d.dataType == MonitorDataType.HBA1C)
              .toList();
          
          // Sort by date ascending
          readings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

          final thresholds = thresholdsAsync.value ?? [];
          HealthThreshold? userThreshold;
          try {
            userThreshold = thresholds.firstWhere((t) => t.dataType == MonitorDataType.HBA1C);
          } catch (_) {}

          final targetMax = userThreshold?.maxValue;

          return RefreshIndicator(
            onRefresh: () async {
               await Future.wait([
                 ref.refresh(monitorDataProvider.future),
                 ref.refresh(patientThresholdsProvider.future),
               ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _GaugeSection(
                    latestReading: readings.isNotEmpty ? readings.last : null,
                    threshold: userThreshold,
                  ),
                  const SizedBox(height: 20),
                  
                  _TrendsSection(
                    readings: readings,
                    targetMax: targetMax,
                  ),
                  const SizedBox(height: 20),

                  _GoalComparisonSection(
                    latestReading: readings.isNotEmpty ? readings.last : null,
                    targetMax: targetMax,
                  ),
                  const SizedBox(height: 20),
                  
                  _HistorySection(
                    readings: readings, 
                    targetMax: targetMax,
                    threshold: userThreshold,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// ============================================================================
// 1. GAUGE CHART (Speedometer) - REFINED DESIGN
// ============================================================================

class _GaugeSection extends StatelessWidget {
  final MonitorData? latestReading;
  final HealthThreshold? threshold;

  const _GaugeSection({this.latestReading, this.threshold});

  Widget _buildMiniTargetRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final val = latestReading?.value ?? 0.0;
    
    const double minScale = 4.0;
    const double maxScale = 12.0;
    
    final double normalized = ((val.clamp(minScale, maxScale)) - minScale) / (maxScale - minScale);
    // -90 deg (left) to +90 deg (right)
    final double rotationAngle = -math.pi / 2 + (normalized * math.pi);

    Color statusColor;
    String statusText;
    
    // Use threshold if available, otherwise neutral
    if (val == 0) {
      statusText = "No Data";
      statusColor = AppTheme.textSecondaryColor;
    } else if (threshold != null) {
      if (val <= threshold!.maxValue) {
        statusColor = AppTheme.primaryGreen;
        statusText = "Normal";
      } else {
        statusColor = AppTheme.errorColor;
        statusText = "High";
      }
    } else {
      statusColor = AppTheme.primaryBlue;
      statusText = "Recorded";
    }

    // Chart Dimensions
    const double chartRadius = 110.0; 
    const double sectionWidth = 20.0;
    const double centerRadius = chartRadius - sectionWidth; 
    // Needle length: reach almost to the end of the bar
    const double needleLength = centerRadius + sectionWidth - 2;

    String infoText;
    if (threshold != null) {
      infoText = 'HbA1c reflects your average blood sugar over the past 3 months.\n\n'
                 '• Your Target: Below ${threshold!.maxValue.toStringAsFixed(1)}%\n'
                 '• Above Target: ${threshold!.maxValue.toStringAsFixed(1)}% or higher';
    } else {
      infoText = 'HbA1c reflects your average blood sugar over the past 3 months.\n\n'
                 '• Set a target in your profile to see status.';
    }

    return _HbA1cCard(
      title: 'Current Status',
      icon: Icons.speed,
      infoText: infoText,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            // Target Range Display
            InkWell(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.track_changes,
                              size: 18,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Target Range',
                              style: TextStyle(
                                color: AppTheme.primaryGreen.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppTheme.primaryGreen.withOpacity(0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMiniTargetRow(
                      'HbA1c',
                      threshold != null 
                          ? '${threshold!.minValue.toStringAsFixed(1)} - ${threshold!.maxValue.toStringAsFixed(1)}%' 
                          : 'Not Set',
                      threshold != null ? AppTheme.primaryGreen : AppTheme.textSecondaryColor,
                    ),
                  ],
                ),
              ),
            ),

            // 1. The Gauge (Half Circle)
            SizedBox(
              height: chartRadius + 10,
              width: chartRadius * 2,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Background Arc
                  Positioned(
                    top: 0,
                    width: chartRadius * 2,
                    height: chartRadius * 2,
                    child: PieChart(
                      PieChartData(
                        startDegreeOffset: 180,
                        sectionsSpace: 0,
                        centerSpaceRadius: centerRadius,
                        sections: threshold != null 
                        ? [
                          // Clinical Ranges (Only show if threshold exists, implying user cares about status)
                          // Note: Mapping exact user thresholds to a fixed gauge is complex, 
                          // so we stick to clinical backgrounds BUT only if a threshold is set.
                          PieChartSectionData(value: 1.7, color: AppTheme.primaryGreen.withOpacity(0.8), radius: sectionWidth, showTitle: false),
                          PieChartSectionData(value: 0.8, color: AppTheme.warningColor.withOpacity(0.8), radius: sectionWidth, showTitle: false),
                          PieChartSectionData(value: 5.5, color: AppTheme.errorColor.withOpacity(0.8), radius: sectionWidth, showTitle: false),
                          PieChartSectionData(value: 8.0, color: Colors.transparent, radius: sectionWidth, showTitle: false),
                        ]
                        : [
                          // Neutral Blue Arc (4.0 to 12.0 range = 8 units)
                          PieChartSectionData(value: 8.0, color: AppTheme.primaryBlue.withOpacity(0.2), radius: sectionWidth, showTitle: false),
                          PieChartSectionData(value: 8.0, color: Colors.transparent, radius: sectionWidth, showTitle: false),
                        ],
                      ),
                    ),
                  ),
                  
                  // Needle
                  if (val > 0) ...[
                    Positioned(
                      top: chartRadius - needleLength,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Transform.rotate(
                          angle: rotationAngle,
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            height: needleLength,
                            width: 6,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.textPrimaryColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Pivot Point (Knob) - Centered
                    Positioned(
                      top: chartRadius - 8, // Center pivot at y=chartRadius (8 is half height)
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppTheme.textPrimaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. Scale Labels
            const SizedBox(
              width: 230,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('4.0%', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('12.0%', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // 3. Value & Status
            Column(
              children: [
                Text(
                  val > 0 ? '${val.toStringAsFixed(1)}%' : '--',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    height: 1.0,
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. TRENDS - FIXED OVERLAPPING / OUT OF BOUNDS
// ============================================================================

class _TrendsSection extends StatefulWidget {
  final List<MonitorData> readings;
  final double? targetMax;

  const _TrendsSection({required this.readings, this.targetMax});

  @override
  State<_TrendsSection> createState() => _TrendsSectionState();
}

class _TrendsSectionState extends State<_TrendsSection> {
  String _selectedRange = '6M';
  final List<String> _ranges = ['6M', '1Y', 'ALL'];

  String _getRangeLabel(String range) {
    switch (range) {
      case '6M':
        return 'Half Year';
      case '1Y':
        return 'Yearly';
      case 'ALL':
        return 'All Time';
      default:
        return range;
    }
  }

  List<MonitorData> _filterData() {
    if (widget.readings.isEmpty || _selectedRange == 'ALL') return widget.readings;
    final now = DateTime.now();
    final duration = _selectedRange == '6M' ? const Duration(days: 180) : const Duration(days: 365);
    final cutoff = now.subtract(duration);
    return widget.readings.where((r) => r.measuredAt.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterData();
    
    double minX = 0, maxX = 1;
    if (filtered.isNotEmpty) {
      minX = filtered.first.measuredAt.millisecondsSinceEpoch.toDouble();
      maxX = filtered.last.measuredAt.millisecondsSinceEpoch.toDouble();
      if (minX == maxX) {
        minX -= 2629743000;
        maxX += 2629743000; 
      }
    } else {
       final now = DateTime.now();
       minX = now.subtract(const Duration(days: 90)).millisecondsSinceEpoch.toDouble();
       maxX = now.millisecondsSinceEpoch.toDouble();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _HbA1cCard(
      title: 'HbA1c Trends',
      icon: Icons.show_chart,
      infoText: 'Visualizes your HbA1c levels over time.\n\n'
                '• Green Band: Normal Range\n'
                '• Dotted Line: Your personal target',
      child: Column(
        children: [
          // Timeline Selector
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: _ranges.map((range) {
                final isSelected = _selectedRange == range;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRange = range),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRangeLabel(range),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                            ? Colors.white 
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(
            height: 220,
            // FIX: ClipRect prevents the RangeAnnotations from drawing outside the container
            child: ClipRect(
              child: LineChart(
                LineChartData(
                  // FIX: Ensure FLChart knows to clip content to the border
                  clipData: const FlClipData.all(), 
                  minX: minX, maxX: maxX, minY: 4, maxY: 10,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (maxX - minX) / 3,
                        getTitlesWidget: (val, _) {
                          // Padding to prevent first/last label clipping
                          if (val <= minX + ((maxX - minX)*0.05) || val >= maxX - ((maxX - minX)*0.05)) return const SizedBox();
                          final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(DateFormat('MMM y').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true, 
                    border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))
                  ),
                  rangeAnnotations: widget.targetMax != null ? RangeAnnotations(
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(y1: 4, y2: 5.7, color: AppTheme.primaryGreen.withOpacity(0.08)),
                      HorizontalRangeAnnotation(y1: 5.7, y2: 6.5, color: AppTheme.warningColor.withOpacity(0.08)),
                      HorizontalRangeAnnotation(y1: 6.5, y2: 14, color: AppTheme.errorColor.withOpacity(0.08)),
                    ],
                  ) : null,
                  extraLinesData: widget.targetMax != null ? ExtraLinesData(
                    horizontalLines: [
                       HorizontalLine(
                         y: widget.targetMax!, 
                         color: AppTheme.primaryBlue.withOpacity(0.8), 
                         strokeWidth: 1, 
                         dashArray: [5,5], 
                         label: HorizontalLineLabel(
                           show: true, 
                           alignment: Alignment.topRight, 
                           padding: const EdgeInsets.only(right: 5, bottom: 2), 
                           style: TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold), 
                           labelResolver: (line) => 'Target'
                         )
                       )
                    ]
                  ) : null,
                  lineBarsData: [
                    LineChartBarData(
                      spots: filtered.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                      isCurved: true,
                      color: AppTheme.primaryBlue,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true, 
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppTheme.primaryBlue, strokeColor: Colors.white, strokeWidth: 2)
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          const FlLine(color: AppTheme.textSecondaryColor, strokeWidth: 1),
                          FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppTheme.primaryBlue, strokeColor: Colors.white)),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)}%',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.targetMax != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem('Normal', AppTheme.primaryGreen.withOpacity(0.5)),
                const SizedBox(width: 16),
                _LegendItem('Pre-diabetes', AppTheme.warningColor.withOpacity(0.5)),
                const SizedBox(width: 16),
                _LegendItem('Diabetes', AppTheme.errorColor.withOpacity(0.5)),
              ],
            )
          ]
        ],
      ),
    );
  }
}

// ============================================================================
// 3. ACTUAL VS GOAL - FIXED TEXT CLIPPING
// ============================================================================

class _GoalComparisonSection extends StatelessWidget {
  final MonitorData? latestReading;
  final double? targetMax;

  const _GoalComparisonSection({this.latestReading, this.targetMax});

  @override
  Widget build(BuildContext context) {
    if (targetMax == null) {
      return _HbA1cCard(
        title: 'Actual vs. Goal',
        icon: Icons.flag_outlined,
        infoText: 'Set a target to see comparison.',
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No target set. Please configure your profile.')),
        ),
      );
    }

    final current = latestReading?.value ?? 0.0;
    final isGood = current <= targetMax! && current > 0;
    final barColor = isGood ? AppTheme.primaryGreen : AppTheme.errorColor;
    final maxY = math.max(current, targetMax!) * 1.4;

    return _HbA1cCard(
      title: 'Actual vs. Goal',
      icon: Icons.flag_outlined,
      infoText: 'Compares your latest reading against your set target.\n\n'
                'Left Bar: Your latest HbA1c\n'
                'Right Bar: Your Goal',
      child: Column(
        children: [
          if (latestReading == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No HbA1c data recorded yet.'),
            )
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40, // Increased reserved size to prevent clipping
                        getTitlesWidget: (val, _) {
                           switch(val.toInt()) {
                             case 0: return const Padding(padding: EdgeInsets.only(top: 8), child: Text('You', style: TextStyle(fontWeight: FontWeight.bold)));
                             case 1: return const Padding(padding: EdgeInsets.only(top: 8), child: Text('Target', style: TextStyle(fontWeight: FontWeight.bold)));
                             default: return const SizedBox();
                           }
                        }
                      )
                    )
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  barGroups: [
                    // Actual Bar
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: current,
                          color: barColor,
                          width: 30,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    ),
                    // Goal Bar
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: targetMax!,
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          width: 30,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    ),
                  ],
                  barTouchData: BarTouchData(
                    enabled: false, // Disable touch interaction, just show tooltip
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 4,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)}%',
                          TextStyle(
                            color: group.x == 0 ? barColor : AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (latestReading != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isGood ? AppTheme.primaryGreen : AppTheme.errorColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (isGood ? AppTheme.primaryGreen : AppTheme.errorColor).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isGood ? Icons.check_circle : Icons.warning,
                    color: isGood ? AppTheme.primaryGreen : AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isGood 
                        ? "You are within your target of <${targetMax!.toStringAsFixed(1)}%"
                        : "You are ${(current - targetMax!).toStringAsFixed(1)}% above your target",
                      style: TextStyle(
                        color: isGood ? AppTheme.primaryGreen : AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. HISTORY LIST - WITH PAGINATION
// ============================================================================

class _HistorySection extends StatefulWidget {
  final List<MonitorData> readings;
  final double? targetMax;
  final HealthThreshold? threshold;

  const _HistorySection({required this.readings, this.targetMax, this.threshold});

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    final reversed = widget.readings.reversed.toList();
    final totalItems = reversed.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    if (totalPages == 0) _currentPage = 0;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = totalItems > 0 ? reversed.sublist(start, end) : <MonitorData>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    icon: const Icon(Icons.chevron_left),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${_currentPage + 1}/$totalPages',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                    icon: const Icon(Icons.chevron_right),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (currentItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No records found',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ),
          
          ...currentItems.map((r) {
             // Determine status color
             String statusText;
             Color statusColor;
             
             if (widget.threshold != null) {
               if (r.value <= widget.threshold!.maxValue) {
                 statusText = 'NORMAL';
                 statusColor = AppTheme.primaryGreen;
               } else {
                 statusText = 'HIGH';
                 statusColor = AppTheme.errorColor;
               }
             } else {
               statusText = 'RECORDED';
               statusColor = AppTheme.primaryBlue;
             }

             return Container(
               margin: const EdgeInsets.only(bottom: 12),
               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
               decoration: BoxDecoration(
                 color: isDark ? AppTheme.midnightSurface : Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.03),
                     blurRadius: 8,
                     offset: const Offset(0, 2),
                   )
                 ],
                 border: Border.all(
                   color: statusColor.withOpacity(0.3),
                   width: 1,
                 ),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   // Left: Value
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.baseline,
                     textBaseline: TextBaseline.alphabetic,
                     children: [
                       Text(
                         r.value.toStringAsFixed(1),
                         style: TextStyle(
                           fontWeight: FontWeight.normal,
                           fontSize: 20,
                           color: AppTheme.textPrimaryColor,
                         ),
                       ),
                       const SizedBox(width: 4),
                       Text(
                         '%',
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                               color: AppTheme.textSecondaryColor,
                               fontSize: 12,
                             ),
                       ),
                     ],
                   ),
                   
                   // Right: Date and Status Badge
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: statusColor.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Text(
                           statusText,
                           style: TextStyle(
                             color: statusColor,
                             fontSize: 10,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                       const SizedBox(height: 6),
                       Text(
                         DateFormat('dd/MM/yy HH:mm').format(r.measuredAt),
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                               fontSize: 11,
                               color: AppTheme.textSecondaryColor,
                             ),
                       ),
                     ],
                   ),
                 ],
               ),
             );
          }),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPERS
// ============================================================================

class _HbA1cCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget child;

  const _HbA1cCard({
    required this.title,
    required this.icon,
    required this.infoText,
    required this.child,
  });

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title, 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(infoText, style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row matching GlucoseDetailScreen
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () => _showInfoDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, 
          height: 12, 
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
      ],
    );
  }
}
```

florence\platform_service\lib\features\patient\recommendations\services\recommendation_engine.dart
```
/// AI-Powered Recommendation Engine for FLORENCE Digital Health Platform
/// Generates personalized health recommendations

import '../../../../core/config/environment.dart';
import '../../../patient/core/models/health_data_models.dart';
import '../../../patient/core/services/data_ingestion_service.dart';
import '../models/recommendation_models.dart';

/// Service for generating health recommendations
class RecommendationEngine {
  final DataIngestionService _dataService = DataIngestionService();

  // Singleton pattern
  static final RecommendationEngine _instance = RecommendationEngine._internal();
  factory RecommendationEngine() => _instance;
  RecommendationEngine._internal();

  // Cache of generated recommendations
  final List<HealthRecommendation> _recommendations = [];

  List<HealthRecommendation> get allRecommendations =>
      List.unmodifiable(_recommendations);

  List<HealthRecommendation> get activeRecommendations =>
      _recommendations.where((r) => r.isActive).toList();

  /// Generate new recommendations based on recent health data
  Future<List<HealthRecommendation>> generateRecommendations({
    int daysToAnalyze = 7,
  }) async {
    // Currently only rule-based recommendations are supported
    // until the Python service exposes a recommendation endpoint.
    return _generateRuleBasedRecommendations();
  }

  /// Generate rule-based recommendations (fallback)
  List<HealthRecommendation> _generateRuleBasedRecommendations() {
    final recommendations = <HealthRecommendation>[];
    final summary = _dataService.getHealthSummary(
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now(),
    );

    // High glucose
    if (summary.averageGlucose > Environment.glucoseHigh) {
      recommendations.add(HealthRecommendation(
        id: 'rec_glucose_high_${DateTime.now().millisecondsSinceEpoch}',
        category: RecommendationCategory.meal,
        title: 'Reduce Average Glucose',
        description: 'Your average glucose is ${summary.averageGlucose.toStringAsFixed(0)} mg/dL. Let\'s work on bringing it down.',
        priority: RecommendationPriority.high,
        status: RecommendationStatus.active,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        actionItems: [
          'Monitor carb portions',
          'Increase fiber intake',
          'Walk 10 mins after meals',
        ],
      ));
    }

    // Low activity
    if (summary.totalActivityMinutes < 150) {
      recommendations.add(HealthRecommendation(
        id: 'rec_activity_low_${DateTime.now().millisecondsSinceEpoch}',
        category: RecommendationCategory.activity,
        title: 'Increase Physical Activity',
        description: 'You logged ${summary.totalActivityMinutes} minutes this week. Aim for 150 minutes.',
        priority: RecommendationPriority.medium,
        status: RecommendationStatus.active,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        actionItems: [
          'Start with 10-minute walks',
          'Try post-meal walking',
          'Gradually increase duration',
        ],
      ));
    }

    _recommendations.addAll(recommendations);
    return recommendations;
  }

  /// Explain a specific recommendation
  Future<String> explainRecommendation(HealthRecommendation recommendation) async {
    // Return static rationale as AI explanation is currently unavailable
    return recommendation.explanation?.rationale ?? 'No explanation available';
  }

  /// Mark recommendation as completed
  void completeRecommendation(String id) {
    final index = _recommendations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _recommendations[index] = _recommendations[index].copyWith(
        status: RecommendationStatus.completed,
      );
    }
  }

  /// Dismiss recommendation
  void dismissRecommendation(String id) {
    final index = _recommendations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _recommendations[index] = _recommendations[index].copyWith(
        status: RecommendationStatus.dismissed,
      );
    }
  }

  /// Clear all recommendations
  void clearRecommendations() {
    _recommendations.clear();
  }
}
```

florence\platform_service\lib\features\patient\dashboard\widgets\quick_actions_grid.dart
```
import 'package:flutter/material.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';

/// Quick Actions Grid
/// Grid of buttons for quick data logging
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onLogGlucose;
  final VoidCallback onLogMeal;
  final VoidCallback onLogActivity;
  final VoidCallback onLogMedication;
  
  const QuickActionsGrid({
    super.key,
    required this.onLogGlucose,
    required this.onLogMeal,
    required this.onLogActivity,
    required this.onLogMedication,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.getBorderColor(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: titleIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flash_on_outlined,
                  color: titleIconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                context,
                'Glucose',
                Icons.water_drop_rounded,
                AppTheme.primaryRed,
                onLogGlucose,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                'Meal',
                Icons.restaurant_rounded,
                AppTheme.mealColor,
                onLogMeal,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                'Activity',
                Icons.directions_run_rounded,
                AppTheme.activityColor,
                onLogActivity,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                'Meds',
                Icons.medication_rounded,
                AppTheme.medicationColor,
                onLogMedication,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppTheme.borderColor.withOpacity(0.5);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 10,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

florence\platform_service\lib\features\patient\core\services\patient_profile_service.dart
```
/// Patient Profile Service for FLORENCE Digital Health Platform
/// Manages multiple patient profiles for testing and demonstration

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/health_data_models.dart';
import 'data_ingestion_service.dart';
import '../../chat/services/chatbot_service.dart';

/// Patient profile types
enum PatientProfileType {
  wellControlled,
  highRisk,
  variable,
}

/// Patient profile metadata
class PatientProfile {
  final PatientProfileType type;
  final String name;
  final String description;
  final double baselineGlucose;
  final double targetHbA1c;
  final double activityLevel; // 0.0-1.0
  final double medicationAdherence; // 0.0-1.0

  const PatientProfile({
    required this.type,
    required this.name,
    required this.description,
    required this.baselineGlucose,
    required this.targetHbA1c,
    required this.activityLevel,
    required this.medicationAdherence,
  });
}

/// Service for managing patient profiles
class PatientProfileService with ChangeNotifier {
  final DataIngestionService _dataService = DataIngestionService();
  final ChatbotService _chatbotService = ChatbotService();
  final Random _random = Random();

  // Singleton pattern
  static final PatientProfileService _instance = PatientProfileService._internal();
  factory PatientProfileService() => _instance;
  PatientProfileService._internal();

  PatientProfileType _currentProfile = PatientProfileType.wellControlled;
  DateTime _lastRefresh = DateTime.now();

  PatientProfileType get currentProfileType => _currentProfile;
  DateTime get lastRefresh => _lastRefresh;

  /// Available patient profiles
  static const List<PatientProfile> availableProfiles = [
    PatientProfile(
      type: PatientProfileType.wellControlled,
      name: 'Well-Controlled Patient',
      description: 'Good glucose control, active lifestyle, consistent medication',
      baselineGlucose: 120.0,
      targetHbA1c: 6.5,
      activityLevel: 0.8,
      medicationAdherence: 0.95,
    ),
    PatientProfile(
      type: PatientProfileType.highRisk,
      name: 'High-Risk Patient',
      description: 'Poor glucose control, low activity, inconsistent medication',
      baselineGlucose: 180.0,
      targetHbA1c: 8.5,
      activityLevel: 0.3,
      medicationAdherence: 0.65,
    ),
    PatientProfile(
      type: PatientProfileType.variable,
      name: 'Variable Patient',
      description: 'Inconsistent patterns, glucose sensitive to activity',
      baselineGlucose: 145.0,
      targetHbA1c: 7.2,
      activityLevel: 0.6,
      medicationAdherence: 0.80,
    ),
  ];

  /// Get current profile
  PatientProfile get currentProfile {
    return availableProfiles.firstWhere((p) => p.type == _currentProfile);
  }

  /// Switch to a different patient profile
  Future<void> switchProfile(PatientProfileType type) async {
    if (_currentProfile == type) return;

    _currentProfile = type;
    await _generateProfileData();
    _lastRefresh = DateTime.now();

    // CRITICAL: Invalidate chatbot context so it uses new profile data
    _chatbotService.invalidateContext();
    print('PatientProfileService: Profile switched to $type, chatbot context invalidated');

    notifyListeners();
  }

  /// Refresh current profile data
  Future<void> refreshCurrentProfile() async {
    await _generateProfileData();
    _lastRefresh = DateTime.now();

    // CRITICAL: Invalidate chatbot context so it fetches fresh data
    _chatbotService.invalidateContext();
    print('PatientProfileService: Profile refreshed, chatbot context invalidated');

    notifyListeners();
  }

  /// Generate data for current profile
  Future<void> _generateProfileData() async {
    // Clear existing data
    _dataService.clearAllData();

    final profile = currentProfile;

    // Generate glucose readings
    await _generateGlucoseData(profile);

    // Generate meals
    await _generateMealsData(profile);

    // Generate activities
    await _generateActivitiesData(profile);

    // Generate medications
    await _generateMedicationsData(profile);

    // Generate HbA1c
    await _generateHbA1cData(profile);

    // Generate sleep
    await _generateSleepData(profile);
  }

  /// Generate glucose readings for profile
  Future<void> _generateGlucoseData(PatientProfile profile) async {
    final now = DateTime.now();
    const days = 30;

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));
      final readingsPerDay = 4 + _random.nextInt(5);

      for (int i = 0; i < readingsPerDay; i++) {
        final hour = (i * 24 / readingsPerDay).floor();
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        // Base value with profile-specific variance
        double value = profile.baselineGlucose;

        // Time-based variations
        if (hour >= 6 && hour <= 9) value += 15; // Morning
        else if (hour >= 12 && hour <= 14) value += 20; // Lunch
        else if (hour >= 18 && hour <= 20) value += 18; // Dinner

        // Profile-specific variability
        double variance = 0;
        if (profile.type == PatientProfileType.wellControlled) {
          variance = _randomGaussian(-15, 15);
        } else if (profile.type == PatientProfileType.highRisk) {
          variance = _randomGaussian(-40, 40);
        } else {
          // Variable - sometimes good, sometimes bad
          variance = _random.nextBool()
              ? _randomGaussian(-15, 15)
              : _randomGaussian(-35, 35);
        }

        final glucoseValue = (value + variance).clamp(70, 350);

        await _dataService.addGlucoseReading(GlucoseReading(
          id: 'glucose_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          value: glucoseValue.toDouble(),
          context: _getGlucoseContext(hour),
          isFlagged: glucoseValue > 200 || glucoseValue < 70,
        ));
      }
    }
  }

  /// Generate meals for profile
  Future<void> _generateMealsData(PatientProfile profile) async {
    final now = DateTime.now();
    const days = 30;
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));
      final mealsPerDay = 3 + _random.nextInt(2);

      for (int i = 0; i < mealsPerDay; i++) {
        final mealType = i < 3 ? mealTypes[i] : 'Snack';
        final hour = i == 0 ? 7 : i == 1 ? 12 : i == 2 ? 19 : 15;
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        // Carbs based on profile
        double baseCarbs = 40.0;
        if (profile.type == PatientProfileType.wellControlled) {
          baseCarbs = 30.0 + _random.nextInt(30); // 30-60g
        } else if (profile.type == PatientProfileType.highRisk) {
          baseCarbs = 50.0 + _random.nextInt(50); // 50-100g
        } else {
          baseCarbs = 25.0 + _random.nextInt(60); // 25-85g
        }

        await _dataService.addMeal(MealLog(
          id: 'meal_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          type: mealType,
          description: _getMealDescription(mealType),
          carbs: baseCarbs,
          calories: (baseCarbs * 4 + 200).toInt(),
          protein: 10.0 + _random.nextInt(25).toDouble(),
          fat: 8.0 + _random.nextInt(20).toDouble(),
        ));
      }
    }
  }

  /// Generate activities for profile
  Future<void> _generateActivitiesData(PatientProfile profile) async {
    final now = DateTime.now();
    const days = 30;
    final activityTypes = ['Walking', 'Running', 'Cycling', 'Swimming', 'Gym', 'Yoga'];
    final intensities = ['Low', 'Moderate', 'High'];

    for (int day = 0; day < days; day++) {
      // Activity frequency based on profile
      final shouldHaveActivity = _random.nextDouble() < profile.activityLevel;

      if (shouldHaveActivity) {
        final date = now.subtract(Duration(days: days - day));
        final hour = 6 + _random.nextInt(14);
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        final duration = profile.type == PatientProfileType.wellControlled
            ? 30 + _random.nextInt(45) // 30-75 min
            : 15 + _random.nextInt(30); // 15-45 min

        final intensity = profile.type == PatientProfileType.wellControlled
            ? intensities[1 + _random.nextInt(2)] // Moderate or High
            : intensities[_random.nextInt(2)]; // Low or Moderate

        await _dataService.addActivity(ActivityLog(
          id: 'activity_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          type: activityTypes[_random.nextInt(activityTypes.length)],
          duration: duration,
          intensity: intensity,
          caloriesBurned: duration * (intensity == 'High' ? 8 : intensity == 'Moderate' ? 5 : 3),
        ));
      }
    }
  }

  /// Generate medications for profile
  Future<void> _generateMedicationsData(PatientProfile profile) async {
    final medications = [
      ('Metformin', '500 mg', 'Twice daily'),
      ('Insulin Glargine', '20 units', 'Once daily'),
    ];

    for (var med in medications) {
      final doses = <MedicationDose>[];
      final now = DateTime.now();

      for (int day = 0; day < 30; day++) {
        final date = now.subtract(Duration(days: 30 - day));

        if (med.$3 == 'Twice daily') {
          // Morning dose
          final shouldTakeMorning = _random.nextDouble() < profile.medicationAdherence;
          doses.add(MedicationDose(
            id: 'dose_${date.millisecondsSinceEpoch}_morning',
            scheduledTime: DateTime(date.year, date.month, date.day, 8, 0),
            taken: shouldTakeMorning,
            takenTime: shouldTakeMorning
                ? DateTime(date.year, date.month, date.day, 8, _random.nextInt(60))
                : null,
          ));

          // Evening dose
          final shouldTakeEvening = _random.nextDouble() < profile.medicationAdherence;
          doses.add(MedicationDose(
            id: 'dose_${date.millisecondsSinceEpoch}_evening',
            scheduledTime: DateTime(date.year, date.month, date.day, 20, 0),
            taken: shouldTakeEvening,
            takenTime: shouldTakeEvening
                ? DateTime(date.year, date.month, date.day, 20, _random.nextInt(60))
                : null,
          ));
        } else {
          final shouldTake = _random.nextDouble() < profile.medicationAdherence;
          doses.add(MedicationDose(
            id: 'dose_${date.millisecondsSinceEpoch}',
            scheduledTime: DateTime(date.year, date.month, date.day, 8, 0),
            taken: shouldTake,
            takenTime: shouldTake
                ? DateTime(date.year, date.month, date.day, 8, _random.nextInt(60))
                : null,
          ));
        }
      }

      await _dataService.addMedication(MedicationLog(
        id: 'med_${med.$1.hashCode}',
        medicationName: med.$1,
        dosage: med.$2,
        frequency: med.$3,
        prescribedDate: DateTime.now().subtract(const Duration(days: 90)),
        doses: doses,
      ));
    }
  }

  /// Generate HbA1c for profile
  Future<void> _generateHbA1cData(PatientProfile profile) async {
    final now = DateTime.now();
    final testDates = [
      now.subtract(const Duration(days: 90)),
      now.subtract(const Duration(days: 180)),
      now.subtract(const Duration(days: 270)),
    ];

    for (var testDate in testDates) {
      await _dataService.addHbA1cResult(HbA1cResult(
        id: 'hba1c_${testDate.millisecondsSinceEpoch}',
        testDate: testDate,
        value: profile.targetHbA1c + _randomGaussian(-0.3, 0.3),
        labName: 'BioTective Labs',
      ));
    }
  }

  /// Generate sleep for profile
  Future<void> _generateSleepData(PatientProfile profile) async {
    final now = DateTime.now();
    const days = 30;

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));

      int sleepHours;
      if (profile.type == PatientProfileType.wellControlled) {
        sleepHours = 7 + _random.nextInt(2); // 7-9 hours
      } else if (profile.type == PatientProfileType.highRisk) {
        sleepHours = 5 + _random.nextInt(3); // 5-8 hours
      } else {
        sleepHours = 6 + _random.nextInt(3); // 6-9 hours
      }

      final bedTime = DateTime(date.year, date.month, date.day, 22 + _random.nextInt(2), _random.nextInt(60));
      final wakeTime = bedTime.add(Duration(hours: sleepHours));

      await _dataService.addSleepLog(SleepLog(
        id: 'sleep_${bedTime.millisecondsSinceEpoch}',
        bedTime: bedTime,
        wakeTime: wakeTime,
        quality: sleepHours >= 7 ? 6 + _random.nextInt(5) : 3 + _random.nextInt(5),
      ));
    }
  }

  // Helper methods
  String _getGlucoseContext(int hour) {
    if (hour >= 5 && hour < 9) return 'Before breakfast';
    if (hour >= 9 && hour < 11) return 'After breakfast';
    if (hour >= 11 && hour < 13) return 'Before lunch';
    if (hour >= 13 && hour < 17) return 'After lunch';
    if (hour >= 17 && hour < 19) return 'Before dinner';
    if (hour >= 19 && hour < 22) return 'After dinner';
    return 'Bedtime';
  }

  String _getMealDescription(String mealType) {
    final breakfasts = ['Oatmeal with berries', 'Eggs and whole wheat toast', 'Greek yogurt with nuts'];
    final lunches = ['Grilled chicken salad', 'Brown rice with vegetables', 'Turkey sandwich'];
    final dinners = ['Salmon with broccoli', 'Lean beef stir-fry', 'Grilled chicken with quinoa'];
    final snacks = ['Apple with peanut butter', 'Mixed nuts', 'String cheese'];

    switch (mealType) {
      case 'Breakfast':
        return breakfasts[_random.nextInt(breakfasts.length)];
      case 'Lunch':
        return lunches[_random.nextInt(lunches.length)];
      case 'Dinner':
        return dinners[_random.nextInt(dinners.length)];
      default:
        return snacks[_random.nextInt(snacks.length)];
    }
  }

  double _randomGaussian(double min, double max) {
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    final randStdNormal = sqrt(-2.0 * log(u1)) * sin(2.0 * pi * u2);
    final mean = (min + max) / 2;
    final stdDev = (max - min) / 6;
    return mean + stdDev * randStdNormal;
  }
}
```

florence\platform_service\lib\features\patient\dashboard\screens\bmi_detail_screen.dart
```
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class BmiDetailScreen extends ConsumerWidget {
  const BmiDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorAsync = ref.watch(monitorDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Analytics'),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.getBorderColor(context),
            height: 1.0,
          ),
        ),
      ),
      body: monitorAsync.when(
        data: (dataList) {
          // Filter BMI Data
          final bmiReadings = dataList
              .where((d) => d.dataType == MonitorDataType.BMI)
              .toList();
          
          // Sort by date ascending
          bmiReadings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

          // Get latest reading
          final latestBmi = bmiReadings.isNotEmpty ? bmiReadings.last : null;

          // Get correlation data (HbA1c)
          final hba1cReadings = dataList
              .where((d) => d.dataType == MonitorDataType.HBA1C)
              .toList()
            ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

          return RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(monitorDataProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. Linear Gauge (Current Status)
                  _BmiGaugeSection(latestReading: latestBmi),
                  const SizedBox(height: 20),

                  // 2. Progress Chart (BMI Trend)
                  _BmiTrendSection(readings: bmiReadings),
                  const SizedBox(height: 20),

                  // 3. Clinical Insight (Correlation)
                  _BmiCorrelationSection(
                    bmiReadings: bmiReadings,
                    hba1cReadings: hba1cReadings,
                  ),
                  const SizedBox(height: 20),

                  // 4. History List
                  _BmiHistorySection(readings: bmiReadings),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// ============================================================================
// REUSABLE CHART WRAPPER (Consistent Layout)
// ============================================================================

class _ChartSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget Function(String range, List<MonitorData> filteredData) builder;
  final List<MonitorData> allData;
  final List<String> ranges;

  const _ChartSection({
    required this.title,
    required this.icon,
    required this.infoText,
    required this.builder,
    required this.allData,
    this.ranges = const ['6M', '1Y', 'ALL'], // Default for slow metrics like BMI
  });

  @override
  State<_ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<_ChartSection> {
  late String _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.ranges.first;
    if (widget.ranges.contains('1D')) _selectedRange = '1D';
  }

  List<MonitorData> _filterData() {
    if (widget.allData.isEmpty) return [];
    if (_selectedRange == 'ALL') return widget.allData;

    final now = DateTime.now();
    Duration duration;
    switch (_selectedRange) {
      case '1D': duration = const Duration(days: 1); break;
      case '1M': duration = const Duration(days: 30); break;
      case '3M': duration = const Duration(days: 90); break;
      case '6M': duration = const Duration(days: 180); break;
      case '1Y': duration = const Duration(days: 365); break;
      default: duration = const Duration(days: 365); break;
    }
    final cutoff = now.subtract(duration);
    return widget.allData.where((d) => d.measuredAt.isAfter(cutoff)).toList();
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(widget.icon, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(widget.infoText, style: Theme.of(context).textTheme.bodyMedium),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    final filteredData = _filterData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(widget.icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () => _showInfoDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tabs
          Container(
            height: 36,
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: widget.ranges.map((range) {
                final isSelected = _selectedRange == range;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRange = range),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: isSelected ? AppTheme.primaryBlue : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                      child: Text(_getRangeLabel(range), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          widget.builder(_selectedRange, filteredData),
        ],
      ),
    );
  }

  String _getRangeLabel(String key) {
    switch (key) {
      case '1D': return 'Daily';
      case '1M': return 'Monthly';
      case '3M': return 'Quarterly';
      case '6M': return 'Half Year';
      case '1Y': return 'Yearly';
      case 'ALL': return 'All Time';
      default: return key;
    }
  }
}

// ============================================================================
// 1. LINEAR GAUGE (CURRENT STATUS)
// ============================================================================

class _BmiGaugeSection extends StatelessWidget {
  final MonitorData? latestReading;

  const _BmiGaugeSection({this.latestReading});

  @override
  Widget build(BuildContext context) {
    final bmi = latestReading?.value ?? 0.0;
    String category;
    Color color;

    if (bmi == 0) {
      category = "No Data";
      color = AppTheme.textSecondaryColor;
    } else if (bmi < 18.5) {
      category = "Underweight";
      color = AppTheme.primaryBlue;
    } else if (bmi < 25) {
      category = "Normal";
      color = AppTheme.primaryGreen;
    } else if (bmi < 30) {
      category = "Overweight";
      color = AppTheme.warningColor;
    } else {
      category = "Obese";
      color = AppTheme.errorColor;
    }

    return _BmiCard(
      title: 'Current Status',
      icon: Icons.speed,
      infoText: 'Body Mass Index (BMI) Categories:\n\n'
          '• Underweight: < 18.5\n'
          '• Normal: 18.5 – 24.9\n'
          '• Overweight: 25 – 29.9\n'
          '• Obese: 30+',
      child: Column(
        children: [
          // 1. Target Range Display (Top)
          InkWell(
            onTap: () => Navigator.of(context).pushNamed('/profile'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.track_changes, size: 18, color: AppTheme.primaryGreen),
                          const SizedBox(width: 8),
                          Text(
                            'Target Range',
                            style: TextStyle(
                              color: AppTheme.primaryGreen.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.chevron_right, size: 20, color: AppTheme.primaryGreen.withOpacity(0.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('BMI', style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen.withOpacity(0.8))),
                      Text('18.5 - 24.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (latestReading == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("No BMI data recorded."),
            )
          else ...[
            // 2. Value (Moved Above Chart)
            Text(
              bmi.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                height: 1.0,
              ),
            ),
            
            const SizedBox(height: 24),

            // 3. Linear Gauge (Middle)
            SizedBox(
              height: 40,
              child: LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                const minScale = 15.0;
                const maxScale = 35.0;
                final totalRange = maxScale - minScale;

                double getPos(double val) {
                  return ((val.clamp(minScale, maxScale) - minScale) / totalRange) * width;
                }

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // Track
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Container(width: (3.5 / totalRange) * width, color: AppTheme.primaryBlue.withOpacity(0.3)), // Underweight
                          Container(width: (6.5 / totalRange) * width, color: AppTheme.primaryGreen.withOpacity(0.3)), // Normal
                          Container(width: (5.0 / totalRange) * width, color: AppTheme.warningColor.withOpacity(0.3)), // Overweight
                          Expanded(child: Container(color: AppTheme.errorColor.withOpacity(0.3))), // Obese
                        ],
                      ),
                    ),
                    // Marker
                    Positioned(
                      left: getPos(bmi) - 12,
                      top: -12,
                      child: Column(
                        children: [
                          Icon(Icons.arrow_drop_down, size: 24, color: AppTheme.textPrimaryColor),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 8),
            // Scale Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("15.0", style: Theme.of(context).textTheme.bodySmall),
                Text("18.5", style: Theme.of(context).textTheme.bodySmall),
                Text("25.0", style: Theme.of(context).textTheme.bodySmall),
                Text("30.0", style: Theme.of(context).textTheme.bodySmall),
                Text("35+", style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            
            const SizedBox(height: 24),

            // 4. Status Badge (Below Chart)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                category.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 2. TREND CHART (PROGRESS)
// ============================================================================

class _BmiTrendSection extends StatelessWidget {
  final List<MonitorData> readings;

  const _BmiTrendSection({required this.readings});

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Progress',
      icon: Icons.show_chart,
      ranges: const ['1D', '3M', '6M', '1Y', 'ALL'],
      infoText: 'Visualizes your BMI trends over time.\n\n'
          '• Y-Axis: BMI (kg/m²)\n'
          '• X-Axis: Time\n'
          '• Green Band: Normal BMI Range (18.5 - 25).',
      allData: readings,
      builder: (range, data) {
        if (data.isEmpty) {
          return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No data available for this period.")));
        }

        // Calculate X-Axis bounds based on selected range
        double minX, maxX;
        final now = DateTime.now();

        if (range == '1D') {
          final startOfDay = DateTime(now.year, now.month, now.day);
          minX = startOfDay.millisecondsSinceEpoch.toDouble();
          maxX = startOfDay.add(const Duration(days: 1)).millisecondsSinceEpoch.toDouble();
        } else if (range == 'ALL') {
          minX = data.first.measuredAt.millisecondsSinceEpoch.toDouble();
          maxX = data.last.measuredAt.millisecondsSinceEpoch.toDouble();
          if (minX == maxX) {
            minX -= 2629743000; // -1 Month
            maxX += 2629743000; // +1 Month
          }
        } else {
          maxX = now.millisecondsSinceEpoch.toDouble();
          Duration duration;
          switch (range) {
            case '1M': duration = const Duration(days: 30); break;
            case '3M': duration = const Duration(days: 90); break;
            case '6M': duration = const Duration(days: 180); break;
            case '1Y': duration = const Duration(days: 365); break;
            default: duration = const Duration(days: 365); break;
          }
          minX = now.subtract(duration).millisecondsSinceEpoch.toDouble();
        }

        // Dynamic Y Axis with Safe Zone (18.5 - 25) visibility
        final vals = data.map((e) => e.value);
        double minY = vals.reduce(math.min) - 2;
        double maxY = vals.reduce(math.max) + 2;
        
        // Ensure safe zone is visible
        minY = math.min(minY, 18.0);
        maxY = math.max(maxY, 26.0);

        return Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  clipData: const FlClipData.all(),
                  minX: minX, maxX: maxX, minY: minY, maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (maxX - minX) / 4,
                        getTitlesWidget: (val, _) {
                          final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                          final durationDays = Duration(milliseconds: (maxX - minX).toInt()).inDays;
                          final fmt = range == '1D' ? DateFormat('HH:mm') : (durationDays > 90 ? DateFormat('MMM y') : DateFormat('d/M'));

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(fmt.format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(y1: 18.5, y2: 25, color: AppTheme.primaryGreen.withOpacity(0.2)),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                      isCurved: true,
                      color: AppTheme.primaryBlue,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 3, color: AppTheme.primaryBlue, strokeColor: Colors.white, strokeWidth: 1.5),
                      ),
                      belowBarData: BarAreaData(show: true, color: AppTheme.primaryBlue.withOpacity(0.1)),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(date)}\n',
                            const TextStyle(color: Colors.white70, fontSize: 10),
                            children: [
                              TextSpan(
                                text: spot.y.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem('BMI', AppTheme.primaryBlue, isCircle: true),
                const SizedBox(width: 16),
                _LegendItem('Normal Range', AppTheme.primaryGreen.withOpacity(0.5), isBox: true),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// 3. CORRELATION (BMI vs HbA1c)
// ============================================================================

class _BmiCorrelationSection extends StatelessWidget {
  final List<MonitorData> bmiReadings;
  final List<MonitorData> hba1cReadings;

  const _BmiCorrelationSection({
    required this.bmiReadings,
    required this.hba1cReadings,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'BMI vs. HbA1c',
      icon: Icons.insights,
      infoText: 'Compares your BMI trends against HbA1c levels over time.\n\n'
          '• Blue Line: BMI\n'
          '• Purple Dots: HbA1c %\n'
          '• Goal: Observe if weight changes correlate with better blood sugar control.',
      allData: bmiReadings, // Pass BMI to drive range logic
      ranges: const ['1D', '6M', '1Y', 'ALL'],
      builder: (range, data) {
        // 'data' here is filtered BMI readings
        if (data.isEmpty) {
          return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No BMI data for correlation.")));
        }

        // Calculate X-Axis bounds based on selected range (Consistent with Trend Chart)
        double minX, maxX;
        final now = DateTime.now();

        if (range == '1D') {
          final startOfDay = DateTime(now.year, now.month, now.day);
          minX = startOfDay.millisecondsSinceEpoch.toDouble();
          maxX = startOfDay.add(const Duration(days: 1)).millisecondsSinceEpoch.toDouble();
        } else if (range == 'ALL') {
          minX = data.first.measuredAt.millisecondsSinceEpoch.toDouble();
          maxX = data.last.measuredAt.millisecondsSinceEpoch.toDouble();
          if (minX == maxX) {
            minX -= 2629743000; // -1 Month
            maxX += 2629743000; // +1 Month
          }
        } else {
          maxX = now.millisecondsSinceEpoch.toDouble();
          Duration duration;
          switch (range) {
            case '1M': duration = const Duration(days: 30); break;
            case '3M': duration = const Duration(days: 90); break;
            case '6M': duration = const Duration(days: 180); break;
            case '1Y': duration = const Duration(days: 365); break;
            default: duration = const Duration(days: 365); break;
          }
          minX = now.subtract(duration).millisecondsSinceEpoch.toDouble();
        }

        // Filter HbA1c based on the calculated time range
        final startDt = DateTime.fromMillisecondsSinceEpoch(minX.toInt());
        final endDt = DateTime.fromMillisecondsSinceEpoch(maxX.toInt());
        
        final displayHba1c = hba1cReadings.where((r) => 
          r.measuredAt.isAfter(startDt.subtract(const Duration(days: 7))) && 
          r.measuredAt.isBefore(endDt.add(const Duration(days: 7)))
        ).toList();

        // Normalize Y-Axis: Map HbA1c (4-12) to fit visually within BMI range (15-40)
        // y_chart = ((hba1c - 4) / 8) * 25 + 15
        
        return Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  clipData: const FlClipData.all(),
                  minX: minX, maxX: maxX,
                  minY: 15, maxY: 40, // BMI Scale
                  
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                            final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                            // Determine format based on range, similar to BMI Trend
                            final durationDays = Duration(milliseconds: (maxX - minX).toInt()).inDays;
                            final fmt = range == '1D'
                                ? DateFormat('HH:mm')
                                : (durationDays > 365 ? DateFormat('MMM yy') : DateFormat('d/M'));

                           return Padding(
                             padding: const EdgeInsets.only(top: 8.0),
                             child: Text(fmt.format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                           );
                        }
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1)),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  lineBarsData: [
                    // BMI Line (Blue)
                    LineChartBarData(
                      spots: data.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                      color: AppTheme.primaryBlue,
                      barWidth: 3,
                      isCurved: true,
                      dotData: FlDotData(show: false),
                    ),
                    // HbA1c Line (Purple - Scaled)
                    LineChartBarData(
                      spots: displayHba1c.map((r) {
                        final scaledY = ((r.value - 4) / 8) * 25 + 15;
                        return FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), scaledY);
                      }).toList(),
                      color: Colors.purple,
                      barWidth: 0, 
                      isCurved: false,
                      dotData: FlDotData(
                        show: true, 
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: Colors.purple, strokeWidth: 1, strokeColor: Colors.white)
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                          final dateStr = DateFormat('MMM d').format(date);
                          
                          if (spot.barIndex == 0) {
                            return LineTooltipItem(
                              '$dateStr\n',
                              const TextStyle(color: Colors.white70, fontSize: 10),
                              children: [
                                TextSpan(
                                  text: "BMI: ${spot.y.toStringAsFixed(1)}",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            );
                          } else {
                            final realVal = ((spot.y - 15)/25)*8 + 4;
                            return LineTooltipItem(
                              '$dateStr\n',
                              const TextStyle(color: Colors.white70, fontSize: 10),
                              children: [
                                TextSpan(
                                  text: "HbA1c: ${realVal.toStringAsFixed(1)}%",
                                  style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            );
                          }
                        }).toList();
                      }
                    )
                  )
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem('BMI', AppTheme.primaryBlue, isCircle: true),
                const SizedBox(width: 16),
                _LegendItem('HbA1c %', Colors.purple, isCircle: true),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// 4. HISTORY LIST
// ============================================================================

class _BmiHistorySection extends StatefulWidget {
  final List<MonitorData> readings;

  const _BmiHistorySection({required this.readings});

  @override
  State<_BmiHistorySection> createState() => _BmiHistorySectionState();
}

class _BmiHistorySectionState extends State<_BmiHistorySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    final reversed = widget.readings.reversed.toList();
    final totalItems = reversed.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    if (totalPages == 0) _currentPage = 0;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = totalItems > 0 ? reversed.sublist(start, end) : <MonitorData>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header with Pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              if (totalPages > 0)
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                      icon: const Icon(Icons.chevron_left),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${_currentPage + 1}/$totalPages',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                      icon: const Icon(Icons.chevron_right),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (currentItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text("No history available")),
            )
          else
            ...currentItems.map((r) {
              String label;
              Color color;
              if (r.value < 18.5) { label = "Underweight"; color = AppTheme.primaryBlue; }
              else if (r.value < 25) { label = "Normal"; color = AppTheme.primaryGreen; }
              else if (r.value < 30) { label = "Overweight"; color = AppTheme.warningColor; }
              else { label = "Obese"; color = AppTheme.errorColor; }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          r.value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'kg/m²',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                        ),
                        const SizedBox(height: 4),
                        Text(DateFormat('dd/MM/yy HH:mm').format(r.measuredAt), style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                      ],
                    )
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPERS
// ============================================================================

class _BmiCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget child;

  const _BmiCard({required this.title, required this.icon, required this.infoText, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: [
                          Icon(icon, color: AppTheme.primaryBlue),
                          const SizedBox(width: 12),
                          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      content: Text(infoText, style: Theme.of(context).textTheme.bodyMedium),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Got it"))],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isBox;
  final bool isCircle;

  const _LegendItem(this.label, this.color, {super.key, this.isBox = false, this.isCircle = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBox)
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))
        else if (isCircle)
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
        else
          Container(width: 12, height: 2, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
```

florence\platform_service\lib\features\patient\trends\screens\activity_impact_screen.dart
```
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';

/// Activity Impact Analysis Screen
/// Shows how different physical activities affect glucose levels
class ActivityImpactScreen extends StatefulWidget {
  const ActivityImpactScreen({super.key});

  @override
  State<ActivityImpactScreen> createState() => _ActivityImpactScreenState();
}

class _ActivityImpactScreenState extends State<ActivityImpactScreen> {
  bool _isLoading = false;
  String _selectedIntensity = 'All';

  // Intensity filter options
  final List<String> _intensities = [
    'All',
    'Light',
    'Moderate',
    'Vigorous',
  ];

  // Mock activity impact data
  List<ActivityImpact> _allActivities = [];
  List<ActivityImpact> _filteredActivities = [];

  @override
  void initState() {
    super.initState();
    _loadActivityImpactData();
  }

  /// Load activity impact data
  Future<void> _loadActivityImpactData() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Load real data from Supabase
      // For now, generate mock data
      _generateMockActivityData();

      // Filter by intensity
      _filterActivitiesByIntensity();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error loading activity impact data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Generate mock activity impact data
  void _generateMockActivityData() {
    _allActivities = [
      // Light intensity
      ActivityImpact(
        activityName: 'Walking (Slow)',
        intensity: 'Light',
        avgDuration: 30,
        beforeGlucose: 145,
        afterGlucose: 130,
        glucoseDrop: 15,
        frequency: 25,
        caloriesBurned: 90,
        effectiveness: 3.5,
        optimalTiming: 'After meals',
      ),
      ActivityImpact(
        activityName: 'Yoga',
        intensity: 'Light',
        avgDuration: 45,
        beforeGlucose: 128,
        afterGlucose: 118,
        glucoseDrop: 10,
        frequency: 12,
        caloriesBurned: 135,
        effectiveness: 3.0,
        optimalTiming: 'Morning',
      ),
      ActivityImpact(
        activityName: 'Stretching',
        intensity: 'Light',
        avgDuration: 20,
        beforeGlucose: 135,
        afterGlucose: 128,
        glucoseDrop: 7,
        frequency: 15,
        caloriesBurned: 40,
        effectiveness: 2.5,
        optimalTiming: 'Anytime',
      ),

      // Moderate intensity
      ActivityImpact(
        activityName: 'Walking (Brisk)',
        intensity: 'Moderate',
        avgDuration: 30,
        beforeGlucose: 152,
        afterGlucose: 122,
        glucoseDrop: 30,
        frequency: 20,
        caloriesBurned: 150,
        effectiveness: 4.5,
        optimalTiming: 'After lunch',
      ),
      ActivityImpact(
        activityName: 'Cycling',
        intensity: 'Moderate',
        avgDuration: 40,
        beforeGlucose: 148,
        afterGlucose: 110,
        glucoseDrop: 38,
        frequency: 10,
        caloriesBurned: 280,
        effectiveness: 4.8,
        optimalTiming: 'Morning',
      ),
      ActivityImpact(
        activityName: 'Swimming',
        intensity: 'Moderate',
        avgDuration: 35,
        beforeGlucose: 140,
        afterGlucose: 105,
        glucoseDrop: 35,
        frequency: 8,
        caloriesBurned: 245,
        effectiveness: 4.7,
        optimalTiming: 'Afternoon',
      ),
      ActivityImpact(
        activityName: 'Dancing',
        intensity: 'Moderate',
        avgDuration: 30,
        beforeGlucose: 138,
        afterGlucose: 115,
        glucoseDrop: 23,
        frequency: 6,
        caloriesBurned: 180,
        effectiveness: 4.0,
        optimalTiming: 'Evening',
      ),

      // Vigorous intensity
      ActivityImpact(
        activityName: 'Running',
        intensity: 'Vigorous',
        avgDuration: 25,
        beforeGlucose: 155,
        afterGlucose: 108,
        glucoseDrop: 47,
        frequency: 15,
        caloriesBurned: 325,
        effectiveness: 5.0,
        optimalTiming: 'Morning',
      ),
      ActivityImpact(
        activityName: 'HIIT Workout',
        intensity: 'Vigorous',
        avgDuration: 20,
        beforeGlucose: 142,
        afterGlucose: 98,
        glucoseDrop: 44,
        frequency: 8,
        caloriesBurned: 280,
        effectiveness: 4.9,
        optimalTiming: 'Morning',
      ),
      ActivityImpact(
        activityName: 'Weight Training',
        intensity: 'Vigorous',
        avgDuration: 45,
        beforeGlucose: 138,
        afterGlucose: 102,
        glucoseDrop: 36,
        frequency: 12,
        caloriesBurned: 315,
        effectiveness: 4.6,
        optimalTiming: 'Afternoon',
      ),
      ActivityImpact(
        activityName: 'Basketball',
        intensity: 'Vigorous',
        avgDuration: 35,
        beforeGlucose: 145,
        afterGlucose: 105,
        glucoseDrop: 40,
        frequency: 6,
        caloriesBurned: 350,
        effectiveness: 4.7,
        optimalTiming: 'Afternoon',
      ),
    ];

    // Sort by effectiveness (descending)
    _allActivities.sort((a, b) => b.effectiveness.compareTo(a.effectiveness));
  }

  /// Filter activities by intensity
  void _filterActivitiesByIntensity() {
    if (_selectedIntensity == 'All') {
      _filteredActivities = List.from(_allActivities);
    } else {
      _filteredActivities = _allActivities
          .where((activity) => activity.intensity == _selectedIntensity)
          .toList();
    }
  }

  /// Change intensity filter
  void _changeIntensity(String intensity) {
    setState(() {
      _selectedIntensity = intensity;
      _filterActivitiesByIntensity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topActivities = _filteredActivities.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Impact Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog();
            },
            tooltip: 'Information',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadActivityImpactData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Intensity filter
                    _buildIntensityFilter(),
                    const SizedBox(height: 24),

                    // Summary stats
                    _buildSummaryStats(),
                    const SizedBox(height: 24),

                    // Correlation scatter chart
                    _buildCorrelationChart(),
                    const SizedBox(height: 24),

                    // Duration vs effectiveness
                    _buildDurationEffectivenessChart(),
                    const SizedBox(height: 24),

                    // Top activities
                    _buildTopActivitiesSection(topActivities),
                    const SizedBox(height: 24),

                    // Complete activity ranking
                    _buildCompleteRanking(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build intensity filter
  Widget _buildIntensityFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _intensities.length,
        itemBuilder: (context, index) {
          final intensity = _intensities[index];
          final isSelected = intensity == _selectedIntensity;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(intensity),
              selected: isSelected,
              onSelected: (_) => _changeIntensity(intensity),
              selectedColor: AppTheme.primaryBlue,
              backgroundColor: AppTheme.backgroundColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build summary statistics
  Widget _buildSummaryStats() {
    final avgDrop = _filteredActivities.isEmpty
        ? 0.0
        : _filteredActivities
                .map((a) => a.glucoseDrop)
                .reduce((a, b) => a + b) /
            _filteredActivities.length;

    final totalActivities = _filteredActivities.length;
    final totalSessions = _filteredActivities.isEmpty
        ? 0
        : _filteredActivities
            .map((a) => a.frequency)
            .reduce((a, b) => a + b);

    final bestActivity = _filteredActivities.isEmpty
        ? null
        : _filteredActivities.reduce(
            (a, b) => a.effectiveness > b.effectiveness ? a : b);

    return BaseCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            'Avg Drop',
            '${avgDrop.toStringAsFixed(0)} mg/dL',
            Icons.trending_down,
            AppTheme.successColor,
          ),
          _buildStatColumn(
            'Activities',
            totalActivities.toString(),
            Icons.fitness_center,
            AppTheme.textPrimaryColor,
          ),
          _buildStatColumn(
            'Sessions',
            totalSessions.toString(),
            Icons.calendar_today,
            AppTheme.infoColor,
          ),
          _buildStatColumn(
            'Top',
            bestActivity?.activityName.split(' ').first ?? '-',
            Icons.star,
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build correlation scatter chart (Duration vs Glucose Drop)
  Widget _buildCorrelationChart() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Duration vs Glucose Drop',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Correlation between workout length and effectiveness',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: ResponsiveHelper.getResponsiveCardChartHeight(context),
            child: _filteredActivities.isEmpty
                ? Center(
                    child: Text(
                      'No activity data for this intensity',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ScatterChart(
                    ScatterChartData(
                      minX: 0,
                      maxX: 60,
                      minY: 0,
                      maxY: 60,
                      scatterSpots: _filteredActivities.map((activity) {
                        return ScatterSpot(
                          activity.avgDuration.toDouble(),
                          activity.glucoseDrop.toDouble(),
                          dotPainter: FlDotCirclePainter(
                            color: _getIntensityColor(activity.intensity),
                            radius: 8,
                          ),
                        );
                      }).toList(),
                      scatterTouchData: ScatterTouchData(
                        touchTooltipData: ScatterTouchTooltipData(
                          getTooltipItems: (spot) {
                            final activity = _filteredActivities.firstWhere(
                              (a) =>
                                  a.avgDuration.toDouble() == spot.x &&
                                  a.glucoseDrop.toDouble() == spot.y,
                            );
                            return ScatterTooltipItem(
                              '${activity.activityName}\n${activity.avgDuration} min → -${activity.glucoseDrop} mg/dL',
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) => const SizedBox.shrink(),
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Text(
                            'Duration (minutes)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 15,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  value.toInt().toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: Text(
                            'Glucose Drop (mg/dL)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: 15,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 15,
                        verticalInterval: 15,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.borderColor,
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: AppTheme.borderColor,
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
          ),
          if (_filteredActivities.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Light', _getIntensityColor('Light')),
                const SizedBox(width: 16),
                _buildLegendItem('Moderate', _getIntensityColor('Moderate')),
                const SizedBox(width: 16),
                _buildLegendItem('Vigorous', _getIntensityColor('Vigorous')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build duration vs effectiveness chart
  Widget _buildDurationEffectivenessChart() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Effectiveness Ranking',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on glucose reduction per minute',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: ResponsiveHelper.getResponsiveCardChartHeight(context),
            child: _filteredActivities.isEmpty
                ? Center(
                    child: Text(
                      'No activity data for this intensity',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 6,
                      minY: 0,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final activity =
                                _filteredActivities[group.x.toInt()];
                            return BarTooltipItem(
                              '${activity.activityName}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Rating: ${activity.effectiveness}/5',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) => const SizedBox.shrink(),
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= _filteredActivities.length) {
                                return const SizedBox();
                              }
                              final activity =
                                  _filteredActivities[value.toInt()];
                              final words = activity.activityName.split(' ');
                              final shortName = words.first;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  shortName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.borderColor,
                            strokeWidth: 1,
                          );
                        },
                        drawVerticalLine: false,
                      ),
                      barGroups: _filteredActivities
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final activity = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: activity.effectiveness,
                              color: _getIntensityColor(activity.intensity),
                              width: 24,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Build top activities section
  Widget _buildTopActivitiesSection(List<ActivityImpact> topActivities) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.activityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppTheme.activityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Most Effective Activities',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Best activities for glucose control',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topActivities.map((activity) => _buildActivityCard(activity)),
        ],
      ),
    );
  }

  /// Build complete ranking section
  Widget _buildCompleteRanking() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Activity Ranking',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'All activities sorted by effectiveness',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ..._filteredActivities.map((activity) {
            final rank = _filteredActivities.indexOf(activity) + 1;
            return _buildCompactActivityCard(activity, rank);
          }),
        ],
      ),
    );
  }

  /// Build activity card
  Widget _buildActivityCard(ActivityImpact activity) {
    final color = _getIntensityColor(activity.intensity);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '-${activity.glucoseDrop}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'mg/dL',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.activityName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < activity.effectiveness.floor()
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: AppTheme.warningColor,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity.avgDuration} min avg • ${activity.caloriesBurned} cal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${activity.intensity} • Best: ${activity.optimalTiming}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build compact activity card for complete ranking
  Widget _buildCompactActivityCard(ActivityImpact activity, int rank) {
    final color = _getIntensityColor(activity.intensity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.activityName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${activity.intensity} • ${activity.avgDuration} min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '-${activity.glucoseDrop}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Get color based on intensity
  Color _getIntensityColor(String intensity) {
    switch (intensity) {
      case 'Light':
        return AppTheme.successColor;
      case 'Moderate':
        return AppTheme.infoColor;
      case 'Vigorous':
        return AppTheme.primaryRed;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  /// Show information dialog
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Activity Impact'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This analysis shows how physical activity affects your glucose levels.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Effectiveness Rating: Based on glucose reduction per minute of activity.',
              ),
              SizedBox(height: 8),
              Text('Light: Low-intensity activities (walking, yoga).'),
              SizedBox(height: 8),
              Text('Moderate: Medium-intensity activities (brisk walking, cycling).'),
              SizedBox(height: 8),
              Text('Vigorous: High-intensity activities (running, HIIT).'),
              SizedBox(height: 12),
              Text(
                'Regular physical activity is one of the most effective ways to manage glucose levels.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Activity Impact Data Model
class ActivityImpact {
  final String activityName;
  final String intensity;
  final int avgDuration;
  final int beforeGlucose;
  final int afterGlucose;
  final int glucoseDrop;
  final int frequency;
  final int caloriesBurned;
  final double effectiveness;
  final String optimalTiming;

  ActivityImpact({
    required this.activityName,
    required this.intensity,
    required this.avgDuration,
    required this.beforeGlucose,
    required this.afterGlucose,
    required this.glucoseDrop,
    required this.frequency,
    required this.caloriesBurned,
    required this.effectiveness,
    required this.optimalTiming,
  });
}
```

florence\platform_service\lib\features\patient\dashboard\widgets\ai_insight_card.dart
```
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';

/// AI Insight Card
/// Displays AI-generated health insights and recommendations
class AIInsightCard extends StatelessWidget {
  final String insight;
  final VoidCallback? onTap;
  
  const AIInsightCard({
    super.key,
    required this.insight,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    const double borderRadius = 24.0;

    return AspectRatio(
      aspectRatio: 1.586,
      child: InkWell(
        onTap: onTap ?? () => Navigator.pushNamed(context, AppRoutes.recommendations),
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A237E), // Deep Indigo
                const Color(0xFF3949AB), // Indigo
                AppTheme.primaryBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Insights',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ],
                    ),
                    
                    const Spacer(),

                    // Insight Content
                    Text(
                      insight,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
```

florence\platform_service\lib\features\patient\dashboard\widgets\upcoming_reminders_card.dart
```
import 'package:flutter/material.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';

/// Upcoming Reminders Card
/// Displays upcoming health reminders and tasks
class UpcomingRemindersCard extends StatelessWidget {
  final List<Map<String, dynamic>> reminders;
  final VoidCallback? onViewAll;
  
  const UpcomingRemindersCard({
    super.key,
    required this.reminders,
    this.onViewAll,
  });
  
  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return BaseCard(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 12),
            Text(
              'All caught up!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'No upcoming reminders',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      );
    }
    
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: 20,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View all',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Reminders list
          ...reminders.take(3).map((reminder) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReminderItem(
                icon: reminder['icon'] as IconData,
                title: reminder['title'] as String,
                time: reminder['time'] as String,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

/// Single reminder item
class _ReminderItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  
  const _ReminderItem({
    required this.icon,
    required this.title,
    required this.time,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Arrow
        Icon(
          Icons.chevron_right,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
      ],
    );
  }
}```

florence\platform_service\lib\features\patient\dashboard\screens\blood_pressure_detail_screen.dart
```
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class BloodPressureDetailScreen extends ConsumerWidget {
  const BloodPressureDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorAsync = ref.watch(monitorDataProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure Analytics'),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.getBorderColor(context),
            height: 1.0,
          ),
        ),
      ),
      body: monitorAsync.when(
        data: (dataList) {
          // 1. Pair Systolic and Diastolic readings based on timestamp
          final readings = _pairReadings(dataList);

          // Sort by date ascending for charts
          readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // Get Thresholds
          final thresholds = thresholdsAsync.value ?? [];
          
          // Check for user-defined thresholds
          HealthThreshold? userSys;
          HealthThreshold? userDia;
          try { userSys = thresholds.firstWhere((t) => t.dataType == MonitorDataType.BLOOD_PRESSURE_SYSTOLIC); } catch (_) {}
          try { userDia = thresholds.firstWhere((t) => t.dataType == MonitorDataType.BLOOD_PRESSURE_DIASTOLIC); } catch (_) {}

          final isDefault = userSys == null || userDia == null;

          // Ensure we only pass thresholds if they exist, no defaults
          final sysThreshold = userSys;
          final diaThreshold = userDia;

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.refresh(monitorDataProvider.future),
                ref.refresh(patientThresholdsProvider.future),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 1. Statistics
                _StatisticsSection(
                  readings: readings, 
                  sysThreshold: sysThreshold, 
                  diaThreshold: diaThreshold,
                  isDefault: isDefault,
                ),
                const SizedBox(height: 20),

                // 2. Dual Trend Chart
                _DualTrendSection(
                  readings: readings,
                  sysThreshold: sysThreshold,
                  diaThreshold: diaThreshold,
                ),
                const SizedBox(height: 20),

                // 3. Floating Bar (Pulse Pressure / Daily Range)
                _FloatingBarSection(readings: readings),
                const SizedBox(height: 20),

                // 4. Scatter Plot
                _ScatterSection(
                  readings: readings,
                  sysThreshold: sysThreshold,
                  diaThreshold: diaThreshold,
                ),
                const SizedBox(height: 20),

                // 5. History List
                _HistorySection(
                  readings: readings,
                  sysThreshold: sysThreshold,
                  diaThreshold: diaThreshold,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  List<_BpReading> _pairReadings(List<MonitorData> data) {
    final Map<String, double> sysMap = {};
    final Map<String, double> diaMap = {};
    final Map<String, DateTime> timeMap = {};

    for (var d in data) {
      // Key by timestamp ISO string to pair readings logged together
      final key = d.measuredAt.toIso8601String(); 
      
      if (d.dataType == MonitorDataType.BLOOD_PRESSURE_SYSTOLIC) {
        sysMap[key] = d.value;
        timeMap[key] = d.measuredAt;
      } else if (d.dataType == MonitorDataType.BLOOD_PRESSURE_DIASTOLIC) {
        diaMap[key] = d.value;
        timeMap[key] = d.measuredAt;
      }
    }

    final List<_BpReading> paired = [];
    sysMap.forEach((key, sys) {
      if (diaMap.containsKey(key)) {
        paired.add(_BpReading(timeMap[key]!, sys, diaMap[key]!));
      }
    });

    return paired;
  }
}

class _BpReading {
  final DateTime timestamp;
  final double systolic;
  final double diastolic;
  _BpReading(this.timestamp, this.systolic, this.diastolic);
  
  double get pulsePressure => systolic - diastolic;
}

// ============================================================================
// REUSABLE WRAPPER
// ============================================================================

class _ChartSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget Function(String range, List<_BpReading> filteredData) builder;
  final List<_BpReading> allData;
  final List<String> ranges;

  const _ChartSection({
    required this.title,
    required this.icon,
    required this.infoText,
    required this.builder,
    required this.allData,
    this.ranges = const ['1D', '7D', '14D', '30D'],
  });

  @override
  State<_ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<_ChartSection> {
  late String _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.ranges.contains('7D') ? '7D' : widget.ranges.first;
    if (widget.ranges.contains('1D')) _selectedRange = '1D';
  }

  List<_BpReading> _filterData() {
    if (widget.allData.isEmpty) return [];
    final now = DateTime.now();
    DateTime cutoff;
    switch (_selectedRange) {
      case '7D':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case '14D':
        cutoff = now.subtract(const Duration(days: 14));
        break;
      case '30D':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case '1D':
      default:
        cutoff = DateTime(now.year, now.month, now.day);
        break;
    }
    return widget.allData.where((d) => d.timestamp.isAfter(cutoff)).toList();
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(widget.icon, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(widget.infoText, style: Theme.of(context).textTheme.bodyMedium),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    final filteredData = _filterData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(widget.icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () => _showInfoDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tabs
          Container(
            height: 36,
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: widget.ranges.map((range) {
                final isSelected = _selectedRange == range;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRange = range),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: isSelected ? AppTheme.primaryBlue : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                      child: Text(_getRangeLabel(range), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          widget.builder(_selectedRange, filteredData),
        ],
      ),
    );
  }

  String _getRangeLabel(String key) {
    switch (key) {
      case '1D': return 'Daily';
      case '7D': return 'Weekly';
      case '14D': return 'Bi-Weekly';
      case '30D': return 'Monthly';
      default: return key;
    }
  }
}

// ============================================================================
// SECTIONS
// ============================================================================

class _StatisticsSection extends StatelessWidget {
  final List<_BpReading> readings;
  final HealthThreshold? sysThreshold;
  final HealthThreshold? diaThreshold;
  final bool isDefault;

  const _StatisticsSection({
    required this.readings, 
    this.sysThreshold, 
    this.diaThreshold,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Overview',
      icon: Icons.analytics_outlined,
      infoText: 'Key statistics for blood pressure.\n\n'
                '• Average: Mean systolic/diastolic levels.\n'
                '• Pulse Pressure: Difference between systolic and diastolic (Sys - Dia).\n'
                '• Target: Your configured safe range.',
      allData: readings,
      builder: (range, data) {
        double avgSys = 0, avgDia = 0, avgPulse = 0;
        if (data.isNotEmpty) {
          avgSys = data.map((e) => e.systolic).reduce((a, b) => a + b) / data.length;
          avgDia = data.map((e) => e.diastolic).reduce((a, b) => a + b) / data.length;
          avgPulse = data.map((e) => e.pulsePressure).reduce((a, b) => a + b) / data.length;
        }

        return Column(
          children: [
             // Target Range Display
            InkWell(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.track_changes, size: 18, color: AppTheme.primaryGreen),
                            const SizedBox(width: 8),
                            Text(
                              'Target Ranges',
                              style: TextStyle(color: AppTheme.primaryGreen.withOpacity(0.8), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppTheme.primaryGreen.withOpacity(0.5),
                        ),
                      ],
                    ),
                    if (sysThreshold != null && diaThreshold != null) ...[
                      const SizedBox(height: 12),
                      _buildMiniTargetRow('Systolic', '${sysThreshold!.minValue.toInt()} - ${sysThreshold!.maxValue.toInt()} mmHg', AppTheme.primaryGreen),
                      const SizedBox(height: 4),
                      _buildMiniTargetRow('Diastolic', '${diaThreshold!.minValue.toInt()} - ${diaThreshold!.maxValue.toInt()} mmHg', AppTheme.primaryGreen),
                    ] else ...[
                      const SizedBox(height: 12),
                      _buildMiniTargetRow('Systolic', 'Not Set', AppTheme.textSecondaryColor),
                      const SizedBox(height: 4),
                      _buildMiniTargetRow('Diastolic', 'Not Set', AppTheme.textSecondaryColor),
                    ],
                  ],
                ),
              ),
            ),
            // Stats Grid
            Row(
              children: [
                Expanded(child: _buildStatBox(context, 'Avg Systolic', avgSys.toStringAsFixed(0), 'mmHg', AppTheme.primaryRed)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, 'Avg Diastolic', avgDia.toStringAsFixed(0), 'mmHg', AppTheme.primaryBlue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, 'Pulse Pressure', avgPulse.toStringAsFixed(0), 'mmHg', AppTheme.textSecondaryColor)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniTargetRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String title, String value, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 2),
              Text(unit, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DualTrendSection extends StatelessWidget {
  final List<_BpReading> readings;
  final HealthThreshold? sysThreshold;
  final HealthThreshold? diaThreshold;

  const _DualTrendSection({required this.readings, this.sysThreshold, this.diaThreshold});

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Pressure Trends',
      icon: Icons.show_chart,
      infoText: 'Visualizes your blood pressure trends over time.\n\n'
                '• Y-Axis: Pressure (mmHg)\n'
                '• X-Axis: Time\n'
                '• Shaded Band: Readings within your target safe zone.',
      allData: readings,
      builder: (range, data) {
        double minX, maxX;
        if (range == '1D') {
           final now = DateTime.now();
          // For Daily view, always show today's full 24h range
          final startOfDay = DateTime(now.year, now.month, now.day);
          minX = startOfDay.millisecondsSinceEpoch.toDouble();
          maxX = startOfDay.add(const Duration(days: 1)).millisecondsSinceEpoch.toDouble();
        } else if (data.isNotEmpty) {
           minX = data.first.timestamp.millisecondsSinceEpoch.toDouble();
           maxX = data.last.timestamp.millisecondsSinceEpoch.toDouble();
           if (minX == maxX) { minX -= 3600000; maxX += 3600000; } 
        } else {
           final now = DateTime.now();
           Duration d = const Duration(days: 7);
           if (range == '14D') d = const Duration(days: 14);
           else if (range == '30D') d = const Duration(days: 30);
           minX = now.subtract(d).millisecondsSinceEpoch.toDouble();
           maxX = now.millisecondsSinceEpoch.toDouble();
        }

        return Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: minX, maxX: maxX, minY: 40, maxY: 180,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                    getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (maxX - minX) / (range == '1D' ? 6 : 4), // More ticks for daily view
                        getTitlesWidget: (value, meta) {
                          // Aggressively hide labels near the start and end
                          // Using meta.min/max ensures we match the chart's actual viewport
                          final tolerance = (meta.max - meta.min) * 0.05; // 5% margin
                          if (value <= meta.min + tolerance || value >= meta.max - tolerance) {
                            return const SizedBox();
                          }

                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          // 1D shows Time (HH:mm), others show Date (d/M)
                          final text = range == '1D' 
                              ? DateFormat('HH:mm').format(date) 
                              : DateFormat('d/M').format(date);
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(text, style: const TextStyle(fontSize: 10)));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  // Safe Zones
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [
                      if (sysThreshold != null)
                        HorizontalRangeAnnotation(y1: sysThreshold!.minValue, y2: sysThreshold!.maxValue, color: AppTheme.primaryRed.withOpacity(0.05)),
                      if (diaThreshold != null)
                        HorizontalRangeAnnotation(y1: diaThreshold!.minValue, y2: diaThreshold!.maxValue, color: AppTheme.primaryBlue.withOpacity(0.05)),
                    ]
                  ),
                  // Dotted Threshold Lines
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (sysThreshold != null) ...[
                        HorizontalLine(y: sysThreshold!.minValue, color: AppTheme.primaryRed.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
                        HorizontalLine(y: sysThreshold!.maxValue, color: AppTheme.primaryRed.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
                      ],
                      if (diaThreshold != null) ...[
                        HorizontalLine(y: diaThreshold!.minValue, color: AppTheme.primaryBlue.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
                        HorizontalLine(y: diaThreshold!.maxValue, color: AppTheme.primaryBlue.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
                      ],
                    ],
                  ),
                  lineBarsData: [
                    // Systolic Line
                    LineChartBarData(
                      spots: data.map((r) => FlSpot(r.timestamp.millisecondsSinceEpoch.toDouble(), r.systolic)).toList(),
                      color: AppTheme.primaryRed, barWidth: 2, isCurved: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: AppTheme.primaryRed, strokeWidth: 1.5, strokeColor: Colors.white),
                      ),
                    ),
                    // Diastolic Line
                    LineChartBarData(
                      spots: data.map((r) => FlSpot(r.timestamp.millisecondsSinceEpoch.toDouble(), r.diastolic)).toList(),
                      color: AppTheme.primaryBlue, barWidth: 2, isCurved: true,
                      dotData: FlDotData(
                         show: true,
                         getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: AppTheme.primaryBlue, strokeWidth: 1.5, strokeColor: Colors.white),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          // Thinner line (0.5)
                          const FlLine(color: AppTheme.textSecondaryColor, strokeWidth: 0.5),
                          FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppTheme.primaryBlue, strokeColor: Colors.white)),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                           final isSys = spot.barIndex == 0;
                           return LineTooltipItem(
                             '${isSys ? "Sys" : "Dia"}: ${spot.y.toInt()}',
                             const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                           );
                        }).toList();
                      }
                    )
                  )
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
               _buildLegendItem('Systolic', AppTheme.primaryRed, isCircle: true),
               _buildLegendItem('Diastolic', AppTheme.primaryBlue, isCircle: true),
               _buildLegendItem('Sys Limit', AppTheme.primaryRed.withOpacity(0.5), isBox: true),
               _buildLegendItem('Dia Limit', AppTheme.primaryBlue.withOpacity(0.5), isBox: true),
            ]),
          ],
        );
      },
    );
  }
}

class _FloatingBarSection extends StatelessWidget {
  final List<_BpReading> readings;

  const _FloatingBarSection({required this.readings});

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Daily Range (Pulse Pressure)',
      icon: Icons.bar_chart,
      infoText: 'Visualizes the gap between your systolic and diastolic numbers.\n\n'
                '• Y-Axis: Pressure (mmHg)\n'
                '• X-Axis: Time\n'
                '• Bar Height: Difference between Systolic and Diastolic.',
      allData: readings,
      builder: (range, data) {
        // For bar chart, too many points look bad. Limit or aggregate if needed.
        // Here we simply show the data points available in range.
        // If 1D, show actual points. If 30D, we might want to sample, but filtering is done by wrapper.
        
        return Column(
          children: [
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 200, minY: 40,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: range == '1D' ? (data.length > 0 ? data.length / 6 : 1) : 1,
                        getTitlesWidget: (v, meta) {
                          if (v.toInt() >= data.length) return const SizedBox();

                          final int index = v.toInt();
                          final int total = data.length;
                          bool shouldSkip = false;

                          // Smartly skip labels to avoid clutter
                          switch (range) {
                            case '1D':
                              if (total > 12) shouldSkip = index % 3 != 0; // Show every 3rd
                              else if (total > 5) shouldSkip = index % 2 != 0; // Show every 2nd
                              break;
                            case '30D':
                              if (total > 15) shouldSkip = index % 5 != 0; // Show every 5th
                              else if (total > 8) shouldSkip = index % 3 != 0; // Show every 3rd
                              break;
                            default: // 7D, 14D
                              if (total > 10) shouldSkip = index % 2 != 0;
                              break;
                          }

                          // But, always show the first and last label for context
                          if (index == 0 || index == total - 1) {
                            shouldSkip = false;
                          }

                          if (shouldSkip) return const SizedBox();

                          final date = data[index].timestamp;
                          final text = range == '1D'
                              ? DateFormat('HH:mm').format(date)
                              : DateFormat('d/M').format(date);

                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(text, style: const TextStyle(fontSize: 10)));
                        })),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1)),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))), // Added border
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                         final r = data[group.x.toInt()];
                         return BarTooltipItem(
                           '${r.systolic.toInt()}/${r.diastolic.toInt()}',
                           const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                           children: [TextSpan(text: '\nPulse: ${r.pulsePressure.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.white70))],
                         );
                      }
                    )
                  ),
                  barGroups: data.asMap().entries.map((entry) {
                    final r = entry.value;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: r.systolic,
                          fromY: r.diastolic,
                          color: AppTheme.primaryBlue.withOpacity(0.6),
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Systolic (Top)', AppTheme.primaryBlue.withOpacity(0.6), isBox: true),
                const SizedBox(width: 16),
                _buildLegendItem('Diastolic (Bottom)', AppTheme.primaryBlue.withOpacity(0.6), isBox: true),
              ],
            )
          ],
        );
      },
    );
  }
}

class _ScatterSection extends StatelessWidget {
  final List<_BpReading> readings;
  final HealthThreshold? sysThreshold;
  final HealthThreshold? diaThreshold;

  const _ScatterSection({required this.readings, this.sysThreshold, this.diaThreshold});

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Systolic vs. Diastolic',
      icon: Icons.bubble_chart_outlined,
      infoText: 'Correlates your Systolic vs Diastolic pressure.\n\n'
                '• Y-Axis: Systolic (mmHg)\n'
                '• X-Axis: Diastolic (mmHg)\n'
                '• Color: Green (In Range), Red (Out of Range).',
      allData: readings,
      builder: (range, data) {
        return Column(
          children: [
            SizedBox(
              height: 250,
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: data.map((r) {
                    Color dotColor;
                    if (sysThreshold != null && diaThreshold != null) {
                      if (r.systolic > sysThreshold!.maxValue || r.diastolic > diaThreshold!.maxValue) {
                        dotColor = AppTheme.errorColor;
                      } else if (r.systolic < sysThreshold!.minValue || r.diastolic < diaThreshold!.minValue) {
                        dotColor = AppTheme.warningColor;
                      } else {
                        dotColor = AppTheme.primaryGreen;
                      }
                    } else {
                      dotColor = AppTheme.primaryBlue;
                    }
                    
                    return ScatterSpot(
                      r.diastolic, 
                      r.systolic,
                      dotPainter: FlDotCirclePainter(
                        color: dotColor,
                        radius: 4,
                        strokeWidth: 0,
                      ),
                    );
                  }).toList(),
                  minX: 40, maxX: 130,
                  minY: 80, maxY: 200,
                  gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1), getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20, getTitlesWidget: (value, meta) {
                      if (value <= meta.min || value >= meta.max) return const SizedBox();
                      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                    })),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  scatterTouchData: ScatterTouchData(
                    touchTooltipData: ScatterTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      getTooltipItems: (spot) {
                        return ScatterTooltipItem(
                          'Sys: ${spot.y.toInt()}\nDia: ${spot.x.toInt()}',
                          textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      }
                    )
                  )
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
               if (sysThreshold != null && diaThreshold != null) ...[
                 _buildLegendItem('Low', AppTheme.warningColor, isCircle: true),
                 const SizedBox(width: 16),
                 _buildLegendItem('Normal', AppTheme.primaryGreen, isCircle: true),
                 const SizedBox(width: 16),
                 _buildLegendItem('Elevated', AppTheme.errorColor, isCircle: true),
               ] else
                 _buildLegendItem('Recorded', AppTheme.primaryBlue, isCircle: true),
            ]),
          ],
        );
      },
    );
  }
}

class _HistorySection extends StatefulWidget {
  final List<_BpReading> readings;
  final HealthThreshold? sysThreshold;
  final HealthThreshold? diaThreshold;

  const _HistorySection({
    required this.readings,
    this.sysThreshold,
    this.diaThreshold,
  });

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reversed = widget.readings.reversed.toList();

    final totalItems = reversed.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = reversed.sublist(start, end);

    // Manually build container to allow Paginator in header (same layout as GlucoseDetailScreen)
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header Row with Paginator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24)
                  ),
                  const SizedBox(width: 12),
                  Text('History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              // Pagination Controls (Top Right)
              if (totalPages > 1)
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${_currentPage + 1}/$totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (currentItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No history available',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
            ),
            
          ...currentItems.map((r) {
             // Dynamic Status Logic using Thresholds
             String status;
             Color statusColor;
             
             if (widget.sysThreshold != null && widget.diaThreshold != null) {
               final sysMax = widget.sysThreshold!.maxValue;
               final diaMax = widget.diaThreshold!.maxValue;

               if (r.systolic > sysMax || r.diastolic > diaMax) {
                 status = 'ELEVATED';
                 statusColor = AppTheme.errorColor;
               } else if (r.systolic < widget.sysThreshold!.minValue || r.diastolic < widget.diaThreshold!.minValue) {
                 status = 'LOW';
                 statusColor = AppTheme.warningColor;
               } else {
                 status = 'NORMAL';
                 statusColor = AppTheme.primaryGreen;
               }
             } else {
               status = 'RECORDED';
               statusColor = AppTheme.primaryBlue;
             }

             return Container(
               margin: const EdgeInsets.only(bottom: 12),
               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
               decoration: BoxDecoration(
                 color: isDark ? AppTheme.midnightSurface : Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.03),
                     blurRadius: 8,
                     offset: const Offset(0, 2)
                   )
                 ],
                 border: Border.all(
                   color: statusColor.withOpacity(0.3),
                   width: 1,
                 ),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   // Left: Value
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.baseline,
                     textBaseline: TextBaseline.alphabetic,
                     children: [
                       Text(
                         '${r.systolic.toInt()}/${r.diastolic.toInt()}',
                         style: TextStyle(
                           fontWeight: FontWeight.normal,
                           fontSize: 20, // Reduced font size
                           color: AppTheme.textPrimaryColor,
                         ),
                       ),
                       const SizedBox(width: 4),
                       Text(
                         'mmHg',
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                               color: AppTheme.textSecondaryColor,
                               fontSize: 12,
                             ),
                       ),
                     ],
                   ),
                   // Right: Date and Status Badge
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: statusColor.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Text(
                           status,
                           style: TextStyle(
                             color: statusColor,
                             fontSize: 10,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                       const SizedBox(height: 6),
                       Text(
                         DateFormat('dd/MM/yy HH:mm').format(r.timestamp),
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                               fontSize: 11,
                               color: AppTheme.textSecondaryColor,
                             ),
                       ),
                     ],
                   ),
                 ],
               ),
             );
          }),
        ],
      ),
    );
  }
}

Widget _emptyTitle(double value, TitleMeta meta) => const SizedBox.shrink();

class _ChartContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ChartContainer({super.key, required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.midnightSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

Widget _buildLegendItem(String label, Color color, {bool isBox = false, bool isCircle = false, bool isDashed = false}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (isBox)
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))
      else if (isCircle)
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
      else if (isDashed)
        Container(width: 2, height: 12, color: color)
      else
        Container(width: 12, height: 2, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}
```

florence\platform_service\lib\features\patient\core\providers\health_data_provider.dart
```
/// Health Data Provider for FLORENCE Digital Health Platform
/// State management for patient health data using Provider

import '../../../../core/providers/settings_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/health_data_models.dart';
import '../services/data_ingestion_service.dart';

/// Provider for managing all health-related data
/// This provider now depends on SettingsProvider to determine which data source to use.
class HealthDataProvider with ChangeNotifier {
  final DataIngestionService _dataService = DataIngestionService();

  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  void initialize() {
    if (!_isInitialized) {
      _isInitialized = true;
      refreshData(); // Initial data load
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== GLUCOSE DATA ====================

  List<GlucoseReading> get allGlucoseReadings =>
      _dataService.allGlucoseReadings;

  List<GlucoseReading> getGlucoseReadings({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _dataService.getGlucoseReadings(
      startDate: startDate,
      endDate: endDate,
    );
  }

  GlucoseReading? get latestGlucose =>
      allGlucoseReadings.isNotEmpty ? allGlucoseReadings.first : null;

  Future<void> addGlucoseReading(GlucoseReading reading) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.addGlucoseReading(reading);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGlucoseReading(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.deleteGlucoseReading(id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGlucoseReading(GlucoseReading reading) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.updateGlucoseReading(reading);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== MEAL DATA ====================

  List<MealLog> get allMeals => _dataService.allMeals;

  List<MealLog> getMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _dataService.getMeals(
      startDate: startDate,
      endDate: endDate,
    );
  }

  MealLog? get latestMeal => allMeals.isNotEmpty ? allMeals.first : null;

  Future<void> addMeal(MealLog meal) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.addMeal(meal);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMeal(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.deleteMeal(id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMeal(MealLog meal) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.updateMeal(meal);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== ACTIVITY DATA ====================

  List<ActivityLog> get allActivities => _dataService.allActivities;

  List<ActivityLog> getActivities({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _dataService.getActivities(
      startDate: startDate,
      endDate: endDate,
    );
  }

  ActivityLog? get latestActivity =>
      allActivities.isNotEmpty ? allActivities.first : null;

  Future<void> addActivity(ActivityLog activity) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.addActivity(activity);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.deleteActivity(id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateActivity(ActivityLog activity) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.updateActivity(activity);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== MEDICATION DATA ====================

  List<MedicationLog> get allMedications => _dataService.allMedications;

  Future<void> addMedication(MedicationLog medication) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.addMedication(medication);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.deleteMedication(id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMedication(MedicationLog medication) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.updateMedication(medication);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markDoseTaken(String medicationId, String doseId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.markDoseTaken(medicationId, doseId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== HbA1c DATA ====================

  List<HbA1cResult> get allHbA1cResults => _dataService.allHbA1cResults;

  HbA1cResult? get latestHbA1c => _dataService.latestHbA1c;

  List<BloodPressureReading> get allBloodPressureReadings =>
      _dataService.allBloodPressureReadings;
  BloodPressureReading? get latestBloodPressure =>
      _dataService.latestBloodPressure;

  List<CholesterolResult> get allCholesterolResults =>
      _dataService.allCholesterolResults;
  CholesterolResult? get latestCholesterol => _dataService.latestCholesterol;

  List<BmiResult> get allBmiResults => _dataService.allBmiResults;
  BmiResult? get latestBmi => _dataService.latestBmi;

  Future<void> addHbA1cResult(HbA1cResult result) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.addHbA1cResult(result);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== SLEEP DATA ====================

  List<SleepLog> get allSleepLogs => _dataService.allSleepLogs;

  List<SleepLog> getSleepLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _dataService.getSleepLogs(
      startDate: startDate,
      endDate: endDate,
    );
  }

  SleepLog? get latestSleep => allSleepLogs.isNotEmpty ? allSleepLogs.first : null;

  Future<void> addSleepLog(SleepLog log) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: API call if not demo mode
      await _dataService.addSleepLog(log);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== HEALTH SUMMARY ====================

  HealthSummary getHealthSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _dataService.getHealthSummary(
      startDate: startDate,
      endDate: endDate,
    );
  }

  HealthSummary get last7DaysSummary {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));
    return getHealthSummary(startDate: startDate, endDate: endDate);
  }

  HealthSummary get last30DaysSummary {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    return getHealthSummary(startDate: startDate, endDate: endDate);
  }

  HealthSummary get last90DaysSummary {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 90));
    return getHealthSummary(startDate: startDate, endDate: endDate);
  }

  // ==================== STATISTICS ====================

  /// Average glucose for a time period
  double getAverageGlucose({DateTime? startDate, DateTime? endDate}) {
    final readings = getGlucoseReadings(startDate: startDate, endDate: endDate);
    if (readings.isEmpty) return 0;
    return readings.map((r) => r.value).reduce((a, b) => a + b) / readings.length;
  }

  /// Time in range percentage
  double getTimeInRange({DateTime? startDate, DateTime? endDate}) {
    final readings = getGlucoseReadings(startDate: startDate, endDate: endDate);
    if (readings.isEmpty) return 0;
    final inRange = readings.where((r) => r.isNormal).length;
    return (inRange / readings.length) * 100;
  }

  /// Total carbs consumed
  double getTotalCarbs({DateTime? startDate, DateTime? endDate}) {
    final meals = getMeals(startDate: startDate, endDate: endDate);
    if (meals.isEmpty) return 0;
    return meals.map((m) => m.carbs).reduce((a, b) => a + b);
  }

  /// Total activity minutes
  int getTotalActivityMinutes({DateTime? startDate, DateTime? endDate}) {
    final activities = getActivities(startDate: startDate, endDate: endDate);
    if (activities.isEmpty) return 0;
    return activities.map((a) => a.duration).reduce((a, b) => a + b);
  }

  /// Medication adherence rate
  double getMedicationAdherence() {
    if (allMedications.isEmpty) return 0;
    return allMedications.map((m) => m.adherenceRate).reduce((a, b) => a + b) / allMedications.length;
  }

  // ==================== UTILITY METHODS ====================

  /// Refresh all data from service
  Future<void> refreshData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.fetchRealData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all data
  void clearAllData() {
    _dataService.clearAllData();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

florence\platform_service\lib\features\patient\logging\screens\log_activity_screen.dart
```
import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';

/// Log Activity Screen
/// Allows users to record physical activities and exercise
class LogActivityScreen extends StatefulWidget {
  const LogActivityScreen({super.key});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _activityNameController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  String _selectedActivityType = 'Walking';
  String _selectedIntensity = 'Moderate';
  
  // Activity type options with icons and colors
  final List<Map<String, dynamic>> _activityTypes = [
    {
      'name': 'Walking',
      'icon': Icons.directions_walk,
      'color': const Color(0xFF4CAF50)
    },
    {'name': 'Running', 'icon': Icons.directions_run, 'color': const Color(0xFFFF5722)},
    {'name': 'Cycling', 'icon': Icons.pedal_bike, 'color': const Color(0xFF2196F3)},
    {'name': 'Swimming', 'icon': Icons.pool, 'color': const Color(0xFF00BCD4)},
    {'name': 'Gym', 'icon': Icons.fitness_center, 'color': const Color(0xFF9C27B0)},
    {'name': 'Yoga', 'icon': Icons.self_improvement, 'color': const Color(0xFFE91E63)},
    {'name': 'Sports', 'icon': Icons.sports_soccer, 'color': const Color(0xFFFF9800)},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': const Color(0xFF607D8B)},
  ];
  
  // Intensity options
  final List<String> _intensityOptions = ['Light', 'Moderate', 'Vigorous'];
  
  @override
  void dispose() {
    _activityNameController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  /// Handle save
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);
    
    try {
      // TODO: Save to Supabase
      // await activityService.saveActivity({
      //   'name': _activityNameController.text.trim(),
      //   'type': _selectedActivityType,
      //   'duration': int.parse(_durationController.text),
      //   'intensity': _selectedIntensity,
      //   'timestamp': _selectedDateTime.toIso8601String(),
      //   'notes': _notesController.text.trim(),
      // });
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Helpers.showSuccess(context, 'Activity logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log activity');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Show date time picker
  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      
      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  /// Get estimated calories burned
  int _estimateCalories() {
    final duration = int.tryParse(_durationController.text) ?? 0;
    if (duration == 0) return 0;
    
    // Simple estimation based on activity and intensity
    double multiplier = 5.0; // Base calories per minute
    
    // Adjust by intensity
    switch (_selectedIntensity) {
      case 'Light':
        multiplier = 3.0;
        break;
      case 'Moderate':
        multiplier = 5.0;
        break;
      case 'Vigorous':
        multiplier = 8.0;
        break;
    }
    
    return (duration * multiplier).round();
  }
  
  @override
  Widget build(BuildContext context) {
    final estimatedCalories = _estimateCalories();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Helpers.showInfo(context, 'Activity history coming soon');
            },
            tooltip: 'View History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              _buildInfoCard(),
              const SizedBox(height: 24),
              
              // Activity type selection
              _buildActivityTypeSection(),
              const SizedBox(height: 24),
              
              // Activity name
              _buildActivityNameSection(),
              const SizedBox(height: 24),
              
              // Duration
              _buildDurationSection(estimatedCalories),
              const SizedBox(height: 24),
              
              // Intensity
              _buildIntensitySection(),
              const SizedBox(height: 24),
              
              // Date and time
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              
              // Notes
              _buildNotesSection(),
              const SizedBox(height: 32),
              
              // Save button
              PrimaryButton(
                text: 'Save Activity',
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build info card
  Widget _buildInfoCard() {
    return BaseCard(
      // backgroundColor: AppTheme.activityColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.directions_run,
            color: AppTheme.activityColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Track your physical activities to see how they affect your glucose',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.activityColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build activity type section
  Widget _buildActivityTypeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: _activityTypes.length,
            itemBuilder: (context, index) {
              final activity = _activityTypes[index];
              final isSelected = activity['name'] == _selectedActivityType;
              
              return InkWell(
                onTap: () {
                  setState(() => _selectedActivityType = activity['name']);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activity['color'].withOpacity(0.1)
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? activity['color']
                          : AppTheme.borderColor,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        activity['icon'],
                        color: isSelected
                            ? activity['color']
                            : AppTheme.textSecondaryColor,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity['name'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? activity['color']
                                  : AppTheme.textPrimaryColor,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// Build activity name section
  Widget _buildActivityNameSection() {
    return CustomTextField(
      label: 'Activity Name (Optional)',
      hint: 'e.g., Morning jog, Gym workout',
      controller: _activityNameController,
      textCapitalization: TextCapitalization.sentences,
      prefixIcon: const Icon(Icons.label_outline),
    );
  }
  
  /// Build duration section
  Widget _buildDurationSection(int estimatedCalories) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Duration',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (estimatedCalories > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.activityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: AppTheme.activityColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '~$estimatedCalories kcal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.activityColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _durationController,
            validator: Validators.activityDuration,
            keyboardType: TextInputType.number,
            hint: 'Duration in minutes',
            // suffix: 'minutes',
            prefixIcon: const Icon(Icons.timer),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
  
  /// Build intensity section
  Widget _buildIntensitySection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Intensity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: _intensityOptions.map((intensity) {
              final isSelected = intensity == _selectedIntensity;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIntensity = intensity;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.activityColor
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.activityColor
                              : AppTheme.borderColor,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        intensity,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimaryColor,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  /// Build date time section
  Widget _buildDateTimeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date & Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: AppTheme.activityColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.date(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          Formatters.time(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build notes section
  Widget _buildNotesSection() {
    return CustomTextField(
      label: 'Notes (Optional)',
      hint: 'How did you feel during the activity?',
      controller: _notesController,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
}```

florence\platform_service\lib\features\patient\dashboard\widgets\compact_health_card.dart
```
import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';

class CompactHealthCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String status;
  final DateTime? timestamp;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double? height;

  const CompactHealthCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    this.timestamp,
    required this.icon,
    required this.color,
    this.onTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    const double borderRadius = 16.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode, use a much darker version of the color (lower opacity or mixed with black)
    final bgColors = isDark
        ? [
            color.withOpacity(0.15), // Very subtle in dark mode
            color.withOpacity(0.05),
          ]
        : [
            color,
            Helpers.darken(color, 0.1),
          ];

    final textColor = isDark ? color.withOpacity(0.9) : Colors.white.withOpacity(0.9);
    final valueColor = isDark ? Colors.white : Colors.white;
    final shadowColor = isDark ? Colors.transparent : color.withOpacity(0.2);

    Widget content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          // Optional: Add border in dark mode for definition
          border: isDark ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeader(context, textColor, isDark),
            const SizedBox(height: 12),
            _buildValue(context, valueColor, textColor),
          ],
        ),
      ),
    );

    if (height != null) {
      return SizedBox(height: height, child: content);
    }

    return content;
  }

  Widget _buildHeader(BuildContext context, Color textColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontWeight: isDark ? FontWeight.bold : FontWeight.normal,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.2) : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(100),
            border: isDark ? Border.all(color: color.withOpacity(0.5)) : null,
          ),
          child: Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? color : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildValue(BuildContext context, Color valueColor, Color unitColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 4),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: unitColor,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          timestamp != null 
              ? 'Last updated: ${Formatters.timeAgo(timestamp!)}'
              : 'No history',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: unitColor.withOpacity(0.7),
              ),
        ),
      ],
    );
  }
}
```

florence\platform_service\lib\features\patient\logging\screens\log_glucose_screen.dart
```
import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';

/// Log Glucose Screen
/// Allows users to record blood glucose readings
class LogGlucoseScreen extends StatefulWidget {
  const LogGlucoseScreen({super.key});

  @override
  State<LogGlucoseScreen> createState() => _LogGlucoseScreenState();
}

class _LogGlucoseScreenState extends State<LogGlucoseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _glucoseController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  String _selectedContext = 'Before Meal';
  
  // Context options
  final List<String> _contextOptions = [
    'Before Meal',
    'After Meal (1hr)',
    'After Meal (2hr)',
    'Fasting',
    'Before Bed',
    'Random',
  ];
  
  @override
  void dispose() {
    _glucoseController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  /// Handle save
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);
    
    try {
      // TODO: Save to Supabase
      // final glucoseValue = double.parse(_glucoseController.text);
      // await healthService.saveGlucoseReading({
      //   'value': glucoseValue,
      //   'context': _selectedContext,
      //   'timestamp': _selectedDateTime.toIso8601String(),
      //   'notes': _notesController.text.trim(),
      // });
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Helpers.showSuccess(context, 'Glucose reading saved successfully!');
        
        // Go back to dashboard
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to save glucose reading');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Show date time picker
  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      
      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final glucoseValue = double.tryParse(_glucoseController.text);
    final glucoseColor = _getGlucoseColor(glucoseValue);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Glucose'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show glucose history
              Helpers.showInfo(context, 'History feature coming soon');
            },
            tooltip: 'View History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              _buildInfoCard(),
              const SizedBox(height: 24),
              
              // Glucose value input (large and prominent)
              _buildGlucoseInput(glucoseColor),
              const SizedBox(height: 24),
              
              // Date and time
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              
              // Context selection
              _buildContextSection(),
              const SizedBox(height: 24),
              
              // Notes (optional)
              _buildNotesSection(),
              const SizedBox(height: 32),
              
              // Save button
              PrimaryButton(
                text: 'Save Reading',
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
              const SizedBox(height: 16),
              
              // Reference ranges
              _buildReferenceRanges(),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build info card
  Widget _buildInfoCard() {
    return BaseCard(
      // backgroundColor: AppTheme.infoColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.infoColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Record your blood glucose reading to track your health trends',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.infoColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build glucose input
  Widget _buildGlucoseInput(Color? glucoseColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: glucoseColor?.withOpacity(0.1) ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: glucoseColor?.withOpacity(0.3) ?? Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Blood Glucose Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          
          // Large glucose input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 150,
                child: TextFormField(
                  controller: _glucoseController,
                  validator: Validators.glucose,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: glucoseColor ?? AppTheme.textPrimaryColor,
                      ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '---',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'mg/dL',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
          
          // Status indicator
          if (glucoseColor != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: glucoseColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getGlucoseStatus(double.tryParse(_glucoseController.text)),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Build date time section
  Widget _buildDateTimeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 20,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Date & Time',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.date(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          Formatters.time(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build context section
  Widget _buildContextSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant,
                size: 20,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Context',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _contextOptions.map((context) {
              final isSelected = context == _selectedContext;
              return ChoiceChip(
                label: Text(context),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedContext = context);
                },
                selectedColor: AppTheme.primaryBlue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  /// Build notes section
  Widget _buildNotesSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes,
                size: 20,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Notes (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _notesController,
            hint: 'Add any notes about this reading...',
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
  
  /// Build reference ranges
  Widget _buildReferenceRanges() {
    return BaseCard(
      // backgroundColor: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reference Ranges',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          
          _buildRangeItem(
            'Normal',
            '70-180 mg/dL',
            AppTheme.glucoseNormal,
          ),
          const SizedBox(height: 8),
          _buildRangeItem(
            'Low',
            'Below 70 mg/dL',
            AppTheme.glucoseLow,
          ),
          const SizedBox(height: 8),
          _buildRangeItem(
            'High',
            'Above 180 mg/dL',
            AppTheme.glucoseHigh,
          ),
        ],
      ),
    );
  }
  
  /// Build single range item
  Widget _buildRangeItem(String label, String range, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        Text(
          range,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
      ],
    );
  }
  
  /// Get glucose color based on value
  Color? _getGlucoseColor(double? value) {
    if (value == null) return null;
    
    if (value < 70) {
      return AppTheme.glucoseLow;
    } else if (value > 180) {
      return AppTheme.glucoseHigh;
    } else {
      return AppTheme.glucoseNormal;
    }
  }
  
  /// Get glucose status text
  String _getGlucoseStatus(double? value) {
    if (value == null) return '';
    
    if (value < 70) {
      return 'Low - Eat something!';
    } else if (value > 180) {
      return 'High - Consider activity';
    } else {
      return 'Normal - Great job!';
    }
  }
}```

florence\platform_service\lib\features\patient\notifications\screens\notifications_screen.dart
```
/// Notifications Screen for FLORENCE Digital Health Platform
/// Displays all notifications with filtering and actions

import 'package:flutter/material.dart';
import '../../../../core/services/notifications/notification_service.dart';
import '../../../../core/services/notifications/notification_models.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../config/theme.dart';

/// Notifications screen showing all notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  NotificationType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onNotificationsChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final allNotifications = _notificationService.allNotifications;
    final filteredNotifications = _selectedFilter == null
        ? allNotifications
        : allNotifications
            .where((n) => n.type == _selectedFilter)
            .toList();

    // Group notifications by time
    final today = <HealthNotification>[];
    final yesterday = <HealthNotification>[];
    final thisWeek = <HealthNotification>[];
    final older = <HealthNotification>[];

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(const Duration(days: 7));

    for (var notification in filteredNotifications) {
      if (notification.createdAt.isAfter(todayStart)) {
        today.add(notification);
      } else if (notification.createdAt.isAfter(yesterdayStart)) {
        yesterday.add(notification);
      } else if (notification.createdAt.isAfter(weekStart)) {
        thisWeek.add(notification);
      } else {
        older.add(notification);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Filter dropdown
          PopupMenuButton<NotificationType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (type) {
              setState(() => _selectedFilter = type);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Notifications'),
              ),
              const PopupMenuDivider(),
              ...NotificationType.values.map((type) => PopupMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        _getNotificationIcon(type, 20),
                        const SizedBox(width: 12),
                        Text(_getNotificationTypeName(type)),
                      ],
                    ),
                  )),
            ],
          ),
          // Mark all as read
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              _notificationService.markAllAsRead();
              setState(() {});
            },
            tooltip: 'Mark all as read',
          ),
          // Clear all
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () async {
              final confirmed = await _showConfirmDialog(
                'Clear All Notifications',
                'Are you sure you want to clear all notifications?',
              );
              if (confirmed) {
                _notificationService.clearAll();
                setState(() {});
              }
            },
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: filteredNotifications.isEmpty
          ? _buildEmptyState()
          : ListView(
              children: [
                if (today.isNotEmpty) _buildGroup('Today', today),
                if (yesterday.isNotEmpty) _buildGroup('Yesterday', yesterday),
                if (thisWeek.isNotEmpty) _buildGroup('This Week', thisWeek),
                if (older.isNotEmpty) _buildGroup('Older', older),
              ],
            ),
    );
  }

  /// Build notification group
  Widget _buildGroup(String title, List<HealthNotification> notifications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        ...notifications.map((n) => _buildNotificationCard(n)),
      ],
    );
  }

  /// Build notification card
  Widget _buildNotificationCard(HealthNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.errorColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        _notificationService.deleteNotification(notification.id);
        setState(() {});
      },
      child: InkWell(
        onTap: () {
          // Mark as read
          if (!notification.isRead) {
            _notificationService.markAsRead(notification.id);
            setState(() {});
          }

          // Navigate if action URL exists
          if (notification.actionUrl != null) {
            Navigator.pop(context);
            Navigator.pushNamed(context, notification.actionUrl!);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : _getNotificationColor(notification.type).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade300
                  : _getNotificationColor(notification.type).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _getNotificationIcon(notification.type, 24),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.timeAgo(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          if (notification.priority == NotificationPriority.critical) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == null
                ? 'No notifications'
                : 'No ${_getNotificationTypeName(_selectedFilter!).toLowerCase()}',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Get notification icon
  Icon _getNotificationIcon(NotificationType type, double size) {
    IconData iconData;
    Color color = _getNotificationColor(type);

    switch (type) {
      case NotificationType.alert:
        iconData = Icons.warning;
      case NotificationType.reminder:
        iconData = Icons.alarm;
      case NotificationType.educational:
        iconData = Icons.school;
      case NotificationType.motivational:
        iconData = Icons.emoji_events;
      case NotificationType.summary:
        iconData = Icons.assessment;
      case NotificationType.achievement:
        iconData = Icons.star;
    }

    return Icon(iconData, size: size, color: color);
  }

  /// Get notification color
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return AppTheme.errorColor;
      case NotificationType.reminder:
        return AppTheme.warningColor;
      case NotificationType.educational:
        return AppTheme.primaryBlue;
      case NotificationType.motivational:
        return AppTheme.primaryGreen;
      case NotificationType.summary:
        return AppTheme.accentPurple;
      case NotificationType.achievement:
        return AppTheme.accentGold;
    }
  }

  /// Get notification type name
  String _getNotificationTypeName(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return 'Alerts';
      case NotificationType.reminder:
        return 'Reminders';
      case NotificationType.educational:
        return 'Educational';
      case NotificationType.motivational:
        return 'Motivational';
      case NotificationType.summary:
        return 'Summaries';
      case NotificationType.achievement:
        return 'Achievements';
    }
  }

  /// Show confirm dialog
  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
```

florence\platform_service\lib\features\patient\core\models\health_data_models.dart
```
/// Health Data Models for FLORENCE Digital Health Platform
/// Comprehensive data models for patient health tracking

import 'package:flutter/foundation.dart';

// ============================================================================
// NEW MODELS (MATCHING PYTHON BACKEND)
// ============================================================================

/// Monitor Data Type Enum (Strictly matching Supabase)
enum MonitorDataType {
  BLOOD_PRESSURE_SYSTOLIC,
  BLOOD_PRESSURE_DIASTOLIC,
  GLUCOSE,
  BMI,
  HBA1C,
  ECG,
  CHOLESTEROL_TOTAL,
  CHOLESTEROL_LDL,
  CHOLESTEROL_HDL,
  CHOLESTEROL_TRIGLYCERIDES,
  UNKNOWN, // Safety fallback
}

/// Health Status Enum
enum HealthStatus {
  safe,
  warning,
  critical,
  unknown,
}

/// Monitor Data Model
@immutable
class MonitorData {
  final int id;
  final int patientId;
  final MonitorDataType dataType;
  final double value;
  final DateTime measuredAt;

  const MonitorData({
    required this.id,
    required this.patientId,
    required this.dataType,
    required this.value,
    required this.measuredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'data_type': dataType.name,
      'value': value,
      'measured_at': measuredAt.toIso8601String(),
    };
  }

  factory MonitorData.fromJson(Map<String, dynamic> json) {
    return MonitorData(
      id: json['id'] as int,
      patientId: json['patient_id'] as int,
      dataType: MonitorDataType.values.firstWhere(
        (e) => e.name == json['data_type'],
        orElse: () => MonitorDataType.UNKNOWN, // Fixes crash if type not found
      ),
      value: (json['value'] as num).toDouble(),
      measuredAt: DateTime.parse(json['measured_at'] as String),
    );
  }
}

/// Patient Activity Log Model
@immutable
class PatientActivityLog {
  final int id;
  final String activityDescription;
  final int durationMinutes;
  final DateTime performedAt;

  const PatientActivityLog({
    required this.id,
    required this.activityDescription,
    required this.durationMinutes,
    required this.performedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_description': activityDescription,
      'duration_minutes': durationMinutes,
      'performed_at': performedAt.toIso8601String(),
    };
  }

  factory PatientActivityLog.fromJson(Map<String, dynamic> json) {
    return PatientActivityLog(
      id: json['id'] as int,
      activityDescription: json['activity_description'] as String,
      durationMinutes: json['duration_minutes'] as int,
      performedAt: DateTime.parse(json['performed_at'] as String),
    );
  }
}

/// Daily Patient Log Model (For Diet Overlay)
@immutable
class DailyPatientLog {
  final int id;
  final String? mealDesc;
  final double? glucoseBeforeMeal;
  final double? glucoseAfterMeal;
  final DateTime? glucoseBeforeMealTime;
  final DateTime? glucoseAfterMealTime;
  final DateTime logDate;
  final String mealTime; // 'BREAKFAST', 'LUNCH', 'DINNER'

  const DailyPatientLog({
    required this.id,
    required this.logDate,
    required this.mealTime,
    this.mealDesc,
    this.glucoseBeforeMeal,
    this.glucoseAfterMeal,
    this.glucoseBeforeMealTime,
    this.glucoseAfterMealTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal_desc': mealDesc,
      'glucose_before_meal': glucoseBeforeMeal,
      'glucose_after_meal': glucoseAfterMeal,
      'glucose_before_meal_time': glucoseBeforeMealTime?.toIso8601String(),
      'glucose_after_meal_time': glucoseAfterMealTime?.toIso8601String(),
      'log_date': logDate.toIso8601String(),
      'meal_time': mealTime,
    };
  }

  factory DailyPatientLog.fromJson(Map<String, dynamic> json) {
    return DailyPatientLog(
      id: json['id'] as int,
      logDate: DateTime.parse(json['log_date'] as String),
      mealTime: json['meal_time'] as String,
      mealDesc: json['meal_desc'] as String?,
      glucoseBeforeMeal: json['glucose_before_meal'] != null ? (json['glucose_before_meal'] as num).toDouble() : null,
      glucoseAfterMeal: json['glucose_after_meal'] != null ? (json['glucose_after_meal'] as num).toDouble() : null,
      glucoseBeforeMealTime: json['glucose_before_meal_time'] != null ? DateTime.parse(json['glucose_before_meal_time'] as String) : null,
      glucoseAfterMealTime: json['glucose_after_meal_time'] != null ? DateTime.parse(json['glucose_after_meal_time'] as String) : null,
    );
  }
}

/// Health Threshold Model
@immutable
class HealthThreshold {
  final MonitorDataType dataType;
  final double minValue;
  final double maxValue;

  const HealthThreshold({
    required this.dataType,
    required this.minValue,
    required this.maxValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'data_type': dataType.name,
      'min_value': minValue,
      'max_value': maxValue,
    };
  }

  factory HealthThreshold.fromJson(Map<String, dynamic> json) {
    return HealthThreshold(
      dataType: MonitorDataType.values.firstWhere(
        (e) => e.name == json['data_type'],
        orElse: () => MonitorDataType.UNKNOWN, // Fixes crash here too
      ),
      minValue: (json['min_value'] as num).toDouble(),
      maxValue: (json['max_value'] as num).toDouble(),
    );
  }
}

/// Health Status Evaluator Helper
class HealthStatusEvaluator {
  static HealthStatus evaluate(
    double value,
    MonitorDataType type,
    List<HealthThreshold> thresholds,
  ) {
    // BMI Specific Logic
    if (type == MonitorDataType.BMI) {
      if (value < 18.5) return HealthStatus.warning; // Underweight
      if (value >= 18.5 && value <= 24.9) return HealthStatus.safe; // Normal
      if (value >= 25.0 && value <= 29.9) return HealthStatus.warning; // Overweight
      if (value >= 30.0) return HealthStatus.critical; // Obese
      return HealthStatus.unknown;
    }

    // Find specific threshold
    try {
      final threshold = thresholds.firstWhere((t) => t.dataType == type);
      
      // Cholesterol Logic (Prioritize LDL if passed as type, but here we evaluate per type)
      // If type is LDL, we just check against LDL threshold.
      
      if (value < threshold.minValue) return HealthStatus.warning; // Too low
      if (value > threshold.maxValue) return HealthStatus.critical; // Too high (or warning depending on context, but usually critical for max)
      
      // Refined logic: usually min/max define the SAFE range.
      // So if within [min, max], it is safe.
      if (value >= threshold.minValue && value <= threshold.maxValue) {
        return HealthStatus.safe;
      }
      
      // If outside, determine severity. 
      // For simplicity and based on "min_value, max_value" usually defining the normal range:
      return HealthStatus.warning; 
      
    } catch (e) {
      // No threshold found
      return HealthStatus.unknown;
    }
  }
}

// ============================================================================
// DEPRECATED MODELS (LEGACY)
// ============================================================================

/// Glucose Reading Model
@Deprecated('Use MonitorData instead')
@immutable
class GlucoseReading {
  final String id;
  final DateTime timestamp;
  final double value; // mg/dL
  final String context; // e.g., "Before breakfast", "After lunch"
  final String? notes;
  final bool isFlagged; // For abnormal readings

  const GlucoseReading({
    required this.id,
    required this.timestamp,
    required this.value,
    required this.context,
    this.notes,
    this.isFlagged = false,
  });

  bool get isHigh => value > 180;
  bool get isLow => value < 70;
  bool get isNormal => value >= 70 && value <= 180;

  String get status {
    if (isLow) return 'Low';
    if (isHigh) return 'High';
    return 'Normal';
  }

  GlucoseReading copyWith({
    String? id,
    DateTime? timestamp,
    double? value,
    String? context,
    String? notes,
    bool? isFlagged,
  }) {
    return GlucoseReading(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      value: value ?? this.value,
      context: context ?? this.context,
      notes: notes ?? this.notes,
      isFlagged: isFlagged ?? this.isFlagged,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'context': context,
      'notes': notes,
      'isFlagged': isFlagged,
    };
  }

  factory GlucoseReading.fromJson(Map<String, dynamic> json) {
    return GlucoseReading(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: (json['value'] as num).toDouble(),
      context: json['context'] as String,
      notes: json['notes'] as String?,
      isFlagged: json['isFlagged'] as bool? ?? false,
    );
  }
}

/// Meal Log Model
@immutable
class MealLog {
  final String id;
  final DateTime timestamp;
  final String type; // Breakfast, Lunch, Dinner, Snack
  final String description;
  final double carbs; // grams
  final int calories;
  final double? protein; // grams
  final double? fat; // grams
  final String? photoUrl;
  final String? notes;
  final List<String> tags; // e.g., ["high-carb", "vegetarian"]

  const MealLog({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.description,
    required this.carbs,
    required this.calories,
    this.protein,
    this.fat,
    this.photoUrl,
    this.notes,
    this.tags = const [],
  });

  bool get isHighCarb => carbs > 60;
  bool get isLowCarb => carbs < 30;

  MealLog copyWith({
    String? id,
    DateTime? timestamp,
    String? type,
    String? description,
    double? carbs,
    int? calories,
    double? protein,
    double? fat,
    String? photoUrl,
    String? notes,
    List<String>? tags,
  }) {
    return MealLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      description: description ?? this.description,
      carbs: carbs ?? this.carbs,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'description': description,
      'carbs': carbs,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'photoUrl': photoUrl,
      'notes': notes,
      'tags': tags,
    };
  }

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
      description: json['description'] as String,
      carbs: (json['carbs'] as num).toDouble(),
      calories: json['calories'] as int,
      protein: json['protein'] != null ? (json['protein'] as num).toDouble() : null,
      fat: json['fat'] != null ? (json['fat'] as num).toDouble() : null,
      photoUrl: json['photoUrl'] as String?,
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }
}

/// Activity Log Model
@Deprecated('Use PatientActivityLog instead')
@immutable
class ActivityLog {
  final String id;
  final DateTime timestamp;
  final String type; // Walking, Running, Cycling, etc.
  final int duration; // minutes
  final String intensity; // Low, Moderate, High
  final int? caloriesBurned;
  final double? distance; // km
  final int? steps;
  final String? notes;

  const ActivityLog({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.duration,
    required this.intensity,
    this.caloriesBurned,
    this.distance,
    this.steps,
    this.notes,
  });

  bool get isHighIntensity => intensity == 'High';
  bool get isLowIntensity => intensity == 'Low';

  ActivityLog copyWith({
    String? id,
    DateTime? timestamp,
    String? type,
    int? duration,
    String? intensity,
    int? caloriesBurned,
    double? distance,
    int? steps,
    String? notes,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      intensity: intensity ?? this.intensity,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      distance: distance ?? this.distance,
      steps: steps ?? this.steps,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'duration': duration,
      'intensity': intensity,
      'caloriesBurned': caloriesBurned,
      'distance': distance,
      'steps': steps,
      'notes': notes,
    };
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
      duration: json['duration'] as int,
      intensity: json['intensity'] as String,
      caloriesBurned: json['caloriesBurned'] as int?,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      steps: json['steps'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

/// Medication Log Model
@immutable
class MedicationLog {
  final String id;
  final String medicationName;
  final String dosage;
  final String frequency;
  final DateTime prescribedDate;
  final List<MedicationDose> doses;
  final String? notes;

  const MedicationLog({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.prescribedDate,
    required this.doses,
    this.notes,
  });

  double get adherenceRate {
    if (doses.isEmpty) return 0;
    final takenDoses = doses.where((d) => d.taken).length;
    return takenDoses / doses.length;
  }

  MedicationLog copyWith({
    String? id,
    String? medicationName,
    String? dosage,
    String? frequency,
    DateTime? prescribedDate,
    List<MedicationDose>? doses,
    String? notes,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      prescribedDate: prescribedDate ?? this.prescribedDate,
      doses: doses ?? this.doses,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'prescribedDate': prescribedDate.toIso8601String(),
      'doses': doses.map((d) => d.toJson()).toList(),
      'notes': notes,
    };
  }

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'] as String,
      medicationName: json['medicationName'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      prescribedDate: DateTime.parse(json['prescribedDate'] as String),
      doses: (json['doses'] as List<dynamic>)
          .map((e) => MedicationDose.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }
}

/// Individual Medication Dose
@immutable
class MedicationDose {
  final String id;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final bool taken;
  final bool skipped;
  final String? skipReason;

  const MedicationDose({
    required this.id,
    required this.scheduledTime,
    this.takenTime,
    this.taken = false,
    this.skipped = false,
    this.skipReason,
  });

  bool get isOverdue => !taken && !skipped && DateTime.now().isAfter(scheduledTime);

  MedicationDose copyWith({
    String? id,
    DateTime? scheduledTime,
    DateTime? takenTime,
    bool? taken,
    bool? skipped,
    String? skipReason,
  }) {
    return MedicationDose(
      id: id ?? this.id,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      taken: taken ?? this.taken,
      skipped: skipped ?? this.skipped,
      skipReason: skipReason ?? this.skipReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduledTime': scheduledTime.toIso8601String(),
      'takenTime': takenTime?.toIso8601String(),
      'taken': taken,
      'skipped': skipped,
      'skipReason': skipReason,
    };
  }

  factory MedicationDose.fromJson(Map<String, dynamic> json) {
    return MedicationDose(
      id: json['id'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      takenTime: json['takenTime'] != null ? DateTime.parse(json['takenTime'] as String) : null,
      taken: json['taken'] as bool? ?? false,
      skipped: json['skipped'] as bool? ?? false,
      skipReason: json['skipReason'] as String?,
    );
  }
}

/// Blood Pressure Reading Model
@Deprecated('Use MonitorData instead')
@immutable
class BloodPressureReading {
  final String id;
  final DateTime timestamp;
  final double systolic;
  final double diastolic;
  final String? notes;

  const BloodPressureReading({
    required this.id,
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
    this.notes,
  });

  String get value => '${systolic.toStringAsFixed(0)}/${diastolic.toStringAsFixed(0)}';

  BloodPressureReading copyWith({
    String? id,
    DateTime? timestamp,
    double? systolic,
    double? diastolic,
    String? notes,
  }) {
    return BloodPressureReading(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'systolic': systolic,
      'diastolic': diastolic,
      'notes': notes,
    };
  }

  factory BloodPressureReading.fromJson(Map<String, dynamic> json) {
    return BloodPressureReading(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      systolic: (json['systolic'] as num).toDouble(),
      diastolic: (json['diastolic'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

/// Cholesterol Test Result Model
@Deprecated('Use MonitorData instead')
@immutable
class CholesterolResult {
  final String id;
  final DateTime testDate;
  final double value; // mg/dL
  final String? notes;

  const CholesterolResult({
    required this.id,
    required this.testDate,
    required this.value,
    this.notes,
  });

  CholesterolResult copyWith({
    String? id,
    DateTime? testDate,
    double? value,
    String? notes,
  }) {
    return CholesterolResult(
      id: id ?? this.id,
      testDate: testDate ?? this.testDate,
      value: value ?? this.value,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testDate': testDate.toIso8601String(),
      'value': value,
      'notes': notes,
    };
  }

  factory CholesterolResult.fromJson(Map<String, dynamic> json) {
    return CholesterolResult(
      id: json['id'] as String,
      testDate: DateTime.parse(json['testDate'] as String),
      value: (json['value'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

/// BMI Result Model
@Deprecated('Use MonitorData instead')
@immutable
class BmiResult {
  final String id;
  final DateTime testDate;
  final double value;
  final String? notes;

  const BmiResult({
    required this.id,
    required this.testDate,
    required this.value,
    this.notes,
  });

  BmiResult copyWith({
    String? id,
    DateTime? testDate,
    double? value,
    String? notes,
  }) {
    return BmiResult(
      id: id ?? this.id,
      testDate: testDate ?? this.testDate,
      value: value ?? this.value,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testDate': testDate.toIso8601String(),
      'value': value,
      'notes': notes,
    };
  }

  factory BmiResult.fromJson(Map<String, dynamic> json) {
    return BmiResult(
      id: json['id'] as String,
      testDate: DateTime.parse(json['testDate'] as String),
      value: (json['value'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

/// HbA1c Test Result Model
@Deprecated('Use MonitorData instead')
@immutable
class HbA1cResult {
  final String id;
  final DateTime testDate;
  final double value; // percentage
  final String? notes;
  final String? labName;

  const HbA1cResult({
    required this.id,
    required this.testDate,
    required this.value,
    this.notes,
    this.labName,
  });

  String get interpretation {
    if (value < 5.7) return 'Normal';
    if (value < 6.5) return 'Pre-diabetes';
    return 'Diabetes';
  }

  bool get isControlled => value < 7.0;

  HbA1cResult copyWith({
    String? id,
    DateTime? testDate,
    double? value,
    String? notes,
    String? labName,
  }) {
    return HbA1cResult(
      id: id ?? this.id,
      testDate: testDate ?? this.testDate,
      value: value ?? this.value,
      notes: notes ?? this.notes,
      labName: labName ?? this.labName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testDate': testDate.toIso8601String(),
      'value': value,
      'notes': notes,
      'labName': labName,
    };
  }

  factory HbA1cResult.fromJson(Map<String, dynamic> json) {
    return HbA1cResult(
      id: json['id'] as String,
      testDate: DateTime.parse(json['testDate'] as String),
      value: (json['value'] as num).toDouble(),
      notes: json['notes'] as String?,
      labName: json['labName'] as String?,
    );
  }
}

/// Sleep Log Model
@immutable
class SleepLog {
  final String id;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int? quality; // 1-10 scale
  final String? notes;

  const SleepLog({
    required this.id,
    required this.bedTime,
    required this.wakeTime,
    this.quality,
    this.notes,
  });

  Duration get duration => wakeTime.difference(bedTime);
  int get hoursSlept => duration.inHours;

  bool get isAdequate => hoursSlept >= 7 && hoursSlept <= 9;

  SleepLog copyWith({
    String? id,
    DateTime? bedTime,
    DateTime? wakeTime,
    int? quality,
    String? notes,
  }) {
    return SleepLog(
      id: id ?? this.id,
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bedTime': bedTime.toIso8601String(),
      'wakeTime': wakeTime.toIso8601String(),
      'quality': quality,
      'notes': notes,
    };
  }

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog(
      id: json['id'] as String,
      bedTime: DateTime.parse(json['bedTime'] as String),
      wakeTime: DateTime.parse(json['wakeTime'] as String),
      quality: json['quality'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

/// Health Summary Aggregation
@immutable
class HealthSummary {
  final DateTime startDate;
  final DateTime endDate;
  final double averageGlucose;
  final double glucoseStdDev;
  final int totalReadings;
  final int hyperEvents; // > 180 mg/dL
  final int hypoEvents; // < 70 mg/dL
  final double timeInRange; // percentage 70-180 mg/dL
  final double estimatedA1c;
  final int totalMeals;
  final double averageCarbs;
  final int totalActivityMinutes;
  final double medicationAdherence;
  final int averageSleepHours;

  const HealthSummary({
    required this.startDate,
    required this.endDate,
    required this.averageGlucose,
    required this.glucoseStdDev,
    required this.totalReadings,
    required this.hyperEvents,
    required this.hypoEvents,
    required this.timeInRange,
    required this.estimatedA1c,
    required this.totalMeals,
    required this.averageCarbs,
    required this.totalActivityMinutes,
    required this.medicationAdherence,
    required this.averageSleepHours,
  });

  bool get isWellControlled => timeInRange >= 70 && hypoEvents < 4;

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'averageGlucose': averageGlucose,
      'glucoseStdDev': glucoseStdDev,
      'totalReadings': totalReadings,
      'hyperEvents': hyperEvents,
      'hypoEvents': hypoEvents,
      'timeInRange': timeInRange,
      'estimatedA1c': estimatedA1c,
      'totalMeals': totalMeals,
      'averageCarbs': averageCarbs,
      'totalActivityMinutes': totalActivityMinutes,
      'medicationAdherence': medicationAdherence,
      'averageSleepHours': averageSleepHours,
    };
  }

  factory HealthSummary.fromJson(Map<String, dynamic> json) {
    return HealthSummary(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      averageGlucose: (json['averageGlucose'] as num).toDouble(),
      glucoseStdDev: (json['glucoseStdDev'] as num).toDouble(),
      totalReadings: json['totalReadings'] as int,
      hyperEvents: json['hyperEvents'] as int,
      hypoEvents: json['hypoEvents'] as int,
      timeInRange: (json['timeInRange'] as num).toDouble(),
      estimatedA1c: (json['estimatedA1c'] as num).toDouble(),
      totalMeals: json['totalMeals'] as int,
      averageCarbs: (json['averageCarbs'] as num).toDouble(),
      totalActivityMinutes: json['totalActivityMinutes'] as int,
      medicationAdherence: (json['medicationAdherence'] as num).toDouble(),
      averageSleepHours: json['averageSleepHours'] as int,
    );
  }
}
```

florence\platform_service\lib\features\patient\core\repositories\monitor_data_repository.dart
```
import '../../../../core/services/api_service.dart';
import '../models/health_data_models.dart';

/// Repository to fetch and map health data to MonitorData
class MonitorDataRepository {
  final ApiService _apiService = ApiService();

  /// Get all monitor data for all available types directly from API
  Future<List<MonitorData>> getAllMonitorData() async {
    try {
      final response = await _apiService.get('/patients/me/monitor-data');
      if (response is List) {
        return response.map((json) => MonitorData.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching monitor data: $e');
      // Return empty list on error instead of mock data
      return [];
    }
  }

  /// Get daily patient logs (meals) for overlay
  Future<List<DailyPatientLog>> getDailyPatientLogs() async {
    try {
      final response = await _apiService.get('/patients/me/daily-logs');
      if (response is List) {
        return response.map((json) => DailyPatientLog.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching daily logs: $e');
      return [];
    }
  }

  /// Get activity logs directly from API
  Future<List<ActivityLog>> getActivityLogs() async {
    try {
      final response = await _apiService.get('/patients/me/activity-logs');
      if (response is List) {
        // Map backend fields to UI model
        return response.map((json) {
          return ActivityLog(
            id: json['id'].toString(),
            timestamp: DateTime.parse(json['performed_at']),
            type: json['activity_description'] ?? 'Activity',
            duration: json['duration_minutes'] ?? 0,
            intensity: 'Moderate', // Default as backend doesn't store this yet
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching activity logs: $e');
      return [];
    }
  }

  /// Get health thresholds directly from API
  Future<List<HealthThreshold>> getHealthThresholds() async {
    try {
      final response = await _apiService.get('/patients/me/thresholds');
      if (response is List) {
        return response.map((json) => HealthThreshold.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching thresholds: $e');
      return [];
    }
  }
}
```

florence\platform_service\lib\features\patient\core\services\data_ingestion_service.dart
```
/// Data Ingestion Service for FLORENCE Digital Health Platform
/// Handles in-memory data management for health records

import '../../../../core/services/api_service.dart';
import 'dart:math';
import '../models/health_data_models.dart';

/// Service for managing health data in memory
/// This service acts as a data layer that can later be connected to Supabase
class DataIngestionService {
  // In-memory data stores
  final ApiService _apiService = ApiService();
  final List<GlucoseReading> _glucoseReadings = [];
  final List<MealLog> _meals = [];
  final List<ActivityLog> _activities = [];
  final List<MedicationLog> _medications = [];
  final List<HbA1cResult> _hba1cResults = [];
  final List<SleepLog> _sleepLogs = [];
  final List<BloodPressureReading> _bloodPressureReadings = [];
  final List<CholesterolResult> _cholesterolResults = [];
  final List<BmiResult> _bmiResults = [];
  final List<HealthThreshold> _healthThresholds = [];

  final Random _random = Random();

  // Singleton instance
  static final DataIngestionService _instance = DataIngestionService._internal();
  factory DataIngestionService() => _instance;
  DataIngestionService._internal();

  /// Fetch real data from the backend
  Future<void> fetchRealData() async {
    clearAllData();
    try {
      await fetchThresholds(); // Fetch thresholds first

      // The backend returns monitor data which contains glucose, hba1c etc.
      final monitorData = await _apiService.get('/patients/me/monitor-data') as List;
      
      final systolicReadings = <String, dynamic>{};
      final diastolicReadings = <String, dynamic>{};

      for (var item in monitorData) {
        final dataType = item['data_type'];
        final timestamp = DateTime.parse(item['measured_at']);
        final id = item['id'].toString();
        final value = (item['value'] as num).toDouble();

        switch (dataType) {
          case 'GLUCOSE':
            _glucoseReadings.add(GlucoseReading(
              id: id,
              timestamp: timestamp,
              value: value,
              context: _getGlucoseContext(timestamp.hour),
            ));
            break;
          case 'HBA1C':
            _hba1cResults.add(HbA1cResult(
              id: id,
              testDate: timestamp,
              value: value,
            ));
            break;
          case 'BLOOD_PRESSURE_SYSTOLIC':
            systolicReadings[timestamp.toIso8601String()] = {'id': id, 'value': value};
            break;
          case 'BLOOD_PRESSURE_DIASTOLIC':
            diastolicReadings[timestamp.toIso8601String()] = {'id': id, 'value': value};
            break;
          case 'CHOLESTEROL': // Legacy
          case 'CHOLESTEROL_TOTAL': // New Backend format
            _cholesterolResults.add(CholesterolResult(
              id: id,
              testDate: timestamp,
              value: value,
            ));
            break;
          case 'BMI':
            _bmiResults.add(BmiResult(
              id: id,
              testDate: timestamp,
              value: value,
            ));
            break;
        }
      }

      // Pair up blood pressure readings
      systolicReadings.forEach((timestampStr, systolicData) {
        if (diastolicReadings.containsKey(timestampStr)) {
          final diastolicData = diastolicReadings[timestampStr];
          _bloodPressureReadings.add(BloodPressureReading(
            id: systolicData['id'], // Use systolic ID as primary
            timestamp: DateTime.parse(timestampStr),
            systolic: systolicData['value'],
            diastolic: diastolicData['value'],
          ));
        }
      });
      
      // Fetch Activities
      try {
        final activityData = await _apiService.get('/patients/me/activity-logs');
        if (activityData is List) {
          for (var item in activityData) {
            _activities.add(ActivityLog(
              id: item['id'].toString(),
              timestamp: DateTime.parse(item['performed_at']),
              type: item['activity_description'] ?? 'Activity',
              duration: item['duration_minutes'] ?? 0,
              intensity: 'Moderate', // Default as backend doesn't store intensity yet
            ));
          }
          _activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
      } catch (e) {
        print("Error fetching activities: $e");
      }

      // Fetch Daily Logs (Meals)
      try {
        final mealData = await _apiService.get('/patients/me/daily-logs');
        if (mealData is List) {
          for (var item in mealData) {
            _meals.add(MealLog(
              id: item['id'].toString(),
              timestamp: DateTime.parse(item['log_date']),
              // Map 'BREAKFAST' to 'Breakfast', etc.
              type: item['meal_time']?.toString().split('.').last ?? 'Snack', 
              description: item['meal_desc'] ?? 'Logged Meal',
              carbs: 0, // Placeholder as backend might not send this yet
              calories: 0,
            ));
          }
          _meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
      } catch (e) {
        print("Error fetching meal logs: $e");
      }

      // Sort data after fetching
      _glucoseReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _hba1cResults.sort((a, b) => b.testDate.compareTo(a.testDate));
      _bloodPressureReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _cholesterolResults.sort((a, b) => b.testDate.compareTo(a.testDate));
      _bmiResults.sort((a, b) => b.testDate.compareTo(a.testDate));

    } catch (e) {
      print("Error fetching real data: $e");
      clearAllData();
    }
  }

  /// Fetch health thresholds
  Future<void> fetchThresholds() async {
    _healthThresholds.clear();
    try {
      final response = await _apiService.get('/patients/me/thresholds');
      if (response != null && response is List) {
        for (var item in response) {
          _healthThresholds.add(HealthThreshold.fromJson(item));
        }
      }
    } catch (e) {
      print("Error fetching thresholds: $e");
    }
  }

  /// Initialize with realistic mock data
  void generateAndLoadMockData() {
    clearAllData();
    _generateMockGlucoseReadings();
    _generateMockMeals();
    _generateMockActivities();
    _generateMockMedications();
    _generateMockHbA1cResults();
    _generateMockSleepLogs();
    _generateMockBloodPressureReadings();
    _generateMockCholesterolResults();
    _generateMockBmiResults();
  }

  // ==================== GLUCOSE READINGS ====================

  List<HealthThreshold> get allHealthThresholds => List.unmodifiable(_healthThresholds);

  List<GlucoseReading> get allGlucoseReadings =>
      List.unmodifiable(_glucoseReadings);

  List<GlucoseReading> getGlucoseReadings({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var readings = _glucoseReadings;

    if (startDate != null) {
      readings = readings.where((r) => r.timestamp.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      readings = readings.where((r) => r.timestamp.isBefore(endDate)).toList();
    }

    return List.unmodifiable(readings);
  }

  Future<GlucoseReading> addGlucoseReading(GlucoseReading reading) async {
    _glucoseReadings.add(reading);
    _glucoseReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return reading;
  }

  Future<void> deleteGlucoseReading(String id) async {
    _glucoseReadings.removeWhere((r) => r.id == id);
  }

  Future<GlucoseReading> updateGlucoseReading(GlucoseReading reading) async {
    final index = _glucoseReadings.indexWhere((r) => r.id == reading.id);
    if (index != -1) {
      _glucoseReadings[index] = reading;
    }
    return reading;
  }

  // ==================== MEALS ====================

  List<MealLog> get allMeals => List.unmodifiable(_meals);

  List<MealLog> getMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var meals = _meals;

    if (startDate != null) {
      meals = meals.where((m) => m.timestamp.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      meals = meals.where((m) => m.timestamp.isBefore(endDate)).toList();
    }

    return List.unmodifiable(meals);
  }

  Future<MealLog> addMeal(MealLog meal) async {
    _meals.add(meal);
    _meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return meal;
  }

  Future<void> deleteMeal(String id) async {
    _meals.removeWhere((m) => m.id == id);
  }

  Future<MealLog> updateMeal(MealLog meal) async {
    final index = _meals.indexWhere((m) => m.id == meal.id);
    if (index != -1) {
      _meals[index] = meal;
    }
    return meal;
  }

  // ==================== ACTIVITIES ====================

  List<ActivityLog> get allActivities => List.unmodifiable(_activities);

  List<ActivityLog> getActivities({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var activities = _activities;

    if (startDate != null) {
      activities = activities.where((a) => a.timestamp.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      activities = activities.where((a) => a.timestamp.isBefore(endDate)).toList();
    }

    return List.unmodifiable(activities);
  }

  Future<ActivityLog> addActivity(ActivityLog activity) async {
    _activities.add(activity);
    _activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activity;
  }

  Future<void> deleteActivity(String id) async {
    _activities.removeWhere((a) => a.id == id);
  }

  Future<ActivityLog> updateActivity(ActivityLog activity) async {
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _activities[index] = activity;
    }
    return activity;
  }

  // ==================== MEDICATIONS ====================

  List<MedicationLog> get allMedications => List.unmodifiable(_medications);

  Future<MedicationLog> addMedication(MedicationLog medication) async {
    _medications.add(medication);
    return medication;
  }

  Future<void> deleteMedication(String id) async {
    _medications.removeWhere((m) => m.id == id);
  }

  Future<MedicationLog> updateMedication(MedicationLog medication) async {
    final index = _medications.indexWhere((m) => m.id == medication.id);
    if (index != -1) {
      _medications[index] = medication;
    }
    return medication;
  }

  Future<MedicationLog> markDoseTaken(String medicationId, String doseId) async {
    final medIndex = _medications.indexWhere((m) => m.id == medicationId);
    if (medIndex != -1) {
      final medication = _medications[medIndex];
      final updatedDoses = medication.doses.map((dose) {
        if (dose.id == doseId) {
          return dose.copyWith(
            taken: true,
            takenTime: DateTime.now(),
          );
        }
        return dose;
      }).toList();

      _medications[medIndex] = medication.copyWith(doses: updatedDoses);
      return _medications[medIndex];
    }
    throw Exception('Medication not found');
  }

  // ==================== HbA1c RESULTS ====================

  List<HbA1cResult> get allHbA1cResults => List.unmodifiable(_hba1cResults);

  Future<HbA1cResult> addHbA1cResult(HbA1cResult result) async {
    _hba1cResults.add(result);
    _hba1cResults.sort((a, b) => b.testDate.compareTo(a.testDate));
    return result;
  }

  HbA1cResult? get latestHbA1c =>
      _hba1cResults.isNotEmpty ? _hba1cResults.first : null;

  // ==================== BLOOD PRESSURE ====================

  List<BloodPressureReading> get allBloodPressureReadings =>
      List.unmodifiable(_bloodPressureReadings);

  BloodPressureReading? get latestBloodPressure =>
      _bloodPressureReadings.isNotEmpty ? _bloodPressureReadings.first : null;

  // ==================== CHOLESTEROL ====================

  List<CholesterolResult> get allCholesterolResults =>
      List.unmodifiable(_cholesterolResults);

  CholesterolResult? get latestCholesterol =>
      _cholesterolResults.isNotEmpty ? _cholesterolResults.first : null;

  // ==================== BMI ====================

  List<BmiResult> get allBmiResults => List.unmodifiable(_bmiResults);

  BmiResult? get latestBmi => _bmiResults.isNotEmpty ? _bmiResults.first : null;

  // ==================== SLEEP LOGS ====================

  List<SleepLog> get allSleepLogs => List.unmodifiable(_sleepLogs);

  List<SleepLog> getSleepLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var logs = _sleepLogs;

    if (startDate != null) {
      logs = logs.where((s) => s.bedTime.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      logs = logs.where((s) => s.bedTime.isBefore(endDate)).toList();
    }

    return List.unmodifiable(logs);
  }

  Future<SleepLog> addSleepLog(SleepLog log) async {
    _sleepLogs.add(log);
    _sleepLogs.sort((a, b) => b.bedTime.compareTo(a.bedTime));
    return log;
  }

  // ==================== HEALTH SUMMARY ====================

  HealthSummary getHealthSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final glucoseInRange = getGlucoseReadings(
      startDate: startDate,
      endDate: endDate,
    );

    final mealsInRange = getMeals(
      startDate: startDate,
      endDate: endDate,
    );

    final activitiesInRange = getActivities(
      startDate: startDate,
      endDate: endDate,
    );

    final sleepInRange = getSleepLogs(
      startDate: startDate,
      endDate: endDate,
    );

    // Calculate glucose statistics
    final glucoseValues = glucoseInRange.map((r) => r.value).toList();
    final averageGlucose = glucoseValues.isNotEmpty
        ? glucoseValues.reduce((a, b) => a + b) / glucoseValues.length
        : 0.0;

    final glucoseStdDev = glucoseValues.isNotEmpty
        ? _calculateStdDev(glucoseValues)
        : 0.0;

    final hyperEvents = glucoseInRange.where((r) => r.isHigh).length;
    final hypoEvents = glucoseInRange.where((r) => r.isLow).length;
    final normalReadings = glucoseInRange.where((r) => r.isNormal).length;
    final timeInRange = glucoseInRange.isNotEmpty
        ? (normalReadings / glucoseInRange.length) * 100
        : 0.0;

    // Estimated A1c from average glucose: eA1c = (avg_glucose + 46.7) / 28.7
    final estimatedA1c = (averageGlucose + 46.7) / 28.7;

    // Calculate meal statistics
    final averageCarbs = mealsInRange.isNotEmpty
        ? mealsInRange.map((m) => m.carbs).reduce((a, b) => a + b) / mealsInRange.length
        : 0.0;

    // Calculate activity statistics
    final totalActivityMinutes = activitiesInRange.isNotEmpty
        ? activitiesInRange.map((a) => a.duration).reduce((a, b) => a + b)
        : 0;

    // Calculate medication adherence
    final medicationAdherence = _medications.isNotEmpty
        ? _medications.map((m) => m.adherenceRate).reduce((a, b) => a + b) / _medications.length
        : 0.0;

    // Calculate average sleep
    final averageSleepHours = sleepInRange.isNotEmpty
        ? (sleepInRange.map((s) => s.hoursSlept).reduce((a, b) => a + b) / sleepInRange.length).round()
        : 0;

    return HealthSummary(
      startDate: startDate,
      endDate: endDate,
      averageGlucose: averageGlucose,
      glucoseStdDev: glucoseStdDev,
      totalReadings: glucoseInRange.length,
      hyperEvents: hyperEvents,
      hypoEvents: hypoEvents,
      timeInRange: timeInRange,
      estimatedA1c: estimatedA1c,
      totalMeals: mealsInRange.length,
      averageCarbs: averageCarbs,
      totalActivityMinutes: totalActivityMinutes,
      medicationAdherence: medicationAdherence,
      averageSleepHours: averageSleepHours,
    );
  }

  // ==================== MOCK DATA GENERATION ====================

  void _generateMockGlucoseReadings() {
    final now = DateTime.now();
    const days = 30;

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));
      final readingsPerDay = 4 + _random.nextInt(5);

      for (int i = 0; i < readingsPerDay; i++) {
        final hour = (i * 24 / readingsPerDay).floor();
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        double baseValue = 140 + _randomGaussian(-20, 20);
        if (hour >= 6 && hour <= 9) baseValue += 15;
        else if (hour >= 12 && hour <= 14) baseValue += 20;
        else if (hour >= 18 && hour <= 20) baseValue += 18;

        _glucoseReadings.add(GlucoseReading(
          id: 'glucose_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          value: baseValue.clamp(70, 300),
          context: _getGlucoseContext(hour),
          isFlagged: baseValue > 200 || baseValue < 70,
        ));
      }
    }
  }

  void _generateMockMeals() {
    final now = DateTime.now();
    const days = 30;
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));
      final mealsPerDay = 3 + _random.nextInt(2);

      for (int i = 0; i < mealsPerDay; i++) {
        final mealType = i < 3 ? mealTypes[i] : 'Snack';
        final hour = i == 0 ? 7 : i == 1 ? 12 : i == 2 ? 19 : 15;
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        _meals.add(MealLog(
          id: 'meal_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          type: mealType,
          description: _getMealDescription(mealType),
          carbs: 20.0 + _random.nextInt(60).toDouble(),
          calories: 200 + _random.nextInt(600),
          protein: 5.0 + _random.nextInt(30).toDouble(),
          fat: 5.0 + _random.nextInt(25).toDouble(),
        ));
      }
    }
  }

  void _generateMockActivities() {
    final now = DateTime.now();
    const days = 30;
    final activityTypes = ['Walking', 'Running', 'Cycling', 'Swimming', 'Gym', 'Yoga'];
    final intensities = ['Low', 'Moderate', 'High'];

    for (int day = 0; day < days; day++) {
      if (_random.nextDouble() > 0.4) {
        final date = now.subtract(Duration(days: days - day));
        final hour = 6 + _random.nextInt(14);
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        final duration = 15 + _random.nextInt(75);
        final intensity = intensities[_random.nextInt(intensities.length)];

        _activities.add(ActivityLog(
          id: 'activity_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          type: activityTypes[_random.nextInt(activityTypes.length)],
          duration: duration,
          intensity: intensity,
          caloriesBurned: duration * (intensity == 'High' ? 8 : intensity == 'Moderate' ? 5 : 3),
        ));
      }
    }
  }

  void _generateMockMedications() {
    final medications = [
      ('Metformin', '500 mg', 'Twice daily'),
      ('Insulin Glargine', '20 units', 'Once daily'),
    ];

    for (var med in medications) {
      final doses = <MedicationDose>[];
      final now = DateTime.now();

      for (int day = 0; day < 30; day++) {
        final date = now.subtract(Duration(days: 30 - day));

        if (med.$3 == 'Twice daily') {
          doses.add(MedicationDose(
            id: 'dose_${date.millisecondsSinceEpoch}_morning',
            scheduledTime: DateTime(date.year, date.month, date.day, 8, 0),
            taken: _random.nextDouble() > 0.2,
            takenTime: _random.nextDouble() > 0.2
                ? DateTime(date.year, date.month, date.day, 8, _random.nextInt(60))
                : null,
          ));
          doses.add(MedicationDose(
            id: 'dose_${date.millisecondsSinceEpoch}_evening',
            scheduledTime: DateTime(date.year, date.month, date.day, 20, 0),
            taken: _random.nextDouble() > 0.2,
            takenTime: _random.nextDouble() > 0.2
                ? DateTime(date.year, date.month, date.day, 20, _random.nextInt(60))
                : null,
          ));
        } else {
          doses.add(MedicationDose(
            id: 'dose_${date.millisecondsSinceEpoch}',
            scheduledTime: DateTime(date.year, date.month, date.day, 8, 0),
            taken: _random.nextDouble() > 0.15,
            takenTime: _random.nextDouble() > 0.15
                ? DateTime(date.year, date.month, date.day, 8, _random.nextInt(60))
                : null,
          ));
        }
      }

      _medications.add(MedicationLog(
        id: 'med_${med.$1.hashCode}',
        medicationName: med.$1,
        dosage: med.$2,
        frequency: med.$3,
        prescribedDate: DateTime.now().subtract(const Duration(days: 90)),
        doses: doses,
      ));
    }
  }

  void _generateMockBloodPressureReadings() {
    final now = DateTime.now();
    const days = 30;
    for (int day = 0; day < days; day++) {
      if (_random.nextBool()) { // Not every day
        final date = now.subtract(Duration(days: days - day));
        final timestamp = DateTime(date.year, date.month, date.day, 7 + _random.nextInt(2), _random.nextInt(60));
        _bloodPressureReadings.add(BloodPressureReading(
          id: 'bp_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          systolic: 110 + _random.nextInt(20).toDouble(),
          diastolic: 70 + _random.nextInt(15).toDouble(),
        ));
      }
    }
  }

  void _generateMockCholesterolResults() {
    final now = DateTime.now();
    final testDates = [
      now.subtract(const Duration(days: 120)),
      now.subtract(const Duration(days: 240)),
    ];
    for (var testDate in testDates) {
      _cholesterolResults.add(CholesterolResult(
        id: 'chol_${testDate.millisecondsSinceEpoch}',
        testDate: testDate,
        value: 180 + _random.nextDouble() * 40, // 180-220
      ));
    }
  }

  void _generateMockBmiResults() {
    final now = DateTime.now();
    final testDates = [
      now.subtract(const Duration(days: 100)),
      now.subtract(const Duration(days: 200)),
    ];
    for (var testDate in testDates) {
      _bmiResults.add(BmiResult(
        id: 'bmi_${testDate.millisecondsSinceEpoch}',
        testDate: testDate,
        value: 22 + _random.nextDouble() * 5, // 22-27
      ));
    }
  }

  void _generateMockHbA1cResults() {
    final now = DateTime.now();
    final testDates = [
      now.subtract(const Duration(days: 90)),
      now.subtract(const Duration(days: 180)),
      now.subtract(const Duration(days: 270)),
    ];

    for (var testDate in testDates) {
      _hba1cResults.add(HbA1cResult(
        id: 'hba1c_${testDate.millisecondsSinceEpoch}',
        testDate: testDate,
        value: 6.5 + _random.nextDouble() * 1.5,
        labName: 'BioTective Labs',
      ));
    }
  }

  void _generateMockSleepLogs() {
    final now = DateTime.now();
    const days = 30;

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));
      final bedTime = DateTime(date.year, date.month, date.day, 22 + _random.nextInt(3), _random.nextInt(60));
      final sleepDuration = 6 + _random.nextInt(4); // 6-10 hours
      final wakeTime = bedTime.add(Duration(hours: sleepDuration));

      _sleepLogs.add(SleepLog(
        id: 'sleep_${bedTime.millisecondsSinceEpoch}',
        bedTime: bedTime,
        wakeTime: wakeTime,
        quality: 4 + _random.nextInt(7), // 4-10
      ));
    }
  }

  // ==================== UTILITY METHODS ====================

  String _getGlucoseContext(int hour) {
    if (hour >= 5 && hour < 9) return 'Before breakfast';
    if (hour >= 9 && hour < 11) return 'After breakfast';
    if (hour >= 11 && hour < 13) return 'Before lunch';
    if (hour >= 13 && hour < 17) return 'After lunch';
    if (hour >= 17 && hour < 19) return 'Before dinner';
    if (hour >= 19 && hour < 22) return 'After dinner';
    return 'Bedtime';
  }

  String _getMealDescription(String mealType) {
    final breakfasts = ['Oatmeal with berries', 'Eggs and whole wheat toast', 'Greek yogurt with nuts'];
    final lunches = ['Grilled chicken salad', 'Brown rice with vegetables', 'Turkey sandwich'];
    final dinners = ['Salmon with broccoli', 'Lean beef stir-fry', 'Grilled chicken with quinoa'];
    final snacks = ['Apple with peanut butter', 'Mixed nuts', 'String cheese'];

    switch (mealType) {
      case 'Breakfast':
        return breakfasts[_random.nextInt(breakfasts.length)];
      case 'Lunch':
        return lunches[_random.nextInt(lunches.length)];
      case 'Dinner':
        return dinners[_random.nextInt(dinners.length)];
      default:
        return snacks[_random.nextInt(snacks.length)];
    }
  }

  double _randomGaussian(double min, double max) {
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    final randStdNormal = sqrt(-2.0 * log(u1)) * sin(2.0 * pi * u2);
    final mean = (min + max) / 2;
    final stdDev = (max - min) / 6;
    return mean + stdDev * randStdNormal;
  }

  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  /// Clear all data (for testing)
  void clearAllData() {
    _glucoseReadings.clear();
    _meals.clear();
    _activities.clear();
    _medications.clear();
    _hba1cResults.clear();
    _sleepLogs.clear();
    _bloodPressureReadings.clear();
    _cholesterolResults.clear();
    _bmiResults.clear();
  }

  /// Refresh mock data
  void refreshMockData() { // Renamed for clarity, called by provider
    clearAllData();
    generateAndLoadMockData();
  }
}
```

florence\platform_service\lib\features\patient\profile\screens\profile_screen.dart
```
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../chat/services/chatbot_service.dart';
import '../../core/providers/health_data_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../main.dart';

/// Profile & Settings Screen
/// Unified screen for user profile, health info, and app settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  
  // Mock user data (will be replaced with real data)
  String _userName = 'John Doe';
  String _userEmail = 'john.doe@example.com';
  String _dateOfBirth = 'January 15, 1985';
  String _gender = 'Male';
  String _phoneNumber = '+60 12-345 6789';
  String _diabetesType = 'Type 2';
  double _targetMin = 70.0;
  double _targetMax = 180.0;
  
  // Medications list (mock)
  List<Map<String, String>> _medications = [
    {'name': 'Metformin', 'dosage': '500mg', 'frequency': 'Twice daily'},
    {'name': 'Insulin', 'dosage': '10 units', 'frequency': 'Before meals'},
  ];
  
  // Settings
  String _glucoseUnit = 'mg/dL'; // or 'mmol/L'

  // App info
  final String _appVersion = '1.0.0';
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  /// Load user data
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Get email from the local session (safe)
      final email = supabase.auth.currentUser?.email ?? 'user@example.com';

      // Fetch the full profile from the backend API
      final profile = await _apiService.get('/patients/me');

      if (mounted) {
        setState(() {
          _userEmail = email;
          _userName = profile['name'] ?? 'John Doe';
          _dateOfBirth = profile['date_of_birth'] != null
              ? Formatters.date(DateTime.parse(profile['date_of_birth']))
              : 'Not set';
          _gender = profile['gender'] ?? 'Not set';
          _phoneNumber = profile['phone_number'] ?? 'Not set';
          // TODO: Load other profile fields like diabetes type, targets, etc.
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        Helpers.showError(context, 'Failed to load profile data.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Handle logout
  Future<void> _handleLogout() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
    );
    
    if (confirmed) {
      try {
        // Clear chatbot session state
        ChatbotService().resetSession();
        
        await supabase.auth.signOut();
        if (mounted) {
          AppRoutes.pushAndRemoveUntil(context, AppRoutes.login);
        }
      } catch (e) {
        if (mounted) {
          // In demo mode, just navigate to login
          AppRoutes.pushAndRemoveUntil(context, AppRoutes.login);
        }
      }
    }
  }
  
  /// Edit profile
  void _editProfile() {
    Helpers.showInfo(context, 'Edit profile feature coming soon');
    // TODO: Navigate to edit profile screen or show bottom sheet
  }
  
  /// Edit health profile
  void _editHealthProfile() {
    Helpers.showInfo(context, 'Edit health profile feature coming soon');
    // TODO: Navigate to edit health profile screen
  }
  
  /// Add medication
  void _addMedication() {
    Helpers.showInfo(context, 'Add medication feature coming soon');
    // TODO: Navigate to add medication screen
  }
  
  /// Toggle glucose unit
  void _toggleGlucoseUnit() {
    setState(() {
      _glucoseUnit = _glucoseUnit == 'mg/dL' ? 'mmol/L' : 'mg/dL';
    });
    Helpers.showSuccess(context, 'Glucose unit changed to $_glucoseUnit');
    // TODO: Save preference to storage
  }
  
  /// Toggle dark mode
  void _toggleDarkMode(bool value) {
    Provider.of<ThemeProvider>(context, listen: false).setTheme(
      value ? ThemeMode.dark : ThemeMode.light,
    );
  }
  
  /// Check for updates
  void _checkForUpdates() {
    Helpers.showInfo(context, 'You are using the latest version ($_appVersion)');
    // TODO: Implement version check
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile header with avatar
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    
                    // Personal info section
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 16),
                    
                    // Health profile section
                    _buildHealthProfileSection(),
                    const SizedBox(height: 16),
                    
                    // Medications section
                    _buildMedicationsSection(),
                    const SizedBox(height: 16),
                    
                    // Settings section
                    _buildSettingsSection(),
                    const SizedBox(height: 16),
                    
                    // About section
                    _buildAboutSection(),
                    const SizedBox(height: 24),
                    
                    // Sign out button
                    OutlinedButton(
                      onPressed: _handleLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Sign Out'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
  
  /// Build profile header with avatar
  Widget _buildProfileHeader() {
    return BaseCard(
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            _userName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          
          // Email
          Text(
            _userEmail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 16),
          
          // Edit profile button
          TextButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profile'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build personal info section
  Widget _buildPersonalInfoSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal Information', Icons.person_outline),
          const SizedBox(height: 16),
          
          _buildInfoRow('Date of Birth', _dateOfBirth, Icons.cake),
          const Divider(height: 24),
          _buildInfoRow('Gender', _gender, Icons.wc),
          const Divider(height: 24),
          _buildInfoRow('Phone Number', _phoneNumber, Icons.phone),
        ],
      ),
    );
  }
  
  /// Build health profile section
  Widget _buildHealthProfileSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Health Profile', Icons.favorite_outline),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: _editHealthProfile,
                tooltip: 'Edit',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            'Diabetes Type',
            _diabetesType,
            Icons.medical_information,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Target Glucose Range',
            '${_targetMin.toInt()}-${_targetMax.toInt()} mg/dL',
            Icons.track_changes,
          ),
        ],
      ),
    );
  }
  
  /// Build medications section
  Widget _buildMedicationsSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Medications', Icons.medication),
              TextButton.icon(
                onPressed: _addMedication,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_medications.isEmpty)
            _buildEmptyState('No medications added yet')
          else
            ..._medications.asMap().entries.map((entry) {
              final index = entry.key;
              final med = entry.value;
              return Column(
                children: [
                  if (index > 0) const Divider(height: 24),
                  _buildMedicationItem(
                    med['name']!,
                    med['dosage']!,
                    med['frequency']!,
                  ),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }
  
  /// Build single medication item
  Widget _buildMedicationItem(String name, String dosage, String frequency) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.medicationColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.medication,
            color: AppTheme.medicationColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '$dosage • $frequency',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: AppTheme.textSecondaryColor,
          ),
          onPressed: () {
            // TODO: Show edit/delete options
            Helpers.showInfo(context, 'Edit medication coming soon');
          },
        ),
      ],
    );
  }
  
  /// Build settings section
  Widget _buildSettingsSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Settings', Icons.settings_outlined),
          const SizedBox(height: 16),

          // Glucose unit
          _buildSettingItem(
            'Glucose Unit',
            _glucoseUnit,
            Icons.straighten,
            onTap: _toggleGlucoseUnit,
            showChevron: true,
          ),
          const Divider(height: 24),

          // Dark mode toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => _buildSettingToggle(
              'Dark Mode',
              'Switch between light and dark theme',
              Icons.dark_mode_outlined,
              themeProvider.isDarkMode,
              _toggleDarkMode,
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
  
  /// Build about section
  Widget _buildAboutSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('About', Icons.info_outline),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            'App Version',
            _appVersion,
            Icons.phone_android,
          ),
          const Divider(height: 24),
          
          _buildSettingItem(
            'Check for Updates',
            'Tap to check',
            Icons.system_update,
            onTap: _checkForUpdates,
            showChevron: true,
          ),
          const Divider(height: 24),
          
          _buildSettingItem(
            'Privacy Policy',
            'View our privacy policy',
            Icons.privacy_tip_outlined,
            onTap: () => Helpers.showInfo(context, 'Privacy policy coming soon'),
            showChevron: true,
          ),
          const Divider(height: 24),
          
          _buildSettingItem(
            'Terms of Service',
            'View terms of service',
            Icons.description_outlined,
            onTap: () => Helpers.showInfo(context, 'Terms coming soon'),
            showChevron: true,
          ),
        ],
      ),
    );
  }
  
  /// Build section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
  
  /// Build info row
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build setting item (clickable)
  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    bool showChevron = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondaryColor,
              ),
          ],
        ),
      ),
    );
  }
  
  /// Build setting toggle
  Widget _buildSettingToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppTheme.primaryBlue,
        ),
      ],
    );
  }
  
  /// Build empty state
  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
      ),
    );
  }
}
```

florence\platform_service\lib\features\patient\dashboard\providers\dashboard_providers.dart
```
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/health_data_models.dart';
import '../../core/repositories/monitor_data_repository.dart';
import '../../core/services/data_ingestion_service.dart';

// Repository Provider
final monitorDataRepositoryProvider = Provider<MonitorDataRepository>((ref) {
  return MonitorDataRepository();
});

// Data Service Provider (for Activity)
final dataIngestionServiceProvider = Provider<DataIngestionService>((ref) {
  return DataIngestionService();
});

// Monitor Data Provider
final monitorDataProvider = FutureProvider<List<MonitorData>>((ref) async {
  final repository = ref.watch(monitorDataRepositoryProvider);
  return repository.getAllMonitorData();
});

// Latest Activity Provider
final latestActivityProvider = FutureProvider<ActivityLog?>((ref) async {
  final activities = await ref.watch(activityLogsProvider.future);
  if (activities.isNotEmpty) {
    return activities.first;
  }
  return null;
});

// Patient Thresholds Provider
final patientThresholdsProvider = FutureProvider<List<HealthThreshold>>((ref) async {
  final repository = ref.watch(monitorDataRepositoryProvider);
  return repository.getHealthThresholds();
});

// Daily Patient Logs Provider (Meals)
final dailyPatientLogsProvider = FutureProvider<List<DailyPatientLog>>((ref) async {
  final repository = ref.watch(monitorDataRepositoryProvider);
  return repository.getDailyPatientLogs();
});

// Activity Logs Provider
final activityLogsProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final repository = ref.watch(monitorDataRepositoryProvider);
  return repository.getActivityLogs();
});
```

florence\platform_service\lib\features\patient\logging\screens\log_blood_pressure_screen.dart
```
import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';

/// Log Blood Pressure Screen
class LogBloodPressureScreen extends StatefulWidget {
  const LogBloodPressureScreen({super.key});

  @override
  State<LogBloodPressureScreen> createState() => _LogBloodPressureScreenState();
}

class _LogBloodPressureScreenState extends State<LogBloodPressureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _notesController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);

    try {
      final now = _selectedDateTime.toIso8601String();
      
      // Post Systolic
      await _apiService.post('/patients/me/monitor-data', {
        'data_type': 'BLOOD_PRESSURE_SYSTOLIC',
        'value': double.parse(_systolicController.text),
        'measured_at': now,
      });

      // Post Diastolic
      await _apiService.post('/patients/me/monitor-data', {
        'data_type': 'BLOOD_PRESSURE_DIASTOLIC',
        'value': double.parse(_diastolicController.text),
        'measured_at': now,
      });

      if (mounted) {
        Helpers.showSuccess(context, 'Blood pressure logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log blood pressure: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Blood Pressure'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildInputSection(),
              const SizedBox(height: 24),
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Save Reading',
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return const BaseCard(
      child: Row(
        children: [
          Icon(Icons.monitor_heart, color: AppTheme.primaryRed, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Regularly logging your blood pressure helps monitor cardiovascular health.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blood Pressure (mmHg)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Systolic',
                  hint: 'e.g., 120',
                  controller: _systolicController,
                  validator: (value) =>
                      Validators.minLength(value, 1, fieldName: 'Systolic'),
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.arrow_upward),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Diastolic',
                  hint: 'e.g., 80',
                  controller: _diastolicController,
                  validator: (value) =>
                      Validators.minLength(value, 1, fieldName: 'Diastolic'),
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.arrow_downward),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date & Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppTheme.primaryRed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.date(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          Formatters.time(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return CustomTextField(
      label: 'Notes (Optional)',
      hint: 'Any symptoms or observations?',
      controller: _notesController,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
}
```

florence\platform_service\lib\features\patient\logging\screens\log_medication_screen.dart
```
import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/button_widgets.dart';
import '../../../../shared/widgets/input_widgets.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';

/// Log Medication Screen
/// Allows users to record medication intake
class LogMedicationScreen extends StatefulWidget {
  const LogMedicationScreen({super.key});

  @override
  State<LogMedicationScreen> createState() => _LogMedicationScreenState();
}

class _LogMedicationScreenState extends State<LogMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();
  String _selectedMedicationType = 'Tablet';
  String _selectedTiming = 'Before Meal';
  
  // Medication type options
  final List<Map<String, dynamic>> _medicationTypes = [
    {'name': 'Tablet', 'icon': Icons.medication},
    {'name': 'Capsule', 'icon': Icons.medication_liquid},
    {'name': 'Injection', 'icon': Icons.vaccines},
    {'name': 'Liquid', 'icon': Icons.water_drop},
    {'name': 'Inhaler', 'icon': Icons.air},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];
  
  // Timing options
  final List<String> _timingOptions = [
    'Before Meal',
    'After Meal',
    'With Meal',
    'Empty Stomach',
    'Before Bed',
    'As Needed',
  ];
  
  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  /// Handle save
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);
    
    try {
      // TODO: Save to Supabase
      // await medicationService.saveMedication({
      //   'name': _medicationNameController.text.trim(),
      //   'type': _selectedMedicationType,
      //   'dosage': _dosageController.text.trim(),
      //   'timing': _selectedTiming,
      //   'timestamp': _selectedDateTime.toIso8601String(),
      //   'notes': _notesController.text.trim(),
      // });
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Helpers.showSuccess(context, 'Medication logged successfully!');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to log medication');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Show date time picker
  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      
      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Medication'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Helpers.showInfo(context, 'Medication history coming soon');
            },
            tooltip: 'View History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              _buildInfoCard(),
              const SizedBox(height: 24),
              
              // Medication name
              _buildMedicationNameSection(),
              const SizedBox(height: 24),
              
              // Medication type
              _buildMedicationTypeSection(),
              const SizedBox(height: 24),
              
              // Dosage
              _buildDosageSection(),
              const SizedBox(height: 24),
              
              // Timing
              _buildTimingSection(),
              const SizedBox(height: 24),
              
              // Date and time
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              
              // Notes
              _buildNotesSection(),
              const SizedBox(height: 32),
              
              // Save button
              PrimaryButton(
                text: 'Save Medication',
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
              const SizedBox(height: 16),
              
              // Warning card
              _buildWarningCard(),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build info card
  Widget _buildInfoCard() {
    return BaseCard(
      // backgroundColor: AppTheme.medicationColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.medication,
            color: AppTheme.medicationColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Track your medications to stay on schedule and monitor effects',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.medicationColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build medication name section
  Widget _buildMedicationNameSection() {
    return CustomTextField(
      label: 'Medication Name',
      hint: 'e.g., Metformin, Insulin',
      controller: _medicationNameController,
      validator: (value) => Validators.name(value, fieldName: 'Medication name'),
      textCapitalization: TextCapitalization.words,
      prefixIcon: const Icon(Icons.medical_services),
    );
  }
  
  /// Build medication type section
  Widget _buildMedicationTypeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medication Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _medicationTypes.length,
            itemBuilder: (context, index) {
              final type = _medicationTypes[index];
              final isSelected = type['name'] == _selectedMedicationType;
              
              return InkWell(
                onTap: () {
                  setState(() => _selectedMedicationType = type['name']);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.medicationColor.withOpacity(0.1)
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.medicationColor
                          : AppTheme.borderColor,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type['icon'],
                        color: isSelected
                            ? AppTheme.medicationColor
                            : AppTheme.textSecondaryColor,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type['name'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? AppTheme.medicationColor
                                  : AppTheme.textPrimaryColor,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// Build dosage section
  Widget _buildDosageSection() {
    return CustomTextField(
      label: 'Dosage',
      hint: 'e.g., 500mg, 10 units',
      controller: _dosageController,
      validator: (value) =>
          Validators.minLength(value, 1, fieldName: 'Dosage'),
      prefixIcon: const Icon(Icons.numbers),
    );
  }
  
  /// Build timing section
  Widget _buildTimingSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timingOptions.map((timing) {
              final isSelected = timing == _selectedTiming;
              return ChoiceChip(
                label: Text(timing),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedTiming = timing);
                },
                selectedColor: AppTheme.medicationColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  /// Build date time section
  Widget _buildDateTimeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date & Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: AppTheme.medicationColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.date(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          Formatters.time(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build notes section
  Widget _buildNotesSection() {
    return CustomTextField(
      label: 'Notes (Optional)',
      hint: 'Any side effects or observations?',
      controller: _notesController,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
  
  /// Build warning card
  Widget _buildWarningCard() {
    return BaseCard(
      // backgroundColor: AppTheme.warningColor.withOpacity(0.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warningColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Always consult your healthcare provider before starting, stopping, or changing medications.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
```

florence\platform_service\lib\features\patient\dashboard\widgets\biometrics_section.dart
```
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../core/models/health_data_models.dart'; // Updated import
import '../../../../config/routes.dart';
import 'compact_health_card.dart';
import '../screens/hba1c_detail_screen.dart';
import '../screens/cholesterol_detail_screen.dart';
import '../screens/diet_detail_screen.dart';

/// Biometrics Section
/// A container widget that groups all health metric cards
class BiometricsSection extends StatelessWidget {
  final List<MonitorData> monitorData;
  final ActivityLog? latestActivity;
  final DailyPatientLog? latestMeal;
  final List<HealthThreshold> thresholds;

  const BiometricsSection({
    super.key,
    required this.monitorData,
    this.latestActivity,
    this.latestMeal,
    required this.thresholds,
  });

  @override
  Widget build(BuildContext context) {
    final cards = _buildHealthCards(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final titleIconColor = isDark ? Colors.blue.shade200 : AppTheme.primaryBlue;

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.getBorderColor(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: titleIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monitor_heart_outlined,
                  color: titleIconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Health Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: cards.map((card) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: card,
            )).toList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHealthCards(BuildContext context) {
    final cards = <Widget>[];
    
    MonitorData? getData(MonitorDataType type) {
      final data = monitorData.where((d) => d.dataType == type).toList();
      if (data.isEmpty) return null;
      // Return the reading with the latest timestamp
      return data.reduce((curr, next) => 
        curr.measuredAt.isAfter(next.measuredAt) ? curr : next);
    }

    final glucose = getData(MonitorDataType.GLUCOSE);
    final bpSystolic = getData(MonitorDataType.BLOOD_PRESSURE_SYSTOLIC);
    final bpDiastolic = getData(MonitorDataType.BLOOD_PRESSURE_DIASTOLIC);
    final hba1c = getData(MonitorDataType.HBA1C);
    final cholesterol = getData(MonitorDataType.CHOLESTEROL_TOTAL);
    final bmi = getData(MonitorDataType.BMI);

    // Glucose (Always show)
    cards.add(CompactHealthCard(
      label: 'Glucose',
      value: glucose?.value.toStringAsFixed(0) ?? '--',
      unit: 'mg/dL',
      status: _getGlucoseStatus(glucose?.value, thresholds),
      timestamp: glucose?.measuredAt,
      icon: Icons.water_drop_outlined,
      color: _getGlucoseColor(glucose?.value, thresholds),
      onTap: () => AppRoutes.push(context, AppRoutes.trendsDetail),
    ));

    // Blood Pressure (Always show)
    cards.add(CompactHealthCard(
      label: 'Blood Pressure',
      value: (bpSystolic != null && bpDiastolic != null)
          ? '${bpSystolic.value.toInt()}/${bpDiastolic.value.toInt()}'
          : '--/--',
      unit: 'mmHg',
      status: _getBPStatus(bpSystolic?.value, bpDiastolic?.value, thresholds),
      timestamp: bpSystolic?.measuredAt,
      icon: Icons.monitor_heart_outlined,
      color: _getBPColor(bpSystolic?.value, bpDiastolic?.value, thresholds),
      onTap: () => AppRoutes.push(context, AppRoutes.bloodPressureDetail),
    ));

    // HbA1c (Always show)
    cards.add(CompactHealthCard(
      label: 'HbA1c',
      value: hba1c?.value.toStringAsFixed(1) ?? '--',
      unit: '%',
      status: _getHba1cStatus(hba1c?.value, thresholds),
      timestamp: hba1c?.measuredAt,
      icon: Icons.pie_chart_outline,
      color: _getHba1cColor(hba1c?.value, thresholds),
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const HbA1cDetailScreen())
      ),
    ));

    // Cholesterol (Always show)
    cards.add(CompactHealthCard(
      label: 'Cholesterol',
      value: cholesterol?.value.toStringAsFixed(0) ?? '--',
      unit: 'mg/dL',
      status: _getCholesterolStatus(cholesterol?.value, thresholds),
      timestamp: cholesterol?.measuredAt,
      icon: Icons.bloodtype_outlined,
      color: _getCholesterolColor(cholesterol?.value, thresholds),
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const CholesterolDetailScreen())
      ),
    ));

    // Activity (Always show)
    cards.add(CompactHealthCard(
      label: 'Activity',
      value: latestActivity != null ? '${latestActivity!.duration}' : '--',
      unit: 'min',
      status: latestActivity != null ? 'Latest Log' : 'No Data',
      timestamp: latestActivity?.timestamp,
      icon: Icons.directions_run_outlined,
      color: latestActivity != null ? AppTheme.activityColor : AppTheme.textSecondaryColor,
      onTap: () => AppRoutes.push(context, AppRoutes.activityDetail),
    ));

    // Diet (Always show)
    cards.add(CompactHealthCard(
      label: 'Diet',
      value: latestMeal != null ? _formatMealTime(latestMeal!.mealTime) : '--',
      unit: '',
      status: _getMealStatus(latestMeal),
      timestamp: latestMeal?.logDate,
      icon: Icons.restaurant_menu,
      color: _getMealColor(latestMeal, thresholds),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DietAnalyticsScreen()),
      ),
    ));

    // BMI (Always show)
    cards.add(CompactHealthCard(
      label: 'BMI',
      value: bmi?.value.toStringAsFixed(1) ?? '--',
      unit: '',
      status: _getBmiStatus(bmi?.value, thresholds),
      timestamp: bmi?.measuredAt,
      icon: Icons.height_outlined,
      color: _getBmiColor(bmi?.value, thresholds),
      onTap: () => AppRoutes.push(context, AppRoutes.bmiDetail),
    ));

    return cards;
  }

  String _formatMealTime(String mealTime) {
    if (mealTime.isEmpty) return '';
    return mealTime[0].toUpperCase() + mealTime.substring(1).toLowerCase();
  }

  String _getMealStatus(DailyPatientLog? meal) {
    if (meal == null) return 'No Data';

    // 1. If there is a text description, show it
    if (meal.mealDesc != null && meal.mealDesc!.isNotEmpty) {
      return meal.mealDesc!;
    }

    // 2. If no description but glucose was logged, show that
    if (meal.glucoseBeforeMeal != null || meal.glucoseAfterMeal != null) {
      return 'Glucose Tracked';
    }

    // 3. Fallback if it exists but has no details
    return 'Logged';
  }

  Color _getMealColor(DailyPatientLog? meal, List<HealthThreshold> thresholds) {
    if (meal == null) return AppTheme.textSecondaryColor; // Grey (Empty)

    // Check if glucose tracking is configured
    final t = _getThreshold(thresholds, MonitorDataType.GLUCOSE);
    if (t == null) return AppTheme.primaryBlue; // Neutral if no glucose target

    // If we have BOTH readings, check for high spikes
    if (meal.glucoseBeforeMeal != null && meal.glucoseAfterMeal != null) {
      final spike = meal.glucoseAfterMeal! - meal.glucoseBeforeMeal!;
      
      if (spike > 50) return AppTheme.errorColor;    // Red: High Spike (>50)
      if (spike > 30) return AppTheme.warningColor;  // Orange: Elevated Spike (30-50)
    }

    // Default: Green (Stable spike or just logged)
    return AppTheme.primaryGreen; 
  }

  // --- Helper Methods (Updated to handle nulls) ---

  HealthThreshold? _getThreshold(List<HealthThreshold> thresholds, MonitorDataType type) {
    try {
      return thresholds.firstWhere((t) => t.dataType == type);
    } catch (_) {
      return null;
    }
  }

  String _getGlucoseStatus(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return 'No Data';
    final t = _getThreshold(thresholds, MonitorDataType.GLUCOSE);
    if (t == null) return 'Recorded';

    if (value < t.minValue) return 'Low';
    if (value > t.maxValue) return 'High';
    return 'Normal';
  }
  
  Color _getGlucoseColor(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return AppTheme.textSecondaryColor;
    final t = _getThreshold(thresholds, MonitorDataType.GLUCOSE);
    if (t == null) return AppTheme.primaryBlue; // Neutral blue if no target

    if (value < t.minValue) return AppTheme.errorColor;
    if (value > t.maxValue) return AppTheme.errorColor;
    return AppTheme.primaryGreen;
  }

  String _getBPStatus(double? sys, double? dia, List<HealthThreshold> thresholds) {
    if (sys == null || dia == null) return 'No Data';
    final tSys = _getThreshold(thresholds, MonitorDataType.BLOOD_PRESSURE_SYSTOLIC);
    final tDia = _getThreshold(thresholds, MonitorDataType.BLOOD_PRESSURE_DIASTOLIC);
    
    if (tSys == null || tDia == null) return 'Recorded';

    if (sys > tSys.maxValue || dia > tDia.maxValue) return 'Elevated';
    if (sys < tSys.minValue || dia < tDia.minValue) return 'Low';
    return 'Normal';
  }

  Color _getBPColor(double? sys, double? dia, List<HealthThreshold> thresholds) {
    if (sys == null || dia == null) return AppTheme.textSecondaryColor;
    final tSys = _getThreshold(thresholds, MonitorDataType.BLOOD_PRESSURE_SYSTOLIC);
    final tDia = _getThreshold(thresholds, MonitorDataType.BLOOD_PRESSURE_DIASTOLIC);

    if (tSys == null || tDia == null) return AppTheme.primaryBlue;

    if (sys > tSys.maxValue || dia > tDia.maxValue) return AppTheme.errorColor;
    if (sys < tSys.minValue || dia < tDia.minValue) return AppTheme.warningColor;
    return AppTheme.primaryGreen;
  }

  String _getHba1cStatus(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return 'No Data';
    final t = _getThreshold(thresholds, MonitorDataType.HBA1C);
    if (t == null) return 'Recorded';

    if (value <= t.maxValue) return 'Normal';
    return 'High';
  }

  Color _getHba1cColor(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return AppTheme.textSecondaryColor;
    final t = _getThreshold(thresholds, MonitorDataType.HBA1C);
    if (t == null) return AppTheme.primaryBlue;

    if (value <= t.maxValue) return AppTheme.primaryGreen;
    return AppTheme.errorColor;
  }

  String _getCholesterolStatus(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return 'No Data';
    final t = _getThreshold(thresholds, MonitorDataType.CHOLESTEROL_TOTAL);
    if (t == null) return 'Recorded';

    if (value > t.maxValue) return 'High';
    return 'Desirable';
  }

  Color _getCholesterolColor(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return AppTheme.textSecondaryColor;
    final t = _getThreshold(thresholds, MonitorDataType.CHOLESTEROL_TOTAL);
    if (t == null) return AppTheme.primaryBlue;

    if (value > t.maxValue) return AppTheme.errorColor;
    return AppTheme.primaryGreen;
  }

  String _getBmiStatus(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return 'No Data';
    final t = _getThreshold(thresholds, MonitorDataType.BMI);
    if (t == null) return 'Recorded';

    if (value < t.minValue) return 'Low';
    if (value > t.maxValue) return 'High';
    return 'Normal';
  }

  Color _getBmiColor(double? value, List<HealthThreshold> thresholds) {
    if (value == null) return AppTheme.textSecondaryColor;
    final t = _getThreshold(thresholds, MonitorDataType.BMI);
    if (t == null) return AppTheme.primaryBlue;

    if (value < t.minValue) return AppTheme.warningColor; // Underweight
    if (value > t.maxValue) return AppTheme.errorColor; // Overweight/Obese
    return AppTheme.primaryGreen;
  }
}
```



Just tell me how to edit the files to make the changes.
Don't give me back entire files.
Just show me the edits I need to make.


