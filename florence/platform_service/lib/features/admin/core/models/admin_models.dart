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

@immutable
class AdminOrganization {
  final int id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? website;
  final String? sector;
  final String? facilityType;
  final String? fullAddress;
  final String? state;
  final bool is24Hours;
  final String? operatingHours;
  final int patientCount;
  final int clinicianCount;

  const AdminOrganization({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.website,
    this.sector,
    this.facilityType,
    this.fullAddress,
    this.state,
    this.is24Hours = false,
    this.operatingHours,
    this.patientCount = 0,
    this.clinicianCount = 0,
  });

  factory AdminOrganization.fromJson(Map<String, dynamic> json) {
    return AdminOrganization(
      id: json['id'] as int,
      name: json['name'] ?? 'Unnamed',
      phoneNumber: json['phone_number'],
      email: json['email'],
      website: json['website'],
      sector: json['sector'],
      facilityType: json['facility_type'],
      fullAddress: json['full_address'],
      state: json['state'],
      is24Hours: json['is_24_hours'] ?? false,
      operatingHours: json['operating_hours'],
      patientCount: json['patient_count'] ?? 0,
      clinicianCount: json['clinician_count'] ?? 0,
    );
  }
}

@immutable
class AdminClinician {
  final int id;
  final String userId;
  final String name;
  final String? phoneNumber;
  final String? gender;
  final int? organisationId;
  final String? organisationName;
  final int patientCount;

  const AdminClinician({
    required this.id,
    required this.userId,
    required this.name,
    this.phoneNumber,
    this.gender,
    this.organisationId,
    this.organisationName,
    this.patientCount = 0,
  });

  factory AdminClinician.fromJson(Map<String, dynamic> json) {
    return AdminClinician(
      id: json['id'] as int,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] ?? 'Unknown',
      phoneNumber: json['phone_number'],
      gender: json['gender'],
      organisationId: json['organisation_id'],
      organisationName: json['organisation_name'],
      patientCount: json['patient_count'] ?? 0,
    );
  }
}
