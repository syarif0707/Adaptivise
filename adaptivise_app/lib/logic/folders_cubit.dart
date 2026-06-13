import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

sealed class FoldersState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FoldersInitial extends FoldersState {}

class FoldersLoading extends FoldersState {}

class FoldersLoaded extends FoldersState {
  final List<Map<String, dynamic>> folders;

  FoldersLoaded(this.folders);

  @override
  List<Object?> get props => [folders];
}

class FoldersActionSuccess extends FoldersState {
  final List<Map<String, dynamic>> folders;
  final String message;

  FoldersActionSuccess(this.folders, this.message);

  @override
  List<Object?> get props => [folders, message];
}

class FoldersError extends FoldersState {
  final String message;

  FoldersError(this.message);

  @override
  List<Object?> get props => [message];
}

class FoldersCubit extends Cubit<FoldersState> {
  FoldersCubit() : super(FoldersInitial());

  final _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  List<Map<String, dynamic>> _folders = [];

  void watchFolders() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      emit(FoldersError('Not signed in'));
      return;
    }

    emit(FoldersLoading());
    _subscription?.cancel();
    _subscription = _supabase
        .from('folders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen(
          (data) {
            _folders = List<Map<String, dynamic>>.from(data);
            emit(FoldersLoaded(_folders));
          },
          onError: (error) => emit(FoldersError(error.toString())),
        );
  }

  Future<void> createFolder(String name) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('folders').insert({
        'user_id': userId,
        'name': name.trim(),
      });
      emit(FoldersActionSuccess(_folders, 'Folder "$name" created.'));
    } catch (error) {
      emit(FoldersError('Could not create folder: $error'));
    }
  }

  Future<void> renameFolder(Map<String, dynamic> folder, String name) async {
    try {
      await _supabase
          .from('folders')
          .update({'name': name.trim()})
          .eq('id', folder['id']);
      emit(FoldersActionSuccess(_folders, 'Folder renamed.'));
    } catch (error) {
      emit(FoldersError('Could not rename folder: $error'));
    }
  }

  Future<void> deleteFolder(Map<String, dynamic> folder) async {
    try {
      await _supabase.from('folders').delete().eq('id', folder['id']);
      emit(FoldersActionSuccess(_folders, 'Folder deleted.'));
    } catch (error) {
      emit(FoldersError('Could not delete folder: $error'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
