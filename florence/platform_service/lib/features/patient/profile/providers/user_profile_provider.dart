import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../main.dart';

final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ApiService();
  
  // Get email from the local session (safe)
  final email = supabase.auth.currentUser?.email ?? 'user@example.com';

  // Fetch the full profile from the backend API
  final profile = await apiService.get('/patients/me');
  
  // Mix in the email which might not be guaranteed in the profile response depending on backend
  return {
    ...profile,
    'email': email, // Ensure email is present
  };
});
