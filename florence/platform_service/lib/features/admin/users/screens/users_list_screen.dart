import 'package:flutter/material.dart';
import '../../../../config/admin_theme.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../core/services/admin_auth_service.dart';
import '../../core/services/permission_service.dart';
import '../../../../config/admin_routes.dart';

/// Users List Screen
/// View and manage users (scoped by permissions)
class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _authService = AdminAuthService();
  final _permissionService = PermissionService();
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterRole = 'all'; // all, superadmin, hospitaladmin, doctor
  String _filterStatus = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call

    final currentUser = _permissionService.currentUser;
    List<dynamic> users;

    // Super Admin sees all users, Hospital Admin sees only org users
    if (_permissionService.isSuperAdmin) {
      users = _authService.getAllUsers();
    } else if (currentUser?.organizationId != null) {
      users = _authService
          .getAllUsers()
          .where((u) => u.organizationId == currentUser!.organizationId)
          .toList();
    } else {
      users = [];
    }

    setState(() {
      _users = users;
      _filteredUsers = users;
      _isLoading = false;
    });
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());

        // Role filter
        final matchesRole = _filterRole == 'all' ||
            user.role.name.toLowerCase() == _filterRole.toLowerCase();

        // Status filter
        final matchesStatus =
            _filterStatus == 'all' ||
            (_filterStatus == 'active' && user.isActive) ||
            (_filterStatus == 'inactive' && !user.isActive);

        return matchesSearch && matchesRole && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _permissionService.canCreateUser;

    return AdminScaffold(
      title: 'Users',
      currentRoute: AdminRoutes.users,
      body: AdminPageLayout(
        title: 'Users',
        subtitle: _permissionService.isSuperAdmin
            ? 'Manage all users in the system'
            : 'Manage users in your organization',
        actions: canCreate
            ? [
                ElevatedButton.icon(
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.createUser);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add User'),
                ),
              ]
            : null,
        showCard: false,
        child: Column(
          children: [
            // Search and Filter Bar
            _buildSearchAndFilter(),

            const SizedBox(height: 16),

            // Users Table
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredUsers.isEmpty)
              _buildEmptyState()
            else
              _buildUsersTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Search Field
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _filterUsers();
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Role Filter
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _filterRole,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Roles')),
                      DropdownMenuItem(
                          value: 'superadmin', child: Text('Super Admin')),
                      DropdownMenuItem(
                          value: 'hospitaladmin', child: Text('Hospital Admin')),
                      DropdownMenuItem(value: 'clinician', child: Text('Clinician')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterRole = value ?? 'all';
                      });
                      _filterUsers();
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Status Filter
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value ?? 'all';
                      });
                      _filterUsers();
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Refresh Button
                IconButton(
                  onPressed: _loadUsers,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Results count
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Showing ${_filteredUsers.length} of ${_users.length} users',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AdminTheme.textSecondaryColor,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 48,
          horizontalMargin: 24,
          headingRowColor: MaterialStateProperty.all(
            AdminTheme.backgroundColor,
          ),
          columns: const [
            DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Organization', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Last Active', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: _filteredUsers.map((user) {
            return DataRow(
              cells: [
                // User
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AdminTheme.getRoleColor(user.role.name),
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: AdminTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Role
                DataCell(AdminTheme.getRoleBadge(user.role.displayName)),
                // Organization
                DataCell(
                  Text(
                    user.organizationName ?? 'N/A',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                // Status
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: user.isActive
                          ? AdminTheme.successColor.withOpacity(0.1)
                          : AdminTheme.textLightColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: user.isActive
                            ? AdminTheme.successColor
                            : AdminTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
                // Last Active
                DataCell(
                  Text(
                    user.lastLoginAt != null
                        ? _formatLastActive(user.lastLoginAt!)
                        : 'Never',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                // Actions
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 18),
                        onPressed: () => _showUserDetail(user),
                        tooltip: 'View',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      if (_permissionService.canEditUser)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit feature coming soon')),
                            );
                          },
                          tooltip: 'Edit',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const SizedBox(width: 8),
                      if (_permissionService.canDeleteUser)
                        IconButton(
                          icon: Icon(Icons.delete, size: 18, color: AdminTheme.errorColor),
                          onPressed: () => _confirmDelete(user),
                          tooltip: 'Delete',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: AdminTheme.textLightColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No users found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty || _filterRole != 'all' || _filterStatus != 'all'
                    ? 'Try adjusting your search or filters'
                    : 'Get started by adding your first user',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AdminTheme.textSecondaryColor,
                    ),
              ),
              if (_permissionService.canCreateUser) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.createUser);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add User'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastActive(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showUserDetail(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AdminTheme.getRoleColor(user.role.name),
              child: Text(
                user.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.fullName,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Email', user.email),
              const SizedBox(height: 12),
              _buildInfoRow('Role', user.role.displayName),
              const SizedBox(height: 12),
              _buildInfoRow('Organization', user.organizationName ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Status', user.isActive ? 'Active' : 'Inactive'),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Last Login',
                user.lastLoginAt != null
                    ? _formatLastActive(user.lastLoginAt!)
                    : 'Never',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Created',
                '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Permissions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${user.permissions.length} permissions assigned',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AdminTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (_permissionService.canEditUser)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit feature coming soon')),
                );
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AdminTheme.textSecondaryColor,
                ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete feature coming soon'),
                  backgroundColor: AdminTheme.errorColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
