import 'dart:io';

import 'package:flutter/material.dart';

class PhotoPreviewDialog extends StatefulWidget {
  final File imageFile;
  const PhotoPreviewDialog({super.key, required this.imageFile});

  @override
  State<PhotoPreviewDialog> createState() => _PhotoPreviewDialogState();
}

class _PhotoPreviewDialogState extends State<PhotoPreviewDialog> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.send, color: Colors.white),
            label: const Text('Gönder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(widget.imageFile),
        ),
      ),
    );
  }
}
