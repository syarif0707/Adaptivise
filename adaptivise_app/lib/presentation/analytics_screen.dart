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
          
          final profile = snapshot.data!.first;
          final scores = profile['vark_scores'] as Map<String, dynamic>;
          final String style = profile['primary_vark_style'] ?? "Unknown";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. Brief Explanation Header
                _buildAnalysisCard(style),
                const SizedBox(height: 25),
                
                // 2. The Pie Chart Card
                _buildPieChartCard(scores),
                
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/study'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Start Personalized Study", style: TextStyle(color: Colors.white)),
                ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text("Your VARK Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: (scores['V'] ?? 0).toDouble(), color: AppColors.visual, title: 'V'),
                  PieChartSectionData(value: (scores['A'] ?? 0).toDouble(), color: AppColors.aural, title: 'A'),
                  PieChartSectionData(value: (scores['R'] ?? 0).toDouble(), color: AppColors.readWrite, title: 'R'),
                  PieChartSectionData(value: (scores['K'] ?? 0).toDouble(), color: AppColors.kinesthetic, title: 'K'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}