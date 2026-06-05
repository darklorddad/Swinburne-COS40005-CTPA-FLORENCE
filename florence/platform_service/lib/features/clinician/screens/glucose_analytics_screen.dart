import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:florence/features/clinician/widgets/glucose_chart.dart';
import 'package:florence/features/patient/core/providers/settings_providers.dart';
import 'package:intl/intl.dart';

class GlucoseAnalyticsScreen extends ConsumerStatefulWidget {
  final Patient patient;
  final List<GlucoseReading> readings;
  final double lowThreshold;
  final double highThreshold;
  final String glucoseUnit;

  const GlucoseAnalyticsScreen({
    super.key,
    required this.patient,
    required this.readings,
    required this.lowThreshold,
    required this.highThreshold,
    required this.glucoseUnit,
  });

  @override
  ConsumerState<GlucoseAnalyticsScreen> createState() => _GlucoseAnalyticsScreenState();
}

class _GlucoseAnalyticsScreenState extends ConsumerState<GlucoseAnalyticsScreen> {
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glucose Analytics'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOverviewSection(),
            _buildDailyPatternsSection(),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    // Calculate Time in Range
    int low = 0;
    int range = 0;
    int high = 0;
    for (var r in widget.readings) {
      if (r.value < widget.lowThreshold) {
        low++;
      } else if (r.value > widget.highThreshold) {
        high++;
      } else {
        range++;
      }
    }
    final total = widget.readings.length;
    final lowPct = total > 0 ? (low / total * 100).round() : 0;
    final rangePct = total > 0 ? (range / total * 100).round() : 0;
    final highPct = total > 0 ? (high / total * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
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
                      Icon(Icons.timer_outlined, color: AppTheme.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Time in Range',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Simple visual bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        if (lowPct > 0) Expanded(flex: lowPct, child: Container(height: 20, color: AppTheme.secondaryColor)),
                        if (rangePct > 0) Expanded(flex: rangePct, child: Container(height: 20, color: AppTheme.lowRiskColor)),
                        if (highPct > 0) Expanded(flex: highPct, child: Container(height: 20, color: AppTheme.highRiskColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$lowPct% Low', style: const TextStyle(color: AppTheme.secondaryColor)),
                      Text('$rangePct% In Range', style: const TextStyle(color: AppTheme.lowRiskColor)),
                      Text('$highPct% High', style: const TextStyle(color: AppTheme.highRiskColor)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Average',
                widget.glucoseUnit == 'mmol/L'
                    ? '${_calculateAverage().toStringAsFixed(1)} mmol/L'
                    : '${_calculateAverage().toInt()} mg/dL',
                isUp: false,
                color: AppTheme.primaryColor,
              ),
              _buildStatCard('Variability', '12.5%', isUp: false, color: AppTheme.secondaryColor), // Mock calculation
              _buildStatCard('Readings', widget.readings.length.toString(), color: AppTheme.accentColor),
              _buildStatCard(
                'Lowest',
                widget.glucoseUnit == 'mmol/L'
                    ? '${_minGlucose().toStringAsFixed(1)} mmol/L'
                    : '${_minGlucose().toInt()} mg/dL',
                isUp: false,
                color: AppTheme.lowRiskColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPatternsSection() {
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up, color: AppTheme.textSecondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Glucose Trends',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: GlucoseChart(
                  readings: widget.readings,
                  unit: widget.glucoseUnit,
                  highThreshold: widget.highThreshold,
                  lowThreshold: widget.lowThreshold,
                  hbA1cReadings: const [], // Only glucose
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final sortedReadings = List<GlucoseReading>.from(widget.readings)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    final totalPages = (sortedReadings.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages) _currentPage = totalPages > 0 ? totalPages - 1 : 0;

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < sortedReadings.length) ? startIndex + _itemsPerPage : sortedReadings.length;
    final pageItems = sortedReadings.sublist(startIndex, endIndex);

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
          padding: const EdgeInsets.all(20),
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
                final color = r.value > widget.highThreshold ? AppTheme.highRiskColor : (r.value < widget.lowThreshold ? AppTheme.secondaryColor : AppTheme.lowRiskColor);
                final status = r.value > widget.highThreshold ? 'HIGH' : (r.value < widget.lowThreshold ? 'LOW' : 'NORMAL');

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.glucoseUnit == 'mmol/L'
                                ? r.value.toStringAsFixed(1)
                                : r.value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              widget.glucoseUnit,
                              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, {bool? isUp, Color? color}) {
    final bgColor = color?.withValues(alpha: 0.1) ?? Colors.white;
    final borderColor = color?.withValues(alpha: 0.3) ?? AppTheme.dividerColor;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              if (isUp != null)
                Icon(
                  isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: isUp ? AppTheme.highRiskColor : AppTheme.lowRiskColor,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value, 
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateAverage() {
    if (widget.readings.isEmpty) return 0;
    return widget.readings.fold(0.0, (sum, r) => sum + r.value) / widget.readings.length;
  }

  double _minGlucose() {
    if (widget.readings.isEmpty) return 0;
    return widget.readings.map((r) => r.value).reduce((a, b) => a < b ? a : b);
  }
}
