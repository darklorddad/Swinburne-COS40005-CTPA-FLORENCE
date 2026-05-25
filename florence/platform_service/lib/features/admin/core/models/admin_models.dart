import 'package:flutter/foundation.dart';

@immutable
class AdminPatient {
  final int id;
  final String name;
  final String? phoneNumber;
  final String? gender;
  final String? dateOfBirth;
  final String? organisationName;
  final String? clinicianName;
  final String riskLevel;
  final String? lastRiskAssessment;
  final String? latestAlert;

  const AdminPatient({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.organisationName,
    this.clinicianName,
    required this.riskLevel,
    this.lastRiskAssessment,
    this.latestAlert,
  });

  bool get isHighRisk => riskLevel.toUpperCase() == 'HIGH';
  bool get isMediumRisk => riskLevel.toUpperCase() == 'MEDIUM';

  // New getters for our alerts
  bool get isHypo => latestAlert?.toLowerCase().contains('hypo') ?? false;
  bool get isHyper => latestAlert?.toLowerCase().contains('hyper') ?? false;

  // Determines if they show up in the Action Feed
  bool get requiresAttention => isHighRisk || isHypo || isHyper;

  factory AdminPatient.fromJson(Map<String, dynamic> json) {
    return AdminPatient(
      id: json['id'] as int,
      name: json['Name'] ?? 'Unknown',
      phoneNumber: json['Phone Number'],
      gender: json['Gender'],
      dateOfBirth: json['Date of Birth'],
      organisationName: json['Organisation Name'],
      clinicianName: json['Clinician Name'] ?? 'Unassigned',
      riskLevel: json['Risk Level'] ?? 'LOW',
      lastRiskAssessment: json['Last Risk Assessment'],
      latestAlert: json['Latest Alert'],
    );
  }
}

@immutable
class AdminMetrics {
  final int totalPatients;
  final int highRiskPatients;
  final int hypoPatients;
  final int hyperPatients;

  const AdminMetrics({
    required this.totalPatients,
    required this.highRiskPatients,
    required this.hypoPatients,
    required this.hyperPatients,
  });
}

@immutable
class AdminActivity {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String iconType;

  const AdminActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.iconType,
  });

  factory AdminActivity.fromJson(Map<String, dynamic> json) {
    return AdminActivity(
      id: json['id'] ?? '',
      title: json['title'] ?? 'System Event',
      subtitle: json['subtitle'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      iconType: json['icon_type'] ?? 'update',
    );
  }
}