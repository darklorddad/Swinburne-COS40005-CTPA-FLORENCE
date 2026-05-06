import 'package:florence/features/admin/core/models/admin_enums.dart';
import 'package:florence/features/admin/core/models/admin_user.dart';
import 'package:florence/features/admin/core/services/admin_auth_service.dart';

/// Permission Service
/// Centralized permission checking and validation
/// Works with AdminAuthService to enforce access control
class PermissionService {
  // Singleton pattern
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final _authService = AdminAuthService();

  // ============================================
  // BASIC PERMISSION CHECKS
  // ============================================

  /// Check if current user has a specific permission
  bool hasPermission(AdminPermission permission) {
    return _authService.hasPermission(permission);
  }

  /// Check if current user has any of the specified permissions (OR logic)
  bool hasAnyPermission(List<AdminPermission> permissions) {
    return _authService.hasAnyPermission(permissions);
  }

  /// Check if current user has all of the specified permissions (AND logic)
  bool hasAllPermissions(List<AdminPermission> permissions) {
    return _authService.hasAllPermissions(permissions);
  }

  /// Get current user
  AdminUser? get currentUser => _authService.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _authService.isAuthenticated;

  // ============================================
  // ROLE-BASED CHECKS
  // ============================================

  /// Check if current user is Global Admin
  bool get isAdmin {
    return currentUser?.isAdmin ?? false;
  }

  /// Check if current user is Hospital Admin
  bool get isHospitalAdmin {
    return currentUser?.isHospitalAdmin ?? false;
  }

  /// Check if current user has specific role
  bool hasRole(AdminRole role) {
    return currentUser?.role == role;
  }

  /// Check if current user has any of the specified roles
  bool hasAnyRole(List<AdminRole> roles) {
    final userRole = currentUser?.role;
    if (userRole == null) return false;
    return roles.contains(userRole);
  }

  // ============================================
  // ORGANIZATION CHECKS
  // ============================================

  /// Check if current user belongs to specific organization
  bool belongsToOrganization(String organizationId) {
    final userOrgId = currentUser?.organizationId;
    
    // Global Admin has access to all organizations
    if (isAdmin) return true;
    
    // Check if user's org matches
    return userOrgId == organizationId;
  }

  /// Check if current user can access data from specific organization
  bool canAccessOrganization(String organizationId) {
    // Global Admin can access all organizations
    if (isAdmin) return true;
    
    // Other roles can only access their own organization
    return belongsToOrganization(organizationId);
  }

  /// Get current user's organization ID (null for Global Admin)
  String? get currentOrganizationId {
    return currentUser?.organizationId;
  }

  // ============================================
  // FEATURE-SPECIFIC PERMISSION CHECKS
  // ============================================

  /// Check if user can manage organizations
  bool get canManageOrganizations {
    return hasAnyPermission([
      AdminPermission.createOrganization,
      AdminPermission.editAnyOrganization,
      AdminPermission.deleteOrganization,
    ]);
  }

  /// Check if user can view all organizations
  bool get canViewAllOrganizations {
    return hasPermission(AdminPermission.viewAllOrganizations);
  }

  /// Check if user can create organizations
  bool get canCreateOrganization {
    return hasPermission(AdminPermission.createOrganization);
  }

  /// Check if user can edit any organization
  bool get canEditAnyOrganization {
    return hasPermission(AdminPermission.editAnyOrganization);
  }

  /// Check if user can edit own organization
  bool get canEditOwnOrganization {
    return hasPermission(AdminPermission.editOwnOrganization);
  }

  /// Check if user can edit a specific organization
  bool canEditOrganization(String organizationId) {
    if (canEditAnyOrganization) return true;
    if (canEditOwnOrganization && belongsToOrganization(organizationId)) {
      return true;
    }
    return false;
  }

  // User Management Permissions
  bool get canManageUsers {
    return hasAnyPermission([
      AdminPermission.createUser,
      AdminPermission.editUser,
      AdminPermission.disableUser,
      AdminPermission.deleteUser,
    ]);
  }

  bool get canViewAllUsers {
    return hasPermission(AdminPermission.viewAllUsers);
  }

  bool get canViewOrgUsers {
    return hasPermission(AdminPermission.viewOrgUsers);
  }

  bool get canCreateUser {
    return hasPermission(AdminPermission.createUser);
  }

  bool get canEditUser {
    return hasPermission(AdminPermission.editUser);
  }

  bool get canDeleteUser {
    return hasPermission(AdminPermission.deleteUser);
  }

  bool get canAssignUserRole {
    return hasPermission(AdminPermission.assignUserRole);
  }

  // Patient Management Permissions
  bool get canManagePatients {
    return hasAnyPermission([
      AdminPermission.createPatient,
      AdminPermission.editPatient,
      AdminPermission.deletePatient,
      AdminPermission.mergePatients,
    ]);
  }

  bool get canViewAllPatients {
    return hasPermission(AdminPermission.viewAllPatients);
  }

  bool get canViewOrgPatients {
    return hasPermission(AdminPermission.viewOrgPatients);
  }

  bool get canCreatePatient {
    return hasPermission(AdminPermission.createPatient);
  }

  bool get canEditPatient {
    return hasPermission(AdminPermission.editPatient);
  }

  bool get canDeletePatient {
    return hasPermission(AdminPermission.deletePatient);
  }

  bool get canMergePatients {
    return hasPermission(AdminPermission.mergePatients);
  }

  bool get canExportPatientData {
    return hasPermission(AdminPermission.exportPatientData);
  }

  // Role & Permission Management
  bool get canManageRoles {
    return hasAnyPermission([
      AdminPermission.createRole,
      AdminPermission.editRole,
      AdminPermission.deleteRole,
    ]);
  }

