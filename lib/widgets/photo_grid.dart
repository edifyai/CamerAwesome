import 'package:flutter/material.dart';
import 'dart:io';
import '../models/photo_session.dart';
import '../models/media_item.dart';

class PhotoGrid extends StatelessWidget {
  final PhotoSession photoSession;
  final VoidCallback? onPhotoTap;
  final Function(int index)? onPhotoRemove;
  final double height;
  final EdgeInsets padding;

  const PhotoGrid({
    super.key,
    required this.photoSession,
    this.onPhotoTap,
    this.onPhotoRemove,
    this.height = 100,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: photoSession,
      builder: (context, child) {
        if (!photoSession.hasPhotos) {
          return SizedBox(height: height);
        }

        // Limit to maximum 10 photos
        final displayCount = photoSession.photoCount > 10 ? 10 : photoSession.photoCount;

        return Container(
          height: height,
          padding: padding,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayCount,
            itemBuilder: (context, index) {
              final photo = photoSession.getPhoto(index);
              if (photo == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _PhotoThumbnail(
                  photo: photo,
                  index: index,
                  onTap: onPhotoTap,
                  onRemove: onPhotoRemove,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final MediaItem photo;
  final int index;
  final VoidCallback? onTap;
  final Function(int index)? onRemove;

  const _PhotoThumbnail({
    required this.photo,
    required this.index,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(photo.path),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                    ),
                  );
                },
              ),
            ),
            if (onRemove != null)
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => onRemove!(index),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 