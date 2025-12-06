import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/api_service.dart';

final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final session = Supabase.instance.client.auth.currentSession;
  
  // Fail fast if no session, preventing 422 errors on backend
  if (session == null) {
    throw Exception('User not authenticated');
  }

  final apiService = ApiService();
  
  // Get email from the local session (safe)
  final email = session.user.email ?? 'user@example.com';

  // Fetch the full profile from the backend API
  final profile = await apiService.get('/patients/me');
  
  // Mix in the email which might not be guaranteed in the profile response depending on backend
  return {
    ...profile,
    'email': email, // Ensure email is present
  };
}, isAutoDispose: true);
