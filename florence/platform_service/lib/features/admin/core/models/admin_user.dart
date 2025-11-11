import 'admin_enums.dart';

/// Admin User model
/// Represents users with administrative or clinical access
class AdminUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final AdminRole role;
  final UserStatus status;
  final String? organizationId; // null for Super Admin
  final String? organizationName;
  final String? phone;
  final String? profileImageUrl;
  final List<AdminPermission> permissions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final String? createdBy;

  AdminUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.status = UserStatus.active,
    this.organizationId,
    this.organizationName,
    this.phone,
    this.profileImageUrl,
    this.permissions = const [],
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.createdBy,
  });

  /// Create from JSON
  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      role: AdminRole.fromString(json['role'] as String),
      status: json['status'] != null
          ? UserStatus.fromString(json['status'] as String)
          : UserStatus.active,
      organizationId: json['organization_id'] as String?,
      organizationName: json['organization_name'] as String?,
      phone: json['phone'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((p) => AdminPermission.fromString(p as String))
              .whereType<AdminPermission>()
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role.name,
      'status': status.name,
      'organization_id': organizationId,
      'organization_name': organizationName,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'permissions': permissions.map((p) => p.name).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  /// Create a copy with modified fields
  AdminUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    AdminRole? role,
    UserStatus? status,
    String? organizationId,
    String? organizationName,
    String? phone,
    String? profileImageUrl,
    List<AdminPermission>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    String? createdBy,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Get initials
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  /// Check if user is active
  bool get isActive => status.isActive;

  /// Check if user is Super Admin
  bool get isSuperAdmin => role.isSuperAdmin;

  /// Check if user is Hospital Admin
  bool get isHospitalAdmin => role.isHospitalAdmin;

  /// Check if user is Doctor
  bool get isDoctor => role.isDoctor;

  /// Check if user has a specific permission
  bool hasPermission(AdminPermission permission) {
    return permissions.contains(permission);
  }

  /// Check if user has any of the specified permissions
  bool hasAnyPermission(List<AdminPermission> permissionList) {
    return permissionList.any((p) => permissions.contains(p));
  }

  /// Check if user has all of the specified permissions
  bool hasAllPermissions(List<AdminPermission> permissionList) {
    return permissionList.every((p) => permissions.contains(p));
  }

  /// Get time since last login
  String get lastLoginTimeAgo {
    if (lastLoginAt == null) return 'Never';

    final diff = DateTime.now().difference(lastLoginAt!);
    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}