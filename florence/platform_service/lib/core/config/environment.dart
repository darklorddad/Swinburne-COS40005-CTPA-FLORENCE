/// Environment Configuration for FLORENCE Digital Health Platform

/// Feature flags and environment configuration
class Environment {
  // ==================== FEATURE FLAGS ====================

  /// Enable Supabase backend integration
  /// Set to true when ready to connect to Supabase
  static const bool enableSupabase = false;

  /// Enable AI features (DeepSeek API)
  /// Set to true to use AI-powered recommendations and chatbot
  static const bool enableAI = true;

  /// Enable automation triggers
  /// Set to true to enable automated alerts and notifications
  static const bool enableAutomation = true;

  /// Enable analytics and logging
  static const bool enableAnalytics = false;

  // ==================== AI CONFIGURATION ====================

  /// DeepSeek API Configuration
  /// API Key is stored here for demo purposes
  /// In production, use environment variables or secure storage
  static const String deepSeekApiKey = 'sk-97bfbb146ad345d9acefbc5d6153fc2a';
  static const String deepSeekBaseUrl = 'https://api.deepseek.com/v1';

  // ==================== API CONFIGURATION ====================

  /// Backend API URL
  // static const String apiUrl = 'http://127.0.0.1:8000';
  static const String apiUrl = 'http://10.191.69.105:8000';


  // ==================== SUPABASE CONFIGURATION ====================

  /// Supabase URL (to be configured when ready)
  static const String supabaseUrl = 'https://your-project.supabase.co';

  /// Supabase Anon Key (to be configured when ready)
  static const String supabaseAnonKey = 'your-anon-key-here';

  // ==================== APP CONFIGURATION ====================

  /// App version
  static const String appVersion = '1.0.0';

  /// App environment (dev, staging, production)
  static const String appEnvironment = 'development';

  /// Enable debug mode
  static const bool isDebug = true;

  /// Mock data mode
  static const bool useMockData = !enableSupabase;

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

  // ==================== AI SETTINGS ====================

  /// AI model for recommendations
  static const String aiModelRecommendations = 'deepseek-chat';

  /// AI model for chatbot
  static const String aiModelChatbot = 'deepseek-chat';

  /// AI model for pattern analysis
  static const String aiModelPatternAnalysis = 'deepseek-chat';

  /// Max tokens for AI responses
  static const int maxTokens = 1000;

  /// Temperature for AI (0.0 - 1.0)
  static const double aiTemperature = 0.7;

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
    if (useMockData) return 'Demo Mode (Mock Data)';
    return 'Development Mode';
  }

  /// Check if running in production
  static bool get isProduction => appEnvironment == 'production';

  /// Check if running in development
  static bool get isDevelopment => appEnvironment == 'development';
}
