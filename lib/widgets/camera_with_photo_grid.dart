import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:path_provider/path_provider.dart';
import '../models/photo_session.dart';
import 'photo_grid.dart';
import 'dart:io';

class CameraWithPhotoGrid extends StatefulWidget {
  final PhotoSession? photoSession;
  final Function(String photoPath)? onPhotoTaken;
  final Function(List<String> photoPaths)? onSessionComplete;

  const CameraWithPhotoGrid({
    super.key,
    this.photoSession,
    this.onPhotoTaken,
    this.onSessionComplete,
  });

  @override
  State<CameraWithPhotoGrid> createState() => _CameraWithPhotoGridState();
}

class _CameraWithPhotoGridState extends State<CameraWithPhotoGrid> {
  late PhotoSession _photoSession;

  @override
  void initState() {
    super.initState();
    _photoSession = widget.photoSession ?? PhotoSession();
    // Clear any existing photos to start fresh
    _photoSession.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.custom(
        saveConfig: SaveConfig.photo(
          pathBuilder: (sensors) async {
            final Directory extDir = await getTemporaryDirectory();
            final String dirPath = '${extDir.path}/Pictures/CamerAwesome';
            await Directory(dirPath).create(recursive: true);
            final String filePath = '$dirPath/${DateTime.now().millisecondsSinceEpoch}.jpg';
            return SingleCaptureRequest(filePath, sensors.first);
          },
        ),
        sensorConfig: SensorConfig.single(
          aspectRatio: CameraAspectRatios.ratio_4_3,
          sensor: Sensor.position(SensorPosition.back),
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
                final photoPaths = _photoSession.photos.map((p) => p.path).toList();
                widget.onSessionComplete?.call(photoPaths);
              },
            ),
            onVideoMode: (state) => const Center(
              child: Text('Video mode not supported in this example'),
            ),
            onVideoRecordingMode: (state) => const Center(
              child: Text('Video recording not supported in this example'),
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

  const _PhotoModeUI({
    required this.state,
    required this.photoSession,
    this.onSessionComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top actions
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
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
              // Photo count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedBuilder(
                  animation: photoSession,
                  builder: (context, child) {
                    return Text(
                      '${photoSession.photoCount} photos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              // Flash toggle
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
            ],
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
                    onPhotoRemove: (index) {
                      photoSession.removePhoto(index);
                    },
                    height: 100,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Camera controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Clear all photos
                      AnimatedBuilder(
                        animation: photoSession,
                        builder: (context, child) {
                          return IconButton(
                            onPressed: photoSession.hasPhotos 
                                ? () => _showClearDialog(context)
                                : null,
                            icon: Icon(
                              Icons.delete_sweep,
                              color: photoSession.hasPhotos 
                                  ? Colors.white 
                                  : Colors.white38,
                              size: 32,
                            ),
                          );
                        },
                      ),
                      
                      // Capture button
                      AnimatedBuilder(
                        animation: photoSession,
                        builder: (context, child) {
                          final canTakePhoto = photoSession.canAddMorePhotos;
                          return GestureDetector(
                            onTap: canTakePhoto ? () => state.takePhoto() : null,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: canTakePhoto ? Colors.white : Colors.white38,
                                  width: 4,
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: canTakePhoto ? Colors.white : Colors.white38,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Done button
                      AnimatedBuilder(
                        animation: photoSession,
                        builder: (context, child) {
                          return IconButton(
                            onPressed: photoSession.hasPhotos 
                                ? onSessionComplete
                                : null,
                            icon: Icon(
                              Icons.check,
                              color: photoSession.hasPhotos 
                                  ? Colors.green 
                                  : Colors.white38,
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ],
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

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Photos'),
          content: const Text('Are you sure you want to delete all captured photos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                photoSession.clearAll();
                Navigator.of(context).pop();
              },
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
} 