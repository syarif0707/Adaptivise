import 'package:adaptivise_prototype/core/note_utils.dart';
import 'package:adaptivise_prototype/logic/profile_cubit.dart';
import 'package:adaptivise_prototype/presentation/adaptive_content/auditory_player_screen.dart';
import 'package:adaptivise_prototype/presentation/adaptive_content/kinesthetic_quiz_screen.dart';
import 'package:adaptivise_prototype/presentation/adaptive_content/readwrite_summary_screen.dart';
import 'package:adaptivise_prototype/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdaptiveNoteContainer extends StatelessWidget {
  final Map<String, dynamic> note;
  final String initialStyle;

  const AdaptiveNoteContainer({
    super.key,
    required this.note,
    required this.initialStyle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        final allowed = profileState is ProfileLoaded
            ? context.read<ProfileCubit>().allowedModes()
            : _fallbackAllowed(initialStyle);
        final activeMode = profileState is ProfileLoaded
            ? context.read<ProfileCubit>().defaultMode()
            : _fallbackMode(initialStyle);

        final summary = formatSummaryForDisplay(
          note['summary']?.toString() ?? 'No summary available.',
        );
        final title = note['file_name']?.toString() ?? 'Adaptive Note';
        final quiz = parseQuizContent(note['quiz_content']);
        final rawText = note['raw_text']?.toString() ?? '';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              IconButton(
                tooltip: 'Change learning style',
                icon: const Icon(Icons.tune, color: Colors.black87),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
          body: _LockedModeView(
            activeMode: activeMode,
            allowedModes: allowed,
            readWrite: SummaryModeScreen(summary: summary),
            auditory: AuditoryPlayerScreen(title: title, summary: summary),
            kinesthetic: KinestheticQuizScreen(
              quizData: quiz,
              rawText: rawText,
            ),
          ),
        );
      },
    );
  }

  List<String> _fallbackAllowed(String style) {
    final lower = style.toLowerCase();
    if (lower.contains('kinesthetic')) return ['kinesthetic'];
    if (lower.contains('auditory')) return ['auditory'];
    return ['readwrite'];
  }

  String _fallbackMode(String style) {
    final lower = style.toLowerCase();
    if (lower.contains('kinesthetic')) return 'kinesthetic';
    if (lower.contains('auditory')) return 'auditory';
    return 'readwrite';
  }
}

class _LockedModeView extends StatelessWidget {
  final String activeMode;
  final List<String> allowedModes;
  final Widget readWrite;
  final Widget auditory;
  final Widget kinesthetic;

  const _LockedModeView({
    required this.activeMode,
    required this.allowedModes,
    required this.readWrite,
    required this.auditory,
    required this.kinesthetic,
  });

  @override
  Widget build(BuildContext context) {
    if (!allowedModes.contains(activeMode)) {
      return _LockedPanel(
        message:
            'Your current learning style does not include this mode. Retake the VARK assessment in Profile to change it.',
      );
    }

    return Column(
      children: [
        _ModeBanner(mode: activeMode),
        Expanded(
          child: switch (activeMode) {
            'auditory' => auditory,
            'kinesthetic' => kinesthetic,
            _ => readWrite,
          },
        ),
      ],
    );
  }
}

class _ModeBanner extends StatelessWidget {
  final String mode;

  const _ModeBanner({required this.mode});

  @override
  Widget build(BuildContext context) {
    final label = switch (mode) {
      'auditory' => 'Auditory Mode',
      'kinesthetic' => 'Kinesthetic Mode',
      _ => 'Read/Write Mode',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFF00695C).withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(
            switch (mode) {
              'auditory' => Icons.headphones,
              'kinesthetic' => Icons.gamepad,
              _ => Icons.article,
            },
            color: const Color(0xFF00695C),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF00695C),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: const Text('Change style'),
          ),
        ],
      ),
    );
  }
}

class _LockedPanel extends StatelessWidget {
  final String message;

  const _LockedPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
