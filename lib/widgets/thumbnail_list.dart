import 'package:flutter/material.dart';
import '../models/media_item.dart';
import 'dart:io';

class ThumbnailList extends StatelessWidget {
  final List<MediaItem> media;
  const ThumbnailList({super.key, required this.media});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: media.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(
              children: [
                Image.file(File(media[i].path), width: 60, height: 60, fit: BoxFit.cover),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      // remove from list
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
} 