import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  // Professional Signup with Metadata (Trigger friendly)
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'driver' or 'passenger'
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'user_role': role,
      },
    );
  }

  // Login
  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }
}