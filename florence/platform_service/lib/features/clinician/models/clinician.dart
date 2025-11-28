class Clinician {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String gender;
  final int organisationId;

  Clinician({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.gender,
    required this.organisationId,
  });

  factory Clinician.fromJson(Map<String, dynamic> json) {
    return Clinician(
      id: json['id'].toString(),
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      gender: json['gender'] ?? '',
      organisationId: json['organisation_id'] ?? 0,
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
