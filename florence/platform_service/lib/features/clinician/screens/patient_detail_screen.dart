import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/health_data.dart';
import '../services/mock_data_service.dart';
import '../widgets/glucose_chart.dart';
import '../widgets/activity_chart.dart';
import '../widgets/risk_indicator.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

enum GlucoseUnit { mgPerdL, mmolPerL }

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
  final MockDataService _dataService = MockDataService();
  late TabController _tabController;
  late Patient _patient;
  late PatientHealthData _healthData;
  // Glucose unit state for Avg Glucose metric
  GlucoseUnit _glucoseUnit = GlucoseUnit.mgPerdL;
  // Graph timeframe (days)
  int _graphDays = 30;
  
  // Chatbot state
  final TextEditingController _chatController = TextEditingController();
  final List<_ChatMessage> _chatMessages = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    
    // Load patient data
    _patient = _dataService.getPatients().firstWhere((p) => p.id == widget.patientId);
    _healthData = _dataService.getPatientHealthData(widget.patientId);
    

    // Seed chatbot with a greeting
    _chatMessages.add(
      _ChatMessage(
        text: 'Hi, I am your AI assistant. How can I help with ${_patient.name}\'s care today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_patient.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Health Data'),
            Tab(text: 'AI Chatbot'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildHealthDataTab(),
          _buildChatbotTab(),
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
            case 2:
              // Focus chat input
              FocusScope.of(context).requestFocus(FocusNode());
              break;
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
        
        const SizedBox(height: 16),
        
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
                  _healthData.aiGeneratedSummary,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
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
                  children: _healthData.detectedPatterns.map((pattern) => 
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
        
        const SizedBox(height: 16),
        
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
                  children: _healthData.recommendations.map((recommendation) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
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
        
        const SizedBox(height: 16),
        
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
                      color: Colors.purple,
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
                ..._healthData.automatedActions.take(3).map((action) =>
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
                if (_healthData.automatedActions.length > 3)
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
      ],
    );
  }
  
  Widget _buildHealthDataTab() {
    // Filter datasets by selected timeframe
    final now = DateTime.now();
    final since = now.subtract(Duration(days: _graphDays));
    final filteredGlucose = _healthData.glucoseReadings.where((r) => r.timestamp.isAfter(since)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final filteredHbA1c = _healthData.hbA1cReadings.where((r) => r.timestamp.isAfter(since)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final filteredActivity = _healthData.activityData.where((a) => a.date.isAfter(since)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Glucose & HbA1c Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Glucose & HbA1c Trends',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: SegmentedButton<int>(
                    segments: const <ButtonSegment<int>>[
                      ButtonSegment(value: 7, label: Text('7d')),
                      ButtonSegment(value: 14, label: Text('14d')),
                      ButtonSegment(value: 30, label: Text('30d')),
                      ButtonSegment(value: 90, label: Text('90d')),
                    ],
                    selected: <int>{_graphDays},
                    showSelectedIcon: false,
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    onSelectionChanged: (s) {
                      setState(() {
                        _graphDays = s.first;
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 250,
                  child: GlucoseChart(
                    readings: filteredGlucose,
                    hbA1cReadings: filteredHbA1c,
                  ),
                ),
                const Divider(),
                // Unit selector for Avg Glucose metric
                Align(
                  alignment: Alignment.centerRight,
                  child: SegmentedButton<GlucoseUnit>(
                    segments: const <ButtonSegment<GlucoseUnit>>[
                      ButtonSegment(value: GlucoseUnit.mgPerdL, label: Text('mg/dL')),
                      ButtonSegment(value: GlucoseUnit.mmolPerL, label: Text('mmol/L')),
                    ],
                    selected: <GlucoseUnit>{_glucoseUnit},
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _glucoseUnit = newSelection.first;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildGlucoseStatChip(
                        'Avg Glucose',
                        _formatAvgGlucose(_calculateAverageGlucoseFor(filteredGlucose)),
                        Colors.green,
                      ),
                      _buildGlucoseStatChip(
                        'High Events',
                        filteredGlucose.where((r) => r.isHigh).length.toString(),
                        AppTheme.highRiskColor,
                      ),
                      _buildGlucoseStatChip(
                        'Low Events',
                        filteredGlucose.where((r) => r.isLow).length.toString(),
                        Colors.blue,
                      ),
                      _buildGlucoseStatChip(
                        'Latest HbA1c',
                        '${filteredHbA1c.isEmpty ? "-" : filteredHbA1c.first.value.toString()}%',
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Activity Data Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Physical Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: ActivityChart(
                    activityData: filteredActivity,
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Avg Steps',
                        _calculateAverageSteps().toInt().toString(),
                        Icons.directions_walk,
                        AppTheme.secondaryColor,
                      ),
                      _buildStatCard(
                        'Avg Active Minutes',
                        _calculateAverageActiveMinutes().toInt().toString(),
                        Icons.timer,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Avg Calories',
                        _calculateAverageCalories().toInt().toString(),
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
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
                if (_healthData.medications.isEmpty)
                  const Text('No active medications recorded.'),
                ..._healthData.medications.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                                _buildNutrientChip('Frequency', m.frequency, Colors.green),
                                if (m.startDate != null)
                                  _buildNutrientChip('Started', DateFormat('MMM d, yyyy').format(m.startDate!), Colors.orange),
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

        const SizedBox(height: 16),

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
                const SizedBox(height: 16),
                ..._healthData.mealEntries.take(3).map((meal) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                                    Colors.amber,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildNutrientChip(
                                    'Protein',
                                    '${meal.nutritionSummary['protein']?.toInt() ?? 0}g',
                                    Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildNutrientChip(
                                    'Fat',
                                    '${meal.nutritionSummary['fat']?.toInt() ?? 0}g',
                                    Colors.red,
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
                if (_healthData.mealEntries.length > 3)
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
        
        const SizedBox(height: 16),
        
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
                const SizedBox(height: 16),
                ..._healthData.automatedActions.map((action) =>
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
                    hintText: 'Type your question about ${_patient.name}\'s health...',
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
                      _patient.name.split(' ').map((e) => e[0]).join(''),
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
                          Text(
                            _patient.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          RiskIndicator(riskLevel: _patient.riskLevel),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_patient.age} years, ${_patient.gender}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _patient.conditionName,
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
                        'ID: ${_patient.id}',
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
                      _formatDateTime(_patient.lastSync),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // Contact Info
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _patient.contactInfo,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Message'),
                    onPressed: () {
                      _tabController.animateTo(2); // Go to Notes & Communication tab
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Call'),
                    onPressed: () {
                      // Make call
                    },
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
  Widget _buildGlucoseStatChip(String label, String value, Color color) {
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
  
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
  
  double _calculateAverageGlucoseFor(List<GlucoseReading> readings) {
    if (readings.isEmpty) return 0;
    final sum = readings.fold(0.0, (prev, element) => prev + element.value);
    return sum / readings.length;
  }

  String _formatAvgGlucose(double valueMgPerdL) {
    if (_glucoseUnit == GlucoseUnit.mgPerdL) {
      return '${valueMgPerdL.toInt()} mg/dL';
    }
    // Convert mg/dL to mmol/L: value / 18
    final mmol = valueMgPerdL / 18.0;
    return '${mmol.toStringAsFixed(1)} mmol/L';
  }
  
  double _calculateAverageSteps() {
    if (_healthData.activityData.isEmpty) return 0;
    final sum = _healthData.activityData.fold(0, (prev, element) => prev + element.steps);
    return sum / _healthData.activityData.length;
  }
  
  double _calculateAverageActiveMinutes() {
    if (_healthData.activityData.isEmpty) return 0;
    final sum = _healthData.activityData.fold(0, (prev, element) => prev + element.activeMinutes);
    return sum / _healthData.activityData.length;
  }
  
  double _calculateAverageCalories() {
    if (_healthData.activityData.isEmpty) return 0;
    final sum = _healthData.activityData.fold(0, (prev, element) => prev + element.caloriesBurned);
    return sum / _healthData.activityData.length;
  }
  
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
      if (_healthData.glucoseReadings.isNotEmpty) {
        final recent = _healthData.glucoseReadings.first;
        final highEvents = _healthData.glucoseReadings.where((r) => r.isHigh).length;
        final lowEvents = _healthData.glucoseReadings.where((r) => r.isLow).length;
        return 'Recent glucose for ${_patient.name} is ${recent.value.toStringAsFixed(0)} mg/dL. In the latest window I see $highEvents high and $lowEvents low events. If this followed a meal rich in refined carbs, consider smaller portions and pairing carbs with protein/fiber. I can also help set reminders for checks after dinner.';
      }
      return 'I do not see recent glucose data for ${_patient.name}. You can request new measurements from the Health Data tab.';
    }

    if (lower.contains('activity') || lower.contains('steps')) {
      if (_healthData.activityData.isNotEmpty) {
        final avgSteps = _calculateAverageSteps().toInt();
        return '${_patient.name} averages about $avgSteps steps/day. A practical next step is a 10–15 minute walk after meals to improve post‑prandial glucose. Want me to add a reminder?';
      }
      return 'No recent activity data detected. If the patient uses a tracker, ensure permissions are enabled.';
    }

    if (lower.contains('hba1c') || lower.contains('a1c')) {
      if (_healthData.hbA1cReadings.isNotEmpty) {
        final latest = _healthData.hbA1cReadings.first.value;
        return "Latest HbA1c for ${_patient.name} is ${latest.toStringAsFixed(1)}%. If you'd like, I can draft a message with diet and activity guidance based on this.";
      }
      return 'I do not see a recent HbA1c value. You can request a lab test from the Health Data tab.';
    }

    if (lower.contains('medication')) {
      return 'For medication timing and adherence, consider pairing doses with consistent daily cues (e.g., breakfast). I can set gentle reminders if desired.';
    }

    // Default response
    return 'I can help with glucose trends, HbA1c context, activity insights, and practical next steps. Try asking: "Why were evening glucose levels high?" or "Summarize weekly trends".';
  }

  
  
  
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
