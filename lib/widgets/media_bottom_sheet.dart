import 'package:flutter/material.dart';

class MediaBottomSheet extends StatelessWidget {
  final bool hasMedia;
  const MediaBottomSheet({super.key, required this.hasMedia});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          if (hasMedia) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('View Media'),
              onTap: () => Navigator.pop(context, 'view'),
            ),
          ],
        ],
      ),
    );
  }
}
