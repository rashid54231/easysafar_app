import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  static Future<void> signOut() async => await client.auth.signOut();

  static Future<bool> checkAvatarsBucket() async {
    try {
      final buckets = await client.storage.listBuckets();
      return buckets.any((b) => b.id == 'avatars');
    } catch (e) {
      debugPrint("checkAvatarsBucket error: $e");
      return false;
    }
  }
}
