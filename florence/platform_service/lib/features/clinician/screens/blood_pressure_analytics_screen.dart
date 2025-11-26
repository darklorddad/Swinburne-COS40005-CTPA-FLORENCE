import 'package:flutter/material.dart';
import 'package:clinician_dashboard/models/health_data.dart';
import 'package:clinician_dashboard/models/patient.dart';
import 'package:clinician_dashboard/theme/app_theme.dart';
import 'package:intl/intl.dart';

class BloodPressureAnalyticsScreen extends StatefulWidget {
  final Patient patient;
  final List<BloodPressureReading> readings;

  const BloodPressureAnalyticsScreen({
    super.key,
    required this.patient,
    required this.readings,
  });

  @override
  State<BloodPressureAnalyticsScreen> createState() => _BloodPressureAnalyticsScreenState();
}

class _BloodPressureAnalyticsScreenState extends State<BloodPressureAnalyticsScreen> {
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure Analytics'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOverviewSection(),
            _buildTrendsSection(),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Target Ranges
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lowRiskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Target Ranges', style: TextStyle(color: AppTheme.lowRiskColor, fontWeight: FontWeight.bold)),
                        Icon(Icons.chevron_right, color: AppTheme.lowRiskColor, size: 16),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTargetRow('Systolic', '90 - 120 mmHg'),
                    const SizedBox(height: 4),
                    _buildTargetRow('Diastolic', '60 - 80 mmHg'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Averages
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAvgCard('Avg Systolic', '${_calculateAvgSystolic().toInt()} mmHg'),
                  _buildAvgCard('Avg Diastolic', '${_calculateAvgDiastolic().toInt()} mmHg'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.lowRiskColor.withValues(alpha: 0.8), fontSize: 13)),
        Text(value, style: const TextStyle(color: AppTheme.lowRiskColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildAvgCard(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: const [
                Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Blood Pressure Trends Chart (Coming Soon)', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final sortedReadings = List<BloodPressureReading>.from(widget.readings)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    final totalPages = (sortedReadings.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages) _currentPage = totalPages > 0 ? totalPages - 1 : 0;

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < sortedReadings.length) ? startIndex + _itemsPerPage : sortedReadings.length;
    final pageItems = sortedReadings.sublist(startIndex, endIndex);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with Pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (totalPages > 1)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${_currentPage + 1}/$totalPages'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (pageItems.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: Text("No history available")))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pageItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final r = pageItems[index];
                
                String status = 'NORMAL';
                Color color = AppTheme.lowRiskColor;

                if (r.systolic > 120 || r.diastolic > 80) {
                  status = 'ELEVATED';
                  color = AppTheme.highRiskColor;
                } else if (r.systolic < 90 || r.diastolic < 60) {
                  status = 'LOW';
                  color = AppTheme.mediumRiskColor; // Yellow/Amber
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${r.systolic.toInt()}/${r.diastolic.toInt()}',
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              'mmHg',
                              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('dd/MM/yy HH:mm').format(r.timestamp),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  double _calculateAvgSystolic() {
    if (widget.readings.isEmpty) return 0;
    return widget.readings.fold(0.0, (sum, r) => sum + r.systolic) / widget.readings.length;
  }

  double _calculateAvgDiastolic() {
    if (widget.readings.isEmpty) return 0;
    return widget.readings.fold(0.0, (sum, r) => sum + r.diastolic) / widget.readings.length;
  }
}

