import 'package:flutter/material.dart';

// Make sure these paths match where your files are!
import 'package:adaptivise_prototype/presentation/adaptive_content/kinesthetic_quiz_screen.dart';
import 'package:adaptivise_prototype/presentation/adaptive_content/readwrite_summary_screen.dart';

class AdaptiveNoteContainer extends StatefulWidget {
  final Map<String, dynamic> note;
  final String initialStyle;

  const AdaptiveNoteContainer({
    super.key, 
    required this.note, 
    required this.initialStyle,
  });

  @override
  State<AdaptiveNoteContainer> createState() => _AdaptiveNoteContainerState();
}

class _AdaptiveNoteContainerState extends State<AdaptiveNoteContainer> {
  @override
  Widget build(BuildContext context) {
    // Determine which tab to show first based on their style
    // Tab 0 = Summary, Tab 1 = Quiz
    int startingTab = 0; 
    final styleLower = widget.initialStyle.toLowerCase();
    
    // If they are Kinesthetic, open the Quiz tab first!
    if (styleLower.contains('kinesthetic') || styleLower == 'k') {
      startingTab = 1; 
    }

    return DefaultTabController(
      length: 2, // We have 2 tabs
      initialIndex: startingTab, // Automatically start on their preferred style
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.note['file_name'] ?? 'Adaptive Note', 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00695C),
            labelColor: Color(0xFF00695C),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.article), text: "Read/Write"),
              Tab(icon: Icon(Icons.gamepad), text: "Kinesthetic"),
            ],
          ),
        ),
        
        // This is where we plug in the screens you already built!
        body: TabBarView(
          children: [
            // Tab 0: Summary Screen
            SummaryModeScreen(summary: widget.note['summary'] ?? "No summary available."),
            
            // Tab 1: Quiz Screen (Includes the ?? [] fallback so it never crashes!)
            KinestheticQuizScreen(quizData: widget.note['quiz_content'] ?? []),
          ],
        ),
      ),
    );
  }
}