import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum AuditoryRepeatMode { off, one, all }

sealed class AuditoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuditoryInitial extends AuditoryState {}

class AuditoryReady extends AuditoryState {
  final List<String> segments;
  final int currentIndex;
  final bool isPlaying;
  final bool isPaused;
  final AuditoryRepeatMode repeatMode;
  final String title;

  AuditoryReady({
    required this.segments,
    this.currentIndex = 0,
    this.isPlaying = false,
    this.isPaused = false,
    this.repeatMode = AuditoryRepeatMode.off,
    required this.title,
  });

  double get progress =>
      segments.isEmpty ? 0 : (currentIndex + 1) / segments.length;

  String get currentText =>
      segments.isEmpty ? '' : segments[currentIndex.clamp(0, segments.length - 1)];

  AuditoryReady copyWith({
    List<String>? segments,
    int? currentIndex,
    bool? isPlaying,
    bool? isPaused,
    AuditoryRepeatMode? repeatMode,
    String? title,
  }) {
    return AuditoryReady(
      segments: segments ?? this.segments,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      repeatMode: repeatMode ?? this.repeatMode,
      title: title ?? this.title,
    );
  }

  @override
  List<Object?> get props =>
      [segments, currentIndex, isPlaying, isPaused, repeatMode, title];
}

class AuditoryCubit extends Cubit<AuditoryState> {
  AuditoryCubit() : super(AuditoryInitial());

  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  double _currentRate = 0.48;

  Future<void> setSpeechRate(double rate) async {
    _currentRate = rate;
    await _tts.setSpeechRate(rate);
    // Trigger UI rebuild
    if (state is AuditoryReady) {
      emit((state as AuditoryReady).copyWith()); 
    }
  }

  Future<void> init({required String title, required String text}) async {
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(_onSegmentComplete);
    _tts.setCancelHandler(_onCancelled);

    final segments = _splitIntoSegments(text);
    emit(
      AuditoryReady(
        segments: segments,
        title: title,
      ),
    );
  }

  List<String> _splitIntoSegments(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'https?://[^\s]+'), ' ') // Remove URLs
        .replaceAll(RegExp(r'''[^\w\s.,!?'"-]'''), ' ') // Remove special chars except basic punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();

  if (cleaned.isEmpty) {
    return ['No content available to listen.'];
  }

  final parts = cleaned
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  return parts;
}

  Future<void> play() async {
    final current = state;
    if (current is! AuditoryReady) return;

    if (current.isPaused) {
      await _tts.speak(current.currentText);
      emit(current.copyWith(isPlaying: true, isPaused: false));
      return;
    }

    await _speakCurrent(current);
  }

  Future<void> pause() async {
    final current = state;
    if (current is! AuditoryReady) return;

    await _tts.stop();
    _speaking = false;
    emit(current.copyWith(isPlaying: false, isPaused: true));
  }

  Future<void> stop() async {
    final current = state;
    if (current is! AuditoryReady) return;

    await _tts.stop();
    _speaking = false;
    emit(
      current.copyWith(
        isPlaying: false,
        isPaused: false,
        currentIndex: 0,
      ),
    );
  }

  Future<void> rewind() async {
    final current = state;
    if (current is! AuditoryReady || current.segments.isEmpty) return;

    await _tts.stop();
    _speaking = false;
    final nextIndex = (current.currentIndex - 1).clamp(0, current.segments.length - 1);
    final updated = current.copyWith(
      currentIndex: nextIndex,
      isPlaying: false,
      isPaused: false,
    );
    emit(updated);
    if (current.isPlaying) await _speakCurrent(updated);
  }

  Future<void> fastForward() async {
    final current = state;
    if (current is! AuditoryReady || current.segments.isEmpty) return;

    await _tts.stop();
    _speaking = false;
    final nextIndex =
        (current.currentIndex + 1).clamp(0, current.segments.length - 1);
    final updated = current.copyWith(
      currentIndex: nextIndex,
      isPlaying: false,
      isPaused: false,
    );
    emit(updated);
    if (current.isPlaying) await _speakCurrent(updated);
  }

  void toggleRepeat() {
    final current = state;
    if (current is! AuditoryReady) return;

    final next = switch (current.repeatMode) {
      AuditoryRepeatMode.off => AuditoryRepeatMode.one,
      AuditoryRepeatMode.one => AuditoryRepeatMode.all,
      AuditoryRepeatMode.all => AuditoryRepeatMode.off,
    };
    emit(current.copyWith(repeatMode: next));
  }

  Future<void> _speakCurrent(AuditoryReady current) async {
    if (_speaking) return;
    _speaking = true;
    emit(current.copyWith(isPlaying: true, isPaused: false));
    await _tts.speak(current.currentText);
  }

  void _onSegmentComplete() {
    _speaking = false;
    final current = state;
    if (current is! AuditoryReady) return;

    if (current.repeatMode == AuditoryRepeatMode.one) {
      unawaited(_speakCurrent(current));
      return;
    }

    if (current.currentIndex >= current.segments.length - 1) {
      if (current.repeatMode == AuditoryRepeatMode.all) {
        final reset = current.copyWith(currentIndex: 0, isPlaying: true);
        emit(reset);
        unawaited(_speakCurrent(reset));
        return;
      }
      emit(current.copyWith(isPlaying: false, isPaused: false));
      return;
    }

    final next = current.copyWith(
      currentIndex: current.currentIndex + 1,
      isPlaying: true,
    );
    emit(next);
    unawaited(_speakCurrent(next));
  }

  void _onCancelled() {
    _speaking = false;
  }

  @override
  Future<void> close() {
    _tts.stop();
    return super.close();
  }
}
