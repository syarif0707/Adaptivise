import 'dart:io';

import 'package:adaptivise_prototype/logic/notes_cubit.dart';
import 'package:adaptivise_prototype/presentation/adaptive_content/adaptive_note_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class NoteSlidableTile extends StatelessWidget {
  final Map<String, dynamic> note;

  const NoteSlidableTile({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final isStarred = note['is_starred'] == true;

    return Slidable(
      key: ValueKey(note['id']),
      groupTag: 'lecture_notes',
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.65,
        children: [
          SlidableAction(
            onPressed: (_) => _runAction(
              context,
              () => context.read<NotesCubit>().toggleStar(note),
            ),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            icon: isStarred ? Icons.star : Icons.star_border,
            label: isStarred ? 'Unstar' : 'Star',
          ),
          SlidableAction(
            onPressed: (_) => _runAction(
              context,
              () async {
                // Request permission when user taps download
                if (Platform.isAndroid || Platform.isIOS) {
                  await Permission.storage.request();
                }
                if (!context.mounted) return;
                await context.read<NotesCubit>().downloadNote(note);
              },
            ),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.download,
            label: 'Save',
          ),
          SlidableAction(
            onPressed: (_) => _runAction(
              context,
              () => context.read<NotesCubit>().deleteNote(note),
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
        margin: const EdgeInsets.only(top: 4,bottom: 12),
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
          onTap: () => _openNote(context, note),
        ),
      ),
    );
  }

  Future<void> _openNote(
    BuildContext context,
    Map<String, dynamic> note,
  ) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    final profile = await supabase
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

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $error')),
        );
      }
    }
  }
}