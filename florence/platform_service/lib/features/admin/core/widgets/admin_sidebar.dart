import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:florence/features/admin/core/services/admin_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/config/routes.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AdminTheme.surface, // Clean off-white background
        border: Border(
          right: BorderSide(color: AdminTheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogoHeader(context),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SidebarItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  isActive: currentRoute == AppRoutes.adminDashboard,
                  onTap: () {
                    if (currentRoute != AppRoutes.adminDashboard) {
                      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
                    }
                  },
                ),
                _SidebarItem(
                  icon: Icons.people_alt_outlined,
                  activeIcon: Icons.people_alt_rounded,
                  label: 'Patients',
                  isActive: currentRoute == AppRoutes.adminPatientList,
                  onTap: () {
                    if (currentRoute != AppRoutes.adminPatientList) {
                      Navigator.pushReplacementNamed(context, AppRoutes.adminPatientList);
                    }
                  },
                ),
                _SidebarItem(
                  icon: Icons.medical_services_outlined,
                  activeIcon: Icons.medical_services_rounded,
                  label: 'Clinicians',
                  isActive: currentRoute == '/admin/clinicians',
                  onTap: () {}, // Add route when built
                ),
                _SidebarItem(
                  icon: Icons.medication_outlined,
                  activeIcon: Icons.medication_rounded,
                  label: 'Medications',
                  isActive: currentRoute == '/admin/medications',
                  onTap: () {}, // Add route when built
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Divider(color: AdminTheme.outlineVariant, height: 1),
                ),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  isActive: currentRoute == '/admin/settings',
                  onTap: () {}, // Add route when built
                ),
              ],
            ),
          ),
          _buildProfileCard(context),
        ],
      ),
    );
  }

  Widget _buildLogoHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AdminTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: 
            Image.asset(
              'assets/FLORENCE-light-background-cropped.png',
              width: 72,
              height: 72,
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Florence',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.primary,
                      letterSpacing: -0.5,
                    ),
              ),
              Text(
                'Health Admin',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AdminTheme.outline,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AdminTheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://picsum.photos/id/93/200'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sarah Anderson',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AdminTheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'System Admin',
                  style: TextStyle(
                    fontSize: 12,
                    color: AdminTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20, color: AdminTheme.outline),
            tooltip: 'Logout',
            onPressed: () async {
              // 1. Clear the local Admin Authentication State
              await AdminAuthService().logout();
              
              // 2. Actually destroy the Supabase session
              await Supabase.instance.client.auth.signOut();
              
              // 3. Navigate back to login and destroy the navigation history stack
              if (context.mounted) {
                // You can change AppRoutes.adminLogin to AppRoutes.login 
                // depending on which screen you prefer them to land on
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  AppRoutes.login, 
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    
    final Color activeBgColor = const Color(0xFFEAF0EC); 
    final Color activeTextColor = const Color(0xFF2D4235);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? activeBgColor : Colors.transparent,
          ),
          child: Row(
            children: [
              // 4px vertical indicator bar
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive ? AdminTheme.primary : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                isActive ? (activeIcon ?? icon) : icon,
                color: isActive ? activeTextColor : AdminTheme.outline,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? activeTextColor : AdminTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}