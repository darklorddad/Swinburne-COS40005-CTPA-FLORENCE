import 'package:florence/features/admin/core/models/admin_enums.dart';

/// Organization (Hospital/Clinic) model
/// Represents a healthcare organization in the system
class Organization {
  final String id;
  final String name;
  final String? customLoginUrl;
  final OrganizationStatus status;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? phone;
  final String? email;
  final String? website;
  final String? logoUrl;
  final int? patientCount;
  final int? staffCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Organization({
    required this.id,
    required this.name,
    this.customLoginUrl,
    this.status = OrganizationStatus.active,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.phone,
    this.email,
    this.website,
    this.logoUrl,
    this.patientCount,
    this.staffCount,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// Create from JSON
  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      customLoginUrl: json['custom_login_url'] as String?,
      status: json['status'] != null
          ? OrganizationStatus.fromString(json['status'] as String)
          : OrganizationStatus.active,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postal_code'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logo_url'] as String?,
      patientCount: json['patient_count'] as int?,
      staffCount: json['staff_count'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'custom_login_url': customLoginUrl,
      'status': status.name,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'phone': phone,
      'email': email,
      'website': website,
      'logo_url': logoUrl,
      'patient_count': patientCount,
      'staff_count': staffCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  /// Create a copy with modified fields
  Organization copyWith({
    String? id,
    String? name,
    String? customLoginUrl,
    OrganizationStatus? status,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? phone,
    String? email,
    String? website,
    String? logoUrl,
    int? patientCount,
    int? staffCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      customLoginUrl: customLoginUrl ?? this.customLoginUrl,
      status: status ?? this.status,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      patientCount: patientCount ?? this.patientCount,
      staffCount: staffCount ?? this.staffCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Get full address string
  String get fullAddress {
    final parts = [
      if (address != null) address,
      if (city != null) city,
      if (state != null) state,
      if (postalCode != null) postalCode,
      if (country != null) country,
    ];
    return parts.join(', ');
  }

  /// Check if organization is active
  bool get isActive => status.isActive;
}