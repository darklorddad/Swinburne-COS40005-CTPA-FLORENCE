import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../theme/app_theme.dart';


class RiskIndicator extends StatelessWidget {
  final RiskLevel riskLevel;
  final double size;

  const RiskIndicator({
    super.key,
    required this.riskLevel,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String tooltip;

    switch (riskLevel) {
      case RiskLevel.high:
        color = AppTheme.highRiskColor;
        tooltip = 'High Risk';
        break;
      case RiskLevel.medium:
        color = AppTheme.mediumRiskColor;
        tooltip = 'Medium Risk';
        break;
      case RiskLevel.low:
        color = AppTheme.lowRiskColor;
        tooltip = 'Low Risk';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 1,
            )
          ],
        ),
      ),
    );
  }
}
