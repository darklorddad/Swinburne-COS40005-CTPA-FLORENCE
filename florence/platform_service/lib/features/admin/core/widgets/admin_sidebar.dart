import 'package:flutter/material.dart';
import '../../../../config/admin_theme.dart';
import '../models/admin_enums.dart';
import '../services/permission_service.dart';
import 'permission_guard.dart';

/// Admin Sidebar Navigation
/// Left sidebar menu with permission-based navigation items
class AdminSidebar extends StatelessWidget {
  /// Current active route
  final String currentRoute;

  /// Callback when menu item is tapped
  final Function(String route) onNavigate;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService();
    final currentUser = permissionService.currentUser;

    return Container(
      width: 260,
      color: AdminTheme.sidebarColor,
      child: Column(
        children: [
          // Sidebar Header
          _buildSidebarHeader(context, currentUser),

          const Divider(height: 1, color: AdminTheme.sidebarHoverColor),

          // Navigation Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Dashboard
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  route: '/admin/dashboard',
                ),

                const SizedBox(height: 4),

                // Organizations (Super Admin only)
                SuperAdminGuard(
                  child: Column(
                    children: [
                      _buildSectionHeader(context, 'SYSTEM MANAGEMENT'),
                      _buildMenuItem(
                        context,
                        icon: Icons.business,
                        label: 'Organizations',
                        route: '/admin/organizations',
                      ),
                    ],
                  ),
                ),

                // User Management
                PermissionGuard(
                  anyPermissions: [
                    AdminPermission.viewAllUsers,
                    AdminPermission.viewOrgUsers,
                  ],
                  child: Column(
                    children: [
                      if (!permissionService.isSuperAdmin)
                        _buildSectionHeader(context, 'MANAGEMENT'),
                      _buildMenuItem(
                        context,
                        icon: Icons.people,
                        label: 'Users',
                        route: '/admin/users',
                      ),
                    ],
                  ),
                ),

                // Patient Management
                PermissionGuard(
                  anyPermissions: [
                    AdminPermission.viewAllPatients,
                    AdminPermission.viewOrgPatients,
                  ],
                  child: _buildMenuItem(
                    context,
                    icon: Icons.personal_injury,
                    label: 'Patients',
                    route: '/admin/patients',
                  ),
                ),

                const SizedBox(height: 4),

                // Roles & Permissions (Admin only)
                PermissionGuard(
                  anyRoles: [AdminRole.superAdmin, AdminRole.hospitalAdmin],
                  child: Column(
                    children: [
                      _buildSectionHeader(context, 'ACCESS CONTROL'),
                      PermissionGuard(
                        anyPermissions: [
                          AdminPermission.viewAllRoles,
                          AdminPermission.viewOrgRoles,
                        ],
                        child: _buildMenuItem(
                          context,
                          icon: Icons.admin_panel_settings,
                          label: 'Roles & Permissions',
                          route: '/admin/roles',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Clinical & Operations
                _buildSectionHeader(context, 'CLINICAL & OPERATIONS'),

                // Medications
                PermissionGuard(
                  requiredPermission: AdminPermission.viewMedications,
                  child: _buildMenuItem(
                    context,
                    icon: Icons.medication,
                    label: 'Medications',
                    route: '/admin/medications',
                  ),
                ),

                // Practice Groups
                PermissionGuard(
                  requiredPermission: AdminPermission.viewPracticeGroups,
                  child: _buildMenuItem(
                    context,
                    icon: Icons.groups,
                    label: 'Practice Groups',
                    route: '/admin/practice-groups',
                  ),
                ),

                // Appointments
                PermissionGuard(
                  requiredPermission: AdminPermission.viewAppointments,
                  child: _buildMenuItem(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Appointments',
                    route: '/admin/appointments',
                  ),
                ),

                // Events & Logbook (Clinical staff)
                PermissionGuard(
                  anyPermissions: [
                    AdminPermission.viewHypoHyperEvents,
                    AdminPermission.viewPatientLogbook,
                  ],
                  child: _buildMenuItem(
                    context,
                    icon: Icons.event_note,
                    label: 'Events & Logs',
                    route: '/admin/events',
                  ),
                ),

                const SizedBox(height: 4),

                // Audit Logs (Super Admin only)
                SuperAdminGuard(
                  child: Column(
                    children: [
                      _buildSectionHeader(context, 'MONITORING'),
                      _buildMenuItem(
                        context,
                        icon: Icons.history,
                        label: 'Audit Logs',
                        route: '/admin/audit-logs',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AdminTheme.sidebarHoverColor),

          // Sidebar Footer
          _buildSidebarFooter(context),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context, dynamic currentUser) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdminTheme.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: AdminTheme.primaryLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BioTective',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AdminTheme.textOnDark,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Admin Portal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AdminTheme.textOnDark.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AdminTheme.textOnDark.withOpacity(0.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    int? badge,
  }) {
    final isActive = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onNavigate(route),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? AdminTheme.primaryIndigo.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? AdminTheme.primaryIndigo.withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? AdminTheme.primaryLight
                      : AdminTheme.textOnDark.withOpacity(0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isActive
                              ? AdminTheme.textOnDark
                              : AdminTheme.textOnDark.withOpacity(0.8),
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ),
                if (badge != null && badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AdminTheme.errorColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Settings
          _buildFooterButton(
            context,
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => onNavigate('/admin/settings'),
          ),
          const SizedBox(height: 8),
          // Help
          _buildFooterButton(
            context,
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () {
              // Show help dialog or navigate
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: AdminTheme.textOnDark.withOpacity(0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminTheme.textOnDark.withOpacity(0.6),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsible Sidebar Item Widget
/// For nested menu items (future use)
class AdminSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? route;
  final List<AdminSidebarItem>? children;
  final bool isActive;
  final Function(String)? onNavigate;
  final int? badge;

  const AdminSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.route,
    this.children,
    this.isActive = false,
    this.onNavigate,
    this.badge,
  });

  @override
  State<AdminSidebarItem> createState() => _AdminSidebarItemState();
}

class _AdminSidebarItemState extends State<AdminSidebarItem> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Auto-expand if active
    if (widget.isActive) {
      _isExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.children != null && widget.children!.isNotEmpty;

    return Column(
      children: [
        // Main item
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (hasChildren) {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                } else if (widget.route != null && widget.onNavigate != null) {
                  widget.onNavigate!(widget.route!);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? AdminTheme.primaryIndigo.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isActive
                        ? AdminTheme.primaryIndigo.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      size: 20,
                      color: widget.isActive
                          ? AdminTheme.primaryLight
                          : AdminTheme.textOnDark.withOpacity(0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: widget.isActive
                                  ? AdminTheme.textOnDark
                                  : AdminTheme.textOnDark.withOpacity(0.8),
                              fontWeight:
                                  widget.isActive ? FontWeight.w600 : FontWeight.w500,
                            ),
                      ),
                    ),
                    if (widget.badge != null && widget.badge! > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AdminTheme.errorColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.badge! > 99 ? '99+' : widget.badge.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (hasChildren)
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: AdminTheme.textOnDark.withOpacity(0.5),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Children (if expanded)
        if (hasChildren && _isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: widget.children!,
            ),
          ),
      ],
    );
  }
}