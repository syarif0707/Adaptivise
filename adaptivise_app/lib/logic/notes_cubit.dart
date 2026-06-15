import 'dart:async';
import 'dart:io';

import 'package:adaptivise_prototype/core/api_service.dart';
import 'package:adaptivise_prototype/core/note_utils.dart';
import 'package:adaptivise_prototype/core/pdf_export_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum NotesFilter { all, recent, favorite }

sealed class NotesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {}

class NotesLoading extends NotesState {}

class NotesLoaded extends NotesState {
  final List<Map<String, dynamic>> notes;
  final NotesFilter filter;
  final bool isUploading;
  final String? selectedFolderId;
  final String? selectedFolderName;

  NotesLoaded({
    required this.notes,
    this.filter = NotesFilter.all,
    this.isUploading = false,
    this.selectedFolderId,
    this.selectedFolderName,
  });

  NotesLoaded copyWith({
    List<Map<String, dynamic>>? notes,
    NotesFilter? filter,
    bool? isUploading,
    String? selectedFolderId,
    String? selectedFolderName,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
      filter: filter ?? this.filter,
      isUploading: isUploading ?? this.isUploading,
      selectedFolderId: selectedFolderId ?? this.selectedFolderId,
      selectedFolderName: selectedFolderName ?? this.selectedFolderName,
    );
  }

  @override
  List<Object?> get props =>
      [notes, filter, isUploading, selectedFolderId, selectedFolderName];
}

class NotesActionMessage extends NotesState {
  final List<Map<String, dynamic>> notes;
  final NotesFilter filter;
  final String message;
  final String? selectedFolderId;
  final String? selectedFolderName;

  NotesActionMessage(
    this.notes,
    this.filter,
    this.message, {
    this.selectedFolderId,
    this.selectedFolderName,
  });

  @override
  List<Object?> get props =>
      [notes, filter, message, selectedFolderId, selectedFolderName];
}

class NotesError extends NotesState {
  final String message;

  NotesError(this.message);

  @override
  List<Object?> get props => [message];
}

class NotesCubit extends Cubit<NotesState> {
  NotesCubit() : super(NotesInitial());

  final _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  List<Map<String, dynamic>> _allNotes = [];
  NotesFilter _filter = NotesFilter.all;
  String? _selectedFolderId;
  String? _selectedFolderName;

