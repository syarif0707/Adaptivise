import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/api_service.dart';

abstract class StudyState {}
class StudyInitial extends StudyState {}
class StudyLoading extends StudyState {}
class StudyReady extends StudyState {
  final String summary;
  final List<String> keywords;
  StudyReady(this.summary, this.keywords);
}
class StudyError extends StudyState {
  final String message;
  StudyError(this.message);
}

class StudyCubit extends Cubit<StudyState> {
  StudyCubit() : super(StudyInitial());

  Future<void> processPdfContent(String extractedText) async {
    emit(StudyLoading());
    try {
      // 1. Send text to Python AI
      final result = await ApiService.summarizeText(extractedText);
      
      // 2. Extract Data
      final summary = result['summary'] as String;
      final keywords = List<String>.from(result['keywords']);
      
      // 3. Emit Ready State to update UI
      emit(StudyReady(summary, keywords));
      
      // Note: In production, you would also save this to Supabase here
      
    } catch (e) {
      emit(StudyError("AI Processing failed: ${e.toString()}"));
    }
  }
}