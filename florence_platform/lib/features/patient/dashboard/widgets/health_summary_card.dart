import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../config/theme.dart';

/// Health Summary Card (Hero Card)
/// Displays the latest glucose reading with visual indicator
class HealthSummaryCard extends StatelessWidget {
  final double latestGlucose;
  final DateTime timestamp;
  final VoidCallback? onTap;
  
  const HealthSummaryCard({
    super.key,
    required this.latestGlucose,
    required this.timestamp,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final glucoseColor = _getGlucoseColor(latestGlucose);
    final glucoseStatus = _getGlucoseStatus(latestGlucose);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              glucoseColor,
              glucoseColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: glucoseColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Glucose',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    glucoseStatus,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Glucose value
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  latestGlucose.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 56,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  'mg/dL',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Timestamp
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  Formatters.timeAgo(timestamp),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action hint
            Row(
              children: [
                Text(
                  'View trends',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Get glucose color based on value
  Color _getGlucoseColor(double value) {
    if (value < 70) {
      return AppTheme.glucoseLow;
    } else if (value > 180) {
      return AppTheme.glucoseHigh;
    } else {
      return AppTheme.glucoseNormal;
    }
  }
  
  /// Get glucose status text
  String _getGlucoseStatus(double value) {
    if (value < 70) {
      return 'Low';
    } else if (value > 180) {
      return 'High';
    } else {
      return 'Normal';
    }
  }
}