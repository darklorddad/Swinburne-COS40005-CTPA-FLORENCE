// Environment configuration
// Store your API keys and URLs here
 
// IMPORTANT: In production, use flutter_dotenv or similar
// to keep secrets out of source control

class Env {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://<your-project-ref>.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '<your-anon-key>',
  );
  
  // Backend API Configuration
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://your-api-url.com',
  );
  
  // Feature Flags
  static const bool enableAIFeatures = true;
  static const bool enableOfflineMode = false;
  static const bool enableAnalytics = false;
  
  // App Configuration
  static const String appName = 'Florence';
  static const String appVersion = '1.0.0';
  
  // Validation
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL_HERE' &&
           supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE';
  }
}
