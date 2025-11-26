import 'dart:math';
import 'package:flutter/material.dart';
import 'package:clinician_dashboard/theme/app_theme.dart';

class BMIGauge extends StatelessWidget {
  final double bmi;
  final double weight;
  final double height;
  final bool isMetric;
  final ValueChanged<bool>? onUnitChanged;

  const BMIGauge({
    super.key,
    required this.bmi,
    required this.weight,
    required this.height,
    this.isMetric = true,
    this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          width: 300,
          child: CustomPaint(
            painter: _GaugePainter(bmi: bmi),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          bmi.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          _getBMICategory(bmi),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _getBMIColor(bmi),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInfoChip('Weight', _formatWeight(weight)),
            const SizedBox(width: 24),
            _buildInfoChip('Height', _formatHeight(height)),
          ],
        ),
        if (onUnitChanged != null) ...[
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Metric')),
              ButtonSegment(value: false, label: Text('Imperial')),
            ],
            selected: {isMetric},
            onSelectionChanged: (s) => onUnitChanged!(s.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.primaryColor;
                  }
                  return Colors.transparent;
                },
              ),
              foregroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return AppTheme.textPrimary;
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatWeight(double weightKg) {
    if (isMetric) {
      return '${weightKg.toStringAsFixed(1)} kg';
    }
    final lbs = weightKg * 2.20462;
    return '${lbs.toStringAsFixed(1)} lbs';
  }

  String _formatHeight(double heightCm) {
    if (isMetric) {
      return '${heightCm.toStringAsFixed(0)} cm';
    }
    final totalInches = heightCm / 2.54;
    final ft = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return '$ft\' $inches"';
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    if (bmi < 40) return 'Obese';
    return 'Severely Obese';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.amber;
    if (bmi < 40) return Colors.orange;
    return Colors.red;
  }
}

class _GaugePainter extends CustomPainter {
  final double bmi;

  _GaugePainter({required this.bmi});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2, size.height) - 10;
    final strokeWidth = 40.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw segments
    _drawSegment(canvas, rect, 180, 36, Colors.blue);   // Underweight
    _drawSegment(canvas, rect, 216, 36, Colors.green);  // Normal
    _drawSegment(canvas, rect, 252, 36, Colors.amber);  // Overweight
    _drawSegment(canvas, rect, 288, 36, Colors.orange); // Obese
    _drawSegment(canvas, rect, 324, 36, Colors.red);    // Severely Obese

    // Draw needle
    _drawNeedle(canvas, center, radius, strokeWidth);
  }

  void _drawSegment(Canvas canvas, Rect rect, double startAngleDeg, double sweepAngleDeg, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.butt;

    // Add small gap
    final gap = 2.0; // degrees
    canvas.drawArc(
      rect,
      _degToRad(startAngleDeg + gap/2),
      _degToRad(sweepAngleDeg - gap),
      false,
      paint,
    );
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius, double strokeWidth) {
    // Map BMI to angle
    // Range 10 to 50 maps to 180 to 360 degrees
    double clampedBMI = bmi.clamp(10.0, 50.0);
    double t = (clampedBMI - 10) / (50 - 10); // Normalized 0..1
    double angle = 180 + (t * 180);

    final needleLength = radius - strokeWidth - 10;
    final needlePaint = Paint()
      ..color = AppTheme.textPrimary
      ..style = PaintingStyle.fill;

    final angleRad = _degToRad(angle);
    
    // Needle tip
    final tipX = center.dx + needleLength * cos(angleRad);
    final tipY = center.dy + needleLength * sin(angleRad);

    // Base width
    final baseWidth = 10.0;
    final baseAngleL = angleRad - pi / 2;
    final baseAngleR = angleRad + pi / 2;

    final baseX1 = center.dx + baseWidth * cos(baseAngleL);
    final baseY1 = center.dy + baseWidth * sin(baseAngleL);
    final baseX2 = center.dx + baseWidth * cos(baseAngleR);
    final baseY2 = center.dy + baseWidth * sin(baseAngleR);

    final path = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(baseX1, baseY1)
      ..lineTo(baseX2, baseY2)
      ..close();

    canvas.drawPath(path, needlePaint);
    
    // Center circle
    canvas.drawCircle(center, 8, needlePaint);
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  double _degToRad(double deg) => deg * (pi / 180);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

