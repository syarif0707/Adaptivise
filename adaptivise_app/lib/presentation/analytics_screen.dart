import 'package:adaptivise_prototype/core/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('profiles')
            .stream(primaryKey: ['id'])
            .eq('id', userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No profile data found.'));
          }

          final profile = snapshot.data!.first;
          final scores = Map<String, dynamic>.from(profile['vark_scores'] ?? {});
          final rawStyle = profile['primary_vark_style']?.toString() ?? "Unknown";
          final String style = rawStyle
              .replaceAll(RegExp(r'\bV\b'), 'Visual')
              .replaceAll(RegExp(r'\bA\b'), 'Auditory')
              .replaceAll(RegExp(r'\bR\b'), 'Read/Write')
              .replaceAll(RegExp(r'\bK\b'), 'Kinesthetic');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. Brief Explanation Header
                _buildAnalysisCard(style),
                const SizedBox(height: 25),
                
                // 2. The Pie Chart Card
                _buildPieChartCard(scores),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalysisCard(String style) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your Primary Style: $style", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("This is your personalized learning analysis based on the VARK assessment.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(Map<String, dynamic> scores) {
    double score(String key) {
      final raw = scores[key];
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    final visual = score('Visual');
    final auditory = score('Auditory');
    final readWrite = score('Read/Write');
    final kinesthetic = score('Kinesthetic');
    final total = visual + auditory + readWrite + kinesthetic;

    List<PieChartSectionData> sections = [
      _section('Visual', visual, AppColors.Visual, total),
      _section('Auditory', auditory, AppColors.Auditory, total),
      _section('Read/Write', readWrite, AppColors.ReadWrite, total),
      _section('Kinesthetic', kinesthetic, AppColors.Kinesthetic, total),
    ].where((s) => s.value > 0).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text("Your VARK Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: total > 0
                ? PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 30))
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
    );
  }

  PieChartSectionData _section(String label, double value, Color color, double total) {
    final pct = total > 0 ? (value / total) * 100 : 0;
    return PieChartSectionData(
      value: value,
      color: color,
      title: '$label\n${pct.toStringAsFixed(0)}%',
      radius: 60,
      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }
}