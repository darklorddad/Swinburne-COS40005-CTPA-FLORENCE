import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // Wide screen layout (e.g., web browser)
            return _buildWideLayout();
          } else {
            // Narrow screen layout (e.g., mobile)
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  // The layout for wide screens, using a Row with two columns
  Widget _buildWideLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const ProfileHeader(),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                flex: 2, // Takes 2/3 of the space
                child: Column(
                  children: const [
                    PatientProfileCard(),
                    SizedBox(height: 24),
                    HealthProfileCard(),
                    SizedBox(height: 24),
                    SettingsCard(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right Column
              Expanded(
                flex:
                    3, // Takes 3/3 of the space (a typo in the comment, should be 1/3 but flex 3 is larger) - Let's make it more balanced
                // Correcting the flex ratio to be more like 50/50 or 40/60
                // For this design, let's try flex: 3 and flex: 2
                child: Column(
                  children: const [
                    CurrentMedicationsCard(),
                    SizedBox(height: 24),
                    VitalsCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // The layout for narrow screens, stacking all cards in a single column
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: const [
          ProfileHeader(),
          SizedBox(height: 24),
          PatientProfileCard(),
          SizedBox(height: 16),
          CurrentMedicationsCard(),
          SizedBox(height: 16),
          HealthProfileCard(),
          SizedBox(height: 16),
          VitalsCard(),
          SizedBox(height: 16),
          SettingsCard(),
        ],
      ),
    );
  }
}

// ---- Reusable and Specific Widgets ---- //

// The central avatar, name, and email
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.black87,
          child: Icon(
            Icons.person,
            size: 60,
            color: Colors.white,
          ), // Placeholder icon
        ),
        const SizedBox(height: 16),
        const Text(
          'Thomas Anderson',
          style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'thomas.anderson@gmail.com',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }
}

// Generic card widget to reduce code repetition
class InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const InfoCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}

// Specific card for Patient Profile details
class PatientProfileCard extends StatelessWidget {
  const PatientProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'PATIENT PROFILE',
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () {},
      ),
      child: Column(
        children: const [
          _InfoRow(label: 'Date of Birth', value: '17/8/1997'),
          _InfoRow(label: 'Gender', value: 'Male'),
          _InfoRow(label: 'Phone Number', value: '+60123456789'),
        ],
      ),
    );
  }
}

// Specific card for Health Profile details
class HealthProfileCard extends StatelessWidget {
  const HealthProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'HEALTH PROFILE',
      child: Column(
        children: const [
          _InfoRow(label: 'Diabetes Type', value: 'Type 2'),
          _InfoRow(label: 'Target Glucose Range', value: '4.0-10.0 mmol/L'),
        ],
      ),
    );
  }
}

// Specific card for Settings
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'SETTINGS',
      child: Column(
        children: const [
          _InfoRow(label: 'Units', value: 'Metric'),
          _InfoRow(label: 'Appearance', value: 'Light'),
        ],
      ),
    );
  }
}

// Specific card for Current Medications
class CurrentMedicationsCard extends StatelessWidget {
  const CurrentMedicationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'CURRENT MEDICATIONS',
      child: Column(
        children: [
          _MedicationRow(
            name: 'Metformin (500mg Tablet)',
            status: 'Taken at 8:15am',
            isTaken: true,
          ),
          _MedicationRow(
            name: 'Lantus Insulin (10 units)',
            status: '[Log as taken]',
            isTaken: false,
          ),
          _MedicationRow(
            name: 'Thiazide (150mg Tablet)',
            status: '[Log as taken]',
            isTaken: false,
          ),
        ],
      ),
    );
  }
}

// Specific card for Vitals
class VitalsCard extends StatelessWidget {
  const VitalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'VITALS',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _VitalInfo(
            icon: Icons.favorite_border,
            label: 'Blood Pressure',
            value: '120/79',
          ),
          _VitalInfo(icon: Icons.show_chart, label: 'HbA1c (%)', value: '8.0'),
        ],
      ),
    );
  }
}

// ---- Helper Widgets ---- //

// A reusable row for label-value pairs
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[800])),
          Text(value, style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// A reusable row for the medication list
class _MedicationRow extends StatelessWidget {
  final String name;
  final String status;
  final bool isTaken;
  const _MedicationRow({
    required this.name,
    required this.status,
    required this.isTaken,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.link, color: Colors.grey[800], size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          TextButton(
            onPressed: isTaken ? null : () {},
            child: Text(
              status,
              style: TextStyle(
                color:
                    isTaken ? Colors.grey[800] : Theme.of(context).primaryColor,
                fontStyle: isTaken ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A reusable widget for a single vital sign
class _VitalInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _VitalInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.black87),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[800])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.grey, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}