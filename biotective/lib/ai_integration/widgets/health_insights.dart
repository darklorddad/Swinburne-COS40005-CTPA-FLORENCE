import 'package:flutter/material.dart';
import '../models/health_data.dart';
import '../services/anomaly_detector.dart';

class HealthInsights extends StatefulWidget {
  final String patientId;
  final PatientProfile patientProfile;
  final List<HealthData> recentData;

  const HealthInsights({
    super.key,
    required this.patientId,
    required this.patientProfile,
    required this.recentData,
  });

  @override
  State<HealthInsights> createState() => _HealthInsightsState();
}

class _HealthInsightsState extends State<HealthInsights> {
  List<Anomaly> _anomalies = [];
  String _riskLevel = 'low';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _analyzeHealthData();
  }

  Future<void> _analyzeHealthData() async {
    setState(() => _isLoading = true);

    try {
      final anomalies = AnomalyDetector.detectAnomalies(
        patientId: widget.patientId,
        recentData: widget.recentData,
        patientProfile: widget.patientProfile,
      );

      final riskLevel = AnomalyDetector.calculateRiskLevel(anomalies);

      setState(() {
        _anomalies = anomalies;
        _riskLevel = riskLevel;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing health data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Insights'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRiskLevelCard(),
                  const SizedBox(height: 20),
                  _buildHealthTrendsChart(),
                  const SizedBox(height: 20),
                  _buildAnomaliesSummary(),
                  const SizedBox(height: 20),
                  _buildHealthMetrics(),
                ],
              ),
            ),
    );
  }

  Widget _buildRiskLevelCard() {
    Color riskColor;
    IconData riskIcon;
    String riskMessage;

    switch (_riskLevel) {
      case 'critical':
        riskColor = Colors.red;
        riskIcon = Icons.error;
        riskMessage = 'Critical health risk detected. Please consult your healthcare provider immediately.';
        break;
      case 'high':
        riskColor = Colors.orange;
        riskIcon = Icons.warning;
        riskMessage = 'High health risk detected. Consider consulting your healthcare provider.';
        break;
      case 'moderate':
        riskColor = Colors.blue;
        riskIcon = Icons.info;
        riskMessage = 'Moderate health risk detected. Monitor your health closely.';
        break;
      default:
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
        riskMessage = 'Low health risk. Keep up the good work!';
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(riskIcon, size: 32, color: riskColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Risk Level',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                      Text(
                        _riskLevel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              riskMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTrendsChart() {
    final glucoseData = widget.recentData
        .where((d) => d.glucoseLevel != null)
        .toList();

    if (glucoseData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('No glucose data available for trend analysis'),
          ),
        ),
      );
    }

    // Calculate trend direction
    final firstGlucose = glucoseData.first.glucoseLevel!;
    final lastGlucose = glucoseData.last.glucoseLevel!;
    final trendDirection = lastGlucose > firstGlucose ? 'Increasing' : 
                          lastGlucose < firstGlucose ? 'Decreasing' : 'Stable';
    final trendIcon = lastGlucose > firstGlucose ? Icons.trending_up : 
                     lastGlucose < firstGlucose ? Icons.trending_down : Icons.trending_flat;
    final trendColor = lastGlucose > firstGlucose ? Colors.red : 
                      lastGlucose < firstGlucose ? Colors.green : Colors.blue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Glucose Trends (Last 7 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(trendIcon, size: 48, color: trendColor),
                  const SizedBox(height: 16),
                  Text(
                    trendDirection,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'From ${firstGlucose.toStringAsFixed(0)} to ${lastGlucose.toStringAsFixed(0)} mg/dL',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${glucoseData.length} readings analyzed',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomaliesSummary() {
    if (_anomalies.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 48, color: Colors.green),
                SizedBox(height: 12),
                Text(
                  'No health anomalies detected',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Anomalies Detected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._anomalies.map((anomaly) => _buildAnomalyItem(anomaly)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyItem(Anomaly anomaly) {
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(severityIcon, color: severityColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anomaly.description,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${anomaly.anomalyType.replaceAll('_', ' ').toUpperCase()} • ${_formatDateTime(anomaly.detectedAt)}',
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

  Widget _buildHealthMetrics() {
    final glucoseReadings = widget.recentData.where((d) => d.glucoseLevel != null).map((d) => d.glucoseLevel!).toList();
    final activityData = widget.recentData.where((d) => d.steps != null).map((d) => d.steps!).toList();
    final sleepData = widget.recentData.where((d) => d.sleepHours != null).map((d) => d.sleepHours!).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Metrics Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Glucose',
                    glucoseReadings.isNotEmpty ? '${glucoseReadings.reduce((a, b) => a + b) / glucoseReadings.length}' : 'N/A',
                    'mg/dL',
                    Icons.bloodtype,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Activity',
                    activityData.isNotEmpty ? '${activityData.reduce((a, b) => a + b) / activityData.length}' : 'N/A',
                    'steps/day',
                    Icons.directions_walk,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Sleep',
                    sleepData.isNotEmpty ? '${sleepData.reduce((a, b) => a + b) / sleepData.length}' : 'N/A',
                    'hours/night',
                    Icons.bedtime,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Data Points',
                    '${widget.recentData.length}',
                    'records',
                    Icons.analytics,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
