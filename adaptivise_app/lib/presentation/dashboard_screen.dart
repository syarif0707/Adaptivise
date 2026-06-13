import 'package:adaptivise_prototype/core/app_theme.dart';
import 'package:adaptivise_prototype/logic/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().watchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Learning Analytics',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProfileError) {
            return Center(child: Text(state.message));
          }
          if (state is! ProfileLoaded) {
            return const Center(child: Text('Error loading profile.'));
          }

          final profile = state.profile;
          final style = state.primaryStyle;
          final rawScores = state.varkScores;
          final visual = _scoreFor(rawScores, 'Visual');
          final auditory = _scoreFor(rawScores, 'Auditory');
          final readWrite = _scoreFor(rawScores, 'Read/Write');
          final kinesthetic = _scoreFor(rawScores, 'Kinesthetic');
          final scoreTotal = visual + auditory + readWrite + kinesthetic;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'AI ANALYSIS COMPLETE',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You’re a $style Learner',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _getStyleDescription(style),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Your VARK Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 350,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendItem('Visual', AppColors.Visual),
                          const SizedBox(width: 15),
                          _legendItem('Auditory', AppColors.Auditory),
                          const SizedBox(width: 15),
                          _legendItem('Read/Write', AppColors.ReadWrite),
                          const SizedBox(width: 15),
                          _legendItem('Kinesthetic', AppColors.Kinesthetic),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: scoreTotal > 0
                            ? PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: [
                                    _pieSection(
                                      'Visual',
                                      visual,
                                      AppColors.Visual,
                                      scoreTotal,
                                    ),
                                    _pieSection(
                                      'Auditory',
                                      auditory,
                                      AppColors.Auditory,
                                      scoreTotal,
                                    ),
                                    _pieSection(
                                      'Read/Write',
                                      readWrite,
                                      AppColors.ReadWrite,
                                      scoreTotal,
                                    ),
                                    _pieSection(
                                      'Kinesthetic',
                                      kinesthetic,
                                      AppColors.Kinesthetic,
                                      scoreTotal,
                                    ),
                                  ].where((s) => s.value > 0).toList(),
                                ),
                              )
                            : const Center(
                                child: Text(
                                  'Retake the VARK questionnaire to see your chart.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStyleDescription(String style) {
    final lower = style.toLowerCase();
    if (lower.contains('&') || lower.contains('multimodal')) {
      return 'Your profile shows a balanced preference for multiple learning channels.';
    }
    if (lower.contains('kinesthetic')) {
      return 'You learn best through experience and practice.';
    }
    if (lower.contains('auditory')) {
      return 'You learn best by listening, discussing, and hearing information explained aloud.';
    }
    if (lower.contains('read') || lower.contains('visual')) {
      return 'You learn best through written notes, summaries, and structured reading.';
    }
    return 'Complete the VARK questionnaire to receive a detailed analysis.';
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  double _scoreFor(Map<String, dynamic> scores, String key) {
    final raw = scores[key];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  PieChartSectionData _pieSection(
    String title,
    double value,
    Color color,
    double total,
  ) {
    final percentage = total > 0 ? (value / total) * 100 : 0;
    return PieChartSectionData(
      color: color,
      value: value,
      title: '$title\n${percentage.toStringAsFixed(0)}%',
      radius: 80,
      titleStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
