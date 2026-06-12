import 'dart:convert';
import 'dart:io';

import 'package:adaptivise_prototype/core/api_service.dart';
import 'package:adaptivise_prototype/core/debug_log.dart';
import 'package:adaptivise_prototype/core/note_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class FolderContentScreen extends StatefulWidget {
  final String folderId;
  final String folderName;

  const FolderContentScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<FolderContentScreen> createState() => _FolderContentScreenState();
}

class _FolderContentScreenState extends State<FolderContentScreen> {
  final _supabase = Supabase.instance.client;
  bool _isProcessing = false;
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final notesStream = _supabase
        .from('lecture_notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.folderName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _pickAndUploadNote,
        backgroundColor: const Color(0xFF00695C),
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text(
          _isProcessing ? 'Processing...' : 'Adapt Notes',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: notesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allNotes = snapshot.data!
                    .where((note) => note['folder_id']?.toString() == widget.folderId)
                    .toList();
                final notes = _applyFilter(allNotes);

                agentDebugLog(
                  location: 'folder_content_screen.dart:build',
                  message: 'Notes stream filtered for folder',
                  hypothesisId: 'B',
                  data: {
                    'folderId': widget.folderId,
                    'totalFromStream': snapshot.data!.length,
                    'inFolder': allNotes.length,
                    'afterFilter': notes.length,
                    'filter': _filter,
                  },
                );

                if (notes.isEmpty) {
                  return const Center(
                    child: Text('No notes yet. Tap Adapt Notes to add one!'),
                  );
                }

                return SlidableAutoCloseBehavior(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      return NoteSlidableTile(note: notes[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> notes) {
    switch (_filter) {
      case 'favorite':
        return notes.where((n) => n['is_starred'] == true).toList();
      case 'recent':
        return notes;
      default:
        return notes;
    }
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _chip('Recently', Icons.history, 'recent'),
          _chip('Frequently', Icons.trending_up, 'all'),
          _chip('Favorite', Icons.favorite, 'favorite'),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, String filterKey) {
    final selected = _filter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _filter = filterKey),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: selected ? Colors.teal[50] : Colors.grey[100],
            child: Icon(icon, color: Colors.teal, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: selected ? Colors.teal : Colors.grey,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
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

      if (fileName.toLowerCase().endsWith('.pptx') && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reading slides and generating adaptive content...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      if (!mounted) return;
      setState(() => _isProcessing = true);

      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiService.processNoteUrl),
        );

        request.fields['user_id'] = userId;
        request.fields['folder_id'] = widget.folderId;
        request.fields['storage_path'] = 'uploads/$fileName';
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

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
            'folder_id': widget.folderId,
            'storage_path': 'uploads/$fileName',
            'raw_text': decodedData['raw_text'] ?? '',
            'summary': summaryToSave,
            'quiz_content': quizContent,
            'is_starred': false,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('AI processing complete!')),
            );
          }
        } else {
          throw Exception('Server Error: ${response.statusCode} - $respBody');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }
}
