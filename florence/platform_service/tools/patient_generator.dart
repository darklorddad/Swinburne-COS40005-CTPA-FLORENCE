import 'dart:io';
import 'dart:math';

/// Patient Data Generator for FLORENCE Digital Health Platform
/// Generates realistic patient datasets for testing and demonstration
///
/// Usage:
///   dart tools/patient_generator.dart [number_of_patients] [output_file.csv]
///
/// Example:
///   dart tools/patient_generator.dart 100 patients_data.csv

void main(List<String> arguments) {
  // Parse arguments
  int numberOfPatients = arguments.isNotEmpty ? int.tryParse(arguments[0]) ?? 50 : 50;
  String outputFile = arguments.length > 1 ? arguments[1] : 'generated_patients.csv';

  print('🏥 FLORENCE Patient Data Generator');
  print('═' * 50);
  print('Generating $numberOfPatients patients...\n');

  // Generate patients
  final generator = PatientDataGenerator();
  final patients = generator.generatePatients(numberOfPatients);

  // Write to CSV
  final csv = generator.patientsToCSV(patients);
  File(outputFile).writeAsStringSync(csv);

  print('✅ Successfully generated $numberOfPatients patients');
  print('📄 Output file: $outputFile');
  print('📊 File size: ${(File(outputFile).lengthSync() / 1024).toStringAsFixed(2)} KB');
  print('\nDataset includes:');
  print('  • Patient demographics');
  print('  • 30 days of glucose readings (4-8 per day)');
  print('  • Meal logs with nutrition info');
  print('  • Activity tracking');
  print('  • Medication adherence');
  print('  • HbA1c measurements');
}

class PatientDataGenerator {
  final Random _random = Random();

  // Name pools
  final List<String> _firstNames = [
    'Ahmad', 'Ali', 'Amirah', 'Aziz', 'Chen', 'David', 'Emily', 'Fatimah',
    'Hassan', 'Hui', 'Ismail', 'James', 'John', 'Kumar', 'Lee', 'Maria',
    'Michael', 'Ming', 'Mohammed', 'Nurul', 'Peter', 'Raj', 'Robert', 'Sarah',
    'Siti', 'Tan', 'Wei', 'Yusof', 'Zainab', 'Wong'
  ];

  final List<String> _lastNames = [
    'Abdullah', 'Ahmad', 'Chong', 'Garcia', 'Ibrahim', 'Johnson', 'Krishnan',
    'Lee', 'Lim', 'Martinez', 'Mohamed', 'Ng', 'Osman', 'Patel', 'Rahman',
    'Smith', 'Tan', 'Wang', 'Williams', 'Wong', 'Yap', 'Yusof', 'Zhang'
  ];

  // Medical data pools
  final List<String> _diabetesTypes = ['Type 1', 'Type 2', 'Pre-diabetes'];
  final List<String> _medicationNames = [
    'Metformin', 'Insulin Glargine', 'Sitagliptin', 'Empagliflozin',
    'Liraglutide', 'Gliclazide', 'Pioglitazone'
  ];
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  final List<String> _activityTypes = [
    'Walking', 'Running', 'Cycling', 'Swimming', 'Gym',
    'Yoga', 'Sports', 'Dancing', 'Hiking'
  ];

  List<Patient> generatePatients(int count) {
    return List.generate(count, (index) => _generatePatient(index + 1));
  }

  Patient _generatePatient(int id) {
    final age = 25 + _random.nextInt(55); // 25-80 years
    final diabetesType = _diabetesTypes[_random.nextInt(_diabetesTypes.length)];
    final baselineGlucose = diabetesType == 'Pre-diabetes' ? 110.0 :
                           diabetesType == 'Type 1' ? 160.0 : 140.0;

    return Patient(
      id: 'P${id.toString().padLeft(4, '0')}',
      firstName: _firstNames[_random.nextInt(_firstNames.length)],
      lastName: _lastNames[_random.nextInt(_lastNames.length)],
      email: 'patient${id}@florence.demo',
      age: age,
      gender: _random.nextBool() ? 'Male' : 'Female',
      diabetesType: diabetesType,
      diagnosisDate: _randomDate(DateTime.now().subtract(Duration(days: 365 * 5))),
      baselineGlucose: baselineGlucose,
      hba1c: _generateHbA1c(baselineGlucose),
      glucoseReadings: _generateGlucoseReadings(baselineGlucose, 30),
      meals: _generateMeals(30),
      activities: _generateActivities(30),
      medications: _generateMedications(diabetesType),
    );
  }

