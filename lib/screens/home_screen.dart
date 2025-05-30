import 'package:flutter/material.dart' hide CarouselController;
import 'package:journal_app/main.dart';
import 'package:journal_app/screens/entry_list_screen.dart';
import 'package:provider/provider.dart';

import '../db/database_helper.dart';
import '../models/folder.dart';
import '../providers/app_settings.dart';
import '../widgets/custom_alert_dialog.dart';

/// The main screen showing user-defined folders and appearance settings.
///
/// Provides two tabs:
///  - **Folders**: list, create, edit, delete folders
///  - **Appearance**: toggle dark mode and pick header color
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  /// Helper instance for SQLite operations.
  final db = DatabaseHelper();

  /// Current list of folders loaded from the database.
  List<Folder> _folders = [];

  /// Palette of colors available for folders and header.
  static const Map<String, Color> _colorOptions = {
    'Green': Color(0xFF4CAF50),
    'Blue': Color(0xFF2196F3),
    'Red': Color(0xFFF44336),
    'Yellow': Color(0xFFFBC02D),
    'Purple': Color(0xFF9C27B0),
    'Orange': Color(0xFFFF9800),
    'Pink': Color(0xFFE91E63),
    'Black': Color(0xFF424242),
    'Gray': Color(0xFF757575),
    'Light Blue': Color(0xFF03A9F4),
    'Brown': Color(0xFF795548),
  };

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  /// Loads all folders from the database.
  ///
  /// If none exist, seeds the defaults and reloads.
  Future<void> _loadFolders() async {
    final list = await db.getAllFolders();
    if (list.isEmpty) {
      // Seed default folders on first run
      for (final f in [
        Folder(name: 'Daily Reflections', color: _colorOptions['Blue']!),
        Folder(name: 'Travel Notes', color: _colorOptions['Green']!),
        Folder(name: 'General Notes', color: _colorOptions['Orange']!),
      ]) {
        await db.insertFolder(f);
      }
      _folders = await db.getAllFolders();
    } else {
      _folders = list;
    }
    setState(() {});
  }

  /// Shows the add/edit folder dialog.
  ///
  /// If [folder] is provided, populates fields for editing.
  void _showFolderDialog({Folder? folder}) {
    final isEditing = folder != null;
    String name = folder?.name ?? '';
    String selectedKey = _colorOptions.keys.firstWhere(
      (k) => folder?.color.value == _colorOptions[k]!.value,
      orElse: () => _colorOptions.keys.first,
    );

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (_, setState) {
              return AlertDialog(
                title: Text(isEditing ? 'Edit Folder' : 'New Folder'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: TextEditingController(text: name),
                      onChanged: (v) => name = v,
                      decoration: const InputDecoration(
                        hintText: 'Folder name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _colorOptions.entries.map((e) {
                            final sel = e.key == selectedKey;
                            return GestureDetector(
                              onTap: () => setState(() => selectedKey = e.key),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: e.value,
                                  shape: BoxShape.circle,
                                  border:
                                      sel
                                          ? Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          )
                                          : null,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final trimmed = name.trim();
                      if (trimmed.isEmpty) return;
                      final color = _colorOptions[selectedKey]!;
                      if (isEditing) {
                        // Update existing folder
                        await db.updateFolder(
                          Folder(id: folder!.id, name: trimmed, color: color),
                        );
                      } else {
                        // Create new folder
                        await db.insertFolder(
                          Folder(name: trimmed, color: color),
                        );
                      }
                      await _loadFolders();
                      Navigator.pop(ctx);
                    },
                    child: Text(isEditing ? 'Save' : 'Add'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context)!;
    routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Refresh when returning from another screen
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    // Base style for folder buttons
    final baseStyle = OutlinedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surface,
      minimumSize: const Size.fromHeight(180),
      side: const BorderSide(width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      textStyle: const TextStyle(fontSize: 20),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Journal'),
          backgroundColor: settings.headerColor,
          bottom: const TabBar(
            tabs: [Tab(text: 'FOLDERS'), Tab(text: 'APPEARENCE')],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showFolderDialog,
          child: const Icon(Icons.add),
          backgroundColor: settings.headerColor,
        ),
        body: TabBarView(
          children: [
            // ###################### FOLDERS TAB ######################
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.separated(
                  itemCount: _folders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final f = _folders[i];
                    return OutlinedButton(
                      style: baseStyle.copyWith(
                        side: MaterialStateProperty.all(
                          BorderSide(color: f.color, width: 2),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EntryListScreen(folder: f),
                          ),
                        );
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        title: Text(
                          f.name,
                          style: TextStyle(
                            color: f.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: FutureBuilder<int>(
                          future: db.getEntryCountByFolder(f.id!),
                          builder: (ctx, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const Text('Loading…');
                            }
                            final cnt = snap.data ?? 0;
                            return Text(
                              '$cnt ${cnt == 1 ? "Entry" : "Entries"}',
                            );
                          },
                        ),
                        trailing: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert),
                          onSelected: (action) async {
                            if (action == 'edit') {
                              _showFolderDialog(folder: f);
                            } else {
                              final confirm = await showCustomDialog<bool>(
                                context: context,
                                title: 'Delete Folder?',
                                message:
                                    'This will delete the folder and ALL its entries.',
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                              if (confirm == true) {
                                await db.deleteEntriesByFolder(f.id!);
                                await db.deleteFolder(f.id!);
                                await _loadFolders();
                              }
                            }
                          },
                          itemBuilder:
                              (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ###################### APPEARENCE TAB ######################
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      value: settings.isDarkMode,
                      onChanged: settings.toggleDarkMode,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Main Color',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _colorOptions.entries.map((e) {
                            final sel = e.value == settings.headerColor;
                            return GestureDetector(
                              onTap: () => settings.updateHeaderColor(e.value),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: e.value,
                                  shape: BoxShape.circle,
                                  border:
                                      sel
                                          ? Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          )
                                          : null,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
