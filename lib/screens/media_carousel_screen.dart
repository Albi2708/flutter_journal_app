import 'dart:io';
import 'package:flutter/material.dart';
import 'package:journal_app/db/database_helper.dart';
import 'package:journal_app/models/media_item.dart';

class MediaCarouselScreen extends StatefulWidget {
  final int entryId;
  const MediaCarouselScreen({super.key, required this.entryId});

  @override
  State<MediaCarouselScreen> createState() => _MediaCarouselScreenState();
}

class _MediaCarouselScreenState extends State<MediaCarouselScreen> {
  final _pageController = PageController();
  late Future<List<MediaItem>> _mediaFuture;

  @override
  void initState() {
    super.initState();
    _mediaFuture = DatabaseHelper().getMediaByEntry(widget.entryId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MediaItem>>(
      future: _mediaFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final media = snap.data ?? [];
        return Scaffold(
          appBar: AppBar(title: const Text('Media')),
          body:
              media.isEmpty
                  ? const Center(child: Text('No media to display'))
                  : PageView.builder(
                    itemCount: media.length,
                    itemBuilder: (ctx, idx) {
                      final m = media[idx];
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Image.file(
                              File(m.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (c) => AlertDialog(
                                        title: const Text('Delete Media?'),
                                        content: const Text(
                                          'This will remove the image.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(c, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(c, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true) {
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
    _pageController.dispose();
    super.dispose();
  }
}
