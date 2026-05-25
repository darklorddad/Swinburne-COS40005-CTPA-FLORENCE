import 'package:flutter/material.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/models/clinician_note.dart';
import 'package:florence/features/clinician/services/api_data_service.dart';
import 'package:florence/features/clinician/services/data_service.dart';
import 'package:florence/features/clinician/services/api_service.dart';
import 'package:florence/features/clinician/widgets/risk_indicator.dart';
import 'package:florence/features/clinician/widgets/bmi_gauge.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:florence/features/clinician/screens/glucose_analytics_screen.dart';
import 'package:florence/features/clinician/screens/hba1c_analytics_screen.dart';
import 'package:florence/features/clinician/screens/blood_pressure_analytics_screen.dart';
import 'package:florence/features/clinician/screens/cholesterol_analytics_screen.dart';
import 'package:florence/features/clinician/screens/activity_analytics_screen.dart';
import 'package:florence/features/clinician/screens/bmi_analytics_screen.dart';
import 'package:intl/intl.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final int initialTab;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    this.initialTab = 0,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> with SingleTickerProviderStateMixin {
  final DataService _dataService = ApiDataService();
  late TabController _tabController;
  Patient? _patient;
  PatientHealthData? _healthData;
  List<ClinicianNote>? _notes;
  List<Map<String, dynamic>>? _patientThresholds;
  bool _isLoading = true;
  String? _error;
  String _diseaseFilter = 'ACTIVE';
  // Metric/Imperial toggle for BMI
  bool _isMetric = true;
  
  /*
  // Chatbot state
  final TextEditingController _chatController = TextEditingController();
  final List<_ChatMessage> _chatMessages = [];
  */
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final patient = await _dataService.getPatient(widget.patientId);
      final healthData = await _dataService.getPatientHealthData(widget.patientId);
      final notes = await _dataService.getClinicianNotes(widget.patientId);
      final thresholds = await _dataService.getPatientThresholds(widget.patientId);
      
      if (mounted) {
        setState(() {
          _patient = patient;
          _healthData = healthData;
          _notes = notes;
          _patientThresholds = thresholds;
          _isLoading = false;
        });

        /*
        // Seed chatbot with a greeting
        _chatMessages.add(
          _ChatMessage(
            text: 'Hi, I am your AI assistant. How can I help with ${patient.name}\'s care today?',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        */
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
    _tabController.dispose();
    // _chatController.dispose();
    super.dispose();
  }


  Future<void> _showThresholdsDialog() async {
    setState(() => _isLoading = true);
    try {
      final thresholds = await _dataService.getPatientThresholds(widget.patientId);
      setState(() => _isLoading = false);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Health Thresholds'),
          content: SizedBox(
            width: double.maxFinite,
            child: thresholds.isEmpty
                ? const Text('No thresholds defined.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: thresholds.length,
                    itemBuilder: (context, index) {
                      final t = thresholds[index];
                      return ListTile(
                        title: Text(t['data_type']?.toString().replaceAll('_', ' ') ?? 'Unknown'),
                        subtitle: Text('Min: ${t['min_value']} - Max: ${t['max_value']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showEditSingleThresholdDialog(t),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading thresholds: $e')));
    }
  }

  Future<void> _showEditSingleThresholdDialog(Map<String, dynamic> threshold) async {
    final minController = TextEditingController(text: threshold['min_value'].toString());
    final maxController = TextEditingController(text: threshold['max_value'].toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${threshold['data_type']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              decoration: const InputDecoration(labelText: 'Minimum Value'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: maxController,
              decoration: const InputDecoration(labelText: 'Maximum Value'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final List<Map<String, dynamic>> updatedThresholds = [
          {
            'data_type': threshold['data_type'],
            'min_value': double.parse(minController.text),
            'max_value': double.parse(maxController.text),
          }
        ];
        await _dataService.setPatientThresholds(widget.patientId, updatedThresholds);
        Navigator.pop(context); // Close the list dialog
        _showThresholdsDialog(); // Re-open to show updated values
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating threshold: $e')));
      }
    }
  }

  Future<void> _showAddNoteDialog() async {
    final TextEditingController noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Clinical Note'),
        content: TextField(
          controller: noteController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter your note here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save Note'),
          ),
        ],
      ),
    );

    if (confirmed == true && noteController.text.trim().isNotEmpty && mounted) {
      setState(() => _isLoading = true);
      try {
        await _dataService.addPatientNote(widget.patientId, noteController.text.trim());
        await _loadPatientData();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Details'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _patient == null || _healthData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Details'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error: ${_error ?? "Patient not found"}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadPatientData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_patient!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(62), // 60 for tabs + 2 for border
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Medical Profile'),
                      Tab(text: 'Historical Data'),
                    ],
                  ),
                ),
                Container(
                  color: AppTheme.dividerColor,
                  height: 1.0,
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildMedicalProfileTab(),
            _buildHistoricalDataTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showEditPatientProfileDialog,
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- SECTION 1: PERSONAL INFORMATION ---
        _buildSectionHeader('Demographics & Baseline', Icons.badge_outlined),
        const SizedBox(height: 8),
        _buildPatientHeaderCard(),
        
        const SizedBox(height: 24),

        // --- SECTION 2: MEDICAL CONDITION ---
        _buildSectionHeader('Medical Condition', Icons.medical_services_outlined),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'ACTIVE', label: Text('Active')),
                          ButtonSegment(value: 'RESOLVED', label: Text('Resolved')),
                          ButtonSegment(value: 'ALL', label: Text('All')),
                        ],
                        selected: {_diseaseFilter},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _diseaseFilter = newSelection.first;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Condition editing coming soon')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _patient!.activeDiseasesText,
                  style: const TextStyle(fontSize: 15, height: 1.4, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // --- SECTION 3: HEALTH THRESHOLDS ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Target Health Thresholds', Icons.tune_rounded),
            IconButton(
              icon: const Icon(Icons.edit_note, color: AppTheme.primaryColor),
              onPressed: _showThresholdsDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildEmbeddedThresholdsCard(),

        const SizedBox(height: 24),
        
        // Grid Section Header
        _buildSectionHeader('Current Status', Icons.analytics_outlined),
        const SizedBox(height: 16),
        
        // Health Metrics Stack
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHealthMetricCard(
              'Glucose', 
              _healthData!.glucoseReadings.isNotEmpty ? '${_healthData!.glucoseReadings.last.value.toInt()}' : '--', 
              'mg/dL',
              Icons.water_drop_outlined, 
              _healthData!.glucoseReadings.isNotEmpty ? _getGlucoseRiskLevel(_healthData!.glucoseReadings.last.value) : 'no_data',
              _healthData!.glucoseReadings.isNotEmpty ? _healthData!.glucoseReadings.last.timestamp : null,
            ),
            const SizedBox(height: 12),
            _buildHealthMetricCard(
              'Blood Pressure', 
              _healthData!.bloodPressureReadings.isNotEmpty ? '${_healthData!.bloodPressureReadings.last.systolic.toInt()}/${_healthData!.bloodPressureReadings.last.diastolic.toInt()}' : '--', 
              'mmHg',
              Icons.monitor_heart_outlined, 
              _healthData!.bloodPressureReadings.isNotEmpty ? _getBPRiskLevel(_healthData!.bloodPressureReadings.last.systolic, _healthData!.bloodPressureReadings.last.diastolic) : 'no_data',
              _healthData!.bloodPressureReadings.isNotEmpty ? _healthData!.bloodPressureReadings.last.timestamp : null,
            ),
            const SizedBox(height: 12),
            _buildHealthMetricCard(
              'HbA1c', 
              _healthData!.hbA1cReadings.isNotEmpty ? '${_healthData!.hbA1cReadings.last.value}' : '--', 
              '%',
              Icons.pie_chart_outline, 
              _healthData!.hbA1cReadings.isNotEmpty ? _getHbA1cRiskLevel(_healthData!.hbA1cReadings.last.value) : 'no_data',
              _healthData!.hbA1cReadings.isNotEmpty ? _healthData!.hbA1cReadings.last.timestamp : null,
            ),
            const SizedBox(height: 12),
            _buildHealthMetricCard(
              'Cholesterol', 
              _healthData!.cholesterolReadings.isNotEmpty ? '${_healthData!.cholesterolReadings.last.total}' : '--', 
              'mg/dL', // or unit depending on data
              Icons.bloodtype_outlined, 
              _healthData!.cholesterolReadings.isNotEmpty ? _getCholesterolRiskLevel(_healthData!.cholesterolReadings.last.total, _healthData!.cholesterolReadings.last.ldl, _healthData!.cholesterolReadings.last.triglycerides) : 'no_data',
              _healthData!.cholesterolReadings.isNotEmpty ? _healthData!.cholesterolReadings.last.timestamp : null,
            ),
            const SizedBox(height: 12),
            _buildHealthMetricCard(
              'Activity', 
              _healthData!.activityData.isNotEmpty ? '${_healthData!.activityData.last.activeMinutes}' : '--', 
              'min',
              Icons.directions_run_outlined, 
              _healthData!.activityData.isNotEmpty ? _getActivityRiskLevel(_healthData!.activityData.last.steps, _healthData!.activityData.last.activeMinutes) : 'no_data',
              _healthData!.activityData.isNotEmpty ? _healthData!.activityData.last.date : null,
            ),
            const SizedBox(height: 12),
            _buildHealthMetricCard(
              'BMI', 
              _healthData!.weight > 0 ? _calculateBMI(_healthData!.weight, _healthData!.height).toStringAsFixed(1) : '--', 
              'kg/m²',
              Icons.monitor_weight_outlined, 
              _healthData!.weight > 0 ? _getBMIRiskLevel(_calculateBMI(_healthData!.weight, _healthData!.height)) : 'no_data',
              _patient!.lastUpdate,
            ),
            const SizedBox(height: 12),
            _buildHealthMetricCard(
              'Diet', 
              _healthData!.mealEntries.isNotEmpty ? '${_healthData!.mealEntries.last.nutritionSummary['calories']?.toInt() ?? '--'}' : '--', 
              'kcal',
              Icons.restaurant_outlined, 
              _healthData!.mealEntries.isNotEmpty ? 'low' : 'no_data',
              _healthData!.mealEntries.isNotEmpty ? _healthData!.mealEntries.last.timestamp : null,
            ),
            const SizedBox(height: 12),
            _buildHealthMetricCard(
              'Medication', 
              _healthData!.medications.isNotEmpty ? '${_healthData!.medications.length}' : '--', 
              'active',
              Icons.medication_outlined, 
              _healthData!.medications.isNotEmpty ? 'low' : 'no_data',
              _healthData!.medications.isNotEmpty ? (_healthData!.medications.last.startDate ?? _patient!.lastUpdate) : null,
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Detected Patterns Card
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.dividerColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.monitor_heart_outlined, color: AppTheme.textSecondary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Detected Patterns',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_healthData!.detectedPatterns.isEmpty)
                  const Text('No significant patterns detected at this time.', style: TextStyle(color: AppTheme.textSecondary)),
                Column(
                  children: _healthData!.detectedPatterns.map((pattern) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pattern,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // --- SECTION 4: CLINICAL NOTES ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Clinical Notes', Icons.description_outlined),
            IconButton(
              icon: const Icon(Icons.add_comment, color: AppTheme.primaryColor),
              onPressed: _showAddNoteDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildClinicalNotesCard(),
      ],
    );
  }
  
  Widget _buildHealthMetricCard(String label, String value, String unit, IconData icon, String riskLevel, DateTime? lastUpdated) {
    Color bgColor;
    String statusText;
    
    switch (riskLevel) {
      case 'high':
        bgColor = AppTheme.highRiskColor;
        statusText = 'High';
        break;
      case 'no_data':
        bgColor = Colors.blueGrey.shade600;
        statusText = 'No Data';
        break;
      case 'medium':
      case 'low':
      default:
        bgColor = AppTheme.secondaryColor;
        statusText = 'Normal';
        break;
    }

    String timeText = 'No history';
    if (lastUpdated != null) {
      final diff = DateTime.now().difference(lastUpdated);
      if (diff.inDays > 30) {
        timeText = 'Last updated: ${diff.inDays ~/ 30} months ago';
      } else if (diff.inDays > 0) {
        timeText = 'Last updated: ${diff.inDays} days ago';
      } else if (diff.inHours > 0) {
        timeText = 'Last updated: ${diff.inHours} hours ago';
      } else if (diff.inMinutes > 0) {
        timeText = 'Last updated: ${diff.inMinutes} minutes ago';
      } else {
        timeText = 'Last updated: Just now';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods for Risk Levels
  String _getGlucoseRiskLevel(double value) {
    if (value < 70 || value > 180) return 'high';
    if (value > 140) return 'medium';
    return 'low';
  }
  
  String _getBPRiskLevel(double systolic, double diastolic) {
    if (systolic >= 140 || diastolic >= 90) return 'high';
    if (systolic >= 130 || diastolic >= 80) return 'medium';
    return 'low';
  }
  
  String _getHbA1cRiskLevel(double value) {
    if (value >= 8.0) return 'high';
    if (value >= 7.0) return 'medium';
    return 'low';
  }
  
  String _getCholesterolRiskLevel(double total, double ldl, double trig) {
    if (total >= 240 || ldl >= 160 || trig >= 200) return 'high';
    if (total >= 200 || ldl >= 130 || trig >= 150) return 'medium';
    return 'low';
  }
  
  String _getActivityRiskLevel(int steps, int minutes) {
    if (steps == 0 && minutes == 0) return 'no_data';
    // Simplified placeholder risk level for activity
    return 'low';
  }
  
  double _calculateBMI(double weightKg, double heightCm) {
    if (heightCm == 0) return 0;
    return weightKg / ((heightCm / 100) * (heightCm / 100));
  }
  
  String _getBMIRiskLevel(double bmi) {
    if (bmi >= 30.0) return 'high';
    if (bmi >= 25.0) return 'medium';
    return 'low';
  }
  
  Widget _buildHistoricalDataTab() {
    // Filter datasets by selected timeframe
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 30)); // Default 30 days for activity

    final latestGlucose = _healthData!.glucoseReadings.isNotEmpty ? _healthData!.glucoseReadings.last : null;
    final latestHbA1c = _healthData!.hbA1cReadings.isNotEmpty ? _healthData!.hbA1cReadings.last : null;
    final latestBP = _healthData!.bloodPressureReadings.isNotEmpty ? _healthData!.bloodPressureReadings.last : null;
    final latestCholesterol = _healthData!.cholesterolReadings.isNotEmpty ? _healthData!.cholesterolReadings.last : null;

    final hasGlucose = latestGlucose != null;
    final hasHbA1c = latestHbA1c != null;
    final hasBP = latestBP != null;
    final hasCholesterol = latestCholesterol != null;

    final filteredActivity = _healthData!.activityData.where((a) => a.date.isAfter(since)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final bmi = _healthData!.weight / ((_healthData!.height / 100) * (_healthData!.height / 100));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // BMI Card
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BmiAnalyticsScreen(
                patient: _patient!,
                readings: _healthData!.bmiReadings,
                currentWeight: _healthData!.weight,
                currentHeight: _healthData!.height,
              ),
            ),
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.dividerColor, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Body Mass Index',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  BMIGauge(
                    bmi: bmi,
                    weight: _healthData!.weight,
                    height: _healthData!.height,
                    isMetric: _isMetric,
                    onUnitChanged: (val) => setState(() => _isMetric = val),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Glucose & HbA1c Summary Cards
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildHealthMetricSummaryCard(
                  title: 'Glucose',
                  value: hasGlucose ? '${latestGlucose.value.toInt()} mg/dL' : '-- mg/dL',
                  status: hasGlucose ? (latestGlucose.isHigh ? 'High' : (latestGlucose.isLow ? 'Low' : 'Normal')) : '',
                  statusColor: hasGlucose ? (latestGlucose.isHigh ? AppTheme.highRiskColor : (latestGlucose.isLow ? AppTheme.secondaryColor : AppTheme.lowRiskColor)) : Colors.grey,
                  icon: Icons.water_drop,
                  hasData: hasGlucose,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GlucoseAnalyticsScreen(
                        patient: _patient!,
                        readings: _healthData!.glucoseReadings,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHealthMetricSummaryCard(
                  title: 'HbA1c',
                  value: hasHbA1c ? '${latestHbA1c.value}%' : '-- %',
                  status: hasHbA1c ? (latestHbA1c.value < 5.7 ? 'Normal' : 'High') : '',
                  statusColor: hasHbA1c ? (latestHbA1c.value < 5.7 ? AppTheme.lowRiskColor : AppTheme.highRiskColor) : Colors.grey,
                  icon: Icons.pie_chart,
                  hasData: hasHbA1c,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HbA1cAnalyticsScreen(
                        patient: _patient!,
                        readings: _healthData!.hbA1cReadings,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),

        // Blood Pressure Summary Card
        _buildHealthMetricSummaryCard(
          title: 'Blood Pressure',
          value: hasBP ? '${latestBP.systolic.toInt()}/${latestBP.diastolic.toInt()} mmHg' : '--/-- mmHg',
          status: hasBP ? (latestBP.systolic > 120 || latestBP.diastolic > 80 ? 'Elevated' : (latestBP.systolic < 90 || latestBP.diastolic < 60 ? 'Low' : 'Normal')) : '',
          statusColor: hasBP ? (latestBP.systolic > 120 || latestBP.diastolic > 80 ? AppTheme.highRiskColor : (latestBP.systolic < 90 || latestBP.diastolic < 60 ? AppTheme.mediumRiskColor : AppTheme.lowRiskColor)) : Colors.grey,
          icon: Icons.favorite,
          hasData: hasBP,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BloodPressureAnalyticsScreen(
                patient: _patient!,
                readings: _healthData!.bloodPressureReadings,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),

        // Cholesterol Summary Card
        _buildHealthMetricSummaryCard(
          title: 'Cholesterol',
          value: hasCholesterol ? '${latestCholesterol.total.toInt()} mg/dL' : '-- mg/dL',
          status: hasCholesterol ? (latestCholesterol.total >= 240 ? 'High' : (latestCholesterol.total >= 200 ? 'Borderline' : 'Desirable')) : '',
          statusColor: hasCholesterol ? (latestCholesterol.total >= 240 ? AppTheme.highRiskColor : (latestCholesterol.total >= 200 ? AppTheme.mediumRiskColor : AppTheme.lowRiskColor)) : Colors.grey,
          icon: Icons.opacity,
          hasData: hasCholesterol,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CholesterolAnalyticsScreen(
                patient: _patient!,
                readings: _healthData!.cholesterolReadings,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Physical Activity Summary Card
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityAnalyticsScreen(
                patient: _patient!,
                activityData: filteredActivity,
              ),
            ),
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.dividerColor, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.lowRiskColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_run, size: 20, color: AppTheme.lowRiskColor),
                      ),
                      const SizedBox(width: 12),
                      const Text('Physical Activity Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (filteredActivity.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Avg Steps',
                          _calculateAverageSteps().toInt().toString(),
                          Icons.directions_walk,
                          AppTheme.secondaryColor,
                        ),
                        _buildStatCard(
                          'Avg Active Mins',
                          _calculateAverageActiveMinutes().toInt().toString(),
                          Icons.timer,
                          AppTheme.lowRiskColor,
                        ),
                        _buildStatCard(
                          'Avg Calories',
                          _calculateAverageCalories().toInt().toString(),
                          Icons.local_fire_department,
                          AppTheme.accentColor,
                        ),
                      ],
                    ),
                  ] else ...[
                    const Center(
                      child: Text(
                        'No activity data for the selected period',
                        style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        

        const SizedBox(height: 12),

        // Diet Log Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.dividerColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.restaurant_outlined, color: AppTheme.accentColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Diet Log',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_healthData!.mealEntries.isEmpty)
                   const Text('No diet logs recorded.', style: TextStyle(color: AppTheme.textSecondary)),
                ..._healthData!.mealEntries.take(3).map((meal) => 
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getMealIcon(meal.mealType),
                            color: AppTheme.accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    meal.mealType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(meal.timestamp),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                meal.foodItems.map((f) => '${f.name} (${f.quantity} ${f.unit})').join(', '),
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildNutrientChip(
                                    'Carbs',
                                    '${meal.nutritionSummary['carbs']?.toInt() ?? 0}g',
                                    AppTheme.accentColor,
                                  ),
                                  _buildNutrientChip(
                                    'Protein',
                                    '${meal.nutritionSummary['protein']?.toInt() ?? 0}g',
                                    AppTheme.primaryColor,
                                  ),
                                  _buildNutrientChip(
                                    'Fat',
                                    '${meal.nutritionSummary['fat']?.toInt() ?? 0}g',
                                    AppTheme.secondaryColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_healthData!.mealEntries.length > 3)
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        // Show all meal entries
                      },
                      child: const Text('View all entries', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Automated Actions Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.dividerColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.automatedActionColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppTheme.automatedActionColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Automated Actions Log',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._healthData!.automatedActions.map((action) =>
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.automatedActionColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getAutomatedActionIcon(action.type),
                            color: AppTheme.automatedActionColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    action.type,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(action.timestamp),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                action.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (action.response != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Response: ${action.response}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHealthMetricSummaryCard({
    required String title,
    required String value,
    required String status,
    required Color statusColor,
    required IconData icon,
    required VoidCallback onTap,
    bool hasData = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasData ? statusColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: hasData ? statusColor : Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        status,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 10, color: statusColor),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No Data',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

/*
  Widget _buildChatbotTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              final isUser = msg.isUser;
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isUser ? null : Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Row(
                            children: const [
                              Icon(Icons.smart_toy, size: 16, color: AppTheme.secondaryColor),
                              SizedBox(width: 6),
                              Text('Florence Bot', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        if (!isUser) const SizedBox(height: 6),
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: isUser ? Colors.white : AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Type your question about ${_patient!.name}\'s health...',
                    prefixIcon: const Icon(Icons.chat_bubble_outline),
                  ),
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _handleSendMessage,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
  */
  
  Widget _buildPatientHeaderCard() {
    final riskColor = AppTheme.getRiskColor(_patient!.riskLevel.name);
    final riskNameProper = _patient!.riskLevel.name[0].toUpperCase() + 
                           _patient!.riskLevel.name.substring(1).toLowerCase();
    
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Avatar
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: riskColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: riskColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _patient!.name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase(),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _patient!.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                            tooltip: 'Edit Patient Profile',
                            onPressed: _showEditPatientProfileDialog,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Status Pills Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildHeaderPill(
                            'ID: ${_patient!.id}', 
                            Icons.badge_outlined,
                            AppTheme.textSecondary,
                            Colors.white,
                          ),
                          _buildHeaderPill(
                            '${_patient!.age} yrs, ${_patient!.gender}', 
                            Icons.person_outline,
                            AppTheme.textSecondary,
                            Colors.white,
                          ),
                          _buildHeaderPill(
                            riskNameProper, 
                            Icons.warning_amber_rounded,
                            riskColor,
                            Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Contact Info Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _patient!.contactInfo,
                          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (_patient!.emergencyContactName != null) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.emergency_outlined, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency: ${_patient!.emergencyContactName}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_patient!.emergencyContactRelationship} • ${_patient!.emergencyContactPhone}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmbeddedThresholdsCard() {
    if (_patientThresholds == null || _patientThresholds!.isEmpty) {
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.dividerColor),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No custom health targets configured yet.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final labels = {
      'BLOOD_PRESSURE_SYSTOLIC': 'BP (Systolic)',
      'BLOOD_PRESSURE_DIASTOLIC': 'BP (Diastolic)',
      'GLUCOSE': 'Glucose Target',
      'BMI': 'Target BMI',
      'HBA1C': 'Target HbA1c',
      'CHOLESTEROL_TOTAL': 'Total Cholesterol',
      'CHOLESTEROL_LDL': 'LDL Cholesterol',
      'CHOLESTEROL_HDL': 'HDL Cholesterol',
      'CHOLESTEROL_TRIGLYCERIDES': 'Triglycerides'
    };

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.dividerColor),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: _patientThresholds!.map((threshold) {
            final type = threshold['data_type'] ?? '';
            final displayName = labels[type] ?? type.replaceAll('_', ' ');

            String unit = '';
            if (type == 'GLUCOSE') unit = ' mg/dL';
            if (type.contains('CHOLESTEROL')) unit = ' mg/dL';
            if (type.contains('BLOOD_PRESSURE')) unit = ' mmHg';
            if (type == 'HBA1C') unit = ' %';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${(threshold['min_value'] as num).toStringAsFixed(1)} - ${(threshold['max_value'] as num).toStringAsFixed(1)}$unit',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildClinicalNotesCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_notes == null || _notes!.isEmpty)
              const Text('No clinical notes recorded yet.',
                  style: TextStyle(color: AppTheme.textSecondary)),
            if (_notes != null && _notes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _notes!
                    .map((note) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.textPrimary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.dividerColor
                                      .withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('MMM d, yyyy - h:mm a')
                                      .format(note.timestamp),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  note.content,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildMedicalProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- MEDICAL CONDITION ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Medical Condition', Icons.medical_services_outlined),
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Condition editing coming soon')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'ACTIVE', label: Text('Active')),
                          ButtonSegment(value: 'RESOLVED', label: Text('Resolved')),
                          ButtonSegment(value: 'ALL', label: Text('All')),
                        ],
                        selected: {_diseaseFilter},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _diseaseFilter = newSelection.first;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _patient!.activeDiseasesText,
                  style: const TextStyle(fontSize: 15, height: 1.4, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // --- TARGET HEALTH THRESHOLDS ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Target Health Thresholds', Icons.tune_rounded),
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
              onPressed: _showThresholdsDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildEmbeddedThresholdsCard(),
        const SizedBox(height: 24),

        // --- MEDICATIONS CABINET ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Current Medications', Icons.medication_outlined),
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medication management coming soon')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_healthData!.medications.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('No active medications recorded.', style: TextStyle(color: AppTheme.textSecondary)),
          )
        else
          ..._healthData!.medications.map((m) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medication, color: AppTheme.secondaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            m.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.dividerColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              m.dosage,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildNutrientChip('Route', m.route, AppTheme.primaryColor),
                          _buildNutrientChip('Frequency', m.frequency, AppTheme.lowRiskColor),
                          if (m.startDate != null)
                            _buildNutrientChip('Started', DateFormat('MMM d, yyyy').format(m.startDate!), AppTheme.accentColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildHeaderPill(String text, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper widgets
  
  double _calculateAverageSteps() {
    if (_healthData == null || _healthData!.activityData.isEmpty) return 0;
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 30));
    final filtered = _healthData!.activityData.where((a) => a.date.isAfter(since)).toList();
    if (filtered.isEmpty) return 0;
    
    double total = 0;
    for (var a in filtered) {
      total += a.steps;
    }
    return total / filtered.length;
  }

  double _calculateAverageActiveMinutes() {
    if (_healthData == null || _healthData!.activityData.isEmpty) return 0;
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 30));
    final filtered = _healthData!.activityData.where((a) => a.date.isAfter(since)).toList();
    if (filtered.isEmpty) return 0;
    
    double total = 0;
    for (var a in filtered) {
      total += a.activeMinutes;
    }
    return total / filtered.length;
  }

  double _calculateAverageCalories() {
    if (_healthData == null || _healthData!.activityData.isEmpty) return 0;
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 30));
    final filtered = _healthData!.activityData.where((a) => a.date.isAfter(since)).toList();
    if (filtered.isEmpty) return 0;
    
    double total = 0;
    for (var a in filtered) {
      total += a.caloriesBurned;
    }
    return total / filtered.length;
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildNutrientChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  
  
  // Helper methods
  /*
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }
  */
  
  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.restaurant;
      default:
        return Icons.food_bank;
    }
  }
  
  IconData _getAutomatedActionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'reminder':
        return Icons.notifications;
      case 'educational tip':
        return Icons.lightbulb;
      case 'motivational prompt':
        return Icons.emoji_emotions;
      case 'weekly summary':
        return Icons.summarize;
      default:
        return Icons.smart_toy;
    }
  }
  
  
  /*
  // Dialog methods
  void _handleSendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add(_ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _chatController.clear();
    });

    // Generate a simple, data-aware reply
    Future.delayed(const Duration(milliseconds: 300), () {
      final reply = _generateBotReply(text);
      setState(() {
        _chatMessages.add(_ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
      });
    });
  }

  String _generateBotReply(String userText) {
    final lower = userText.toLowerCase();

    if (lower.contains('glucose') || lower.contains('sugar')) {
      if (_healthData!.glucoseReadings.isNotEmpty) {
        final recent = _healthData!.glucoseReadings.first;
        final highEvents = _healthData!.glucoseReadings.where((r) => r.isHigh).length;
        final lowEvents = _healthData!.glucoseReadings.where((r) => r.isLow).length;
        return 'Recent glucose for ${_patient!.name} is ${recent.value.toStringAsFixed(0)} mg/dL. In the latest window I see $highEvents high and $lowEvents low events. If this followed a meal rich in refined carbs, consider smaller portions and pairing carbs with protein/fiber. I can also help set reminders for checks after dinner.';
      }
      return 'I do not see recent glucose data for ${_patient!.name}. You can request new measurements from the Health Data tab.';
    }

    if (lower.contains('activity') || lower.contains('steps')) {
      if (_healthData!.activityData.isNotEmpty) {
        final avgSteps = _calculateAverageSteps().toInt();
        return '${_patient!.name} averages about $avgSteps steps/day. A practical next step is a 10–15 minute walk after meals to improve post‑prandial glucose. Want me to add a reminder?';
      }
      return 'No recent activity data detected. If the patient uses a tracker, ensure permissions are enabled.';
    }

    if (lower.contains('hba1c') || lower.contains('a1c')) {
      if (_healthData!.hbA1cReadings.isNotEmpty) {
        final latest = _healthData!.hbA1cReadings.first.value;
        return "Latest HbA1c for ${_patient!.name} is ${latest.toStringAsFixed(1)}%. If you'd like, I can draft a message with diet and activity guidance based on this.";
      }
      return 'I do not see a recent HbA1c value. You can request a lab test from the Health Data tab.';
    }

    if (lower.contains('medication')) {
      return 'For medication timing and adherence, consider pairing doses with consistent daily cues (e.g., breakfast). I can set gentle reminders if desired.';
    }

    // Default response
    return 'I can help with glucose trends, HbA1c context, activity insights, and practical next steps. Try asking: "Why were evening glucose levels high?" or "Summarize weekly trends".';
  }
  */

  
  
  
  void _showScheduleFollowupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Follow-up'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select follow-up type and date'),
            // Add date picker and dropdown for follow-up type
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Schedule follow-up
              Navigator.pop(context);
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showEditPatientProfileDialog() async {
    final nameCtrl = TextEditingController(text: _patient!.name);
    final phoneCtrl = TextEditingController(text: _patient!.contactInfo);
    final ageCtrl = TextEditingController(text: _patient!.age.toString());
    final ecNameCtrl = TextEditingController(text: _patient!.emergencyContactName);
    final ecPhoneCtrl = TextEditingController(text: _patient!.emergencyContactPhone);
    final ecRelCtrl = TextEditingController(text: _patient!.emergencyContactRelationship);
    RiskLevel selectedRisk = _patient!.riskLevel;
    String? selectedGender = _patient!.gender;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setDialogState) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Patient Profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ageCtrl,
                    decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake)),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: ['Male', 'Female', 'Other'].contains(selectedGender) ? selectedGender : null,
                    items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) => setDialogState(() => selectedGender = v),
                    decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<RiskLevel>(
                    value: selectedRisk,
                    items: RiskLevel.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name[0] + r.name.substring(1).toLowerCase()))).toList(),
                    onChanged: (v) => setDialogState(() => selectedRisk = v!),
                    decoration: const InputDecoration(labelText: 'Risk Level', prefixIcon: Icon(Icons.gpp_maybe)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ecNameCtrl,
                    decoration: const InputDecoration(labelText: 'Contact Name', prefixIcon: Icon(Icons.contact_page_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ecRelCtrl,
                    decoration: const InputDecoration(labelText: 'Relationship', prefixIcon: Icon(Icons.family_restroom_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ecPhoneCtrl,
                    decoration: const InputDecoration(labelText: 'Contact Phone', prefixIcon: Icon(Icons.phone_callback_outlined)),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final api = ApiService();
        await api.put('/clinicians/me/patients/${widget.patientId}/profile', {
          'name': nameCtrl.text.trim(),
          'phone_number': phoneCtrl.text.trim(),
          'gender': selectedGender,
          'risk_level': selectedRisk.name.toUpperCase(),
          'emergency_contact_name': ecNameCtrl.text.trim(),
          'emergency_contact_relationship': ecRelCtrl.text.trim(),
          'emergency_contact_phone': ecPhoneCtrl.text.trim(),
        });
        await _loadPatientData();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showRequestDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Health Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select data type to request from the patient'),
            // Add checkboxes for different data types
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Send request
              Navigator.pop(context);
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}
