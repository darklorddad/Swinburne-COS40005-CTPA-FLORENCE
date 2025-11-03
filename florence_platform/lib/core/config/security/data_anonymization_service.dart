/// Data Anonymization Service for FLORENCE Digital Health Platform
/// Masks and anonymizes personally identifiable information (PII)
library;

import 'dart:math';

/// De-identification levels
enum DeidentificationLevel {
  safe,      // Remove all PII
  limited,   // Keep some aggregate data
  minimal,   // Minimal masking
}

/// Service for anonymizing sensitive patient data
class DataAnonymizationService {
  // Singleton pattern
  static final DataAnonymizationService _instance = DataAnonymizationService._internal();
  factory DataAnonymizationService() => _instance;
  DataAnonymizationService._internal();

  final Random _random = Random();

  /// Anonymize a full dataset
  Map<String, dynamic> anonymizePatientData(Map<String, dynamic> data) {
    final anonymized = Map<String, dynamic>.from(data);

    // Anonymize personal identifiers
    if (anonymized.containsKey('firstName')) {
      anonymized['firstName'] = _anonymizeName(anonymized['firstName']);
    }
    if (anonymized.containsKey('lastName')) {
      anonymized['lastName'] = _anonymizeName(anonymized['lastName']);
    }
    if (anonymized.containsKey('email')) {
      anonymized['email'] = _anonymizeEmail(anonymized['email']);
    }
    if (anonymized.containsKey('phone')) {
      anonymized['phone'] = _anonymizePhone(anonymized['phone']);
    }
    if (anonymized.containsKey('address')) {
      anonymized['address'] = _anonymizeAddress(anonymized['address']);
    }
    if (anonymized.containsKey('id')) {
      anonymized['id'] = _anonymizeId(anonymized['id']);
    }

    // Replace with generic identifier
    anonymized['anonymizedId'] = 'PATIENT_${_generateAnonymousId()}';

    return anonymized;
  }

  /// Anonymize name
  String _anonymizeName(String name) {
    if (name.isEmpty) return 'Anonymous';
    return 'Patient ${name[0]}***';
  }

  /// Anonymize email
  String _anonymizeEmail(String email) {
    if (!email.contains('@')) return 'anonymous@example.com';

    final parts = email.split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    }

    return '${username.substring(0, 2)}***@$domain';
  }

  /// Anonymize phone number
  String _anonymizePhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 4) {
      return '***-***-****';
    }

    // Show last 2 digits only
    final lastTwo = digitsOnly.substring(digitsOnly.length - 2);
    return '***-***-**$lastTwo';
  }

  /// Anonymize address
  String _anonymizeAddress(String address) {
    // Keep general area but remove specific address
    return 'General Area Only';
  }

  /// Anonymize ID
  String _anonymizeId(String id) {
    return 'ID_${_random.nextInt(9000) + 1000}';
  }

  /// Generate anonymous ID
  String _generateAnonymousId() {
    return '${_random.nextInt(90000) + 10000}';
  }

  /// Mask personally identifiable information in text
  String maskPII(String text) {
    var masked = text;

    // Mask email addresses
    masked = masked.replaceAllMapped(
      RegExp(r'[\w\.-]+@[\w\.-]+\.\w+'),
      (match) => _anonymizeEmail(match.group(0)!),
    );

    // Mask phone numbers (various formats)
    masked = masked.replaceAllMapped(
      RegExp(r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}'),
      (match) => '***-***-****',
    );

    // Mask names (simple heuristic: capitalized words)
    // This is basic; production should use NER (Named Entity Recognition)
    masked = masked.replaceAllMapped(
      RegExp(r'\b[A-Z][a-z]+\s+[A-Z][a-z]+\b'),
      (match) => '[NAME REDACTED]',
    );

    return masked;
  }

  /// Pseudonymize data (consistent anonymous identifiers)
  final Map<String, String> _pseudonymCache = {};

  String pseudonymize(String identifier) {
    if (_pseudonymCache.containsKey(identifier)) {
      return _pseudonymCache[identifier]!;
    }

    final pseudo = 'PSN_${_generateAnonymousId()}';
    _pseudonymCache[identifier] = pseudo;
    return pseudo;
  }

  /// Apply de-identification based on level
  Map<String, dynamic> deidentify(
    Map<String, dynamic> data,
    DeidentificationLevel level,
  ) {
    switch (level) {
      case DeidentificationLevel.safe:
        return _deidentifySafe(data);
      case DeidentificationLevel.limited:
        return _deidentifyLimited(data);
      case DeidentificationLevel.minimal:
        return _deidentifyMinimal(data);
    }
  }

  Map<String, dynamic> _deidentifySafe(Map<String, dynamic> data) {
    return {
      // Remove all PII, keep only aggregated health metrics
      'averageGlucose': data['averageGlucose'],
      'timeInRange': data['timeInRange'],
      'totalActivityMinutes': data['totalActivityMinutes'],
      'ageRange': _getAgeRange(data['age']),
      'diabetesType': data['diabetesType'],
    };
  }

  Map<String, dynamic> _deidentifyLimited(Map<String, dynamic> data) {
    final anonymized = anonymizePatientData(data);
    // Keep health data, remove specific identifiers
    anonymized.remove('email');
    anonymized.remove('phone');
    anonymized.remove('address');
    return anonymized;
  }

  Map<String, dynamic> _deidentifyMinimal(Map<String, dynamic> data) {
    return anonymizePatientData(data);
  }

  String _getAgeRange(dynamic age) {
    if (age == null) return 'Unknown';
    final ageInt = age is int ? age : int.tryParse(age.toString()) ?? 0;

    if (ageInt < 18) return '0-17';
    if (ageInt < 30) return '18-29';
    if (ageInt < 40) return '30-39';
    if (ageInt < 50) return '40-49';
    if (ageInt < 60) return '50-59';
    if (ageInt < 70) return '60-69';
    return '70+';
  }

  /// Clear pseudonym cache
  void clearCache() {
    _pseudonymCache.clear();
  }

  /// Generate aggregate statistics (privacy-preserving)
  Map<String, dynamic> generateAggregateStats(List<Map<String, dynamic>> patients) {
    if (patients.isEmpty) {
      return {
        'totalPatients': 0,
        'averageAge': 0,
        'diabetesTypeDistribution': {},
      };
    }

    final ages = patients
        .map((p) => p['age'] is int ? p['age'] as int : int.tryParse(p['age'].toString()) ?? 0)
        .where((age) => age > 0)
        .cast<int>()
        .toList();

    final avgAge = ages.isNotEmpty ? ages.reduce((a, b) => a + b) / ages.length : 0;

    final diabetesTypes = <String, int>{};
    for (var patient in patients) {
      final type = patient['diabetesType'] as String? ?? 'Unknown';
      diabetesTypes[type] = (diabetesTypes[type] ?? 0) + 1;
    }

    return {
      'totalPatients': patients.length,
      'averageAge': avgAge.toStringAsFixed(1),
      'ageRanges': _getAgeRangeDistribution(ages),
      'diabetesTypeDistribution': diabetesTypes,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, int> _getAgeRangeDistribution(List<int> ages) {
    final distribution = <String, int>{};

    for (var age in ages) {
      final range = _getAgeRange(age);
      distribution[range] = (distribution[range] ?? 0) + 1;
    }

    return distribution;
  }
}
