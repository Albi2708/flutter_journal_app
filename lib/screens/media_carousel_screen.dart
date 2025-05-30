import 'dart:io';
import 'package:flutter/material.dart';
import 'package:journal_app/db/database_helper.dart';
import 'package:journal_app/models/media_item.dart';

/// A full-screen carousel viewer for photos attached to a journal entry.
///
/// Displays all images for the entry with ID [entryId], allows swiping
/// between them, and deleting individual images.
class MediaCarouselScreen extends StatefulWidget {
  /// The ID of the journal entry whose media items will be shown.
  final int entryId;

  const MediaCarouselScreen({super.key, required this.entryId});

  @override
  State<MediaCarouselScreen> createState() => _MediaCarouselScreenState();
}

class _MediaCarouselScreenState extends State<MediaCarouselScreen> {
  /// Controller for the [PageView] to enable programmatic page changes.
  final _pageController = PageController();

  /// Future that resolves to the list of media items for this entry.
  late Future<List<MediaItem>> _mediaFuture;

  @override
  void initState() {
    super.initState();
    // Kick off loading of media items from the database.
    _mediaFuture = DatabaseHelper().getMediaByEntry(widget.entryId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MediaItem>>(
      future: _mediaFuture,
      builder: (ctx, snap) {
        // While loading, show a spinner.
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final media = snap.data ?? [];

        // Once loaded, display either a message or a swipeable PageView.
        return Scaffold(
          appBar: AppBar(title: const Text('Media')),
          body: media.isEmpty
              ? const Center(child: Text('No media to display'))
              : PageView.builder(
                  controller: _pageController,
                  itemCount: media.length,
                  itemBuilder: (ctx, idx) {
                    final m = media[idx];
                    return Stack(
                      children: [
                        // Show the image scaled to fit.
                        Positioned.fill(
                          child: Image.file(
                            File(m.path),
                            fit: BoxFit.contain,
                          ),
                        ),
                        // A delete button in the top-right corner.
                        Positioned(
                          top: 16,
                          right: 16,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              // Confirm deletion with the user.
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Delete Media?'),
                                  content: const Text(
                                    'This will remove the image.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                // Delete from database and update UI.
                                await DatabaseHelper().deleteMedia(m.id!);
                                setState(() => media.removeAt(idx));
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Dispose of the page controller to free resources.
    _pageController.dispose();
    super.dispose();
  }
}
