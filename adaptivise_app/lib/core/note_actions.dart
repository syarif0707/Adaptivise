import 'dart:convert';

import 'package:adaptivise_prototype/core/debug_log.dart';
import 'package:adaptivise_prototype/presentation/adaptive_content/adaptive_note_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoteActions {
  static final _supabase = Supabase.instance.client;

  static Future<void> toggleStar(Map<String, dynamic> note) async {
    final noteId = note['id'];
    if (noteId == null) throw Exception('Note id is missing');

    final current = note['is_starred'] == true;
    final next = !current;

    agentDebugLog(
      location: 'note_actions.dart:toggleStar',
      message: 'Star toggle requested',
      hypothesisId: 'C',
      data: {'noteId': noteId.toString(), 'current': current, 'next': next},
    );

    await _supabase
        .from('lecture_notes')
        .update({'is_starred': next})
        .eq('id', noteId);

    agentDebugLog(
      location: 'note_actions.dart:toggleStar',
      message: 'Star toggle succeeded',
      hypothesisId: 'C',
      data: {'noteId': noteId, 'is_starred': next},
    );
  }

  static Future<void> deleteNote(Map<String, dynamic> note) async {
    final noteId = note['id'];
    if (noteId == null) throw Exception('Note id is missing');

    agentDebugLog(
      location: 'note_actions.dart:deleteNote',
      message: 'Delete requested',
      hypothesisId: 'C',
      data: {'noteId': noteId.toString(), 'fileName': note['file_name']},
    );

    await _supabase.from('lecture_notes').delete().eq('id', noteId);

    agentDebugLog(
      location: 'note_actions.dart:deleteNote',
      message: 'Delete succeeded',
      hypothesisId: 'C',
      data: {'noteId': noteId},
    );
  }

  static Future<void> downloadNote(Map<String, dynamic> note) async {
    final fileName = (note['file_name'] ?? 'note').toString();
    final safeName = fileName.replaceAll(RegExp(r'[^\w\-. ]'), '_');
    final content = StringBuffer()
      ..writeln('# $fileName')
      ..writeln()
      ..writeln('## Summary')
      ..writeln(note['summary'] ?? 'No summary available.')
      ..writeln()
      ..writeln('## Quiz')
      ..writeln(jsonEncode(note['quiz_content'] ?? []));

    agentDebugLog(
      location: 'note_actions.dart:downloadNote',
      message: 'Download/share started',
      hypothesisId: 'D',
      data: {'fileName': safeName, 'bytes': content.length},
    );

    await Share.shareXFiles(
      [
        XFile.fromData(
          utf8.encode(content.toString()),
          name: '$safeName-study-pack.md',
          mimeType: 'text/markdown',
        ),
      ],
      subject: fileName,
    );
  }

  static Future<void> openNote(
    BuildContext context,
    Map<String, dynamic> note,
  ) async {
    final userId = _supabase.auth.currentUser!.id;
    final profile = await _supabase
        .from('profiles')
        .select('primary_vark_style')
        .eq('id', userId)
        .single();

    if (!context.mounted) return;

    final userStyle =
        profile['primary_vark_style']?.toString() ?? 'Read/Write';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdaptiveNoteContainer(
          note: note,
          initialStyle: userStyle,
        ),
      ),
    );
  }
}

class NoteSlidableTile extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback? onChanged;

  const NoteSlidableTile({
    super.key,
    required this.note,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isStarred = note['is_starred'] == true;

    agentDebugLog(
      location: 'note_actions.dart:NoteSlidableTile.build',
      message: 'Rendering slidable note tile',
      hypothesisId: 'A',
      data: {
        'noteId': note['id']?.toString(),
        'isStarred': isStarred,
      },
    );

    return Slidable(
      key: ValueKey(note['id']),
      groupTag: 'lecture_notes',
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.65,
        children: [
          SlidableAction(
            onPressed: (ctx) => _runAction(
              context,
              () => NoteActions.toggleStar(note),
              isStarred
                  ? '${note['file_name'] ?? 'Note'} removed from favorites.'
                  : '${note['file_name'] ?? 'Note'} added to favorites.',
            ),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            icon: isStarred ? Icons.star : Icons.star_border,
            label: isStarred ? 'Unstar' : 'Star',
          ),
          SlidableAction(
            onPressed: (ctx) => _runAction(
              context,
              () => NoteActions.downloadNote(note),
              '${note['file_name'] ?? 'Note'} ready to save.',
            ),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.download,
            label: 'Save',
          ),
          SlidableAction(
            onPressed: (ctx) => _runAction(
              context,
              () => NoteActions.deleteNote(note),
              '${note['file_name'] ?? 'Note'} deleted.',
            ),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: Icon(
            isStarred ? Icons.star : Icons.description,
            color: Colors.teal,
            size: 40,
          ),
          title: Text(
            note['file_name'] ?? 'Untitled Note',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('Swipe left for actions · Tap to study'),
          trailing: const Icon(Icons.play_circle_fill, color: Colors.teal),
          onTap: () => NoteActions.openNote(context, note),
        ),
      ),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    agentDebugLog(
      location: 'note_actions.dart:_runAction',
      message: 'Slidable action pressed',
      hypothesisId: 'E',
      data: {'noteId': note['id']?.toString()},
    );

    try {
      await action();
      onChanged?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (error) {
      agentDebugLog(
        location: 'note_actions.dart:_runAction',
        message: 'Slidable action failed',
        hypothesisId: 'C',
        data: {'noteId': note['id']?.toString(), 'error': error.toString()},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $error')),
        );
      }
    }
  }
}
