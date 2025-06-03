import 'package:flutter/material.dart';
import 'dart:io';
import '../models/photo_session.dart';
import '../models/media_item.dart';

class PhotoGrid extends StatelessWidget {
  final PhotoSession photoSession;
  final Function(int index)? onPhotoTap;
  final Function(int index)? onPhotoRemove;
  final double height;
  final EdgeInsets padding;
  final int? selectedIndex;

  const PhotoGrid({
    super.key,
    required this.photoSession,
    this.onPhotoTap,
    this.onPhotoRemove,
    this.height = 120,
    this.padding = const EdgeInsets.all(8.0),
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: photoSession,
      builder: (context, child) {
        return Container(
          height: height,
          padding: padding,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 1.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: 10, // Always show 10 slots
            itemBuilder: (context, index) {
              final photo = index < photoSession.photoCount 
                  ? photoSession.getPhoto(index) 
                  : null;

              return _PhotoSlot(
                photo: photo,
                index: index,
                onTap: photo != null ? () => onPhotoTap?.call(index) : null,
                onRemove: photo != null ? onPhotoRemove : null,
                size: height - 16, // Account for padding
                isSelected: selectedIndex == index,
              );
            },
          ),
        );
      },
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final MediaItem? photo;
  final int index;
  final VoidCallback? onTap;
  final Function(int index)? onRemove;
  final double size;
  final bool isSelected;

  const _PhotoSlot({
    required this.photo,
    required this.index,
    this.onTap,
    this.onRemove,
    this.size = 80,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: photo != null ? Colors.transparent : Colors.grey[800],
          border: Border.all(
            color: isSelected 
                ? Colors.white 
                : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (photo != null) 
              ClipRRect(
                borderRadius: BorderRadius.circular(isSelected ? 6 : 7),
                child: Image.file(
                  File(photo!.path),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: size,
                      height: size,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 20,
                      ),
                    );
                  },
                ),
              )
            else
              // Empty slot placeholder
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: Colors.grey[800],
                ),
              ),
            
            if (photo != null && onRemove != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemove!(index),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
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