import 'package:adaptivise_prototype/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart // Import your colors

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _profileStream;

  @override
  void initState() {
    super.initState();
    // Stream the current user's profile
    final userId = _supabase.auth.currentUser!.id;
    _profileStream = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .limit(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Learning Analytics", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _profileStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Error loading profile or no data."));
          }

          final profile = snapshot.data!.first;
          final String style = profile['primary_vark_style'] ?? 'Not Determined';
          // Access JSONB scores and cast to int/double safely
          final Map<String, dynamic> rawScores = profile['vark_scores'] ?? {};
          final double visual = _scoreFor(rawScores, 'Visual');
          final double auditory = _scoreFor(rawScores, 'Auditory');
          final double readWrite = _scoreFor(rawScores, 'Read/Write');
          final double kinesthetic = _scoreFor(rawScores, 'Kinesthetic');
          final double scoreTotal = visual + auditory + readWrite + kinesthetic;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brief Explanation Card (Matching image_8)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
                        child: const Text("AI ANALYSIS COMPLETE", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(height: 16),
                      Text("You’re a $style Learner", textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        _getStyleDescription(style),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                const Text("Your VARK Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 16),

                // Pie Chart Card (Matching image_8)
                Container(
                  height: 350,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      // Custom Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendItem("Visual", AppColors.Visual),
                          const SizedBox(width: 15),
                          _legendItem("Auditory", AppColors.Auditory),
                          const SizedBox(width: 15),
                          _legendItem("Read/Write", AppColors.ReadWrite),
                          const SizedBox(width: 15),
                          _legendItem("Kinesthetic", AppColors.Kinesthetic),
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
                                    _pieSection("Visual", visual, AppColors.Visual, scoreTotal),
                                    _pieSection("Auditory", auditory, AppColors.Auditory, scoreTotal),
                                    _pieSection("Read/Write", readWrite, AppColors.ReadWrite, scoreTotal),
                                    _pieSection("Kinesthetic", kinesthetic, AppColors.Kinesthetic, scoreTotal),
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
                const SizedBox(height: 30),
                // Action Button
                
                ElevatedButton(
                  onPressed: () {
                    // Navigate to learning resources or recommendations
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => RecommendationsScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Explore Learning Resources", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper function to provide descriptions
  String _getStyleDescription(String style) {
    if (style == "Multimodal") {
      return "Your profile shows a balanced preference for multiple learning channels, often adapting your approach based on the context of the material.";
    } else if (style == "Kinesthetic") {
      return "You learn best through experience and practice. Real-world examples, demonstrations, and physical activities help you understand concepts.";
    } else if (style == "Read/Write") {
      return "You have a strong preference for information displayed as words. Reading notes, textbooks, and writing summaries are your most effective study methods.";
    }
    return "Complete the VARK questionnaire to receive a detailed analysis of your preferred learning style.";
  }

  // Helper for Legend Items
  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
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

  PieChartSectionData _pieSection(String title, double value, Color color, double total) {
    final percentage = total > 0 ? (value / total) * 100 : 0;

    return PieChartSectionData(
      color: color,
      value: value,
      title: '$title\n${percentage.toStringAsFixed(0)}%',
      radius: 80,
      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }
}