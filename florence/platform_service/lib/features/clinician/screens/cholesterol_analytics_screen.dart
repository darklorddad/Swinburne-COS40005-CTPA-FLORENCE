import 'package:flutter/material.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class CholesterolAnalyticsScreen extends StatefulWidget {
  final Patient patient;
  final List<CholesterolReading> readings;

  const CholesterolAnalyticsScreen({
    super.key,
    required this.patient,
    required this.readings,
  });

  @override
  State<CholesterolAnalyticsScreen> createState() => _CholesterolAnalyticsScreenState();
}

class _CholesterolAnalyticsScreenState extends State<CholesterolAnalyticsScreen> {
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cholesterol Analytics'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOverviewSection(),
            _buildBreakdownSection(),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final latest = widget.readings.isNotEmpty ? widget.readings.last : null;
    double ratio = 0;
    if (latest != null && latest.hdl > 0) {
      ratio = latest.total / latest.hdl;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monitor_heart_outlined, color: AppTheme.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text('Cholesterol Ratio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  ),
                  Icon(Icons.info_outline, size: 20, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 20),
              // Target Ranges Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lowRiskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.lowRiskColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target Ranges', style: TextStyle(color: AppTheme.lowRiskColor, fontWeight: FontWeight.bold)),
                        Icon(Icons.check_circle_outline, color: AppTheme.lowRiskColor, size: 16),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTargetRow('Total', '100 - 200 mg/dL'),
                    _buildTargetRow('LDL', '0 - 100 mg/dL'),
                    _buildTargetRow('HDL', '40 - 100 mg/dL'),
                    _buildTargetRow('Triglycerides', '0 - 150 mg/dL'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Ratio Chart
              Center(
                child: SizedBox(
                  height: 150,
                  width: 150,
                  child: CustomPaint(
                    painter: _RatioPainter(ratio: ratio),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Ratio', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            ratio.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.lowRiskColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ratio < 5 ? 'Excellent' : 'High',
                              style: TextStyle(
                                fontSize: 10,
                                color: ratio < 5 ? AppTheme.lowRiskColor : AppTheme.highRiskColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('HDL (Good)', AppTheme.lowRiskColor),
                  const SizedBox(width: 16),
                  _buildLegendItem('Non-HDL', AppTheme.highRiskColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.lowRiskColor.withValues(alpha: 0.8), fontSize: 13)),
          Text(value, style: const TextStyle(color: AppTheme.lowRiskColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBreakdownSection() {
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
                  Icon(Icons.bar_chart, color: AppTheme.textSecondary, size: 20),
                  SizedBox(width: 8),
                  Text('Cholesterol Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ],
              ),
              const SizedBox(height: 20),
              const SizedBox(
                height: 200,
                child: Center(child: Text('Breakdown Chart (Coming Soon)', style: TextStyle(color: AppTheme.textSecondary))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final sortedReadings = List<CholesterolReading>.from(widget.readings)
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
          // Header
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
                final isHigh = r.total >= 240;
                final status = isHigh ? 'HIGH' : (r.total >= 200 ? 'BORDERLINE' : 'DESIRABLE');
                final color = isHigh ? AppTheme.highRiskColor : (r.total >= 200 ? AppTheme.mediumRiskColor : AppTheme.lowRiskColor);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                r.total.toInt().toString(),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Text('Total mg/dL', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yy HH:mm').format(r.timestamp),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailColumn('LDL', r.ldl.toInt().toString(), 'mg/dL', AppTheme.highRiskColor),
                          _buildDetailColumn('HDL', r.hdl.toInt().toString(), 'mg/dL', AppTheme.lowRiskColor),
                          _buildDetailColumn('Triglycerides', r.triglycerides.toInt().toString(), 'mg/dL', Colors.orange),
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

  Widget _buildDetailColumn(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(width: 2),
            Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

class _RatioPainter extends CustomPainter {
  final double ratio;

  _RatioPainter({required this.ratio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final strokeWidth = 20.0;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.grey.withValues(alpha: 0.1);

    canvas.drawCircle(center, radius, bgPaint);

    // Draw HDL segment (Good) - Green
    // Ratio implies Total/HDL. The "good" part is HDL.
    // Visualizing ratio isn't direct pie chart.
    // Let's just draw two segments based on an arbitrary "good" vs "bad" proportion for visual effect matching the image.
    // Image shows ~60% Red, 40% Green.
    // Let's assume Green is 1/Ratio portion? No.
    // I'll just draw a static representation or based on (HDL / Total) * 360 degrees.
    
    // HDL %
    double hdlPct = 0.3; // Default fallback
    if (ratio > 0) {
      hdlPct = 1 / ratio; // HDL / Total
    }
    
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final hdlPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppTheme.lowRiskColor
      ..strokeCap = StrokeCap.round;

    final nonHdlPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppTheme.highRiskColor
      ..strokeCap = StrokeCap.round;

    // Draw Non-HDL (Red)
    canvas.drawArc(rect, -pi / 2, 2 * pi * (1 - hdlPct), false, nonHdlPaint);
    
    // Draw HDL (Green)
    canvas.drawArc(rect, -pi / 2 + (2 * pi * (1 - hdlPct)), 2 * pi * hdlPct, false, hdlPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

