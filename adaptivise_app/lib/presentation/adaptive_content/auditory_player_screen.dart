import 'package:adaptivise_prototype/core/app_theme.dart';
import 'package:adaptivise_prototype/logic/auditory_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuditoryPlayerScreen extends StatelessWidget {
  final String title;
  final String summary;

  const AuditoryPlayerScreen({
    super.key,
    required this.title,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuditoryCubit()..init(title: title, text: summary),
      child: const _AuditoryPlayerBody(),
    );
  }
}

class _AuditoryPlayerBody extends StatelessWidget {
  const _AuditoryPlayerBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuditoryCubit, AuditoryState>(
      builder: (context, state) {
        if (state is! AuditoryReady) {
          return const Center(child: CircularProgressIndicator());
        }

        final repeatLabel = switch (state.repeatMode) {
          AuditoryRepeatMode.off => 'OFF',
          AuditoryRepeatMode.one => 'ONE',
          AuditoryRepeatMode.all => 'ALL',
        };

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.Auditory.withValues(alpha: 0.15),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.Auditory,
                          AppColors.Auditory.withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.Auditory.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.headphones, size: 72, color: Colors.white),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            state.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Segment ${state.currentIndex + 1} of ${state.segments.length}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: state.progress.clamp(0.0, 1.0),
                    onChanged: null,
                    activeColor: AppColors.Auditory,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          state.currentText,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlButton(
                        icon: Icons.repeat,
                        label: repeatLabel,
                        active: state.repeatMode != AuditoryRepeatMode.off,
                        onTap: () => context.read<AuditoryCubit>().toggleRepeat(),
                      ),
                      const SizedBox(width: 12),
                      _ControlButton(
                        icon: Icons.replay_10,
                        label: 'Back',
                        onTap: () => context.read<AuditoryCubit>().rewind(),
                      ),
                      const SizedBox(width: 12),
                      _PlayButton(state: state),
                      const SizedBox(width: 12),
                      _ControlButton(
                        icon: Icons.forward_10,
                        label: 'Skip',
                        onTap: () => context.read<AuditoryCubit>().fastForward(),
                      ),
                      const SizedBox(width: 12),
                      _ControlButton(
                        icon: Icons.stop_circle_outlined,
                        label: 'Stop',
                        onTap: () => context.read<AuditoryCubit>().stop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayButton extends StatelessWidget {
  final AuditoryReady state;

  const _PlayButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuditoryCubit>();
    final isActive = state.isPlaying;

    return GestureDetector(
      onTap: () {
        if (isActive) {
          cubit.pause();
        } else {
          cubit.play();
        }
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.Auditory,
          boxShadow: [
            BoxShadow(
              color: AppColors.Auditory.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          isActive ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: active
                ? AppColors.Auditory.withValues(alpha: 0.2)
                : Colors.grey[100],
            child: Icon(
              icon,
              color: active ? AppColors.Auditory : Colors.black87,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
