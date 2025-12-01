class Validators {
  // ============================================
  // EMAIL VALIDATION
  // ============================================
  
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // ============================================
  // PASSWORD VALIDATION
  // ============================================
  
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }
  
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // ============================================
  // NAME VALIDATION
  // ============================================
  
  static String? name(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return '$fieldName must be less than 50 characters';
    }
    
    // Only letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }
  
  // ============================================
  // PHONE VALIDATION
  // ============================================
  
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // Malaysian phone numbers typically have 9-11 digits
    if (digitsOnly.length < 9 || digitsOnly.length > 11) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
  
  // ============================================
  // GLUCOSE VALIDATION
  // ============================================
  
  static String? glucose(String? value) {
    if (value == null || value.isEmpty) {
      return 'Glucose level is required';
    }
    
    final normalized = value.replaceAll(',', '.');
    final glucoseValue = double.tryParse(normalized);
    
    if (glucoseValue == null) {
      return 'Please enter a valid number';
    }
    
    if (glucoseValue < 20 || glucoseValue > 600) {
      return 'Glucose level must be between 20 and 600 mg/dL';
    }
    
    return null;
  }
  
  // ============================================
  // HbA1c VALIDATION
  // ============================================
  
  static String? hba1c(String? value) {
    if (value == null || value.isEmpty) {
      return 'HbA1c level is required';
    }
    
    final normalized = value.replaceAll(',', '.');
    final hba1cValue = double.tryParse(normalized);
    
    if (hba1cValue == null) {
      return 'Please enter a valid number';
    }
    
    if (hba1cValue < 2.0 || hba1cValue > 25.0) {
      return 'HbA1c level must be between 2.0% and 25.0%';
    }
    
    return null;
  }
  
  // ============================================
  // WEIGHT VALIDATION
  // ============================================
  
  static String? weight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }
    
    final normalized = value.replaceAll(',', '.');
    final weightValue = double.tryParse(normalized);
    
    if (weightValue == null) {
      return 'Please enter a valid number';
    }
    
    if (weightValue < 20 || weightValue > 300) {
      return 'Weight must be between 20 and 300 kg';
    }
    
    return null;
  }
  
  // ============================================
  // ACTIVITY DURATION VALIDATION
  // ============================================
  
  static String? activityDuration(String? value) {
    if (value == null || value.isEmpty) {
      return 'Duration is required';
    }
    
    final duration = int.tryParse(value);
    
    if (duration == null) {
      return 'Please enter a valid number';
    }
    
    if (duration < 1 || duration > 480) {
      return 'Duration must be between 1 and 480 minutes';
    }
    
    return null;
  }
  
  // ============================================
  // GENERIC VALIDATORS
  // ============================================
  
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String? minLength(String? value, int min, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < min) {
      return '$fieldName must be at least $min characters';
    }
    
    return null;
  }
  
  static String? maxLength(String? value, int max, {String fieldName = 'This field'}) {
    if (value != null && value.length > max) {
      return '$fieldName must be less than $max characters';
    }
    return null;
  }
  
  static String? numeric(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final normalized = value.replaceAll(',', '.');
    if (double.tryParse(normalized) == null) {
      return '$fieldName must be a number';
    }
    
    return null;
  }
  
  static String? range(String? value, double min, double max, {String fieldName = 'Value'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final normalized = value.replaceAll(',', '.');
    final numValue = double.tryParse(normalized);
    
    if (numValue == null) {
      return '$fieldName must be a number';
    }
    
    if (numValue < min || numValue > max) {
      return '$fieldName must be between $min and $max';
    }
    
    return null;
  }
}
