// import 'package:flutter/material.dart';
// import 'package:florence/config/admin_theme.dart';
// import 'package:florence/features/admin/core/models/admin_enums.dart';
// import 'package:florence/features/admin/core/services/permission_service.dart';

// /// Access Denied Screen
// /// Shown when user attempts to access a page/feature without proper permissions
// /// HTTP 403 Forbidden equivalent
// class AccessDeniedScreen extends StatelessWidget {
//   /// Optional message to display
//   final String? message;

//   /// Required permission that was missing
//   final AdminPermission? requiredPermission;

//   /// Required role that was missing
//   final AdminRole? requiredRole;

//   /// Whether to show "Go Back" button
//   final bool showBackButton;

//   /// Custom action button
//   final Widget? customAction;

//   const AccessDeniedScreen({
//     super.key,
//     this.message,
//     this.requiredPermission,
//     this.requiredRole,
//     this.showBackButton = true,
//     this.customAction,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final permissionService = PermissionService();
//     final currentUser = permissionService.currentUser;

//     return Scaffold(
//       backgroundColor: AdminTheme.backgroundColor,
//       appBar: AppBar(
//         title: const Text('Access Denied'),
//         automaticallyImplyLeading: showBackButton,
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 500),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Error Icon
//                 Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: AdminTheme.errorColor.withValues(alpha: 0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.block,
//                     size: 64,
//                     color: AdminTheme.errorColor,
//                   ),
//                 ),

//                 const SizedBox(height: 32),

//                 // Error Code
//                 Text(
//                   '403',
//                   style: Theme.of(context).textTheme.displayLarge?.copyWith(
//                         color: AdminTheme.errorColor,
//                         fontWeight: FontWeight.w700,
//                       ),
//                 ),

//                 const SizedBox(height: 8),

//                 // Title
//                 Text(
//                   'Access Denied',
//                   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                         fontWeight: FontWeight.w600,
//                       ),
//                 ),

//                 const SizedBox(height: 16),

//                 // Message
//                 Text(
//                   message ?? _getDefaultMessage(),
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                         color: AdminTheme.textSecondaryColor,
//                       ),
//                 ),

//                 const SizedBox(height: 24),

//                 // Details Card
//                 if (requiredPermission != null || requiredRole != null || currentUser != null)
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: AdminTheme.surfaceColor,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: AdminTheme.borderColor,
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Current User Info
//                         if (currentUser != null) ...[
//                           _DetailRow(
//                             icon: Icons.person,
//                             label: 'Logged in as',
//                             value: currentUser.fullName,
//                           ),
//                           const SizedBox(height: 12),
//                           _DetailRow(
//                             icon: Icons.badge,
//                             label: 'Your role',
//                             value: currentUser.role.displayName,
//                             valueColor: AdminTheme.getRoleColor(currentUser.role.name),
//                           ),
//                           if (currentUser.organizationName != null) ...[
//                             const SizedBox(height: 12),
//                             _DetailRow(
//                               icon: Icons.business,
//                               label: 'Organization',
//                               value: currentUser.organizationName!,
//                             ),
//                           ],
//                           const Divider(height: 24),
//                         ],

//                         // Required Permission
//                         if (requiredPermission != null) ...[
//                           _DetailRow(
//                             icon: Icons.lock,
//                             label: 'Required permission',
//                             value: requiredPermission!.displayName,
//                             valueColor: AdminTheme.errorColor,
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             requiredPermission!.description,
//                             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                                   color: AdminTheme.textLightColor,
//                                   fontStyle: FontStyle.italic,
//                                 ),
//                           ),
//                         ],

//                         // Required Role
//                         if (requiredRole != null) ...[
//                           _DetailRow(
//                             icon: Icons.shield,
//                             label: 'Required role',
//                             value: requiredRole!.displayName,
//                             valueColor: AdminTheme.errorColor,
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             requiredRole!.description,
//                             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                                   color: AdminTheme.textLightColor,
//                                   fontStyle: FontStyle.italic,
//                                 ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),

//                 const SizedBox(height: 32),

