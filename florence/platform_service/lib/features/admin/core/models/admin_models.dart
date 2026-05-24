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
  });

  bool get isHighRisk => riskLevel.toUpperCase() == 'HIGH';
  bool get isMediumRisk => riskLevel.toUpperCase() == 'MEDIUM';

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
    );
  }
}

@immutable
class AdminMetrics {
  final int totalPatients;
  final int highRiskPatients;
  final int activeClinicians;
  final int connectedDevices;

  const AdminMetrics({
    required this.totalPatients,
    required this.highRiskPatients,
    required this.activeClinicians,
    required this.connectedDevices,
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