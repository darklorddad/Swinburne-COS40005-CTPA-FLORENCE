import 'package:flutter/material.dart';
import 'package:florence/features/clinician/models/alert.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AlertItem extends StatelessWidget {
  final Alert alert;
  final VoidCallback onTap;

  const AlertItem({
    super.key,
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      color: _getAlertColor(alert.type).withValues(alpha: 0.1), // Filled in background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getAlertColor(alert.type).withValues(alpha: 0.4), // Stronger outline
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with patient name and timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _getAlertColor(alert.type).withValues(alpha: 0.5)),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: _getAlertColor(alert.type),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        alert.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatTimestamp(alert.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Alert type chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getAlertColor(alert.type),
                    width: 1,
                  ),
                ),
                child: Text(
                  alert.typeDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    color: _getAlertColor(alert.type),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Alert description
              Text(
                alert.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppTheme.textPrimary,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // View details link
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward_ios, size: 14),
                    label: const Text('View Details'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      foregroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }

  Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.highGlucose:
      case AlertType.highHbA1c:
      case AlertType.highBloodPressure:
        return AppTheme.highRiskColor;
      case AlertType.lowGlucose:
        return AppTheme.primaryColor;
      case AlertType.lowPhysicalActivity:
      case AlertType.missedMedication:
        return AppTheme.mediumRiskColor;
      case AlertType.irregularSleepPattern:
        return AppTheme.primaryColor;
    }
  }
}
