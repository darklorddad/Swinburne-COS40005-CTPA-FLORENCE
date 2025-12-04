import 'package:flutter/material.dart';
import '../models/admin_enums.dart';
import '../services/permission_service.dart';

/// Permission Guard Widget
/// Conditionally renders child widget based on user permissions
/// Shows fallback or hides content if user lacks required permissions
class PermissionGuard extends StatelessWidget {
  /// Child widget to show if permission check passes
  final Widget child;

  /// Single required permission
  final AdminPermission? requiredPermission;

  /// Multiple required permissions (OR logic - user needs at least one)
  final List<AdminPermission>? anyPermissions;

  /// Multiple required permissions (AND logic - user needs all)
  final List<AdminPermission>? allPermissions;

  /// Required role
  final AdminRole? requiredRole;

  /// Multiple required roles (OR logic - user needs at least one)
  final List<AdminRole>? anyRoles;

  /// Widget to show when permission check fails
  /// If null, widget is hidden (SizedBox.shrink)
  final Widget? fallback;

  /// Whether to show fallback or hide completely when check fails
  /// Default: false (hide completely)
  final bool showFallback;

  /// Custom permission check function
  /// If provided, overrides other permission checks
  final bool Function()? customCheck;

  const PermissionGuard({
    super.key,
    required this.child,
    this.requiredPermission,
    this.anyPermissions,
    this.allPermissions,
    this.requiredRole,
    this.anyRoles,
    this.fallback,
    this.showFallback = false,
    this.customCheck,
  }) : assert(
          requiredPermission != null ||
              anyPermissions != null ||
              allPermissions != null ||
              requiredRole != null ||
              anyRoles != null ||
              customCheck != null,
          'At least one permission check must be provided',
        );

  bool _checkPermissions() {
    final permissionService = PermissionService();

    // Custom check takes precedence
    if (customCheck != null) {
      return customCheck!();
    }

    // Check single permission
    if (requiredPermission != null) {
      if (!permissionService.hasPermission(requiredPermission!)) {
        return false;
      }
    }

    // Check any permissions (OR logic)
    if (anyPermissions != null && anyPermissions!.isNotEmpty) {
      if (!permissionService.hasAnyPermission(anyPermissions!)) {
        return false;
      }
    }

    // Check all permissions (AND logic)
    if (allPermissions != null && allPermissions!.isNotEmpty) {
      if (!permissionService.hasAllPermissions(allPermissions!)) {
        return false;
      }
    }

    // Check single role
    if (requiredRole != null) {
      if (!permissionService.hasRole(requiredRole!)) {
        return false;
      }
    }

    // Check any roles (OR logic)
    if (anyRoles != null && anyRoles!.isNotEmpty) {
      if (!permissionService.hasAnyRole(anyRoles!)) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final hasPermission = _checkPermissions();

    if (hasPermission) {
      return child;
    }

    // Permission check failed
    if (showFallback && fallback != null) {
      return fallback!;
    }

    return const SizedBox.shrink();
  }
}

/// Permission Guard for role-based access
/// Simplified widget for role checking only
class RoleGuard extends StatelessWidget {
  final Widget child;
  final AdminRole? role;
  final List<AdminRole>? anyRoles;
  final Widget? fallback;
  final bool showFallback;

  const RoleGuard({
    super.key,
    required this.child,
    this.role,
    this.anyRoles,
    this.fallback,
    this.showFallback = false,
  }) : assert(
          role != null || anyRoles != null,
          'Either role or anyRoles must be provided',
        );

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      requiredRole: role,
      anyRoles: anyRoles,
      fallback: fallback,
      showFallback: showFallback,
      child: child,
    );
  }
}

/// Permission Guard for Global Admin only
class AdminGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const AdminGuard({
    super.key,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      role: AdminRole.admin,
      fallback: fallback,
      showFallback: showFallback,
      child: child,
    );
  }
}

/// Permission Guard for Hospital Admin only
class HospitalAdminGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const HospitalAdminGuard({
    super.key,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      role: AdminRole.hospitalAdmin,
      fallback: fallback,
      showFallback: showFallback,
      child: child,
    );
  }
}


/// Permission Guard Builder
/// Provides builder pattern for more complex conditional rendering
class PermissionGuardBuilder extends StatelessWidget {
  final AdminPermission? requiredPermission;
  final List<AdminPermission>? anyPermissions;
  final List<AdminPermission>? allPermissions;
  final AdminRole? requiredRole;
  final List<AdminRole>? anyRoles;
  final Widget Function(BuildContext context, bool hasPermission) builder;

  const PermissionGuardBuilder({
    super.key,
    this.requiredPermission,
    this.anyPermissions,
    this.allPermissions,
    this.requiredRole,
    this.anyRoles,
    required this.builder,
  });

  bool _checkPermissions() {
    final permissionService = PermissionService();

    if (requiredPermission != null) {
      if (!permissionService.hasPermission(requiredPermission!)) {
        return false;
      }
    }

    if (anyPermissions != null && anyPermissions!.isNotEmpty) {
      if (!permissionService.hasAnyPermission(anyPermissions!)) {
        return false;
      }
    }

    if (allPermissions != null && allPermissions!.isNotEmpty) {
      if (!permissionService.hasAllPermissions(allPermissions!)) {
        return false;
      }
    }

    if (requiredRole != null) {
      if (!permissionService.hasRole(requiredRole!)) {
        return false;
      }
    }

    if (anyRoles != null && anyRoles!.isNotEmpty) {
      if (!permissionService.hasAnyRole(anyRoles!)) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final hasPermission = _checkPermissions();
    return builder(context, hasPermission);
  }
}

/// Disable widget based on permissions
/// Widget is visible but disabled/grayed out if user lacks permissions
class PermissionDisabler extends StatelessWidget {
  final Widget child;
  final AdminPermission? requiredPermission;
  final List<AdminPermission>? anyPermissions;
  final List<AdminPermission>? allPermissions;
  final AdminRole? requiredRole;
  final String? disabledMessage;

  const PermissionDisabler({
    super.key,
    required this.child,
    this.requiredPermission,
    this.anyPermissions,
    this.allPermissions,
    this.requiredRole,
    this.disabledMessage,
  });

  bool _checkPermissions() {
    final permissionService = PermissionService();

    if (requiredPermission != null) {
      if (!permissionService.hasPermission(requiredPermission!)) {
        return false;
      }
    }

    if (anyPermissions != null && anyPermissions!.isNotEmpty) {
      if (!permissionService.hasAnyPermission(anyPermissions!)) {
        return false;
      }
    }

    if (allPermissions != null && allPermissions!.isNotEmpty) {
      if (!permissionService.hasAllPermissions(allPermissions!)) {
        return false;
      }
    }

    if (requiredRole != null) {
      if (!permissionService.hasRole(requiredRole!)) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final hasPermission = _checkPermissions();

    if (!hasPermission) {
      return Tooltip(
        message: disabledMessage ?? 'You do not have permission for this action',
        child: Opacity(
          opacity: 0.5,
          child: IgnorePointer(
            child: child,
          ),
        ),
      );
    }

    return child;
  }
}
