import 'dart:io';

import 'package:adaptivise_prototype/logic/folders_cubit.dart';
import 'package:adaptivise_prototype/logic/notes_cubit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AdaptSource { pdf, docx, html, pptx }

Future<void> showAdaptNotesFlow(BuildContext context) async {
  final foldersState = context.read<FoldersCubit>().state;
  final folders = switch (foldersState) {
    FoldersLoaded(:final folders) => folders,
    FoldersActionSuccess(:final folders) => folders,
    _ => <Map<String, dynamic>>[],
  };

  if (folders.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create a subject first using the drawer.')),
    );
    return;
  }

  final notesState = context.read<NotesCubit>().state;
  String? folderId = notesState is NotesLoaded
      ? notesState.selectedFolderId
      : notesState is NotesActionMessage
          ? notesState.selectedFolderId
          : null;

  if (folderId == null) {
    folderId = await _pickSubject(context, folders);
    if (folderId == null) return;
  }

  if (!context.mounted) return;
  final source = await showModalBottomSheet<AdaptSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adapt Notes From',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _sourceTile(ctx, AdaptSource.pdf, Icons.picture_as_pdf, 'PDF', 'Upload a .pdf file'),
            _sourceTile(ctx, AdaptSource.docx, Icons.description, 'Word Document', 'Upload a .docx file'),
            _sourceTile(ctx, AdaptSource.pptx, Icons.slideshow, 'PowerPoint', 'Upload a .pptx file'),
            _sourceTile(ctx, AdaptSource.html, Icons.language, 'Web Page', 'Paste a web link (HTML)'),
          ],
        ),
      ),
    ),
  );

  if (source == null || !context.mounted) return;

  switch (source) {
    case AdaptSource.html:
      final url = await _promptUrl(context);
      if (url == null || url.trim().isEmpty) return;
      if (!context.mounted) return;
      await context.read<NotesCubit>().uploadFromUrl(url.trim(), folderId);
    case AdaptSource.pdf:
      await _pickFile(context, folderId, ['pdf']);
    case AdaptSource.docx:
      await _pickFile(context, folderId, ['docx']);
    case AdaptSource.pptx:
      await _pickFile(context, folderId, ['pptx']);
  }
}

Widget _sourceTile(
  BuildContext context,
  AdaptSource source,
  IconData icon,
  String title,
  String subtitle,
) {
  return ListTile(
    leading: CircleAvatar(
      backgroundColor: Colors.teal.withValues(alpha: 0.12),
      child: Icon(icon, color: Colors.teal),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle),
    onTap: () => Navigator.pop(context, source),
  );
}

Future<String?> _pickSubject(
  BuildContext context,
  List<Map<String, dynamic>> folders,
) async {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Choose Subject'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: folders
              .map(
                (folder) => ListTile(
                  leading: const Icon(Icons.folder, color: Colors.teal),
                  title: Text(folder['name']?.toString() ?? 'Subject'),
                  onTap: () => Navigator.pop(ctx, folder['id'].toString()),
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}

Future<String?> _promptUrl(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Paste Web Link'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'https://example.com/article',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.url,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('Adapt'),
        ),
      ],
    ),
  );
}

Future<void> _pickFile(
  BuildContext context,
  String folderId,
  List<String> extensions,
) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: extensions,
  );

  if (result == null || result.files.single.path == null) return;
  if (!context.mounted) return;

  await context.read<NotesCubit>().uploadFromFile(
        File(result.files.single.path!),
        result.files.single.name,
        folderId,
      );
}
