import 'package:flutter/material.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:intl/intl.dart';

class HbA1cAnalyticsScreen extends StatefulWidget {
  final Patient patient;
  final List<HbA1cReading> readings;

  const HbA1cAnalyticsScreen({
    super.key,
    required this.patient,
    required this.readings,
  });

  @override
  State<HbA1cAnalyticsScreen> createState() => _HbA1cAnalyticsScreenState();
}

class _HbA1cAnalyticsScreenState extends State<HbA1cAnalyticsScreen> {
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HbA1c Analytics'),
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
    final latest = widget.readings.isNotEmpty ? widget.readings.last.value : 0.0;
    const target = 6.0;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.track_changes_outlined, color: AppTheme.textSecondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Actual vs. Goal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar('You', latest, latest <= target ? AppTheme.lowRiskColor : AppTheme.highRiskColor),
                  _buildBar('Target', target, AppTheme.secondaryColor.withValues(alpha: 0.5)),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (latest <= target ? AppTheme.lowRiskColor : AppTheme.highRiskColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (latest <= target ? AppTheme.lowRiskColor : AppTheme.highRiskColor).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      latest <= target ? Icons.check_circle : Icons.warning,
                      color: latest <= target ? AppTheme.lowRiskColor : AppTheme.highRiskColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        latest <= target 
                            ? 'You are within your target of <$target%'
                            : 'You are above your target of <$target%',
                        style: TextStyle(
                          color: latest <= target ? AppTheme.lowRiskColor : AppTheme.highRiskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, double value, Color color) {
    return Column(
      children: [
        Text('${value.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: value * 20, // Scale factor
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTrendsSection() {
    // Placeholder for trends chart
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bar_chart_rounded, size: 40, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
                const Text(
                  'HbA1c Trends',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chart visualization coming soon',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final sortedReadings = List<HbA1cReading>.from(widget.readings)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    final totalPages = (sortedReadings.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages) _currentPage = totalPages > 0 ? totalPages - 1 : 0;

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < sortedReadings.length) ? startIndex + _itemsPerPage : sortedReadings.length;
    final pageItems = sortedReadings.sublist(startIndex, endIndex);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                final status = r.value < 5.7 ? 'NORMAL' : (r.value < 6.5 ? 'PRE-DIABETES' : 'DIABETES');
                final color = r.value < 5.7 ? AppTheme.lowRiskColor : (r.value < 6.5 ? AppTheme.accentColor : AppTheme.highRiskColor);

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
                            r.value.toStringAsFixed(1),
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
                              '%',
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
}
