import 'package:flutter/material.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:intl/intl.dart';

class PatientListItem extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const PatientListItem({
    super.key,
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor = AppTheme.getRiskColor(patient.riskLevel.name);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: riskColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Patient Avatar placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Patient info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Risk Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            patient.riskLevel.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${patient.id} • ${patient.age} yrs • ${patient.gender}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient.conditionName,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Last update info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Last Update',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    _formatLastUpdate(patient.lastSync),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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

  String _formatLastUpdate(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(lastSync);
    }
  }
}
