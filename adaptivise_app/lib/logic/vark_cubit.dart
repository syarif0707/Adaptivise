import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/api_service.dart';
import '../data/supabase_repo.dart';

abstract class VarkState {}
class VarkInitial extends VarkState {}
class VarkLoading extends VarkState {}
class VarkSuccess extends VarkState { final String style; VarkSuccess(this.style); }
class VarkError extends VarkState { final String message; VarkError(this.message); }

class VarkCubit extends Cubit<VarkState> {
  final SupabaseRepo _repo = SupabaseRepo();

  VarkCubit() : super(VarkInitial());

  Future<void> processVarkScores(Map<String, int> scores) async {
    emit(VarkLoading());
    try {
      // 1. Format scores for Python API [V, A, R, K]
      final scoreList = [scores['V'] ?? 0, scores['A'] ?? 0, scores['R'] ?? 0, scores['K'] ?? 0];
      
      // 2. Call Python Backend (Hybrid Weighted K-Means)
      final result = await ApiService.classifyVark(scoreList);
      final dominantStyle = result['learning_style'][0]; // Gets 'V', 'A', 'R', or 'K'

      // 3. Save to Supabase
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await _repo.updateVarkProfile(userId, dominantStyle, scores);
      }

      emit(VarkSuccess(dominantStyle));
    } catch (e) {
      emit(VarkError("Failed to process profile: $e"));
    }
  }
}