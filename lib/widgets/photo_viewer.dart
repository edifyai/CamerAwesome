import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camerawesome/models/photo_session.dart';
import 'package:camerawesome/widgets/photo_grid.dart';

class PhotoViewer extends StatefulWidget {
  final PhotoSession photoSession;
  final int initialIndex;
  final Function(int index)? onPhotoRemove;
  final VoidCallback? onDone;

  const PhotoViewer({
    super.key,
    required this.photoSession,
    required this.initialIndex,
    this.onPhotoRemove,
    this.onDone,
  });

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late int _currentIndex;
  late PageController _pageController;
  bool _showGrid = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: widget.photoSession,
        builder: (context, child) {
          // Ensure current index is valid
          if (_currentIndex >= widget.photoSession.photoCount) {
            _currentIndex = widget.photoSession.photoCount - 1;
          }
          if (_currentIndex < 0 && widget.photoSession.hasPhotos) {
            _currentIndex = 0;
          }

          final currentPhoto = widget.photoSession.hasPhotos
              ? widget.photoSession.getPhoto(_currentIndex)
              : null;

          if (currentPhoto == null) {
            return const Center(
              child: Text(
                'No photos available',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.photoSession.photoCount,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final photo = widget.photoSession.getPhoto(index);
                  return Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showGrid = !_showGrid;
                        });
                      },
                      child: Image.file(
                        File(photo?.path ?? ''),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 100,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              // Top bar with back, flag, and done buttons
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: _showGrid ? 0 : -100,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back arrow
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      // Done button
                      TextButton(
                        onPressed: () {
                          widget.onDone?.call();
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom grid
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                bottom: _showGrid ? 0 : -150,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: PhotoGrid(
                      photoSession: widget.photoSession,
                      selectedIndex: _currentIndex,
                      onPhotoTap: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      onPhotoRemove: widget.onPhotoRemove,
                      height: 100,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
