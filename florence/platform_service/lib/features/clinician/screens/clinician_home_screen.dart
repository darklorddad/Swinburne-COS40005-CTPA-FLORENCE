import 'package:flutter/material.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/models/alert.dart';
import 'package:florence/features/clinician/services/api_data_service.dart';
import 'package:florence/features/clinician/widgets/patient_list_item.dart';
import 'package:florence/features/clinician/widgets/alert_item.dart';
import 'package:florence/features/clinician/widgets/patient_filter.dart';
import 'package:florence/features/clinician/screens/patient_detail_screen.dart';
import 'package:florence/features/clinician/screens/clinician_profile_screen.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:florence/features/clinician/services/data_service.dart';

class ClinicianHomeScreen extends StatefulWidget {
  const ClinicianHomeScreen({super.key});

  @override
  State<ClinicianHomeScreen> createState() => _ClinicianHomeScreenState();
}

class _ClinicianHomeScreenState extends State<ClinicianHomeScreen> {
  final DataService _dataService = ApiDataService();
  List<Patient> _patients = [];
  List<Alert> _alerts = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  RiskLevel? _selectedRiskLevel;
  int _selectedUpdateFilter = 0;
  bool _showFilters = false;
  final TextEditingController _newPatientNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final patients = await _dataService.getPatients();
      final alerts = await _dataService.getAlerts();
      
      if (mounted) {
        setState(() {
          _patients = patients;
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _newPatientNameController.dispose();
    super.dispose();
  }

  List<Patient> get _filteredPatients {
    return _patients.where((patient) {
      // Apply search filter
      final nameMatches = patient.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final idMatches = patient.id.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Apply risk level filter
      final riskMatches = _selectedRiskLevel == null || patient.riskLevel == _selectedRiskLevel;
      
      // Apply last update filter
      final now = DateTime.now();
      bool updateMatches = true;
      if (_selectedUpdateFilter == 1) {
        // Today only
        updateMatches = now.difference(patient.lastSync).inHours < 24;
      } else if (_selectedUpdateFilter == 2) {
        // Last 3 days
        updateMatches = now.difference(patient.lastSync).inHours < 72;
      } else if (_selectedUpdateFilter == 3) {
        // Last week
        updateMatches = now.difference(patient.lastSync).inDays < 7;
      } else if (_selectedUpdateFilter == 4) {
        // Last 3 weeks
        updateMatches = now.difference(patient.lastSync).inDays < 21;
      }
      
      return (nameMatches || idMatches) && riskMatches && updateMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    if (isMobile) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Clinician Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  _showNotificationsSheet();
                },
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClinicianProfileScreen(),
                    ),
                  );
                },
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Patients'),
                Tab(text: 'Priority Alerts'),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $_error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search patient by name or ID',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                                  color: _showFilters ? AppTheme.primaryColor : null,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showFilters = !_showFilters;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),

                        if (_showFilters)
                          PatientFilters(
                            onRiskFilterChanged: (riskLevel) {
                              setState(() {
                                _selectedRiskLevel = riskLevel;
                              });
                            },
                            onLastUpdateFilterChanged: (filter) {
                              setState(() {
                                _selectedUpdateFilter = filter;
                              });
                            },
                            selectedRiskLevel: _selectedRiskLevel,
                            selectedUpdateFilter: _selectedUpdateFilter,
                          ),

                        // Tabs content
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildPatientsTabContent(),
                              _buildAlertsTabContent(),
                            ],
                          ),
                        ),
                      ],
                    ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              _showAddPatientDialog();
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinician Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showNotificationsSheet();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClinicianProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search patient by name or ID',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showFilters ? Icons.filter_list_off : Icons.filter_list,
                              color: _showFilters ? AppTheme.primaryColor : null,
                            ),
                            onPressed: () {
                              setState(() {
                                _showFilters = !_showFilters;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    
                    // Filters
                    if (_showFilters)
                      PatientFilters(
                        onRiskFilterChanged: (riskLevel) {
                          setState(() {
                            _selectedRiskLevel = riskLevel;
                          });
                        },
                        onLastUpdateFilterChanged: (filter) {
                          setState(() {
                            _selectedUpdateFilter = filter;
                          });
                        },
                        selectedRiskLevel: _selectedRiskLevel,
                        selectedUpdateFilter: _selectedUpdateFilter,
                      ),

                    // Main content
                    Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient List
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Patients (${_filteredPatients.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadData,
                          child: _filteredPatients.isEmpty
                              ? LayoutBuilder(
                                  builder: (context, constraints) => ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                        child: const Center(child: Text('No patients found')),
                                      )
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 16),
                                  itemCount: _filteredPatients.length,
                                  itemBuilder: (context, index) {
                                    return PatientListItem(
                                      patient: _filteredPatients[index],
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PatientDetailScreen(
                                              patientId: _filteredPatients[index].id,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Vertical divider
                const VerticalDivider(width: 1),
                
                // Alert Panel
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Priority Alerts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Refresh'),
                              onPressed: () async {
                                await _loadData();
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadData,
                          child: _alerts.isEmpty
                              ? LayoutBuilder(
                                  builder: (context, constraints) => ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                        child: const Center(child: Text('No alerts')),
                                      )
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  itemCount: _alerts.length,
                                  itemBuilder: (context, index) {
                                    return AlertItem(
                                      alert: _alerts[index],
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PatientDetailScreen(
                                              patientId: _alerts[index].patientId,
                                              initialTab: 1, // Show data visualization tab
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddPatientDialog();
        },
      ),
    );
  }

  // Mobile tab builders
  Widget _buildPatientsTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Patients (${_filteredPatients.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _filteredPatients.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Container(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: const Center(child: Text('No patients found')),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filteredPatients.length,
                    itemBuilder: (context, index) {
                      return PatientListItem(
                        patient: _filteredPatients[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientDetailScreen(
                                patientId: _filteredPatients[index].id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Priority Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                onPressed: () async {
                  await _loadData();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _alerts.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Container(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: const Center(child: Text('No alerts')),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      return AlertItem(
                        alert: _alerts[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientDetailScreen(
                                patientId: _alerts[index].patientId,
                                initialTab: 1,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _alerts.isEmpty
                      ? const Center(child: Text('No notifications'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _alerts.length,
                          itemBuilder: (context, index) {
                            final alert = _alerts[index];
                            return AlertItem(
                              alert: alert,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PatientDetailScreen(
                                      patientId: alert.patientId,
                                      initialTab: 1,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _showAddPatientDialog() async {
    try {
      // Show loading indicator while fetching
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final availablePatients = await _dataService.getAvailablePatients();
      
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add Patient'),
          content: SizedBox(
            width: double.maxFinite,
            child: availablePatients.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No available patients found to add.'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availablePatients.length,
                  itemBuilder: (context, index) {
                    final patient = availablePatients[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        child: Text(
                          patient.name.isNotEmpty ? patient.name[0] : '?',
                          style: const TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                      title: Text(patient.name),
                      subtitle: Text('ID: ${patient.id}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                        onPressed: () async {
                          try {
                            await _dataService.assignPatient(patient.id);
                            if (mounted) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Patient ${patient.name} added to your list')),
                                );
                                _loadData();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error adding patient: $e')),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading if error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading available patients: $e')),
        );
      }
    }
  }
}
