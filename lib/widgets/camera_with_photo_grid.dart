import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CameraWithPhotoGrid extends StatefulWidget {
  final PhotoSession? photoSession;
  final Function(String photoPath)? onPhotoTaken;
  final Function(String photoPath)? onPhotoRemoved;
  final Function(List<String> photoPaths)? onSessionComplete;
  final bool clearExistingPhotos;

  const CameraWithPhotoGrid({
    super.key,
    this.photoSession,
    this.onPhotoTaken,
    this.onPhotoRemoved,
    this.onSessionComplete,
    this.clearExistingPhotos = true,
  });

  @override
  State<CameraWithPhotoGrid> createState() => _CameraWithPhotoGridState();
}

class _CameraWithPhotoGridState extends State<CameraWithPhotoGrid> {
  late PhotoSession _photoSession;
  SensorPosition _currentSensor = SensorPosition.back;

  @override
  void initState() {
    super.initState();
    _photoSession = widget.photoSession ?? PhotoSession();

    if (widget.clearExistingPhotos) {
      _photoSession.clearAll();
    }
  }

  void _switchCamera() {
    setState(() {
      _currentSensor = _currentSensor == SensorPosition.back
          ? SensorPosition.front
          : SensorPosition.back;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey(_currentSensor), // Force rebuild when sensor changes
      body: CameraAwesomeBuilder.custom(
        saveConfig: SaveConfig.photo(
          pathBuilder: (sensors) async {
            final Directory extDir = await getTemporaryDirectory();
            final String dirPath = '${extDir.path}/Pictures/CamerAwesome';
            await Directory(dirPath).create(recursive: true);
            final String filePath =
                '$dirPath/${DateTime.now().millisecondsSinceEpoch}.jpg';
            return SingleCaptureRequest(filePath, sensors.first);
          },
        ),
        sensorConfig: SensorConfig.single(
          sensor: Sensor.position(_currentSensor),
          flashMode: FlashMode.auto,
          aspectRatio: CameraAspectRatios.ratio_16_9,
        ),
        onMediaCaptureEvent: (mediaCapture) {
          if (mediaCapture.status == MediaCaptureStatus.success) {
            final String? photoPath = mediaCapture.captureRequest.when(
              single: (single) => single.file?.path,
              multiple: (multiple) => multiple.fileBySensor.values.first?.path,
            );

            if (photoPath != null) {
              _photoSession.addPhoto(photoPath);
              widget.onPhotoTaken?.call(photoPath);
            }
          }
        },
        builder: (cameraState, preview) {
          return cameraState.when(
            onPreparingCamera: (state) => const Center(
              child: CircularProgressIndicator(),
            ),
            onPhotoMode: (state) => _PhotoModeUI(
              state: state,
              photoSession: _photoSession,
              onSessionComplete: () {
                final photoPaths =
                    _photoSession.photos.map((p) => p.path).toList();
                widget.onSessionComplete?.call(photoPaths);
              },
              onPhotoRemoved: widget.onPhotoRemoved,
              onSwitchCamera: _switchCamera,
            ),
            onVideoMode: (state) => const Center(
              child: Text('Video mode not supported'),
            ),
            onVideoRecordingMode: (state) => const Center(
              child: Text('Video recording not supported'),
            ),
          );
        },
      ),
    );
  }
}

class _PhotoModeUI extends StatelessWidget {
  final PhotoCameraState state;
  final PhotoSession photoSession;
  final VoidCallback? onSessionComplete;
  final Function(String photoPath)? onPhotoRemoved;
  final VoidCallback? onSwitchCamera;

