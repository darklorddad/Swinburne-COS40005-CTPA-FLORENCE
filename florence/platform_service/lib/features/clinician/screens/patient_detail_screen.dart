import 'package:flutter/material.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/services/api_data_service.dart';
import 'package:florence/features/clinician/services/data_service.dart';
import 'package:florence/features/clinician/widgets/risk_indicator.dart';
import 'package:florence/features/clinician/widgets/bmi_gauge.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:florence/features/clinician/screens/glucose_analytics_screen.dart';
import 'package:florence/features/clinician/screens/hba1c_analytics_screen.dart';
import 'package:florence/features/clinician/screens/blood_pressure_analytics_screen.dart';
import 'package:florence/features/clinician/screens/cholesterol_analytics_screen.dart';
import 'package:florence/features/clinician/screens/activity_analytics_screen.dart';
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
  bool _isLoading = true;
  String? _error;
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
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final patients = await _dataService.getPatients();
      final patient = patients.firstWhere((p) => p.id == widget.patientId);
      final healthData = await _dataService.getPatientHealthData(widget.patientId);
      
      if (mounted) {
        setState(() {
          _patient = patient;
          _healthData = healthData;
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

  Future<void> _showUnassignConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Patient'),
        content: Text('Are you sure you want to remove ${_patient!.name} from your patient list? They will become available for other clinicians.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        // Assuming DataService has or will have an unassign method. 
        // If not, this needs to be added to your service layer.
        await _dataService.unassignPatient(widget.patientId);
        
        if (mounted) {
          Navigator.pop(context); // Return to previous screen
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_patient!.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Health Data'),
            // Tab(text: 'AI Chatbot'), // Temporarily disabled
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildHealthDataTab(),
          // _buildChatbotTab(), // Temporarily disabled
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle action based on current tab
          switch (_tabController.index) {
            case 0:
              // Schedule follow-up
              _showScheduleFollowupDialog();
              break;
            case 1:
              // Request new measurements
              _showRequestDataDialog();
              break;
            /* case 2:
              // Focus chat input
              FocusScope.of(context).requestFocus(FocusNode());
              break; */
          }
        },
        child: Icon(_tabController.index == 0 ? Icons.calendar_today : (_tabController.index == 1 ? Icons.sync : Icons.smart_toy)),
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Patient header card
        _buildPatientHeaderCard(),
        
        const SizedBox(height: 12),
        
        /*
        // AI-Generated Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI-Generated Health Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _healthData!.aiGeneratedSummary,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        */
        
        // Detected Patterns Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: AppTheme.secondaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Detected Patterns',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: _healthData!.detectedPatterns.map((pattern) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(pattern),
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
        
        const SizedBox(height: 12),
        
        /*
        // Recommendations Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Recommendations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: _healthData!.recommendations.map((recommendation) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppTheme.lowRiskColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(recommendation),
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
        
        const SizedBox(height: 12),
        */
        
        /*
        // Recent Automated Actions Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.smart_toy,
                      color: AppTheme.automatedActionColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Recent Automated Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._healthData!.automatedActions.take(3).map((action) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getAutomatedActionIcon(action.type),
                            color: Colors.purple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action.type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                action.description,
                                style: const TextStyle(
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                DateFormat('MMM d, h:mm a').format(action.timestamp),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_healthData!.automatedActions.length > 3)
                  TextButton(
                    onPressed: () {
                      _tabController.animateTo(1); // Go to Health Data tab
                    },
                    child: const Text('View all automated actions'),
                  ),
              ],
            ),
          ),
        ),
        */
      ],
    );
  }
  
  Widget _buildHealthDataTab() {
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
        Card(
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.directions_run, size: 20, color: AppTheme.textSecondary),
                      SizedBox(width: 8),
                      Text('Physical Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Medications Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Medications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_healthData!.medications.isEmpty)
                  const Text('No active medications recorded.'),
                ..._healthData!.medications.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.medication, color: AppTheme.secondaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  m.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  m.dosage,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildNutrientChip('Route', m.route, AppTheme.primaryColor),
                                _buildNutrientChip('Frequency', m.frequency, AppTheme.lowRiskColor),
                                if (m.startDate != null)
                                  _buildNutrientChip('Started', DateFormat('MMM d, yyyy').format(m.startDate!), AppTheme.accentColor),
                              ],
                            ),
                            if (m.notes != null) ...[
                              const SizedBox(height: 4),
                              Text(m.notes!, style: const TextStyle(fontSize: 13)),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Diet Log Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diet Log',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._healthData!.mealEntries.take(3).map((meal) => 
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getMealIcon(meal.mealType),
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(meal.timestamp),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                meal.foodItems.map((f) => '${f.name} (${f.quantity} ${f.unit})').join(', '),
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildNutrientChip(
                                    'Carbs',
                                    '${meal.nutritionSummary['carbs']?.toInt() ?? 0}g',
                                    AppTheme.accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildNutrientChip(
                                    'Protein',
                                    '${meal.nutritionSummary['protein']?.toInt() ?? 0}g',
                                    AppTheme.lowRiskColor,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildNutrientChip(
                                    'Fat',
                                    '${meal.nutritionSummary['fat']?.toInt() ?? 0}g',
                                    AppTheme.highRiskColor,
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
                      onPressed: () {
                        // Show all meal entries
                      },
                      child: const Text('View all entries'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Automated Actions Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Automated Actions Log',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._healthData!.automatedActions.map((action) =>
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getAutomatedActionIcon(action.type),
                            color: Colors.purple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(action.timestamp),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                action.description,
                                style: const TextStyle(fontSize: 13),
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
        color: hasData ? statusColor : const Color(0xFF616161),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (!hasData) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No Data',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              else
                Text(
                  'No history',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _patient!.name.split(' ').map((e) => e[0]).join(''),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _patient!.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          RiskIndicator(riskLevel: _patient!.riskLevel),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.person_remove_outlined, size: 24, color: Colors.grey),
                            tooltip: 'Unassign Patient',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _showUnassignConfirmation,
                          ),
                        ],
                      ),
                      Text(
                        '${_patient!.age} years, ${_patient!.gender}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _patient!.conditionName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Patient ID
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ID: ${_patient!.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last Update:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _formatDateTime(_patient!.lastSync),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            
            // Contact Info
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _patient!.contactInfo,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.message, size: 16),
                        label: const Text('Message'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          _tabController.animateTo(2); // Go to AI Chatbot tab
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Call'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          // Make call
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper widgets
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
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
  
  double _calculateAverageSteps() {
    if (_healthData!.activityData.isEmpty) return 0;
    final sum = _healthData!.activityData.fold(0, (prev, element) => prev + element.steps);
    return sum / _healthData!.activityData.length;
  }
  
  double _calculateAverageActiveMinutes() {
    if (_healthData!.activityData.isEmpty) return 0;
    final sum = _healthData!.activityData.fold(0, (prev, element) => prev + element.activeMinutes);
    return sum / _healthData!.activityData.length;
  }
  
  double _calculateAverageCalories() {
    if (_healthData!.activityData.isEmpty) return 0;
    final sum = _healthData!.activityData.fold(0, (prev, element) => prev + element.caloriesBurned);
    return sum / _healthData!.activityData.length;
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
