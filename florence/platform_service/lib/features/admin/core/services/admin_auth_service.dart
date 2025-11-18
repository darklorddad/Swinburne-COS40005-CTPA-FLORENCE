import '../models/admin_user.dart';
import '../models/admin_enums.dart';
import '../models/organization.dart';

/// Admin Authentication Service
/// Handles login, logout, and session management for admin users
/// Currently uses mock data - will be replaced with Supabase integration
class AdminAuthService {
  // Singleton pattern
  static final AdminAuthService _instance = AdminAuthService._internal();
  factory AdminAuthService() => _instance;
  AdminAuthService._internal();

  // Current logged-in user
  AdminUser? _currentUser;
  AdminUser? get currentUser => _currentUser;

  // Session state
  bool get isAuthenticated => currentUser != null;

  // ============================================
  // MOCK DATA - Organizations
  // ============================================

  final List<Organization> _mockOrganizations = [
    Organization(
      id: 'org_001',
      name: 'City General Hospital',
      customLoginUrl: 'city-general',
      status: OrganizationStatus.active,
      address: '123 Medical Plaza',
      city: 'Kuching',
      state: 'Sarawak',
      country: 'Malaysia',
      postalCode: '93000',
      phone: '+60 82-123456',
      email: 'admin@citygeneral.com',
      website: 'www.citygeneral.com',
      patientCount: 342,
      staffCount: 45,
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2025, 10, 20),
      createdBy: 'super_admin_001',
    ),
    Organization(
      id: 'org_002',
      name: 'Memorial Medical Center',
      customLoginUrl: 'memorial-medical',
      status: OrganizationStatus.active,
      address: '456 Healthcare Avenue',
      city: 'Miri',
      state: 'Sarawak',
      country: 'Malaysia',
      postalCode: '98000',
      phone: '+60 85-654321',
      email: 'info@memorialmedical.com',
      website: 'www.memorialmedical.com',
      patientCount: 567,
      staffCount: 78,
      createdAt: DateTime(2024, 3, 10),
      updatedAt: DateTime(2025, 10, 15),
      createdBy: 'super_admin_001',
    ),
    Organization(
      id: 'org_003',
      name: 'Community Health Clinic',
      customLoginUrl: 'community-health',
      status: OrganizationStatus.active,
      address: '789 Wellness Street',
      city: 'Sibu',
      state: 'Sarawak',
      country: 'Malaysia',
      postalCode: '96000',
      phone: '+60 84-789012',
      email: 'contact@communityhealthclinic.com',
      website: 'www.communityhealthclinic.com',
      patientCount: 189,
      staffCount: 23,
      createdAt: DateTime(2024, 6, 20),
      updatedAt: DateTime(2025, 10, 10),
      createdBy: 'super_admin_001',
    ),
  ];

  // ============================================
  // MOCK DATA - Users
  // ============================================

  final List<AdminUser> _mockUsers = [
    // Super Admin
    AdminUser(
      id: 'super_admin_001',
      email: 'superadmin@biotective.com',
      firstName: 'Sarah',
      lastName: 'Anderson',
      role: AdminRole.superAdmin,
      status: UserStatus.active,
      organizationId: null, // Super Admin has no org restriction
      organizationName: null,
      phone: '+60 12-3456789',
      profileImageUrl: null,
      permissions: AdminPermission.values.toList(), // All permissions
      createdAt: DateTime(2024, 1, 1),
      lastLoginAt: DateTime(2025, 10, 27, 8, 30),
    ),

    // Hospital Admin - City General Hospital
    AdminUser(
      id: 'hospital_admin_001',
      email: 'admin@citygeneral.com',
      firstName: 'Michael',
      lastName: 'Chen',
      role: AdminRole.hospitalAdmin,
      status: UserStatus.active,
      organizationId: 'org_001',
      organizationName: 'City General Hospital',
      phone: '+60 12-9876543',
      profileImageUrl: null,
      permissions: [
        // Organization (own only)
        AdminPermission.viewOwnOrganization,
        AdminPermission.editOwnOrganization,
        
        // Users (org-scoped)
        AdminPermission.viewOrgUsers,
        AdminPermission.createUser,
        AdminPermission.editUser,
        AdminPermission.disableUser,
        AdminPermission.assignUserRole,
        
        // Patients (org-scoped)
        AdminPermission.viewOrgPatients,
        AdminPermission.createPatient,
        AdminPermission.editPatient,
        AdminPermission.mergePatients,
        AdminPermission.exportPatientData,
        
        // Roles (view/edit, not create)
        AdminPermission.viewOrgRoles,
        AdminPermission.editRole,
        
        // Medications (view only)
        AdminPermission.viewMedications,
        
        // Practice Groups
        AdminPermission.viewPracticeGroups,
        AdminPermission.createPracticeGroup,
        AdminPermission.editPracticeGroup,
        AdminPermission.deletePracticeGroup,
        
        // Appointments
        AdminPermission.viewAppointments,
        AdminPermission.createAppointment,
        AdminPermission.editAppointment,
        AdminPermission.cancelAppointment,
        
        // Clinical Data
        AdminPermission.viewPatientHealthData,
        AdminPermission.editPatientHealthData,
        AdminPermission.viewHypoHyperEvents,
        AdminPermission.viewPatientLogbook,
        AdminPermission.addPatientNotes,
      ],
      createdAt: DateTime(2024, 1, 15),
      lastLoginAt: DateTime(2025, 10, 26, 14, 45),
    ),

    // Hospital Admin - Memorial Medical Center
    AdminUser(
      id: 'hospital_admin_002',
      email: 'admin@memorialmedical.com',
      firstName: 'Emily',
      lastName: 'Rodriguez',
      role: AdminRole.hospitalAdmin,
      status: UserStatus.active,
      organizationId: 'org_002',
      organizationName: 'Memorial Medical Center',
      phone: '+60 13-5554321',
      profileImageUrl: null,
      permissions: [
        // Same permissions as hospital_admin_001
        AdminPermission.viewOwnOrganization,
        AdminPermission.editOwnOrganization,
        AdminPermission.viewOrgUsers,
        AdminPermission.createUser,
        AdminPermission.editUser,
        AdminPermission.disableUser,
        AdminPermission.assignUserRole,
        AdminPermission.viewOrgPatients,
        AdminPermission.createPatient,
        AdminPermission.editPatient,
        AdminPermission.mergePatients,
        AdminPermission.exportPatientData,
        AdminPermission.viewOrgRoles,
        AdminPermission.editRole,
        AdminPermission.viewMedications,
        AdminPermission.viewPracticeGroups,
        AdminPermission.createPracticeGroup,
        AdminPermission.editPracticeGroup,
        AdminPermission.deletePracticeGroup,
        AdminPermission.viewAppointments,
        AdminPermission.createAppointment,
        AdminPermission.editAppointment,
        AdminPermission.cancelAppointment,
        AdminPermission.viewPatientHealthData,
        AdminPermission.editPatientHealthData,
        AdminPermission.viewHypoHyperEvents,
        AdminPermission.viewPatientLogbook,
        AdminPermission.addPatientNotes,
      ],
      createdAt: DateTime(2024, 3, 10),
      lastLoginAt: DateTime(2025, 10, 25, 9, 15),
    ),

    // Doctor - City General Hospital
    AdminUser(
      id: 'doctor_001',
      email: 'dr.johnson@citygeneral.com',
      firstName: 'James',
      lastName: 'Johnson',
      role: AdminRole.doctor,
      status: UserStatus.active,
      organizationId: 'org_001',
      organizationName: 'City General Hospital',
      phone: '+60 14-2223344',
      profileImageUrl: null,
      permissions: [
        // Patients (view only)
        AdminPermission.viewOrgPatients,
        
        // Clinical Data (full access)
        AdminPermission.viewPatientHealthData,
        AdminPermission.editPatientHealthData,
        AdminPermission.viewHypoHyperEvents,
        AdminPermission.viewPatientLogbook,
        AdminPermission.addPatientNotes,
        
        // Appointments (view/edit)
        AdminPermission.viewAppointments,
        AdminPermission.editAppointment,
        
        // Medications (view only)
        AdminPermission.viewMedications,
      ],
      createdAt: DateTime(2024, 2, 1),
      lastLoginAt: DateTime(2025, 10, 27, 7, 00),
    ),

    // Doctor - Memorial Medical Center
    AdminUser(
      id: 'doctor_002',
      email: 'dr.patel@memorialmedical.com',
      firstName: 'Priya',
      lastName: 'Patel',
      role: AdminRole.doctor,
      status: UserStatus.active,
      organizationId: 'org_002',
      organizationName: 'Memorial Medical Center',
      phone: '+60 15-6667788',
      profileImageUrl: null,
      permissions: [
        // Same as doctor_001
        AdminPermission.viewOrgPatients,
        AdminPermission.viewPatientHealthData,
        AdminPermission.editPatientHealthData,
        AdminPermission.viewHypoHyperEvents,
        AdminPermission.viewPatientLogbook,
        AdminPermission.addPatientNotes,
        AdminPermission.viewAppointments,
        AdminPermission.editAppointment,
        AdminPermission.viewMedications,
      ],
      createdAt: DateTime(2024, 3, 15),
      lastLoginAt: DateTime(2025, 10, 26, 16, 30),
    ),

    // Doctor - Community Health Clinic
    AdminUser(
      id: 'doctor_003',
      email: 'dr.wong@communityhealthclinic.com',
      firstName: 'David',
      lastName: 'Wong',
      role: AdminRole.doctor,
      status: UserStatus.active,
      organizationId: 'org_003',
      organizationName: 'Community Health Clinic',
      phone: '+60 16-9998877',
      profileImageUrl: null,
      permissions: [
        // Same as other doctors
        AdminPermission.viewOrgPatients,
        AdminPermission.viewPatientHealthData,
        AdminPermission.editPatientHealthData,
        AdminPermission.viewHypoHyperEvents,
        AdminPermission.viewPatientLogbook,
        AdminPermission.addPatientNotes,
        AdminPermission.viewAppointments,
        AdminPermission.editAppointment,
        AdminPermission.viewMedications,
      ],
      createdAt: DateTime(2024, 6, 25),
      lastLoginAt: DateTime(2025, 10, 24, 13, 20),
    ),
  ];

  // ============================================
  // AUTHENTICATION METHODS
  // ============================================

  /// Login with email and password
  /// Returns AdminUser on success, null on failure
  Future<AdminUser?> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Find user by email
      final user = _mockUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );

      // Check if user is active
      if (!user.isActive) {
        throw Exception('Account is inactive or suspended');
      }

      // In real app, verify password with backend
      // For demo, accept any password for existing users
      // In production: if (password != user.hashedPassword) throw Exception

      // Update last login time
      final updatedUser = user.copyWith(
        lastLoginAt: DateTime.now(),
      );

      // Set current user
      _currentUser = updatedUser;

      return updatedUser;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    _currentUser = null;
  }

  /// Check if user has specific permission
  bool hasPermission(AdminPermission permission) {
    if (_currentUser == null) return false;
    return _currentUser!.hasPermission(permission);
  }

  /// Check if user has any of the permissions
  bool hasAnyPermission(List<AdminPermission> permissions) {
    if (_currentUser == null) return false;
    return _currentUser!.hasAnyPermission(permissions);
  }

  /// Check if user has all of the permissions
  bool hasAllPermissions(List<AdminPermission> permissions) {
    if (_currentUser == null) return false;
    return _currentUser!.hasAllPermissions(permissions);
  }

  /// Get current user's organization
  Organization? getCurrentUserOrganization() {
    if (_currentUser == null || _currentUser!.organizationId == null) {
      return null;
    }

    try {
      return _mockOrganizations.firstWhere(
        (org) => org.id == _currentUser!.organizationId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all organizations (Super Admin only)
  List<Organization> getAllOrganizations() {
    if (_currentUser?.isSuperAdmin != true) {
      return [];
    }
    return _mockOrganizations;
  }

  /// Get organization by ID
  Organization? getOrganizationById(String id) {
    try {
      return _mockOrganizations.firstWhere((org) => org.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all users (filtered by permission)
  List<AdminUser> getAllUsers() {
    if (_currentUser == null) return [];

    if (_currentUser!.hasPermission(AdminPermission.viewAllUsers)) {
      // Super Admin: see all users
      return _mockUsers;
    } else if (_currentUser!.hasPermission(AdminPermission.viewOrgUsers)) {
      // Hospital Admin/Doctor: see only org users
      return _mockUsers
          .where((u) => u.organizationId == _currentUser!.organizationId)
          .toList();
    }

    return [];
  }

  // ============================================
  // DEMO HELPERS
  // ============================================

  /// Get demo credentials for testing
  static Map<String, Map<String, String>> getDemoCredentials() {
    return {
      'Super Admin': {
        'email': 'superadmin@biotective.com',
        'password': 'demo123',
        'description': 'Full system access',
      },
      'Hospital Admin (City General)': {
        'email': 'admin@citygeneral.com',
        'password': 'demo123',
        'description': 'City General Hospital access',
      },
      'Hospital Admin (Memorial)': {
        'email': 'admin@memorialmedical.com',
        'password': 'demo123',
        'description': 'Memorial Medical Center access',
      },
      'Doctor (City General)': {
        'email': 'dr.johnson@citygeneral.com',
        'password': 'demo123',
        'description': 'Clinical access - City General',
      },
      'Doctor (Memorial)': {
        'email': 'dr.patel@memorialmedical.com',
        'password': 'demo123',
        'description': 'Clinical access - Memorial',
      },
      'Doctor (Community)': {
        'email': 'dr.wong@communityhealthclinic.com',
        'password': 'demo123',
        'description': 'Clinical access - Community Clinic',
      },
    };
  }
}
