import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/services/supabase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wfczreizzherxoduirxv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndmY3pyZWl6emhlcnhvZHVpcnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcyNTk5NDQsImV4cCI6MjA4MjgzNTk0NH0.W8HCz3kHWdp1xQqg93gjz2-E6Jhtc-EGaBLX8rYVyiY',
  );

  final bucketExists = await SupabaseService.checkAvatarsBucket();
  if (!bucketExists) {
    debugPrint("WARNING: 'avatars' bucket not found. Create it in Supabase Dashboard > Storage.");
  }

  runApp(const EasySafarApp());
}
