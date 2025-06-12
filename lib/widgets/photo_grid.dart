import 'package:camerawesome/widgets/colors.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camerawesome/models/photo_session.dart';
import 'package:camerawesome/models/media_item.dart';

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
    return Padding(
      padding: const EdgeInsets.only(
          right: 8.0, top: 8.0), // space between items and top space for X
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none, // allow X to overflow
          children: [
            // Outer decoration (border, background, etc)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? Colors.white : AppColors.photoSlotBackground,
                  width: isSelected ? 1 : 0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photo != null
                    ? Image.file(
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
                      )
                    : Container(
                        color: AppColors.photoSlotBackground,
                      ),
              ),
            ),

            // Floating 'X' button
            if (photo != null && onRemove != null)
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () => onRemove!(index),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.removeButtonBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.removeButtonIcon,
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
