import 'package:flutter/material.dart';
import '../models/health_data.dart';
import '../services/recommendation_engine.dart';
import '../services/anomaly_detector.dart';
import '../services/automation_layer.dart';

class AIDashboard extends StatefulWidget {
  final String patientId;
  final PatientProfile patientProfile;
  final List<HealthData> recentData;

  const AIDashboard({
    super.key,
    required this.patientId,
    required this.patientProfile,
    required this.recentData,
  });

  @override
  State<AIDashboard> createState() => _AIDashboardState();
}

class _AIDashboardState extends State<AIDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Recommendation> _recommendations = [];
  List<Anomaly> _anomalies = [];
  List<AutomationTrigger> _triggers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAIData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAIData() async {
    setState(() => _isLoading = true);

    try {
      // Load recommendations
      final recommendations = await RecommendationEngine.generateRecommendations(
        patientId: widget.patientId,
        recentData: widget.recentData,
        patientProfile: widget.patientProfile,
      );

      // Detect anomalies
      final anomalies = AnomalyDetector.detectAnomalies(
        patientId: widget.patientId,
        recentData: widget.recentData,
        patientProfile: widget.patientProfile,
      );

      // Get active triggers
      final triggers = AutomationLayer.getActiveTriggers(widget.patientId);

      setState(() {
        _recommendations = recommendations;
        _anomalies = anomalies;
        _triggers = triggers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading AI data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.lightbulb), text: 'Recommendations'),
            Tab(icon: Icon(Icons.warning), text: 'Alerts'),
            Tab(icon: Icon(Icons.autorenew), text: 'Automation'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendationsTab(),
                _buildAlertsTab(),
                _buildAutomationTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAIData,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    if (_recommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Great job! No recommendations at this time.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        return _buildRecommendationCard(recommendation);
      },
    );
  }

  Widget _buildRecommendationCard(Recommendation recommendation) {
    Color priorityColor;
    IconData priorityIcon;
    
    switch (recommendation.priority) {
      case 'urgent':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'high':
        priorityColor = Colors.orange;
        priorityIcon = Icons.warning;
        break;
      case 'medium':
        priorityColor = Colors.blue;
        priorityIcon = Icons.info;
        break;
      default:
        priorityColor = Colors.green;
        priorityIcon = Icons.lightbulb;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(priorityIcon, color: priorityColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(recommendation.priority.toUpperCase()),
                  backgroundColor: priorityColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: priorityColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why this recommendation:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation.explanation,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Mark as read
                    setState(() {
                      recommendation.isRead = true;
                    });
                  },
                  child: const Text('Mark as Read'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    // Mark as acted upon
                    setState(() {
                      recommendation.isActedUpon = true;
                      recommendation.actedUponAt = DateTime.now();
                    });
                  },
                  child: const Text('I\'ve Done This'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    if (_anomalies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No health alerts at this time.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _anomalies.length,
      itemBuilder: (context, index) {
        final anomaly = _anomalies[index];
        return _buildAnomalyCard(anomaly);
      },
    );
  }

  Widget _buildAnomalyCard(Anomaly anomaly) {
    Color severityColor;
    IconData severityIcon;
    
    switch (anomaly.severity) {
      case 'critical':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'high':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      case 'moderate':
        severityColor = Colors.blue;
        severityIcon = Icons.info;
        break;
      default:
        severityColor = Colors.green;
        severityIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(severityIcon, color: severityColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    anomaly.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(anomaly.severity.toUpperCase()),
                  backgroundColor: severityColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: severityColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Detected: ${_formatDateTime(anomaly.detectedAt)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${anomaly.anomalyType.replaceAll('_', ' ').toUpperCase()}',
              style: const TextStyle(fontSize: 14),
            ),
            if (!anomaly.isResolved) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    anomaly.isResolved = true;
                    anomaly.resolvedAt = DateTime.now();
                  });
                },
                child: const Text('Mark as Resolved'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationTab() {
    if (_triggers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.autorenew, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'No active automation triggers.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _triggers.length,
      itemBuilder: (context, index) {
        final trigger = _triggers[index];
        return _buildTriggerCard(trigger);
      },
    );
  }

  Widget _buildTriggerCard(AutomationTrigger trigger) {
    Color priorityColor;
    IconData priorityIcon;
    
    switch (trigger.priority) {
      case 'critical':
        priorityColor = Colors.red;
        priorityIcon = Icons.error;
        break;
      case 'urgent':
        priorityColor = Colors.orange;
        priorityIcon = Icons.priority_high;
        break;
      case 'high':
        priorityColor = Colors.orange;
        priorityIcon = Icons.warning;
        break;
      case 'medium':
        priorityColor = Colors.blue;
        priorityIcon = Icons.info;
        break;
      default:
        priorityColor = Colors.green;
        priorityIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(priorityIcon, color: priorityColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trigger.triggerType.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(trigger.priority.toUpperCase()),
                  backgroundColor: priorityColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: priorityColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              trigger.message,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${_formatDateTime(trigger.createdAt)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Action: ${trigger.actionType.replaceAll('_', ' ').toUpperCase()}',
              style: const TextStyle(fontSize: 12),
            ),
            if (!trigger.isResolved) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    trigger.isResolved = true;
                    trigger.resolvedAt = DateTime.now();
                  });
                },
                child: const Text('Mark as Resolved'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
