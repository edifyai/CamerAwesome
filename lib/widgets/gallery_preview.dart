import 'package:flutter/material.dart';
import '../models/media_item.dart';
import 'dart:io';

class GalleryPreview extends StatelessWidget {
  final List<MediaItem> media;
  const GalleryPreview({super.key, required this.media});
  @override
  Widget build(BuildContext context) => media.isEmpty
      ? const SizedBox(width: 60, height: 60)
      : Image.file(File(media.last.path), width: 60, height: 60, fit: BoxFit.cover);
} 