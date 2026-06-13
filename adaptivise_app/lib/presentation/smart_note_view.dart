import 'package:adaptivise_prototype/core/note_actions.dart';
import 'package:adaptivise_prototype/logic/folders_cubit.dart';
import 'package:adaptivise_prototype/logic/notes_cubit.dart';
import 'package:adaptivise_prototype/presentation/widgets/adapt_notes_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class NotesLibraryScreen extends StatefulWidget {
  const NotesLibraryScreen({super.key});

  @override
  State<NotesLibraryScreen> createState() => _NotesLibraryScreenState();
}

class _NotesLibraryScreenState extends State<NotesLibraryScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    context.read<FoldersCubit>().watchFolders();
    context.read<NotesCubit>().watchNotes();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FoldersCubit, FoldersState>(
      listener: (context, state) {
        if (state is FoldersActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is FoldersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: BlocConsumer<NotesCubit, NotesState>(
      listener: (context, state) {
        if (state is NotesActionMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is NotesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, notesState) {
        final isUploading =
            notesState is NotesLoaded ? notesState.isUploading : false;
        final selectedFolderName = notesState is NotesLoaded
            ? notesState.selectedFolderName
            : notesState is NotesActionMessage
                ? notesState.selectedFolderName
                : null;
        final notes = switch (notesState) {
          NotesLoaded(:final notes) => notes,
          NotesActionMessage(:final notes) => notes,
          _ => <Map<String, dynamic>>[],
        };

        final folders = switch (context.watch<FoldersCubit>().state) {
          FoldersLoaded(:final folders) => folders,
          FoldersActionSuccess(:final folders) => folders,
          _ => <Map<String, dynamic>>[],
        };

        final folderNames = {
          for (final f in folders) f['id'].toString(): f['name']?.toString() ?? 'Subject',
        };

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          endDrawer: _SubjectDrawer(folders: folders),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Files',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
                if (selectedFolderName != null)
                  Text(
                    selectedFolderName,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: 'Filter by subject',
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                icon: const Icon(Icons.filter_list, color: Colors.teal),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: isUploading ? null : () => showAdaptNotesFlow(context),
            backgroundColor: const Color(0xFF00695C),
            icon: isUploading
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
              isUploading ? 'Processing...' : 'Adapt Notes',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Column(
            children: [
              // Search Bar & Favorite Toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search notes...',
                          prefixIcon: const Icon(Icons.search, color: Colors.teal),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.teal),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.toLowerCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: _showFavoritesOnly ? Colors.teal.shade50 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                          color: _showFavoritesOnly ? Colors.teal : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _showFavoritesOnly = !_showFavoritesOnly;
                            context.read<NotesCubit>().setFilter(
                              _showFavoritesOnly ? NotesFilter.favorite : NotesFilter.all,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (notesState) {
                  NotesLoading() || NotesInitial() =>
                    const Center(child: CircularProgressIndicator()),
                  NotesError(:final message) => Center(child: Text(message)),
                  _ => Builder(
                    builder: (context) {
                      // Apply local search filter
                      final displayedNotes = notes.where((n) {
                        if (_searchQuery.isEmpty) return true;
                        final name = (n['file_name'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();

                      if (displayedNotes.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open,
                                    size: 72, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  selectedFolderName == null
                                      ? 'No notes found'
                                      : 'No notes in $selectedFolderName',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap Adapt Notes to upload PDF, Word, PowerPoint, or a web link.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SlidableAutoCloseBehavior(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedNotes.length,
                          itemBuilder: (context, index) {
                            final note = displayedNotes[index];
                            final subject = folderNames[note['folder_id']?.toString()] ??
                                'Unsorted';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (selectedFolderName == null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 6,
                                    ),
                                    child: Text(
                                      subject,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.teal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                NoteSlidableTile(note: note),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                },
              ),
            ],
          ),
        );
      },
      ),
    );
  }
}

class _SubjectDrawer extends StatelessWidget {
  final List<Map<String, dynamic>> folders;

  const _SubjectDrawer({required this.folders});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Subjects',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.all_inbox, color: Colors.teal),
              title: const Text('All subjects'),
              onTap: () {
                context.read<NotesCubit>().selectSubject();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Expanded(
              child: folders.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Create your first subject below.'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        return ListTile(
                          leading: const Icon(Icons.folder, color: Colors.teal),
                          title: Text(folder['name']?.toString() ?? 'Subject'),
                          onTap: () {
                            context.read<NotesCubit>().selectSubject(
                                  folderId: folder['id'].toString(),
                                  folderName:
                                      folder['name']?.toString() ?? 'Subject',
                                );
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final name = await _promptFolderName(context);
                    if (name != null && name.trim().isNotEmpty && context.mounted) {
                      await context.read<FoldersCubit>().createFolder(name.trim());
                    }
                  },
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('New Subject'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _promptFolderName(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Biology, History',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}