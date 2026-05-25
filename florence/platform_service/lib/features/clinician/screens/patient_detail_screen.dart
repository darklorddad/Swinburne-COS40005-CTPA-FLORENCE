import 'package:florence/features/clinician/models/clinician_note.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/screens/activity_analytics_screen.dart';
import 'package:florence/features/clinician/screens/blood_pressure_analytics_screen.dart';
import 'package:florence/features/clinician/screens/bmi_analytics_screen.dart';
import 'package:florence/features/clinician/screens/cholesterol_analytics_screen.dart';
import 'package:florence/features/clinician/screens/glucose_analytics_screen.dart';
import 'package:florence/features/clinician/screens/hba1c_analytics_screen.dart';
import 'package:florence/features/clinician/services/api_data_service.dart';
import 'package:florence/features/clinician/services/api_service.dart';
import 'package:florence/features/clinician/services/data_service.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:florence/features/clinician/widgets/bmi_gauge.dart';
import 'package:florence/features/patient/core/providers/medication_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
  String _glucoseUnit = 'mmol/L';
  String _cholesterolUnit = 'mmol/L';

  double _displayGlucose(double value) {
    if (_glucoseUnit == 'mg/dL') {
      return value * 18.018;
    }
    return value;
  }

  double _displayCholesterol(double value) {
    if (_cholesterolUnit == 'mg/dL') {
      return value * 38.67;
    }
    return value;
  }
  
  /*
  // Chatbot state
  final TextEditingController _chatController = TextEditingController();
  final List<_ChatMessage> _chatMessages = [];
  */
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
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
      
      String gUnit = 'mmol/L';
      String cUnit = 'mmol/L';
      try {
        final settings = await ApiService().get('/clinicians/me/settings');
        if (settings != null) {
          gUnit = settings['glucose_unit'] ?? 'mmol/L';
          cUnit = settings['cholesterol_unit'] ?? 'mmol/L';
        }
      } catch (e) {
        debugPrint('Failed loading clinician units context in detail screen: $e');
      }

      if (mounted) {
        setState(() {
          _patient = patient;
          _healthData = healthData;
          _notes = notes;
          _patientThresholds = thresholds;
          _glucoseUnit = gUnit;
          _cholesterolUnit = cUnit;
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

    final List<String> tabTitles = ['Overview', 'Medical Profile', 'Historical Data'];

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tabTitles[_tabController.index],
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
        
        // Grid Section Header
        _buildSectionHeader('Current Status', Icons.analytics_outlined),
        const SizedBox(height: 16),
        
        // Health Metrics Stack
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHealthMetricCard(
              'Glucose',
              _healthData!.glucoseReadings.isNotEmpty
                  ? _displayGlucose(_healthData!.glucoseReadings.last.value)
                      .toStringAsFixed(_glucoseUnit == 'mmol/L' ? 1 : 0)
                  : '--',
              _glucoseUnit,
              Icons.water_drop_outlined,
              _healthData!.glucoseReadings.isNotEmpty
                  ? _getGlucoseRiskLevel(_healthData!.glucoseReadings.last.value)
                  : 'no_data',
              _healthData!.glucoseReadings.isNotEmpty
                  ? _healthData!.glucoseReadings.last.timestamp
                  : null,
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
              _healthData!.cholesterolReadings.isNotEmpty
                  ? _displayCholesterol(_healthData!.cholesterolReadings.last.total)
                      .toStringAsFixed(_cholesterolUnit == 'mmol/L' ? 1 : 0)
                  : '--',
              _cholesterolUnit,
              Icons.bloodtype_outlined,
              _healthData!.cholesterolReadings.isNotEmpty
                  ? _getCholesterolRiskLevel(
                      _healthData!.cholesterolReadings.last.total,
                      _healthData!.cholesterolReadings.last.ldl,
                      _healthData!.cholesterolReadings.last.triglycerides)
                  : 'no_data',
              _healthData!.cholesterolReadings.isNotEmpty
                  ? _healthData!.cholesterolReadings.last.timestamp
                  : null,
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
    final mgDl = value * 18.018;
    if (mgDl < 70 || mgDl > 180) return 'high';
    if (mgDl > 140) return 'medium';
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
    final totalMgDl = total * 38.67;
    final ldlMgDl = ldl * 38.67;
    final trigMgDl = trig * 38.67;

    if (totalMgDl >= 240 || ldlMgDl >= 160 || trigMgDl >= 200) return 'high';
    if (totalMgDl >= 200 || ldlMgDl >= 130 || trigMgDl >= 150) return 'medium';
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
        // --- 1. MEDICAL CONDITIONS CARD ---
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.medical_services_outlined, size: 20, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Medical Conditions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: AppTheme.primaryColor),
                      tooltip: 'Add New Condition',
                      onPressed: _showAddDiseaseDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'ACTIVE', label: Text('Active', style: TextStyle(fontSize: 13))),
                          ButtonSegment(value: 'RESOLVED', label: Text('Resolved', style: TextStyle(fontSize: 13))),
                          ButtonSegment(value: 'ALL', label: Text('All', style: TextStyle(fontSize: 13))),
                        ],
                        selected: {_diseaseFilter},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _diseaseFilter = newSelection.first;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          selectedBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          selectedForegroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFilteredDiseaseList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- 2. TARGET HEALTH THRESHOLDS CARD ---
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 20, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Health Thresholds',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: AppTheme.textSecondary),
                      onPressed: _showEditThresholdsDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildEmbeddedThresholdsList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- 3. CURRENT MEDICATIONS CARD ---
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 20, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Current Medications',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          size: 22, color: AppTheme.primaryColor),
                      tooltip: 'Add New Medication',
                      onPressed: _showAddMedicationDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMedicalCabinetList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilteredDiseaseList() {
    // Fallback Mock logs framework for safe runtime handling
    final List<Map<String, dynamic>> testDiseases = [
      {'id': 1, 'condition_name': 'Asthma', 'status': 'active', 'diagnosed_date': '2026-05-01'},
      {'id': 2, 'condition_name': 'Hypertension', 'status': 'active', 'diagnosed_date': '2026-05-01'},
    ];

    final filtered = testDiseases.where((item) {
      final statusStr = (item['status'] ?? 'active').toString().toUpperCase();
      if (_diseaseFilter == 'ALL') return true;
      return statusStr == _diseaseFilter;
    }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text('No medical conditions match this filter.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = filtered[index];
        final name = item['condition_name'] ?? 'Unknown';
        final status = (item['status'] ?? 'active').toString().toLowerCase();
        final date = item['diagnosed_date'] ?? 'Not Set';

        final isActive = status == 'active';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.red.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.medical_services,
                      color: isActive ? Colors.red.shade400 : AppTheme.textSecondary,
                      size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Diagnosed: $date',
                        style: const TextStyle(
                            color: AppTheme.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'RESOLVED',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.red.shade600
                            : Colors.green.shade700),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppTheme.textSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (action) => _handleDiseaseAction(action, item),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Text(isActive ? 'Mark as Resolved' : 'Mark as Active'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Details'),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          SizedBox(width: 6),
                          Text('Remove', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmbeddedThresholdsList() {
    if (_patientThresholds == null || _patientThresholds!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No thresholds configured.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      );
    }

    final labels = {
      'BLOOD_PRESSURE_SYSTOLIC': 'BP (Systolic)',
      'BLOOD_PRESSURE_DIASTOLIC': 'BP (Diastolic)',
      'GLUCOSE': 'Glucose',
      'BMI': 'Healthy BMI',
      'HBA1C': 'HbA1c',
      'CHOLESTEROL_TOTAL': 'Total Cholesterol',
      'CHOLESTEROL_LDL': 'LDL Cholesterol',
      'CHOLESTEROL_HDL': 'HDL Cholesterol',
      'CHOLESTEROL_TRIGLYCERIDES': 'Triglycerides'
    };

    final icons = {
      'BLOOD_PRESSURE_SYSTOLIC': Icons.monitor_heart_outlined,
      'BLOOD_PRESSURE_DIASTOLIC': Icons.favorite_border_rounded,
      'GLUCOSE': Icons.water_drop_outlined,
      'BMI': Icons.monitor_weight_outlined,
      'HBA1C': Icons.pie_chart_outline_rounded,
      'CHOLESTEROL_TOTAL': Icons.bubble_chart_outlined,
      'CHOLESTEROL_LDL': Icons.opacity_outlined,
      'CHOLESTEROL_HDL': Icons.opacity,
      'CHOLESTEROL_TRIGLYCERIDES': Icons.texture_rounded
    };

    return Column(
      children: List.generate(_patientThresholds!.length, (index) {
        final t = _patientThresholds!.elementAt(index);
        final type = t['data_type'] ?? '';
        final displayName = labels[type] ?? type.replaceAll('_', ' ');
        final iconData = icons[type] ?? Icons.analytics_outlined;

        double minValue = (t['min_value'] as num).toDouble();
        double maxValue = (t['max_value'] as num).toDouble();
        String unit = '';

        if (type == 'GLUCOSE') {
          unit = ' $_glucoseUnit';
          if (_glucoseUnit == 'mg/dL') {
            minValue = minValue * 18.018;
            maxValue = maxValue * 18.018;
          }
        } else if (type.contains('CHOLESTEROL')) {
          unit = ' $_cholesterolUnit';
          if (_cholesterolUnit == 'mg/dL') {
            minValue = minValue * 38.67;
            maxValue = maxValue * 38.67;
          }
        } else if (type.contains('BLOOD_PRESSURE')) {
          unit = ' mmHg';
        } else if (type == 'HBA1C') {
          unit = ' %';
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Icon(iconData,
                      size: 20,
                      color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${minValue.toStringAsFixed(1)} - ${maxValue.toStringAsFixed(1)}$unit',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            if (index < _patientThresholds!.length - 1)
              const Divider(height: 1, color: AppTheme.dividerColor),
          ],
        );
      }),
    );
  }

  Widget _buildMedicalCabinetList() {
    if (_healthData?.medications == null || _healthData!.medications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No active medications recorded.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      );
    }

    return Column(
      children: _healthData!.medications.map((m) {
        final formStr = (m.route).toLowerCase();
        final dosageStr = m.dosage;
        final freqStr = (m.frequency).toLowerCase();

        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication,
                    color: AppTheme.secondaryColor, size: 20),
              ),
              title: Text(m.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textPrimary)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('$formStr • $dosageStr • $freqStr',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppTheme.textSecondary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (action) => _handleMedicationAction(action, m),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Details'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    textColor: Colors.red,
                    child: Row(
                      children: const [
                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        SizedBox(width: 6),
                        Text('Remove'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.dividerColor),
          ],
        );
      }).toList(),
    );
  }

  void _handleMedicationAction(String action, dynamic medication) {
    if (action == 'edit') {
      _showEditMedicationDialog(medication);
    } else if (action == 'delete') {
      _confirmDeleteMedication(medication);
    }
  }

  void _handleDiseaseAction(String action, Map<String, dynamic> disease) {
    if (action == 'edit') {
      _showEditDiseaseDialog(disease);
    } else if (action == 'delete') {
      _confirmDeleteDisease(disease);
    } else if (action == 'toggle_status') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status toggle coming soon')),
      );
    }
  }

  Future<void> _uiSelectDatePicker(
      BuildContext context, TextEditingController targetController) async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (selected != null) {
      final monthsList = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final dayString = selected.day.toString().padLeft(2, '0');
      targetController.text =
          "$dayString ${monthsList[selected.month - 1]} ${selected.year}";
    }
  }

  Future<void> _showAddDiseaseDialog() async {
    final conditionCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: "26 May 2026");
    String selectedStatus = 'active';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Medical Condition',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                TextFormField(
                  controller: conditionCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Condition Name', hintText: 'e.g. Asthma'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status Context'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'resolved', child: Text('Resolved')),
                  ],
                  onChanged: (v) => setModalState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosed Date',
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  onTap: () => _uiSelectDatePicker(context, dateCtrl),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Add Entry')),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDiseaseDialog(Map<String, dynamic> disease) async {
    final conditionCtrl =
        TextEditingController(text: disease['condition_name']);
    final dateCtrl =
        TextEditingController(text: disease['diagnosed_date'] ?? '26 May 2026');
    String selectedStatus = disease['status'] ?? 'active';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Medical Condition',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                TextFormField(
                  controller: conditionCtrl,
                  decoration: const InputDecoration(labelText: 'Condition Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status Context'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'resolved', child: Text('Resolved')),
                  ],
                  onChanged: (v) => setModalState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosed Date',
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  onTap: () => _uiSelectDatePicker(context, dateCtrl),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Save Changes')),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteDisease(Map<String, dynamic> disease) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Condition?'),
        content: Text(
            'Are you sure you want to permanently delete ${disease['condition_name']} from this patient profile?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showEditThresholdsDialog() {
    _showThresholdsDialog();
  }

  void _confirmDeleteMedication(dynamic m) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Medication?'),
        content: Text(
            'Are you sure you want to discard ${m.name} from this schedule profile?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showEditMedicationsDialog() {
    _showAddMedicationDialog();
  }

  void _showAddMedicationDialog() {
    showDialog(
      context: context,
      builder: (context) => ClinicianMedicationFormDialog(
          isEdit: false, patientId: widget.patientId),
    );
  }

  void _showEditMedicationDialog(dynamic medication) {
    showDialog(
      context: context,
      builder: (context) => ClinicianMedicationFormDialog(
          isEdit: true, medication: medication, patientId: widget.patientId),
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

  
  
  
}

class ClinicianMedicationFormDialog extends ConsumerStatefulWidget {
  final bool isEdit;
  final dynamic medication;
  final String patientId;

  const ClinicianMedicationFormDialog({
    super.key,
    required this.isEdit,
    this.medication,
    required this.patientId,
  });

  @override
  ConsumerState<ClinicianMedicationFormDialog> createState() =>
      _ClinicianMedicationFormDialogState();
}

class _ClinicianMedicationFormDialogState
    extends ConsumerState<ClinicianMedicationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Map<String, dynamic>? _selectedDictionaryItem;
  dynamic _selectedFrequency;

  String _selectedType = 'Tablet';
  List<String> _selectedTimings = ['ANYTIME'];

  final List<String> _medicationTypes = [
    'Tablet',
    'Capsule',
    'Injection',
    'ml',
    'Inhaler',
    'Other'
  ];
  final List<String> _timingInstructions = [
    'BEFORE_BREAKFAST',
    'WITH_BREAKFAST',
    'AFTER_BREAKFAST',
    'BEFORE_LUNCH',
    'WITH_LUNCH',
    'AFTER_LUNCH',
    'BEFORE_DINNER',
    'WITH_DINNER',
    'AFTER_DINNER',
    'BEFORE_SUPPER',
    'WITH_SUPPER',
    'AFTER_SUPPER',
    'WITH_SNACK',
    'BEFORE_BED',
    'EMPTY_STOMACH',
    'AS_NEEDED',
    'ANYTIME'
  ];

  int _getDosesFromFrequency(dynamic freq) {
    if (freq == null) return 1;
    final text = (freq['patient_text'] ?? freq['latin_code']).toString().toLowerCase();
    if (text.contains('twice') || text == 'bid' || text.contains('2 times')) return 2;
    if (text.contains('three') || text == 'tid' || text.contains('3 times')) return 3;
    if (text.contains('four') || text == 'qid' || text.contains('4 times')) return 4;
    return 1;
  }

  void _onFrequencyChanged(dynamic val) {
    setState(() {
      _selectedFrequency = val;
      int requiredDoses = _getDosesFromFrequency(val);

      while (_selectedTimings.length < requiredDoses) {
        _selectedTimings.add('ANYTIME');
      }
      if (_selectedTimings.length > requiredDoses) {
        _selectedTimings = _selectedTimings.sublist(0, requiredDoses);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.medication != null) {
      final m = widget.medication;
      _nameController.text = m.name ?? "";
      _amountController.text = m.dosage ?? "";
      _selectedType = _medicationTypes.contains(m.form) ? m.form : 'Tablet';

      _selectedTimings = m.timingInstructions != null
          ? List<String>.from(m.timingInstructions)
          : ['ANYTIME'];
    }
  }

  InputDecoration _getCustomInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }

  String _getOrdinalLabel(int index) {
    const ordinals = ["1st", "2nd", "3rd", "4th", "5th"];
    if (index <= ordinals.length) return ordinals[index - 1];
    return "${index}th";
  }

  @override
  Widget build(BuildContext context) {
    final dictAsync = ref.watch(medicationDictionaryProvider);
    final freqAsync = ref.watch(dosageFrequenciesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.isEdit ? "Edit Medication" : "Add Medication",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(height: 20),
                const Text("Medication Name",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                dictAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text("Error loading dictionary data"),
                  data: (dictionaryList) {
                    final dictionary =
                        dictionaryList.cast<Map<String, dynamic>>();
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Autocomplete<Map<String, dynamic>>(
                          initialValue:
                              TextEditingValue(text: _nameController.text),
                          displayStringForOption: (option) =>
                              (option['brand_name'] ?? option['generic_name'])
                                  .toString(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<Map<String,
                                  dynamic>>.empty();
                            }
                            return dictionary.where((med) {
                              final brand =
                                  (med['brand_name']?.toString() ?? '')
                                      .toLowerCase();
                              final query = textEditingValue.text.toLowerCase();
                              return brand.contains(query);
                            });
                          },
                          onSelected: (selection) => setState(
                              () => _selectedDictionaryItem = selection),
                          fieldViewBuilder: (context, controller, focusNode,
                              onFieldSubmitted) {
                            controller.addListener(() {
                              _nameController.text = controller.text;
                            });
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required field'
                                  : null,
                              decoration: _getCustomInputDecoration(
                                  "Search dictionary or type custom name...",
                                  suffixIcon:
                                      const Icon(Icons.search, size: 18)),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Amount",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Required'
                                : null,
                            decoration: _getCustomInputDecoration("e.g. 1, 1.5"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Type",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: _getCustomInputDecoration("Type"),
                            items: _medicationTypes
                                .map((t) =>
                                    DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedType = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Frequency",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                freqAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text("Error loading frequencies"),
                  data: (frequencies) {
                    return DropdownButtonFormField<dynamic>(
                      value: _selectedFrequency,
                      hint: const Text("Select frequency pattern"),
                      decoration: _getCustomInputDecoration("Select frequency"),
                      items: frequencies
                          .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f['patient_text'] ?? f['latin_code'])))
                          .toList(),
                      onChanged: _onFrequencyChanged,
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Divider(),
                const Text("Specific Timings",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                ...List.generate(_selectedTimings.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                              "${_selectedTimings.length > 1 ? _getOrdinalLabel(index + 1) : 'Daily'} Dose:",
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedTimings[index],
                            decoration: _getCustomInputDecoration("Timing"),
                            items: _timingInstructions.map((t) {
                              final formatted =
                                  t.replaceAll('_', ' ').toLowerCase();
                              return DropdownMenuItem(
                                  value: t,
                                  child: Text(formatted[0].toUpperCase() +
                                      formatted.substring(1)));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedTimings[index] = val!),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white),
                      child:
                          Text(widget.isEdit ? "Save Changes" : "Add Medication"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on _PatientDetailScreenState {
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
}
