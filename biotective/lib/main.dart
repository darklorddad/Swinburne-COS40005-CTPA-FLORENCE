import 'package:flutter/material.dart';
import 'ai_integration/models/health_data.dart';
import 'ai_integration/widgets/ai_dashboard.dart';
import 'ai_integration/widgets/chatbot_widget.dart';
import 'ai_integration/widgets/health_insights.dart';

void main() {
  runApp(const BioTectiveApp());
}

class BioTectiveApp extends StatelessWidget {
  const BioTectiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioTective - AI Health Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BioTectiveHomePage(),
    );
  }
}

class BioTectiveHomePage extends StatefulWidget {
  const BioTectiveHomePage({super.key});

  @override
  State<BioTectiveHomePage> createState() => _BioTectiveHomePageState();
}

class _BioTectiveHomePageState extends State<BioTectiveHomePage> {
  int _selectedIndex = 0;
  
  // Sample patient data for demonstration
  late PatientProfile _patientProfile;
  late List<HealthData> _sampleData;

  @override
  void initState() {
    super.initState();
    _initializeSampleData();
  }

  void _initializeSampleData() {
    _patientProfile = PatientProfile(
      id: 'patient_001',
      name: 'John Doe',
      age: 45,
      gender: 'Male',
      diabetesType: 'type2',
      medications: ['Metformin', 'Glipizide'],
      preferences: {
        'notifications': true,
        'language': 'en',
        'units': 'mg/dL',
      },
      riskLevel: 'moderate',
      lastUpdated: DateTime.now(),
    );

    // Generate sample health data for the past week
    _sampleData = _generateSampleHealthData();
  }

  List<HealthData> _generateSampleHealthData() {
    final data = <HealthData>[];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      
      // Add multiple readings per day
      for (int j = 0; j < 3; j++) {
        final timestamp = DateTime(date.year, date.month, date.day, 8 + j * 6);
        
        data.add(HealthData(
          patientId: 'patient_001',
          timestamp: timestamp,
          glucoseLevel: 120 + (j * 20) + (i * 5), // Varying glucose levels
          steps: 8000 + (i * 500) + (j * 200), // Varying activity
          heartRate: 75 + (j * 5),
          mealType: j == 0 ? 'breakfast' : j == 1 ? 'lunch' : 'dinner',
          medicationTaken: 'yes',
          sleepHours: 7.5 + (i * 0.2),
          stressLevel: i % 2 == 0 ? 'low' : 'moderate',
          weight: 75.5 + (i * 0.1),
        ));
      }
    }
    
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BioTective Health Platform'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _sampleData = _generateSampleHealthData();
              });
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          AIDashboard(
            patientId: _patientProfile.id,
            patientProfile: _patientProfile,
            recentData: _sampleData,
          ),
          HealthInsights(
            patientId: _patientProfile.id,
            patientProfile: _patientProfile,
            recentData: _sampleData,
          ),
          ChatbotWidget(
            patientId: _patientProfile.id,
            patientProfile: _patientProfile,
            recentData: _sampleData,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'AI Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildQuickStats(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
          const SizedBox(height: 20),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${_patientProfile.name}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your AI health assistant is here to help you manage your diabetes effectively.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red[400]),
                const SizedBox(width: 8),
                Text(
                  'Risk Level: ${_patientProfile.riskLevel.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final latestGlucose = _sampleData.last.glucoseLevel ?? 0;
    final avgSteps = _sampleData
        .where((d) => d.steps != null)
        .map((d) => d.steps!)
        .reduce((a, b) => a + b) / 
        _sampleData.where((d) => d.steps != null).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Latest Glucose',
            '${latestGlucose.toStringAsFixed(0)}',
            'mg/dL',
            Icons.bloodtype,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Avg Steps',
            '${avgSteps.toStringAsFixed(0)}',
            'per day',
            Icons.directions_walk,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._sampleData.take(5).map((data) => _buildActivityItem(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(HealthData data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.favorite, color: Colors.blue[600], size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Glucose: ${data.glucoseLevel?.toStringAsFixed(0) ?? 'N/A'} mg/dL',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${data.mealType ?? 'No meal'} • ${_formatTime(data.timestamp)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1; // AI Assistant tab
                      });
                    },
                    icon: const Icon(Icons.smart_toy),
                    label: const Text('AI Assistant'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 3; // Chat tab
                      });
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Ask AI'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 2; // Insights tab
                      });
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('Health Insights'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Add new health data
                      _addNewHealthData();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Data'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewHealthData() {
    final newData = HealthData(
      patientId: _patientProfile.id,
      timestamp: DateTime.now(),
      glucoseLevel: 130 + (DateTime.now().millisecond % 50),
      steps: 5000 + (DateTime.now().millisecond % 3000),
      heartRate: 75 + (DateTime.now().millisecond % 20),
      mealType: 'snack',
      medicationTaken: 'yes',
      sleepHours: 7.5,
      stressLevel: 'low',
      weight: 75.5,
    );

    setState(() {
      _sampleData.add(newData);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New health data added!')),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
