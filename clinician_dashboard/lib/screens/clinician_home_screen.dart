import 'package:flutter/material.dart';
import 'package:clinician_dashboard/models/patient.dart';
import 'package:clinician_dashboard/models/alert.dart';
import 'package:clinician_dashboard/services/mock_data_service.dart';
import 'package:clinician_dashboard/widgets/patient_list_item.dart';
import 'package:clinician_dashboard/widgets/alert_item.dart';
import 'package:clinician_dashboard/widgets/patient_filter.dart';
import 'package:clinician_dashboard/screens/patient_detail_screen.dart';

class ClinicianHomeScreen extends StatefulWidget {
  const ClinicianHomeScreen({super.key});

  @override
  State<ClinicianHomeScreen> createState() => _ClinicianHomeScreenState();
}

class _ClinicianHomeScreenState extends State<ClinicianHomeScreen> {
  final MockDataService _dataService = MockDataService();
  late List<Patient> _patients;
  late List<Alert> _alerts;
  String _searchQuery = '';
  RiskLevel? _selectedRiskLevel;
  int _selectedUpdateFilter = 0;
  bool _showFilters = false;
  final TextEditingController _newPatientNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _patients = _dataService.getPatients();
    _alerts = _dataService.getAlerts();
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
                  _showClinicianProfileDialog();
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
          body: Column(
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
                        color: _showFilters ? Colors.blue : null,
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
              _showClinicianProfileDialog();
            },
          ),
        ],
      ),
      body: Column(
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
                    color: _showFilters ? Colors.blue : null,
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
                              onPressed: () {
                                setState(() {
                                  _alerts = _dataService.getAlerts();
                                });
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
                onPressed: () {
                  setState(() {
                    _alerts = _dataService.getAlerts();
                  });
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

  void _showClinicianProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clinician Profile'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: Dr. Example Clinician'),
            SizedBox(height: 8),
            Text('Role: Endocrinologist'),
            SizedBox(height: 8),
            Text('Patients Assigned: 5'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  void _showAddPatientDialog() {
    _newPatientNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _newPatientNameController.text.trim();
              if (name.isEmpty) return;
              setState(() {
                final newId = 'P${(_patients.length + 1).toString().padLeft(3, '0')}';
                _patients.add(
                  Patient(
                    id: newId,
                    name: name,
                    age: 50,
                    gender: 'Unknown',
                    condition: ChronicCondition.type2Diabetes,
                    riskLevel: RiskLevel.low,
                    lastSync: DateTime.now(),
                    contactInfo: '',
                  ),
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Patient "$name" added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