//                 // Action Buttons
//                 Wrap(
//                   spacing: 12,
//                   runSpacing: 12,
//                   alignment: WrapAlignment.center,
//                   children: [
//                     // Back Button
//                     if (showBackButton)
//                       OutlinedButton.icon(
//                         onPressed: () => Navigator.of(context).pop(),
//                         icon: const Icon(Icons.arrow_back),
//                         label: const Text('Go Back'),
//                       ),

//                     // Custom Action
//                     if (customAction != null) customAction!,

//                     // Dashboard Button
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         // Navigate to appropriate dashboard based on role
//                         Navigator.of(context).pushNamedAndRemoveUntil(
//                           _getDashboardRoute(currentUser?.role),
//                           (route) => false,
//                         );
//                       },
//                       icon: const Icon(Icons.dashboard),
//                       label: const Text('Go to Dashboard'),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 24),

//                 // Help Text
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: AdminTheme.infoColor.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: AdminTheme.infoColor.withValues(alpha: 0.3),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.info_outline,
//                         color: AdminTheme.infoColor,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           'If you believe you should have access to this feature, please contact your system administrator.',
//                           style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                                 color: AdminTheme.infoColor,
//                               ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   String _getDefaultMessage() {
//     return 'You do not have permission to access this page or perform this action. '
//         'Please contact your administrator if you believe this is an error.';
//   }

//   String _getDashboardRoute(AdminRole? role) {
//     if (role == null) return '/admin/login';

//     switch (role) {
//       case AdminRole.admin:
//         return '/admin/home';
//       case AdminRole.hospitalAdmin:
//         return '/admin/hospital-dashboard';
//     }
    
//     return '/admin/login';
//   }
// }

// /// Detail row widget for displaying key-value pairs
// class _DetailRow extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final Color? valueColor;

//   const _DetailRow({
//     required this.icon,
//     required this.label,
//     required this.value,
//     this.valueColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(
//           icon,
//           size: 20,
//           color: AdminTheme.textSecondaryColor,
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: AdminTheme.textSecondaryColor,
//                     ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 value,
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                       color: valueColor,
//                     ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// /// Access Denied Dialog
// /// Can be shown as a dialog instead of full screen
// class AccessDeniedDialog extends StatelessWidget {
//   final String? message;
//   final AdminPermission? requiredPermission;
//   final AdminRole? requiredRole;

//   const AccessDeniedDialog({
//     super.key,
//     this.message,
//     this.requiredPermission,
//     this.requiredRole,
//   });

//   /// Show the access denied dialog
//   static Future<void> show(
//     BuildContext context, {
//     String? message,
//     AdminPermission? requiredPermission,
//     AdminRole? requiredRole,
//   }) {
//     return showDialog(
//       context: context,
//       builder: (context) => AccessDeniedDialog(
//         message: message,
//         requiredPermission: requiredPermission,
//         requiredRole: requiredRole,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       icon: Container(
//         width: 60,
//         height: 60,
//         decoration: BoxDecoration(
//           color: AdminTheme.errorColor.withValues(alpha: 0.1),
//           shape: BoxShape.circle,
//         ),
//         child: const Icon(
//           Icons.block,
//           color: AdminTheme.errorColor,
//           size: 30,
//         ),
//       ),
//       title: const Text('Access Denied'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             message ?? 'You do not have permission to perform this action.',
//             style: Theme.of(context).textTheme.bodyMedium,
//           ),
//           if (requiredPermission != null) ...[
//             const SizedBox(height: 16),
//             Text(
//               'Required permission:',
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: AdminTheme.textSecondaryColor,
//                   ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               requiredPermission!.displayName,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     fontWeight: FontWeight.w600,
//                     color: AdminTheme.errorColor,
//                   ),
//             ),
//           ],
//           if (requiredRole != null) ...[
//             const SizedBox(height: 16),
//             Text(
//               'Required role:',
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: AdminTheme.textSecondaryColor,
//                   ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               requiredRole!.displayName,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     fontWeight: FontWeight.w600,
//                     color: AdminTheme.errorColor,
//                   ),
//             ),
//           ],
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('OK'),
//         ),
//       ],
//     );
//   }
// }
