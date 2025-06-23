import 'package:flutter/material.dart';

class VideoImportDialog extends StatelessWidget {
  final VoidCallback onImportFromDevice;
  final VoidCallback onImportFromCamera;

  const VideoImportDialog({
    super.key,
    required this.onImportFromDevice,
    required this.onImportFromCamera,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Video'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('From Device Storage'),
            subtitle: const Text('Select videos from your device'),
            onTap: () {
              Navigator.pop(context);
              onImportFromDevice();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Record New Video'),
            subtitle: const Text('Record a new video using camera'),
            onTap: () {
              Navigator.pop(context);
              onImportFromCamera();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onImportFromDevice,
    required VoidCallback onImportFromCamera,
  }) {
    return showDialog(
      context: context,
      builder: (context) => VideoImportDialog(
        onImportFromDevice: onImportFromDevice,
        onImportFromCamera: onImportFromCamera,
      ),
    );
  }
}
