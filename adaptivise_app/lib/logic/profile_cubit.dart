import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

sealed class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> profile;

  ProfileLoaded(this.profile);

  // FIX: Properly expand abbreviations like "A & K" to "Auditory & Kinesthetic"
  String get primaryStyle {
    final rawStyle = profile['primary_vark_style']?.toString() ?? 'Not Determined';
    
    // Create a translation map
    const map = {
      'V': 'Visual',
      'A': 'Auditory',
      'R': 'Read/Write',
      'K': 'Kinesthetic',
    };

    // If it's a multimodal result like "A & K"
    if (rawStyle.contains('&')) {
      final parts = rawStyle.split('&').map((e) => e.trim()).toList();
      final expandedParts = parts.map((p) => map[p] ?? p).toList();
      return expandedParts.join(' & ');
    }

    // If it's a single result like "V"
    return map[rawStyle] ?? rawStyle;
  }

  Map<String, dynamic> get varkScores =>
      Map<String, dynamic>.from(profile['vark_scores'] ?? {});

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());

  final _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  void watchProfile() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      emit(ProfileError('Not signed in'));
      return;
    }

    emit(ProfileLoading());
    _subscription?.cancel();
    _subscription = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen(
          (data) {
            if (data.isEmpty) {
              emit(ProfileError('Profile not found'));
              return;
            }
            emit(ProfileLoaded(data.first));
          },
          onError: (error) => emit(ProfileError(error.toString())),
        );
  }

  /// Returns allowed learning-mode keys for the current profile.
  List<String> allowedModes() {
    final current = state;
    if (current is! ProfileLoaded) return ['readwrite'];

    final style = current.primaryStyle.toLowerCase();
    if (style.contains('&') || style.contains('multimodal')) {
      final modes = <String>{};
      if (style.contains('visual') || style.contains('read')) {
        modes.add('readwrite');
      }
      if (style.contains('auditory')) modes.add('auditory');
      if (style.contains('kinesthetic')) modes.add('kinesthetic');
      return modes.isEmpty ? ['readwrite'] : modes.toList();
    }

    if (style.contains('kinesthetic') || style == 'k') return ['kinesthetic'];
    if (style.contains('auditory') || style == 'a') return ['auditory'];
    if (style.contains('visual') || style.contains('read') || style == 'r') {
      return ['readwrite'];
    }
    return ['readwrite'];
  }

  String defaultMode() {
    final modes = allowedModes();
    final style = (state is ProfileLoaded)
        ? (state as ProfileLoaded).primaryStyle.toLowerCase()
        : '';

    if (style.contains('kinesthetic')) return 'kinesthetic';
    if (style.contains('auditory')) return 'auditory';
    return modes.first;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}