  const _PhotoModeUI({
    required this.state,
    required this.photoSession,
    this.onSessionComplete,
    this.onPhotoRemoved,
    this.onSwitchCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top actions
        Positioned(
          top: 0,
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
              color: Colors.black.withOpacity(0.8),
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
                // Back button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                // Flash toggle (centered)
                IconButton(
                  onPressed: () {
                    final currentFlash = state.sensorConfig.flashMode;
                    final newFlash = currentFlash == FlashMode.none
                        ? FlashMode.auto
                        : FlashMode.none;
                    state.sensorConfig.setFlashMode(newFlash);
                  },
                  icon: StreamBuilder<FlashMode>(
                    stream: state.sensorConfig.flashMode$,
                    builder: (context, snapshot) {
                      final flashMode = snapshot.data ?? FlashMode.none;
                      return Icon(
                        flashMode == FlashMode.none
                            ? Icons.flash_off
                            : Icons.flash_auto,
                        color: Colors.white,
                        size: 28,
                      );
                    },
                  ),
                ),
                // Done button
                AnimatedBuilder(
                  animation: photoSession,
                  builder: (context, child) {
                    return TextButton(
                      onPressed:
                          photoSession.hasPhotos ? onSessionComplete : null,
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: photoSession.hasPhotos
                              ? Colors.yellow
                              : Colors.white38,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Photo grid
                  PhotoGrid(
                    photoSession: photoSession,
                    onPhotoTap: (index) {
                      // Open photo viewer when a photo is tapped
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PhotoViewer(
                            photoSession: photoSession,
                            initialIndex: index,
                            onDone: onSessionComplete,
                            onPhotoRemove: (index) {
                              final photoPath =
                                  photoSession.getPhoto(index)!.path;
                              photoSession.removePhoto(index);
                              onPhotoRemoved?.call(photoPath);
                            },
                          ),
                        ),
                      );
                    },
                    onPhotoRemove: (index) {
                      final photoPath = photoSession.getPhoto(index)!.path;
                      photoSession.removePhoto(index);
                      onPhotoRemoved?.call(photoPath);
                    },
                    height: 100,
                  ),

                  const SizedBox(height: 16),

                  // Camera controls
                  SizedBox(
                    height: 80,
                    child: Stack(
                      children: [
                        // Gallery button - positioned at bottom left
                        Positioned(
                          left: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: AnimatedBuilder(
                              animation: photoSession,
                              builder: (context, child) {
                                return GestureDetector(
                                  onTap: () => _openDeviceGallery(context),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.photo_library,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Capture button - positioned at center
                        Positioned.fill(
                          child: Center(
                            child: AnimatedBuilder(
                              animation: photoSession,
                              builder: (context, child) {
                                final canTakePhoto =
                                    photoSession.canAddMorePhotos;
                                return GestureDetector(
                                  onTap: canTakePhoto
                                      ? () => state.takePhoto()
                                      : null,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: canTakePhoto
                                            ? Colors.white
                                            : Colors.white38,
                                        width: 4,
                                      ),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: canTakePhoto
                                            ? Colors.white
                                            : Colors.white38,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Camera switch button - positioned at bottom right (uncomment if needed)
                        // Positioned(
                        //   right: 16,
                        //   top: 0,
                        //   bottom: 0,
                        //   child: Center(
                        //     child: IconButton(
                        //       onPressed: onSwitchCamera,
                        //       icon: const Icon(
                        //         Icons.flip_camera_ios,
                        //         color: Colors.white,
                        //         size: 32,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openDeviceGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    // Calculate remaining photo slots (max 10 total)
    final int remainingSlots = 10 - photoSession.photoCount;

    // Check if we can add more photos
    if (remainingSlots <= 0) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Maximum 10 photos reached. Remove some photos first.'),
      //     backgroundColor: Colors.orange,
      //     duration: Duration(seconds: 2),
      //   ),
      // );
      return;
    }

    try {
      List<XFile> selectedImages = [];

      if (remainingSlots > 1) {
        // Use multi-select with limit
        selectedImages = await picker.pickMultiImage(limit: remainingSlots);
      } else {
        // Only one slot remaining, use single selection
        final XFile? singleImage = await picker.pickImage(
          source: ImageSource.gallery,
        );
        if (singleImage != null) {
          selectedImages = [singleImage];
        }
      }

      if (selectedImages.isNotEmpty) {
        // Add selected images to photo session
        int addedCount = 0;
        for (final image in selectedImages) {
          if (photoSession.canAddMorePhotos) {
            photoSession.addPhoto(image.path);
            addedCount++;
          } else {
            break; // Stop if we've reached the limit
          }
        }

        // Show confirmation message
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(
        //       addedCount == 1
        //           ? 'Added 1 photo to session'
        //           : 'Added $addedCount photos to session',
        //     ),
        //     backgroundColor: Colors.green,
        //     duration: const Duration(seconds: 2),
        //   ),
        // );

        // Show warning if some photos were not added due to limit
        if (selectedImages.length > addedCount) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(
          //       'Only $addedCount of ${selectedImages.length} photos added. Maximum 10 photos allowed.',
          //     ),
          //     backgroundColor: Colors.orange,
          //     duration: const Duration(seconds: 3),
          //   ),
          // );
        }
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Error accessing gallery: $e'),
      //     backgroundColor: Colors.red,
      //     duration: const Duration(seconds: 2),
      //   ),
      // );
      debugPrint('Error accessing gallery: $e');
    }
  }
}