  bool get canViewAllRoles {
    return hasPermission(AdminPermission.viewAllRoles);
  }

  bool get canCreateRole {
    return hasPermission(AdminPermission.createRole);
  }

  bool get canEditRole {
    return hasPermission(AdminPermission.editRole);
  }

  bool get canViewAllPermissions {
    return hasPermission(AdminPermission.viewAllPermissions);
  }

  bool get canManagePermissions {
    return hasPermission(AdminPermission.managePermissions);
  }

  // Medication Management
  bool get canManageMedications {
    return hasAnyPermission([
      AdminPermission.createMedication,
      AdminPermission.editMedication,
      AdminPermission.deleteMedication,
    ]);
  }

  bool get canViewMedications {
    return hasPermission(AdminPermission.viewMedications);
  }

  bool get canCreateMedication {
    return hasPermission(AdminPermission.createMedication);
  }

  bool get canEditMedication {
    return hasPermission(AdminPermission.editMedication);
  }

  bool get canDeleteMedication {
    return hasPermission(AdminPermission.deleteMedication);
  }

  // Clinical Data Access
  bool get canViewPatientHealthData {
    return hasPermission(AdminPermission.viewPatientHealthData);
  }

  bool get canEditPatientHealthData {
    return hasPermission(AdminPermission.editPatientHealthData);
  }

  bool get canViewHypoHyperEvents {
    return hasPermission(AdminPermission.viewHypoHyperEvents);
  }

  bool get canViewPatientLogbook {
    return hasPermission(AdminPermission.viewPatientLogbook);
  }

  bool get canAddPatientNotes {
    return hasPermission(AdminPermission.addPatientNotes);
  }

  // Audit & Monitoring
  bool get canViewAuditLogs {
    return hasPermission(AdminPermission.viewAuditLogs);
  }

  bool get canViewLoginLogs {
    return hasPermission(AdminPermission.viewLoginLogs);
  }

  bool get canViewActivityLogs {
    return hasPermission(AdminPermission.viewActivityLogs);
  }

  bool get canViewDeviceLogs {
    return hasPermission(AdminPermission.viewDeviceLogs);
  }

  // Practice Groups
  bool get canManagePracticeGroups {
    return hasAnyPermission([
      AdminPermission.createPracticeGroup,
      AdminPermission.editPracticeGroup,
      AdminPermission.deletePracticeGroup,
    ]);
  }

  // Appointments
  bool get canManageAppointments {
    return hasAnyPermission([
      AdminPermission.createAppointment,
      AdminPermission.editAppointment,
      AdminPermission.cancelAppointment,
    ]);
  }

  // System Administration
  bool get canConfigureSystem {
    return hasPermission(AdminPermission.configureSystem);
  }

  bool get canManageBackups {
    return hasPermission(AdminPermission.manageBackups);
  }

  // ============================================
  // PERMISSION REQUIREMENT VALIDATION
  // ============================================

  /// Validate that user has required permission, throw exception if not
  void requirePermission(AdminPermission permission, [String? message]) {
    if (!hasPermission(permission)) {
      throw PermissionDeniedException(
        message ?? 'You do not have permission to perform this action',
        requiredPermission: permission,
      );
    }
  }

  /// Validate that user has any of the required permissions
  void requireAnyPermission(List<AdminPermission> permissions, [String? message]) {
    if (!hasAnyPermission(permissions)) {
      throw PermissionDeniedException(
        message ?? 'You do not have permission to perform this action',
        requiredPermissions: permissions,
      );
    }
  }

  /// Validate that user has all of the required permissions
  void requireAllPermissions(List<AdminPermission> permissions, [String? message]) {
    if (!hasAllPermissions(permissions)) {
      throw PermissionDeniedException(
        message ?? 'You do not have permission to perform this action',
        requiredPermissions: permissions,
      );
    }
  }

  /// Validate that user has specific role
  void requireRole(AdminRole role, [String? message]) {
    if (!hasRole(role)) {
      throw PermissionDeniedException(
        message ?? 'This action requires ${role.displayName} role',
        requiredRole: role,
      );
    }
  }

  /// Validate that user belongs to specific organization
  void requireOrganization(String organizationId, [String? message]) {
    if (!canAccessOrganization(organizationId)) {
      throw PermissionDeniedException(
        message ?? 'You do not have access to this organization',
      );
    }
  }

  // ============================================
  // PERMISSION DESCRIPTION
  // ============================================

  /// Get human-readable description of what a permission allows
  String getPermissionDescription(AdminPermission permission) {
    return permission.description;
  }

  /// Get list of all permissions with descriptions
  Map<AdminPermission, String> getAllPermissionDescriptions() {
    return Map.fromEntries(
      AdminPermission.values.map(
        (p) => MapEntry(p, p.description),
      ),
    );
  }
}

// ============================================
// CUSTOM EXCEPTIONS
// ============================================

/// Exception thrown when user lacks required permissions
class PermissionDeniedException implements Exception {
  final String message;
  final AdminPermission? requiredPermission;
  final List<AdminPermission>? requiredPermissions;
  final AdminRole? requiredRole;

  PermissionDeniedException(
    this.message, {
    this.requiredPermission,
    this.requiredPermissions,
    this.requiredRole,
  });

  @override
  String toString() {
    var msg = 'PermissionDeniedException: $message';
    
    if (requiredPermission != null) {
      msg += '\nRequired permission: ${requiredPermission!.displayName}';
    }
    
    if (requiredPermissions != null && requiredPermissions!.isNotEmpty) {
      msg += '\nRequired permissions: ${requiredPermissions!.map((p) => p.displayName).join(', ')}';
    }
    
    if (requiredRole != null) {
      msg += '\nRequired role: ${requiredRole!.displayName}';
    }
    
    return msg;
  }
}
