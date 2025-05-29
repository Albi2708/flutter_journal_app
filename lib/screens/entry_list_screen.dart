import 'package:flutter/material.dart' hide CarouselController;
import 'package:journal_app/db/database_helper.dart';
import 'package:journal_app/models/folder.dart';
import 'package:journal_app/models/journal_entry.dart';
import 'package:journal_app/screens/entry_edit_screen.dart';
import 'package:journal_app/widgets/custom_alert_dialog.dart';
import 'package:intl/intl.dart';

class EntryListScreen extends StatefulWidget {
  final Folder folder;
  const EntryListScreen({super.key, required this.folder});

  @override
  State<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends State<EntryListScreen> {
  final db = DatabaseHelper();
  List<JournalEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final list = await db.getEntriesByFolder(widget.folder.id!);
    setState(() => _entries = list);
  }

  Future<void> _deleteEntry(int id) async {
    final confirm = await showCustomDialog<bool>(
      context: context,
      title: 'Delete Entry?',
      message: 'This will permanently delete the entry.',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    );
    if (confirm == true) {
      await db.deleteEntry(id);
      await _loadEntries();
    }
  }

  Future<void> _openEditor({JournalEntry? entry}) async {
    final didSave = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryEditScreen(folder: widget.folder, entry: entry),
      ),
    );
    if (didSave == true) {
      await _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name),
        backgroundColor: widget.folder.color,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _entries.length,
        itemBuilder: (_, i) {
          final e = _entries[i];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              title: Text(
                e.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                DateFormat.yMMMd().add_Hm().format(e.date.toLocal()),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _openEditor(entry: e),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteEntry(e.id!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.folder.color,
        onPressed: () async {
          await _openEditor();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
