import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../theme/app_theme.dart';
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with patient name and timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    alert.patientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatTimestamp(alert.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Alert type chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getAlertColor(alert.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getAlertColor(alert.type).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  alert.typeDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getAlertColor(alert.type),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Alert description
              Text(
                alert.description,
                style: const TextStyle(fontSize: 14),
              ),
              
              const SizedBox(height: 8),
              
              // View details link
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        return Colors.blue;
      case AlertType.lowPhysicalActivity:
      case AlertType.missedMedication:
        return AppTheme.mediumRiskColor;
      case AlertType.irregularSleepPattern:
        return Colors.blue;
    }
  }
}
