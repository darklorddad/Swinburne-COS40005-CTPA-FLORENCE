enum RiskLevel { high, medium, low }

enum ChronicCondition { type1Diabetes, type2Diabetes, hypertension, obesity }

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final ChronicCondition condition;
  final RiskLevel riskLevel;
  final DateTime lastSync;
  final String contactInfo;
  final String? photoUrl;
  
  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.condition,
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

  String get conditionName {
    switch (condition) {
      case ChronicCondition.type1Diabetes:
        return 'Type 1 Diabetes';
      case ChronicCondition.type2Diabetes:
        return 'Type 2 Diabetes';
      case ChronicCondition.hypertension:
        return 'Hypertension';
      case ChronicCondition.obesity:
        return 'Obesity';
    }
  }
}
