/// Admin-specific enumerations
/// Defines roles, permissions, and status types for the admin system
library;

// ============================================
// ADMIN ROLES
// ============================================

enum AdminRole {
  superAdmin('Super Admin', 'Full system access'),
  hospitalAdmin('Hospital Admin', 'Organization-level access'),
  doctor('Doctor', 'Clinical access');

  final String displayName;
  final String description;
  
  const AdminRole(this.displayName, this.description);
  
  /// Check if this role is Super Admin
  bool get isSuperAdmin => this == AdminRole.superAdmin;
  
  /// Check if this role is Hospital Admin
  bool get isHospitalAdmin => this == AdminRole.hospitalAdmin;
  
  /// Check if this role is Doctor
  bool get isDoctor => this == AdminRole.doctor;
  
  /// Get role from string
  static AdminRole fromString(String role) {
    switch (role.toLowerCase().replaceAll(' ', '')) {
      case 'superadmin':
        return AdminRole.superAdmin;
      case 'hospitaladmin':
        return AdminRole.hospitalAdmin;
      case 'doctor':
      case 'physician':
        return AdminRole.doctor;
      default:
        throw Exception('Unknown admin role: $role');
    }
  }
}

// ============================================
// PERMISSIONS
// ============================================

enum AdminPermission {
  // Organization Management
  viewAllOrganizations('View All Organizations', 'View organizations across the system'),
  viewOwnOrganization('View Own Organization', 'View assigned organization details'),
  createOrganization('Create Organization', 'Create new organizations'),
  editAnyOrganization('Edit Any Organization', 'Edit any organization details'),
  editOwnOrganization('Edit Own Organization', 'Edit own organization details'),
  deleteOrganization('Delete Organization', 'Delete organizations'),
  
  // User Management
  viewAllUsers('View All Users', 'View users across all organizations'),
  viewOrgUsers('View Organization Users', 'View users in own organization'),
  createUser('Create User', 'Create new user accounts'),
  editUser('Edit User', 'Edit user account details'),
  disableUser('Disable User', 'Disable or enable user accounts'),
  deleteUser('Delete User', 'Permanently delete user accounts'),
  assignUserRole('Assign User Role', 'Assign roles to users'),
  
  // Patient Management
  viewAllPatients('View All Patients', 'View patients across all organizations'),
  viewOrgPatients('View Organization Patients', 'View patients in own organization'),
  createPatient('Create Patient', 'Create new patient records'),
  editPatient('Edit Patient', 'Edit patient information'),
  deletePatient('Delete Patient', 'Delete patient records'),
  mergePatients('Merge Patients', 'Merge duplicate patient records'),
  exportPatientData('Export Patient Data', 'Export patient data'),
  
  // Roles & Permissions Management
  viewAllRoles('View All Roles', 'View all system roles'),
  viewOrgRoles('View Organization Roles', 'View roles in own organization'),
  createRole('Create Role', 'Create new roles'),
  editRole('Edit Role', 'Edit role definitions'),
  deleteRole('Delete Role', 'Delete roles'),
  viewAllPermissions('View All Permissions', 'View all system permissions'),
  managePermissions('Manage Permissions', 'Create and modify permissions'),
  
  // Medication Management
  viewMedications('View Medications', 'View medication list'),
  createMedication('Create Medication', 'Add new medications'),
  editMedication('Edit Medication', 'Modify medication details'),
  deleteMedication('Delete Medication', 'Remove medications'),
  importMedications('Import Medications', 'Bulk import medications'),
  
  // Practice Group Management
  viewPracticeGroups('View Practice Groups', 'View practice groups'),
  createPracticeGroup('Create Practice Group', 'Create new practice groups'),
  editPracticeGroup('Edit Practice Group', 'Modify practice groups'),
  deletePracticeGroup('Delete Practice Group', 'Remove practice groups'),
  
  // Appointment Management
  viewAppointments('View Appointments', 'View appointment schedules'),
  createAppointment('Create Appointment', 'Schedule appointments'),
  editAppointment('Edit Appointment', 'Modify appointments'),
  cancelAppointment('Cancel Appointment', 'Cancel appointments'),
  
  // Clinical Data Access
  viewPatientHealthData('View Patient Health Data', 'Access patient health records'),
  editPatientHealthData('Edit Patient Health Data', 'Modify health records'),
  viewHypoHyperEvents('View Hypo/Hyper Events', 'View glucose events'),
  viewPatientLogbook('View Patient Logbook', 'Access patient daily logs'),
  addPatientNotes('Add Patient Notes', 'Add clinical notes'),
  
  // Audit & Monitoring
  viewAuditLogs('View Audit Logs', 'Access system audit logs'),
  viewLoginLogs('View Login Logs', 'View user login history'),
  viewActivityLogs('View Activity Logs', 'View user activity logs'),
  viewDeviceLogs('View Device Logs', 'View device access logs'),
  
  // System Administration
  configureSystem('Configure System', 'Modify system settings'),
  manageBackups('Manage Backups', 'Handle system backups'),
  viewSystemHealth('View System Health', 'Monitor system status'),
  manageNotifications('Manage Notifications', 'Configure notifications');

  final String displayName;
  final String description;
  
  const AdminPermission(this.displayName, this.description);
  
