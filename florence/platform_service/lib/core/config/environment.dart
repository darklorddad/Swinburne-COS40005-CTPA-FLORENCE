/// Environment Configuration for FLORENCE Digital Health Platform
library;

/// Feature flags and environment configuration
class Environment {
  // ==================== FEATURE FLAGS ====================

  /// Enable Supabase backend integration
  /// Set to true when ready to connect to Supabase
  static const bool enableSupabase = true;

  /// Enable AI features (via Microservice)
  /// Set to true to use AI-powered recommendations and chatbot
  static const bool enableAI = true;

  /// Enable automation triggers
  /// Set to true to enable automated alerts and notifications
  static const bool enableAutomation = true;

  /// Enable analytics and logging
  static const bool enableAnalytics = false;

  // ==================== API CONFIGURATION ====================

  /// Backend API URL (Data Service)
  /// Defaults to DEV. Override in CI with --dart-define=DATA_SERVICE_URL=https://prod...
  static const String dataServiceUrl = String.fromEnvironment(
    'DATA_SERVICE_URL',
    defaultValue: 'https://dev-ds-florence-dhp.vercel.app',
    // defaultValue: 'https://ds-git-clinician-2026-04-10-florence-dhp.vercel.app',
  );

  /// Chatbot Service URL
  /// Defaults to DEV. Override in CI with --dart-define=LLM_CHATBOT_SERVICE_URL=https://prod...
  static const String llmChatbotServiceUrl = String.fromEnvironment(
    'LLM_CHATBOT_SERVICE_URL',
    defaultValue: 'https://dev-llmcs-florence-dhp.vercel.app',
  );

  /// LLM Engine Service URL
  /// Defaults to DEV. Override in CI with --dart-define=LLM_ENGINE_SERVICE_URL=https://prod...
  static const String llmEngineServiceUrl = String.fromEnvironment(
    'LLM_ENGINE_SERVICE_URL',
    defaultValue: 'https://dev-llmes-florence-dhp.vercel.app',
  );

  // ==================== SUPABASE CONFIGURATION ====================
  
  // IMPORTANT: Replace these with your actual Supabase project URL and Anon Key
  // You can find these in your Supabase project settings under "API"
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL', 
    defaultValue: 'https://opltjtmmiuwbaikvlive.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9wbHRqdG1taXV3YmFpa3ZsaXZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2OTc0NDYsImV4cCI6MjA3NTI3MzQ0Nn0.iRpi8CpnGA6fVMxEpsKw0GeIabxyCPFMBtCssmMNsLs',
  );

  // ==================== APP CONFIGURATION ====================

  /// App version
  static const String appVersion = '1.0.0';

  /// App environment (dev, staging, production)
  static const String appEnvironment = 'development';

  /// Enable debug mode
  static const bool isDebug = true;

  // ==================== THRESHOLDS ====================

  /// Glucose thresholds (mg/dL)
  static const double glucoseHigh = 180.0;
  static const double glucoseLow = 70.0;
  static const double glucoseTargetMin = 80.0;
  static const double glucoseTargetMax = 140.0;

  /// HbA1c targets (%)
  static const double hba1cTarget = 7.0;
  static const double hba1cPrediabetes = 5.7;
  static const double hba1cDiabetes = 6.5;

  /// Activity targets (minutes per week)
  static const int activityTargetWeekly = 150;
  static const int activityTargetDaily = 30;

  /// Medication adherence target (%)
  static const double medicationAdherenceTarget = 80.0;

  /// Sleep targets (hours)
  static const int sleepMinHours = 7;
  static const int sleepMaxHours = 9;

  // ==================== NOTIFICATION SETTINGS ====================

  /// How often to check for automation triggers (minutes)
  static const int automationCheckInterval = 15;

  /// Max notifications per day
  static const int maxNotificationsPerDay = 10;

  // ==================== HELPER METHODS ====================

  /// Check if a feature is enabled
  static bool isFeatureEnabled(String feature) {
    switch (feature) {
      case 'supabase':
        return enableSupabase;
      case 'ai':
        return enableAI;
      case 'automation':
        return enableAutomation;
      case 'analytics':
        return enableAnalytics;
      default:
        return false;
    }
  }

  /// Get current mode description
  static String get modeDescription {
    if (enableSupabase) return 'Production Mode (Supabase Connected)';
    return 'Development Mode';
  }

  /// Check if running in production
  static bool get isProduction => appEnvironment == 'production';

  /// Check if running in development
  static bool get isDevelopment => appEnvironment == 'development';

  /// Validation to check if Supabase keys are default placeholders
  static bool get isConfigured {
    return supabaseUrl != 'https://<your-project-ref>.supabase.co' &&
           supabaseAnonKey != '<your-anon-key>';
  }
}
