import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:image_picker/image_picker.dart';

import 'package:journal_app/db/database_helper.dart';
import 'package:journal_app/models/folder.dart';
import 'package:journal_app/models/journal_entry.dart';
import 'package:journal_app/models/media_item.dart';
import 'package:journal_app/widgets/media_bottom_sheet.dart';
import 'package:journal_app/screens/media_carousel_screen.dart';

class EntryEditScreen extends StatefulWidget {
  final Folder folder;
  final JournalEntry? entry;
  const EntryEditScreen({super.key, required this.folder, this.entry});

  @override
  State<EntryEditScreen> createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends State<EntryEditScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleCtrl.text = widget.entry!.title;
      _contentCtrl.text = widget.entry!.content;
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    final now = DateTime.now();
    final e = JournalEntry(
      id: widget.entry?.id,
      folderId: widget.folder.id!,
      title: title,
      content: content,
      date: now,
    );
    if (widget.entry == null) {
      await db.insertEntry(e);
    } else {
      await db.updateEntry(e);
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _pickAndSaveImage(ImageSource src) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: src);
    if (file == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(file.path);
    final newPath = p.join(appDir.path, fileName);
    final saved = await File(file.path).copy(newPath);

    await db.insertMedia(
      MediaItem(
        entryId: widget.entry!.id!,
        path: saved.path,
        date: DateTime.now(),
      ),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Media added')));
  }

  Future<void> _showMediaOptions() async {
    if (widget.entry?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save the entry first to add media')),
      );
      return;
    }

    final media = await db.getMediaByEntry(widget.entry!.id!);

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => MediaBottomSheet(hasMedia: media.isNotEmpty),
    );
    if (choice == null) return;

    if (choice == 'camera') {
      await _pickAndSaveImage(ImageSource.camera);
    } else if (choice == 'gallery') {
      await _pickAndSaveImage(ImageSource.gallery);
    } else if (choice == 'view') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MediaCarouselScreen(entryId: widget.entry!.id!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'New Entry'),
        backgroundColor: widget.folder.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.folder.color,
        onPressed: _showMediaOptions,
        tooltip: 'Add Media',
        child: const Icon(Icons.camera_alt),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