  /// Get permission from string
  static AdminPermission? fromString(String permission) {
    try {
      return AdminPermission.values.firstWhere(
        (p) => p.name.toLowerCase() == permission.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}

// ============================================
// ORGANIZATION STATUS
// ============================================

enum OrganizationStatus {
  active('Active', 'Organization is active and operational'),
  inactive('Inactive', 'Organization is temporarily inactive'),
  suspended('Suspended', 'Organization access is suspended');

  final String displayName;
  final String description;
  
  const OrganizationStatus(this.displayName, this.description);
  
  /// Check if organization is active
  bool get isActive => this == OrganizationStatus.active;
  
  /// Get status from string
  static OrganizationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return OrganizationStatus.active;
      case 'inactive':
        return OrganizationStatus.inactive;
      case 'suspended':
        return OrganizationStatus.suspended;
      default:
        return OrganizationStatus.inactive;
    }
  }
}

// ============================================
// USER STATUS
// ============================================

enum UserStatus {
  active('Active', 'User account is active'),
  inactive('Inactive', 'User account is inactive'),
  suspended('Suspended', 'User account is suspended'),
  pendingVerification('Pending Verification', 'Email verification pending');

  final String displayName;
  final String description;
  
  const UserStatus(this.displayName, this.description);
  
  /// Check if user is active
  bool get isActive => this == UserStatus.active;
  
  /// Get status from string
  static UserStatus fromString(String status) {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'active':
        return UserStatus.active;
      case 'inactive':
        return UserStatus.inactive;
      case 'suspended':
        return UserStatus.suspended;
      case 'pendingverification':
        return UserStatus.pendingVerification;
      default:
        return UserStatus.inactive;
    }
  }
}

// ============================================
// AUDIT LOG ACTION TYPES
// ============================================

enum AuditActionType {
  // Authentication
  login('Login', 'User logged in'),
  logout('Logout', 'User logged out'),
  failedLogin('Failed Login', 'Login attempt failed'),
  
  // User Management
  userCreated('User Created', 'New user account created'),
  userUpdated('User Updated', 'User account updated'),
  userDeleted('User Deleted', 'User account deleted'),
  userDisabled('User Disabled', 'User account disabled'),
  userEnabled('User Enabled', 'User account enabled'),
  
  // Organization Management
  organizationCreated('Organization Created', 'New organization created'),
  organizationUpdated('Organization Updated', 'Organization updated'),
  organizationDeleted('Organization Deleted', 'Organization deleted'),
  
  // Patient Management
  patientCreated('Patient Created', 'New patient record created'),
  patientUpdated('Patient Updated', 'Patient record updated'),
  patientDeleted('Patient Deleted', 'Patient record deleted'),
  patientsMerged('Patients Merged', 'Patient records merged'),
  patientDataViewed('Patient Data Viewed', 'Patient data accessed'),
  
  // Role & Permission Changes
  roleCreated('Role Created', 'New role created'),
  roleUpdated('Role Updated', 'Role modified'),
  roleDeleted('Role Deleted', 'Role deleted'),
  permissionsChanged('Permissions Changed', 'User permissions modified'),
  
  // Clinical Data
  healthDataViewed('Health Data Viewed', 'Patient health data accessed'),
  healthDataModified('Health Data Modified', 'Patient health data changed'),
  medicationChanged('Medication Changed', 'Patient medication updated'),
  
  // System
  settingsChanged('Settings Changed', 'System settings modified'),
  dataExported('Data Exported', 'Data export performed'),
  backupCreated('Backup Created', 'System backup created');

  final String displayName;
  final String description;
  
  const AuditActionType(this.displayName, this.description);
}

// ============================================
// APPOINTMENT STATUS
// ============================================

enum AppointmentStatus {
  scheduled('Scheduled', 'Appointment is scheduled'),
  confirmed('Confirmed', 'Appointment is confirmed'),
  inProgress('In Progress', 'Appointment is ongoing'),
  completed('Completed', 'Appointment completed'),
  cancelled('Cancelled', 'Appointment cancelled'),
  noShow('No Show', 'Patient did not attend');

  final String displayName;
  final String description;
  
  const AppointmentStatus(this.displayName, this.description);
  
  /// Get status from string
  static AppointmentStatus fromString(String status) {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'scheduled':
        return AppointmentStatus.scheduled;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'inprogress':
        return AppointmentStatus.inProgress;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'noshow':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.scheduled;
    }
  }
}

// ============================================
// PATIENT STATUS
// ============================================

enum PatientStatus {
  active('Active', 'Patient is actively monitored'),
  inactive('Inactive', 'Patient is not currently active'),
  discharged('Discharged', 'Patient has been discharged'),
  transferred('Transferred', 'Patient transferred to another facility');

  final String displayName;
  final String description;
  
  const PatientStatus(this.displayName, this.description);
  
  /// Check if patient is active
  bool get isActive => this == PatientStatus.active;
  
  /// Get status from string
  static PatientStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return PatientStatus.active;
      case 'inactive':
        return PatientStatus.inactive;
      case 'discharged':
        return PatientStatus.discharged;
      case 'transferred':
        return PatientStatus.transferred;
      default:
        return PatientStatus.inactive;
    }
  }
}