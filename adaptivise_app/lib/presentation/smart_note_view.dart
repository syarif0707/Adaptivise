import 'package:adaptivise_prototype/core/debug_log.dart';
import 'package:adaptivise_prototype/presentation/folder_content_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotesLibraryScreen extends StatefulWidget {
  const NotesLibraryScreen({super.key});

  @override
  State<NotesLibraryScreen> createState() => _NotesLibraryScreenState();
}

class _NotesLibraryScreenState extends State<NotesLibraryScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser!.id;
    final foldersStream = _supabase
        .from('folders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Subjects',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Create folder',
            onPressed: _showCreateFolderDialog,
            icon: const Icon(Icons.create_new_folder, color: Colors.teal),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateFolderDialog,
        backgroundColor: const Color(0xFF00695C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Subject',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: foldersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final folders = snapshot.data!;

          agentDebugLog(
            location: 'smart_note_view.dart:build',
            message: 'Folders stream update',
            hypothesisId: 'B',
            data: {'folderCount': folders.length},
          );

          if (folders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 72, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'No subjects yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a folder for each subject (e.g. Biology, Math) and upload notes inside it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showCreateFolderDialog,
                      icon: const Icon(Icons.create_new_folder),
                      label: const Text('Create Subject Folder'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.folder,
                    color: Colors.teal,
                    size: 40,
                  ),
                  title: Text(
                    folder['name'] ?? 'Untitled Folder',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Tap to view and adapt notes'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') {
                        _showRenameFolderDialog(folder);
                      } else if (value == 'delete') {
                        _confirmDeleteFolder(folder);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete folder')),
                    ],
                  ),
                  onTap: () {
                    agentDebugLog(
                      location: 'smart_note_view.dart:onTap',
                      message: 'Opening folder',
                      hypothesisId: 'B',
                      data: {
                        'folderId': folder['id']?.toString(),
                        'folderName': folder['name'],
                      },
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FolderContentScreen(
                          folderId: folder['id'].toString(),
                          folderName: folder['name'] ?? 'Folder',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateFolderDialog() async {
    final name = await _promptFolderName(title: 'New Subject Folder');
    if (name == null || name.trim().isEmpty) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('folders').insert({
        'user_id': userId,
        'name': name.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder "$name" created.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create folder: $error')),
        );
      }
    }
  }

  Future<void> _showRenameFolderDialog(Map<String, dynamic> folder) async {
    final name = await _promptFolderName(
      title: 'Rename Folder',
      initialValue: folder['name']?.toString() ?? '',
    );
    if (name == null || name.trim().isEmpty) return;

    try {
      await _supabase
          .from('folders')
          .update({'name': name.trim()})
          .eq('id', folder['id']);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not rename folder: $error')),
        );
      }
    }
  }

  Future<void> _confirmDeleteFolder(Map<String, dynamic> folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
          'Delete "${folder['name']}"? Notes inside will remain but lose this folder link.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase.from('folders').delete().eq('id', folder['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder deleted.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete folder: $error')),
        );
      }
    }
  }

  Future<String?> _promptFolderName({
    required String title,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Biology, Calculus, History',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => Navigator.pop(context, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
