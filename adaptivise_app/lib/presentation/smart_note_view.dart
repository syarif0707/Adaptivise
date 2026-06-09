import 'dart:convert';

import 'package:adaptivise_prototype/core/api_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

// Make sure you have these imports for your AI screens!
import 'package:adaptivise_prototype/presentation/adaptive_content/kinesthetic_quiz_screen.dart';
import 'package:adaptivise_prototype/presentation/adaptive_content/readwrite_summary_screen.dart';

class NotesLibraryScreen extends StatefulWidget {
  const NotesLibraryScreen({super.key});

  @override
  State<NotesLibraryScreen> createState() => _NotesLibraryScreenState();
}

class _NotesLibraryScreenState extends State<NotesLibraryScreen> {
  final _supabase = Supabase.instance.client;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    // 1. THIS IS THE FIX: We are telling the stream to look at 'lecture_notes', not 'folders'
    final notesStream = _supabase
        .from('lecture_notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Notes",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _pickAndUploadNote,
        backgroundColor: const Color(0xFF00695C),
        icon: _isProcessing 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text(_isProcessing ? "Processing..." : "Adapt Notes",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: notesStream, // Using our corrected stream here
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final notes = snapshot.data!;
                
                // 2. THE DEBUG PRINT: Look for this in your VS Code terminal!
                print("I FOUND ${notes.length} NOTES FOR THIS USER! ");

                if (notes.isEmpty) return const Center(child: Text("No notes yet. Tap Adapt Notes to add one!"));

                // 3. DISPLAY THE NOTES
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const Icon(Icons.description, color: Colors.teal, size: 40),
                        title: Text(note['file_name'] ?? 'Untitled Note', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Tap to start Adaptive Study"),
                        trailing: const Icon(Icons.play_circle_fill, color: Colors.teal),
                        onTap: () async {
                          final userId = _supabase.auth.currentUser!.id;
                          final profile = await _supabase.from('profiles').select('primary_vark_style').eq('id', userId).single();
                          
                          if (!context.mounted) return;

                          final rawStyle = profile['primary_vark_style']?.toString().toLowerCase().trim() ?? "";

                          if (rawStyle.contains("kinesthetic") || rawStyle == "k") {
                            Navigator.push(context, MaterialPageRoute(
                              // 👇 THE FIX IS HERE: Add "?? []" to the end of note['quiz_content']
                              builder: (context) => KinestheticQuizScreen(quizData: note['quiz_content'] ?? []),
                            ));
                          } else {
                            Navigator.push(context, MaterialPageRoute(
                              // 👇 You can add it here too, just to be safe!
                              builder: (context) => SummaryModeScreen(summary: note['summary'] ?? "No summary available."),
                            ));
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _chip("Recently", Icons.history),
          _chip("Frequently", Icons.trending_up),
          _chip("Favorite", Icons.favorite),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: Colors.grey[100], child: Icon(icon, color: Colors.teal, size: 20)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Future<void> _pickAndUploadNote() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'pptx'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      final String fileName = result.files.single.name;
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) return;

      if (fileName.toLowerCase().endsWith('.pptx')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reading slides and generating adaptive content..."),
            duration: Duration(seconds: 2),
          ),
        );
      }

      setState(() => _isProcessing = true);

      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiService.processNoteUrl),
        );

        request.fields['user_id'] = userId;
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
        request.fields['storage_path'] = 'uploads/$fileName';
        var response = await request.send();

        final respBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final decodedData = jsonDecode(respBody) as Map<String, dynamic>;
          final rawSummary = decodedData['summary']?.toString() ?? '';
          final quizContent = decodedData['quiz_content'] ?? [];

          String summaryToSave = rawSummary;
          if (rawSummary.isNotEmpty) {
            try {
              summaryToSave = await ApiService.formatWithGemini(rawSummary);
            } catch (formatError) {
              debugPrint('Gemini formatting skipped: $formatError');
            }
          }

          await _supabase.from('lecture_notes').insert({
            'user_id': userId,
            'file_name': fileName,
            'storage_path': 'uploads/$fileName',
            'raw_text': decodedData['raw_text'] ?? '',
            'summary': summaryToSave,
            'quiz_content': quizContent,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("AI processing complete! Check your library.")),
            );
          }
        } else {
          throw Exception("Server Error: ${response.statusCode} - $respBody");
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }
}
