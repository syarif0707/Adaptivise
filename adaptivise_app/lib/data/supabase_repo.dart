import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profile.dart';

class SupabaseRepo {
  final _supabase = Supabase.instance.client;

  Future<UserProfile?> getUserProfile(String userId) async {
    final data = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> updateVarkProfile(String userId, String style, Map<String, int> scores) async {
    await _supabase.from('profiles').upsert({
      'id': userId,
      'primary_vark_style': style,
      'vark_scores': scores,
      'updated_at': 'now()',
    });
  }

  Future<List<Map<String, dynamic>>> getFolders(String userId) async {
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('folders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false),
    );
  }

  Future<Map<String, dynamic>> createFolder(String userId, String name) async {
    return Map<String, dynamic>.from(
      await _supabase
          .from('folders')
          .insert({'user_id': userId, 'name': name})
          .select()
          .single(),
    );
  }
}