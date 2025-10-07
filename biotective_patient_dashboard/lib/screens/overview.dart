// lib/screens/overview_screen.dart

import 'package:flutter/material.dart';

// --- Main Screen Widget --- //

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, this would be a shared 'Scaffold' widget to avoid repetition.
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1100) { // Using a wider breakpoint for this layout
            return _buildWideLayout();
          } else {
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  // --- Layouts for Wide and Narrow Screens --- //

  // Layout for wide screens (web) with a two-column design
  Widget _buildWideLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Welcome back, Tom!", style: TextStyle(fontSize: 28, color: Colors.black, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const SummaryCardsGrid(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Main Chart)
              const Expanded(
                flex: 3,
                child: GlucoseChartCard(),
              ),
              const SizedBox(width: 24),
              // Right Column (Medications and Insights)
              Expanded(
                flex: 2,
                child: Column(
                  children: const [
                    MedicationsCard(),
                    SizedBox(height: 24),
                    InsightsCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Layout for narrow screens (mobile) with a single, scrollable column
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Welcome back, Tom!", style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          SummaryCardsGrid(),
          SizedBox(height: 16),
          GlucoseChartCard(),
          SizedBox(height: 16),
          MedicationsCard(),
          SizedBox(height: 16),
          InsightsCard(),
        ],
      ),
    );
  }
}

// --- Specific Dashboard Widgets --- //

// A grid of the 4 summary cards
class SummaryCardsGrid extends StatelessWidget {
  const SummaryCardsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // GridView is great for responsive grids. It adapts the number of columns.
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2, // 4 cards on web, 2 on mobile
      shrinkWrap: true, // Important for nesting in a ScrollView
      physics: const NeverScrollableScrollPhysics(), // Disables GridView's own scrolling
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5, // Adjust aspect ratio for card shape
      children: const [
        _SummaryCard(
          title: 'Avg. Glucose',
          value: '11.2',
          unit: 'mmol/L',
          icon: Icons.bloodtype,
          color: Colors.red,
        ),
        _SummaryCard(
          title: 'HbA1c Reading',
          value: '8.0',
          unit: '%',
          icon: Icons.show_chart,
          color: Colors.orange,
        ),
        _SummaryCard(
          title: 'Weekly Activity',
          value: '120/150',
          unit: 'mins',
          icon: Icons.directions_walk,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'Glucose Spikes',
          value: '3',
          unit: 'this week',
          icon: Icons.trending_up,
          color: Colors.purple,
        ),
      ],
    );
  }
}

// The main Glucose Trend Chart Card
class GlucoseChartCard extends StatelessWidget {
  const GlucoseChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Weekly Glucose Trend',
      titleStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Colors.black,
      ),
      child: Container(
        height: 300, // Fixed height for the chart area
        alignment: Alignment.center,
        // In a real app, you would replace this with a charting library
        // like 'fl_chart' or 'charts_flutter'
        child: const Text(
          '[ Interactive Line Chart Placeholder ]',
          style: TextStyle(color: Colors.grey, fontSize: 18),
        ),
      ),
    );
  }
}

// The "Today's Medications" Card
class MedicationsCard extends StatelessWidget {
  const MedicationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: "Today's Medications",
      titleStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Colors.black,
      ),
      child: Column(
        children: [
          _MedicationRow(
            name: 'Metformin (500mg Tablet)',
            instruction: 'With Breakfast',
            isTaken: true,
          ),
          _MedicationRow(
            name: 'Lantus Insulin (10 units)',
            instruction: 'Once daily before bed',
            isTaken: false,
          ),
        ],
      ),
    );
  }
}

// The AI-Powered Insights Card
class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Your Weekly Insight ✨',
      titleStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Colors.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "We've noticed your glucose often spikes after dinner. Consider a 15-minute walk afterwards to help manage it.",
            style: TextStyle(color: Colors.black, height: 1.5), // Improved line spacing
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: const Text('Why this suggestion?'),
          ),
        ],
      ),
    );
  }
}

// --- Reusable Helper Widgets --- //

// A single summary card for the top grid
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text(unit, style: const TextStyle(fontSize: 12, color: Colors.black)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// A generic card widget, similar to the one in ProfileScreen
class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final TextStyle? titleStyle;

  const _InfoCard({
    required this.title,
    required this.child,
    this.titleStyle
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}

// A reusable row for the medication list
class _MedicationRow extends StatelessWidget {
  final String name;
  final String instruction;
  final bool isTaken;

  const _MedicationRow({
    required this.name,
    required this.instruction,
    required this.isTaken,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(isTaken ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isTaken ? Colors.green : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                Text(instruction, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isTaken ? null : () {},
            child: Text(isTaken ? 'Taken' : 'Log as Taken'),
          ),
        ],
      ),
    );
  }
}