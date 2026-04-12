import 'package:flutter/material.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/features/admin/core/widgets/admin_scaffold.dart';
import 'package:florence/features/admin/core/services/admin_auth_service.dart';
import 'package:florence/config/admin_routes.dart';

/// Organizations List Screen
/// View and manage all organizations in the system (Global Admin only)
class OrganizationsListScreen extends StatefulWidget {
  const OrganizationsListScreen({super.key});

  @override
  State<OrganizationsListScreen> createState() =>
      _OrganizationsListScreenState();
}

class _OrganizationsListScreenState extends State<OrganizationsListScreen> {
  final _authService = AdminAuthService();
  List<dynamic> _organizations = [];
  List<dynamic> _filteredOrganizations = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive, suspended

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call

    final orgs = _authService.getAllOrganizations();

    setState(() {
      _organizations = orgs;
      _filteredOrganizations = orgs;
      _isLoading = false;
    });
  }

  void _filterOrganizations() {
    setState(() {
      _filteredOrganizations = _organizations.where((org) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            org.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            org.city.toLowerCase().contains(_searchQuery.toLowerCase());

        // Status filter
        final matchesStatus = _filterStatus == 'all' ||
            org.status.name.toLowerCase() == _filterStatus.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Organizations',
      currentRoute: AdminRoutes.organizations,
      body: AdminPageLayout(
        title: 'Organizations',
        subtitle: 'Manage healthcare organizations in the system',
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              AdminRoutes.push(context, AdminRoutes.createOrganization);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Organization'),
          ),
        ],
        showCard: false,
        child: Column(
          children: [
            // Search and Filter Bar
            _buildSearchAndFilter(),

            const SizedBox(height: 16),

            // Organizations Grid/List
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredOrganizations.isEmpty)
              _buildEmptyState()
            else
              _buildOrganizationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Search Field
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search organizations...',
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
                  _filterOrganizations();
                },
              ),
            ),

            const SizedBox(width: 16),

            // Status Filter
            SizedBox(
              width: 180,
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
                  DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value ?? 'all';
                  });
                  _filterOrganizations();
                },
              ),
            ),

            const SizedBox(width: 16),

            // Refresh Button
            IconButton(
              onPressed: _loadOrganizations,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationsList() {
    return ResponsiveGrid(
      minChildWidth: 350,
      spacing: 16,
      runSpacing: 16,
      children: _filteredOrganizations.map((org) {
        return _buildOrganizationCard(org);
      }).toList(),
    );
  }

  Widget _buildOrganizationCard(dynamic org) {
    return Card(
      child: InkWell(
        onTap: () {
          // Navigate to organization detail
          // AdminRoutes.push(context, AdminRoutes.organizationDetail, arguments: org.id);
          _showOrganizationDetail(org);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AdminTheme.primaryIndigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: AdminTheme.primaryIndigo,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          org.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        AdminTheme.getStatusBadge(org.status.displayName),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Details
              _buildDetailRow(
                Icons.location_on,
                '${org.city}, ${org.state}',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.email,
                org.email ?? 'No email',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.phone,
                org.phone ?? 'No phone',
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '${org.patientCount}',
                      'Patients',
                      Icons.personal_injury,
                      AdminTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      '${org.staffCount}',
                      'Staff',
                      Icons.people,
                      AdminTheme.accentTeal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showOrganizationDetail(org);
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to edit
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit feature coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AdminTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AdminTheme.textSecondaryColor,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.withOpacity(0.8),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ],
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
                Icons.business_outlined,
                size: 64,
                color: AdminTheme.textLightColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No organizations found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty || _filterStatus != 'all'
                    ? 'Try adjusting your search or filter'
                    : 'Get started by creating your first organization',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AdminTheme.textSecondaryColor,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  AdminRoutes.push(context, AdminRoutes.createOrganization);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Organization'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrganizationDetail(dynamic org) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.business, color: AdminTheme.primaryIndigo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                org.name,
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
              _buildInfoRow('Status', org.status.displayName),
              const SizedBox(height: 12),
              _buildInfoRow('City', org.city ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('State', org.state ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Country', org.country ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Email', org.email ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Phone', org.phone ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Website', org.website ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Patients', '${org.patientCount}'),
              const SizedBox(height: 12),
              _buildInfoRow('Staff', '${org.staffCount}'),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Created',
                '${org.createdAt.day}/${org.createdAt.month}/${org.createdAt.year}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
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
}
