enum RiskLevel { high, medium, low }

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final List<String> activeDiseases;
  final RiskLevel riskLevel;
  final DateTime lastSync;
  final String contactInfo;
  final String? photoUrl;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.activeDiseases,
    required this.riskLevel,
    required this.lastSync,
    required this.contactInfo,
    this.photoUrl,
  });

  // Helper method to get color for risk level
  String get riskLevelColor {
    switch (riskLevel) {
      case RiskLevel.high:
        return 'red';
      case RiskLevel.medium:
        return 'yellow';
      case RiskLevel.low:
        return 'green';
    }
  }

  String get activeDiseasesText {
    if (activeDiseases.isEmpty) return 'No active diseases';
    return activeDiseases.join(', ');
  }
}
