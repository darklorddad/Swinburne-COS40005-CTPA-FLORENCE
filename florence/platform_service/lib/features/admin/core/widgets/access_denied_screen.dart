import 'package:flutter/material.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/features/admin/core/models/admin_enums.dart';

class AccessDeniedScreen extends StatelessWidget {
  final String? message;
  final AdminPermission? requiredPermission;
  final AdminRole? requiredRole;

  const AccessDeniedScreen({
    super.key,
    this.message,
    this.requiredPermission,
    this.requiredRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AdminTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.block, size: 64, color: AdminTheme.error),
            ),
            const SizedBox(height: 24),
            Text('Access Denied', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              message ?? 'You do not have permission to view this page or perform this action.', 
              style: const TextStyle(color: AdminTheme.outline, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/admin-dashboard'),
              icon: const Icon(Icons.dashboard),
              label: const Text('Return to Dashboard'),
              style: FilledButton.styleFrom(backgroundColor: AdminTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
