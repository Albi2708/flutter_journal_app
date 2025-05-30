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

/// A screen for creating or viewing/editing a journal entry.
///
/// Allows the user to set a title, content, and attach or view media.
/// On save, inserts or updates the entry in the database.
class EntryEditScreen extends StatefulWidget {
  /// The folder to which this entry belongs.
  final Folder folder;

  /// An existing entry to edit, or null to create a new one.
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
    // If editing, pre-fill the text fields with existing data
    if (widget.entry != null) {
      _titleCtrl.text = widget.entry!.title;
      _contentCtrl.text = widget.entry!.content;
    }
  }

  /// Validates input, then inserts or updates the entry in the database.
  ///
  /// Pops the screen with `true` on success to signal a reload.
  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    // Require a non-empty title
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
      // New entry
      await db.insertEntry(e);
    } else {
      // Existing entry
      await db.updateEntry(e);
    }

    // Signal to caller that a save occurred
    Navigator.of(context).pop(true);
  }

  /// Opens the image picker (camera or gallery), saves the file locally,
  /// and records its path in the media table.
  Future<void> _pickAndSaveImage(ImageSource src) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: src);
    if (file == null) return; // user cancelled

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

  /// Presents a bottom sheet with options to take a photo, pick from gallery,
  /// or view existing media attachments.
  Future<void> _showMediaOptions() async {
    // Must save entry first to have an ID
    if (widget.entry?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save the entry first to add media')),
      );
      return;
    }

    // Check if media already exists
    final media = await db.getMediaByEntry(widget.entry!.id!);

    // Show actions sheet
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => MediaBottomSheet(hasMedia: media.isNotEmpty),
    );
    if (choice == null) return;

    // Handle selection
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

      /// Floating action to add/view media.
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
            // Title input
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Content input (multiline)
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
