import 'package:flutter/material.dart';
import 'package:clinician_dashboard/models/patient.dart';
import 'package:clinician_dashboard/models/alert.dart';
import 'package:clinician_dashboard/services/api_data_service.dart';
import 'package:clinician_dashboard/widgets/patient_list_item.dart';
import 'package:clinician_dashboard/widgets/alert_item.dart';
import 'package:clinician_dashboard/widgets/patient_filter.dart';
import 'package:clinician_dashboard/screens/patient_detail_screen.dart';
import 'package:clinician_dashboard/screens/clinician_profile_screen.dart';
import 'package:clinician_dashboard/theme/app_theme.dart';
import 'package:clinician_dashboard/services/data_service.dart';

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
                        child: _filteredPatients.isEmpty
                            ? const Center(child: Text('No patients found'))
                            : ListView.builder(
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
                        child: _alerts.isEmpty
                            ? const Center(child: Text('No alerts'))
                            : ListView.builder(
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
          child: _filteredPatients.isEmpty
              ? const Center(child: Text('No patients found'))
              : ListView.builder(
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
          child: _alerts.isEmpty
              ? const Center(child: Text('No alerts'))
              : ListView.builder(
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


  void _showAddPatientDialog() {
    _newPatientNameController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Patient'),
        content: TextField(
          controller: _newPatientNameController,
          decoration: const InputDecoration(
            labelText: 'Patient name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _newPatientNameController.text.trim();
              if (name.isEmpty) return;
              
              try {
                final newPatient = Patient(
                  id: '', // Will be assigned by backend
                  name: name,
                  age: 50,
                  gender: 'Unknown',
                  condition: ChronicCondition.type2Diabetes,
                  riskLevel: RiskLevel.low,
                  lastSync: DateTime.now(),
                  contactInfo: '',
                );
                
                await _dataService.addPatient(newPatient);
                await _loadData(); // Reload to get updated list
                
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Patient "$name" added')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding patient: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
