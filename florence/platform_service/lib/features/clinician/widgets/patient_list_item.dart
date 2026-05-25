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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: riskColor.withValues(alpha: 0.15), // Filled in background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: riskColor.withValues(alpha: 0.5), // Stronger outline
          width: 1.5,
        ),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Patient Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: riskColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
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
                    Text(
                      patient.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      patient.age > 0 
                          ? 'ID: ${patient.id} • ${patient.age} yrs • ${patient.gender}'
                          : 'ID: ${patient.id}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient.activeDiseasesText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Right side info (Edit action and Last Update)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded,
                        color: AppTheme.primaryColor, size: 26),
                    tooltip: 'View & Edit Details',
                    onPressed: onTap,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Last Update',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  Text(
                    _formatLastUpdate(patient.lastUpdate),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
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

  String _formatLastUpdate(DateTime? lastUpdate) {
    if (lastUpdate == null) return 'No data';
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(lastUpdate);
    }
  }
}
