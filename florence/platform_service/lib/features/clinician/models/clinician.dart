class Clinician {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String gender;
  final int organisationId;
  final String? organisationName;
  final String? organisationEmail;
  final String? organisationPhone;

  Clinician({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.gender,
    required this.organisationId,
    this.organisationName,
    this.organisationEmail,
    this.organisationPhone,
  });

  factory Clinician.fromJson(Map<String, dynamic> json) {
    final org = json['organisation'] as Map<String, dynamic>?;
    return Clinician(
      id: json['id'].toString(),
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      gender: json['gender'] ?? '',
      organisationId: json['organisation_id'] ?? 0,
      organisationName: org != null ? org['name'] : json['organisation_name'],
      organisationEmail: org != null ? org['email'] : json['organisation_email'],
      organisationPhone: org != null ? (org['phone_number'] ?? org['phone']) : json['organisation_phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'gender': gender,
    };
  }
}