  List<GlucoseReading> _generateGlucoseReadings(double baseline, int days) {
    List<GlucoseReading> readings = [];
    final now = DateTime.now();

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));
      final readingsPerDay = 4 + _random.nextInt(5); // 4-8 readings per day

      for (int i = 0; i < readingsPerDay; i++) {
        final hour = (i * 24 / readingsPerDay).floor();
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        // Simulate glucose patterns based on time
        double timeVariance = 0;
        if (hour >= 6 && hour <= 9) timeVariance = 15; // Morning spike
        else if (hour >= 12 && hour <= 14) timeVariance = 20; // Lunch spike
        else if (hour >= 18 && hour <= 20) timeVariance = 18; // Dinner spike

        final value = baseline +
                     _randomGaussian(-20, 20) +
                     timeVariance +
                     _randomGaussian(-10, 10);

        readings.add(GlucoseReading(
          timestamp: timestamp,
          value: value.clamp(70, 300),
          context: _getGlucoseContext(hour),
        ));
      }
    }

    return readings;
  }

  List<Meal> _generateMeals(int days) {
    List<Meal> meals = [];
    final now = DateTime.now();

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));
      final mealsPerDay = 3 + _random.nextInt(2); // 3-4 meals per day

      for (int i = 0; i < mealsPerDay; i++) {
        final mealType = i < 3 ? _mealTypes[i] : 'Snack';
        final hour = i == 0 ? 7 : i == 1 ? 12 : i == 2 ? 19 : 15;
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        meals.add(Meal(
          timestamp: timestamp,
          type: mealType,
          description: _generateMealDescription(mealType),
          carbs: 20.0 + _random.nextInt(60).toDouble(),
          calories: 200 + _random.nextInt(600),
          protein: 5.0 + _random.nextInt(30).toDouble(),
          fat: 5.0 + _random.nextInt(25).toDouble(),
        ));
      }
    }

    return meals;
  }

  List<Activity> _generateActivities(int days) {
    List<Activity> activities = [];
    final now = DateTime.now();

    for (int day = 0; day < days; day++) {
      // 60% chance of activity per day
      if (_random.nextDouble() > 0.4) {
        final date = now.subtract(Duration(days: days - day));
        final hour = 6 + _random.nextInt(14); // 6 AM - 8 PM
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        final activityType = _activityTypes[_random.nextInt(_activityTypes.length)];

        activities.add(Activity(
          timestamp: timestamp,
          type: activityType,
          duration: 15 + _random.nextInt(75), // 15-90 minutes
          intensity: ['Low', 'Moderate', 'High'][_random.nextInt(3)],
          caloriesBurned: 50 + _random.nextInt(400),
        ));
      }
    }

    return activities;
  }

  List<Medication> _generateMedications(String diabetesType) {
    final count = diabetesType == 'Pre-diabetes' ? 1 :
                 diabetesType == 'Type 1' ? 2 :
                 1 + _random.nextInt(2);

    return List.generate(count, (i) {
      return Medication(
        name: _medicationNames[_random.nextInt(_medicationNames.length)],
        dosage: '${5 + _random.nextInt(20) * 5} mg',
        frequency: ['Once daily', 'Twice daily', 'With meals'][_random.nextInt(3)],
        adherenceRate: 0.7 + _random.nextDouble() * 0.3, // 70-100%
      );
    });
  }

  double _generateHbA1c(double baselineGlucose) {
    // HbA1c roughly correlates with average glucose
    // Formula approximation: HbA1c ≈ (avg_glucose + 46.7) / 28.7
    return ((baselineGlucose + 46.7) / 28.7).clamp(4.5, 12.0);
  }

  String _getGlucoseContext(int hour) {
    if (hour >= 5 && hour < 9) return 'Before breakfast';
    if (hour >= 9 && hour < 11) return 'After breakfast';
    if (hour >= 11 && hour < 13) return 'Before lunch';
    if (hour >= 13 && hour < 17) return 'After lunch';
    if (hour >= 17 && hour < 19) return 'Before dinner';
    if (hour >= 19 && hour < 22) return 'After dinner';
    return 'Bedtime';
  }

  String _generateMealDescription(String mealType) {
    final breakfasts = ['Oatmeal with fruit', 'Eggs and toast', 'Nasi lemak', 'Roti canai'];
    final lunches = ['Chicken rice', 'Salad bowl', 'Noodles', 'Sandwich'];
    final dinners = ['Grilled fish with vegetables', 'Curry with rice', 'Pasta', 'Stir-fry'];
    final snacks = ['Apple', 'Nuts', 'Yogurt', 'Protein bar'];

    switch (mealType) {
      case 'Breakfast': return breakfasts[_random.nextInt(breakfasts.length)];
      case 'Lunch': return lunches[_random.nextInt(lunches.length)];
      case 'Dinner': return dinners[_random.nextInt(dinners.length)];
      default: return snacks[_random.nextInt(snacks.length)];
    }
  }

  DateTime _randomDate(DateTime start) {
    final daysRange = DateTime.now().difference(start).inDays;
    return start.add(Duration(days: _random.nextInt(daysRange)));
  }

  double _randomGaussian(double min, double max) {
    // Box-Muller transform for Gaussian distribution
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    final randStdNormal = sqrt(-2.0 * log(u1)) * sin(2.0 * pi * u2);
    final mean = (min + max) / 2;
    final stdDev = (max - min) / 6;
    return mean + stdDev * randStdNormal;
  }

  String patientsToCSV(List<Patient> patients) {
    final StringBuffer csv = StringBuffer();

    // Header
    csv.writeln('patient_id,first_name,last_name,email,age,gender,diabetes_type,'
               'diagnosis_date,baseline_glucose,hba1c,medication_count,'
               'avg_daily_readings,avg_glucose,glucose_variability,meal_count,'
               'activity_count,adherence_rate,risk_score');

    // Data rows
    for (var patient in patients) {
      final avgGlucose = patient.glucoseReadings.map((r) => r.value).reduce((a, b) => a + b) /
                        patient.glucoseReadings.length;
      final glucoseStdDev = _calculateStdDev(patient.glucoseReadings.map((r) => r.value).toList());
      final avgDailyReadings = (patient.glucoseReadings.length / 30).toStringAsFixed(1);
      final adherenceRate = patient.medications.map((m) => m.adherenceRate)
                           .reduce((a, b) => a + b) / patient.medications.length;
      final riskScore = _calculateRiskScore(patient, avgGlucose, glucoseStdDev);

      csv.writeln('${patient.id},'
                 '${patient.firstName},'
                 '${patient.lastName},'
                 '${patient.email},'
                 '${patient.age},'
                 '${patient.gender},'
                 '${patient.diabetesType},'
                 '${patient.diagnosisDate.toIso8601String().split('T')[0]},'
                 '${patient.baselineGlucose.toStringAsFixed(1)},'
                 '${patient.hba1c.toStringAsFixed(1)},'
                 '${patient.medications.length},'
                 '$avgDailyReadings,'
                 '${avgGlucose.toStringAsFixed(1)},'
                 '${glucoseStdDev.toStringAsFixed(1)},'
                 '${patient.meals.length},'
                 '${patient.activities.length},'
                 '${(adherenceRate * 100).toStringAsFixed(1)},'
                 '${riskScore.toStringAsFixed(2)}');
    }

    return csv.toString();
  }

  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  double _calculateRiskScore(Patient patient, double avgGlucose, double stdDev) {
    double score = 0;

    // HbA1c contribution (0-40 points)
    if (patient.hba1c > 9) score += 40;
    else if (patient.hba1c > 8) score += 30;
    else if (patient.hba1c > 7) score += 20;
    else score += 10;

    // Glucose variability (0-30 points)
    if (stdDev > 50) score += 30;
    else if (stdDev > 40) score += 20;
    else if (stdDev > 30) score += 10;

    // Average glucose (0-20 points)
    if (avgGlucose > 200) score += 20;
    else if (avgGlucose > 180) score += 15;
    else if (avgGlucose > 160) score += 10;

    // Medication adherence (0-10 points) - inverted
    final adherence = patient.medications.map((m) => m.adherenceRate)
                     .reduce((a, b) => a + b) / patient.medications.length;
    score += (1 - adherence) * 10;

    return score.clamp(0, 100);
  }
}

