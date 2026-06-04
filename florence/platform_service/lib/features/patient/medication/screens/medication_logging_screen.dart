import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/features/patient/dashboard/widgets/medication_section.dart';

class MedicationLoggingScreen extends ConsumerWidget {
  const MedicationLoggingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Medication'),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.getBorderColor(context),
            height: 1.0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Helpers.showInfo(context, 'Medication history coming soon');
              },
              tooltip: 'View History',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reusing the refactored section
                    MedicationLoggingSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
