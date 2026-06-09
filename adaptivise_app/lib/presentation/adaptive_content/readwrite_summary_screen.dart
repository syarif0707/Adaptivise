import 'package:adaptivise_prototype/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SummaryModeScreen extends StatefulWidget {
  final String summary;
  const SummaryModeScreen({super.key, required this.summary});

  @override
  State<SummaryModeScreen> createState() => _SummaryModeScreenState();
}

class _SummaryModeScreenState extends State<SummaryModeScreen> {
  final FlutterTts _tts = FlutterTts();
  bool isSpeaking = false;

  void _toggleSpeech() async {
    if (isSpeaking) {
      await _tts.stop();
      setState(() => isSpeaking = false);
    } else {
      await _tts.speak(widget.summary);
      setState(() => isSpeaking = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SUMMARY MODE")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Markdown(
                  data: widget.summary, 
                  selectable: true, // Allows users to copy text
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 16, color: Colors.black),
                    h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                    listBullet: const TextStyle(fontSize: 16, color: Colors.teal),
                    tableBorder: TableBorder.all(color: Colors.grey.shade300, width: 1),
                    tableBody: const TextStyle(fontSize: 14),
                  ),
                  ),
                ),
              ),  
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            FloatingActionButton(
              onPressed: _toggleSpeech,
              backgroundColor: AppColors.readWrite,
              child: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
            ),
          ],
        ),
      ),
    );
  }
}