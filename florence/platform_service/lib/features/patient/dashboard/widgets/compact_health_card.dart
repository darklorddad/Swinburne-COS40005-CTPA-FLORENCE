import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';

class CompactHealthCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String status;
  final DateTime? timestamp;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double? height;
  final String? subtitleOverride;

  const CompactHealthCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    this.timestamp,
    required this.icon,
    required this.color,
    this.onTap,
    this.height,
    this.subtitleOverride,
  });

  @override
  Widget build(BuildContext context) {
    const double borderRadius = 16.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode, use a much darker version of the color (lower opacity or mixed with black)
    final bgColors = isDark
        ? [
            color.withOpacity(0.15), // Very subtle in dark mode
            color.withOpacity(0.05),
          ]
        : [
            color,
            Helpers.darken(color, 0.1),
          ];

    final textColor = isDark ? color.withOpacity(0.9) : Colors.white.withOpacity(0.9);
    final valueColor = isDark ? Colors.white : Colors.white;
    final shadowColor = isDark ? Colors.transparent : color.withOpacity(0.2);

    Widget content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          // Optional: Add border in dark mode for definition
          border: isDark ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeader(context, textColor, isDark),
            const SizedBox(height: 12),
            _buildValue(context, valueColor, textColor),
          ],
        ),
      ),
    );

    if (height != null) {
      return SizedBox(height: height, child: content);
    }

    return content;
  }

  Widget _buildHeader(BuildContext context, Color textColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontWeight: isDark ? FontWeight.bold : FontWeight.normal,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.2) : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(100),
            border: isDark ? Border.all(color: color.withOpacity(0.5)) : null,
          ),
          child: Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? color : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildValue(BuildContext context, Color valueColor, Color unitColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 4),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: unitColor,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitleOverride ?? (timestamp != null 
              ? 'Last updated: ${Formatters.timeAgo(timestamp!)}'
              : 'No history'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: unitColor.withOpacity(0.7),
              ),
        ),
      ],
    );
  }
}