// Data Models
class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final int age;
  final String gender;
  final String diabetesType;
  final DateTime diagnosisDate;
  final double baselineGlucose;
  final double hba1c;
  final List<GlucoseReading> glucoseReadings;
  final List<Meal> meals;
  final List<Activity> activities;
  final List<Medication> medications;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.age,
    required this.gender,
    required this.diabetesType,
    required this.diagnosisDate,
    required this.baselineGlucose,
    required this.hba1c,
    required this.glucoseReadings,
    required this.meals,
    required this.activities,
    required this.medications,
  });
}

class GlucoseReading {
  final DateTime timestamp;
  final double value;
  final String context;

  GlucoseReading({
    required this.timestamp,
    required this.value,
    required this.context,
  });
}

class Meal {
  final DateTime timestamp;
  final String type;
  final String description;
  final double carbs;
  final int calories;
  final double protein;
  final double fat;

  Meal({
    required this.timestamp,
    required this.type,
    required this.description,
    required this.carbs,
    required this.calories,
    required this.protein,
    required this.fat,
  });
}

class Activity {
  final DateTime timestamp;
  final String type;
  final int duration;
  final String intensity;
  final int caloriesBurned;

  Activity({
    required this.timestamp,
    required this.type,
    required this.duration,
    required this.intensity,
    required this.caloriesBurned,
  });
}

class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final double adherenceRate;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.adherenceRate,
  });
}