  void watchNotes() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      emit(NotesError('Not signed in'));
      return;
    }

    emit(NotesLoading());
    _subscription?.cancel();
    _subscription = _supabase
        .from('lecture_notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen(
          (data) {
            _allNotes = List<Map<String, dynamic>>.from(data);
            _emitLoaded();
          },
          onError: (error) => emit(NotesError(error.toString())),
        );
  }

  void selectSubject({String? folderId, String? folderName}) {
    _selectedFolderId = folderId;
    _selectedFolderName = folderName;
    _emitLoaded();
  }

  void setFilter(NotesFilter filter) {
    _filter = filter;
    _emitLoaded();
  }

  void _emitLoaded({bool isUploading = false}) {
    emit(
      NotesLoaded(
        notes: _applyFilter(_allNotes),
        filter: _filter,
        isUploading: isUploading,
        selectedFolderId: _selectedFolderId,
        selectedFolderName: _selectedFolderName,
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> notes) {
    var filtered = notes;
    if (_selectedFolderId != null) {
      filtered = filtered
          .where((n) => n['folder_id']?.toString() == _selectedFolderId)
          .toList();
    }

    switch (_filter) {
      case NotesFilter.favorite:
        return filtered.where((n) => n['is_starred'] == true).toList();
      case NotesFilter.recent:
      case NotesFilter.all:
        return filtered;
    }
  }

  Future<void> toggleStar(Map<String, dynamic> note) async {
    final noteId = note['id'];
    if (noteId == null) throw Exception('Note id is missing');

    final next = note['is_starred'] != true;
    await _supabase
        .from('lecture_notes')
        .update({'is_starred': next})
        .eq('id', noteId);

    final label = note['file_name'] ?? 'Note';
    emit(
      NotesActionMessage(
        _applyFilter(_allNotes),
        _filter,
        next ? '$label added to favorites.' : '$label removed from favorites.',
        selectedFolderId: _selectedFolderId,
        selectedFolderName: _selectedFolderName,
      ),
    );
  }

  Future<String> downloadNote(Map<String, dynamic> note) async {
    final String? path = await PdfExportService.saveStudyPackPdf(
      fileName: (note['file_name'] ?? 'note').toString(),
      summary: note['summary']?.toString() ?? 'No summary available.',
      quizContent: parseQuizContent(note['quiz_content']),
    );

    if (path == null) {
      throw Exception('Failed to save note PDF.');
    }

    emit(
      NotesActionMessage(
        _applyFilter(_allNotes),
        _filter,
        'Saved to $path',
        selectedFolderId: _selectedFolderId,
        selectedFolderName: _selectedFolderName,
      ),
    );
    return path;
  }

  Future<void> deleteNote(Map<String, dynamic> note) async {
    final noteId = note['id'];
    if (noteId == null) throw Exception('Note id is missing');

    await _supabase.from('lecture_notes').delete().eq('id', noteId);
    emit(
      NotesActionMessage(
        _applyFilter(_allNotes),
        _filter,
        '${note['file_name'] ?? 'Note'} deleted.',
        selectedFolderId: _selectedFolderId,
        selectedFolderName: _selectedFolderName,
      ),
    );
  }

  Future<void> uploadFromFile(File file, String fileName, String folderId) async {
    await _processAndSave(
      () => ApiService.processNote(
        file: file,
        userId: _supabase.auth.currentUser!.id,
        storagePath: 'uploads/$fileName',
        folderId: folderId,
      ),
      fileName,
      folderId,
    );
  }

  Future<void> uploadFromUrl(String url, String folderId) async {
    final fileName = _fileNameFromUrl(url);
    await _processAndSave(
      () => ApiService.processUrl(
        url: url,
        userId: _supabase.auth.currentUser!.id,
        storagePath: 'uploads/web-${DateTime.now().millisecondsSinceEpoch}.html',
        folderId: folderId,
      ),
      fileName,
      folderId,
    );
  }

  String _fileNameFromUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) return 'web-page.html';
    final host = uri.host.replaceAll('.', '-');
    return '$host-page.html';
  }

  Future<void> _processAndSave(
    Future<Map<String, dynamic>> Function() processRequest,
    String fileName,
    String folderId,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _emitLoaded(isUploading: true);

    try {
      final decodedData = await processRequest();
      final rawText = decodedData['raw_text']?.toString() ?? '';
      var rawSummary = decodedData['summary']?.toString() ?? '';
      var quizContent = parseQuizContent(decodedData['quiz_content']);

      if (quizContent.isEmpty && rawText.isNotEmpty) {
        quizContent = parseQuizContent(await ApiService.generateQuiz(rawText));
      }

      if (rawSummary.isNotEmpty) {
        try {
          rawSummary = await ApiService.formatWithGemini(rawSummary);
        } catch (error) {
          debugPrint('Gemini formatting failed, using raw summary: $error');
        }
      }

      await _supabase.from('lecture_notes').insert({
        'user_id': userId,
        'file_name': fileName,
        'folder_id': folderId,
        'storage_path': 'uploads/$fileName',
        'raw_text': rawText,
        'summary': rawSummary,
        'quiz_content': quizContent,
        'is_starred': false,
      });

      emit(
        NotesActionMessage(
          _applyFilter(_allNotes),
          _filter,
          'AI processing complete!',
          selectedFolderId: _selectedFolderId,
          selectedFolderName: _selectedFolderName,
        ),
      );
    } catch (error) {
      emit(NotesError('Upload failed: $error'));
      _emitLoaded(isUploading: false);
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
