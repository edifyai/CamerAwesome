import 'package:flutter/foundation.dart';
import 'package:camerawesome/models/media_item.dart';

class PhotoSession extends ChangeNotifier {
  final List<MediaItem> _photos = [];
  static const int maxPhotos = 10;

  List<MediaItem> get photos => List.unmodifiable(_photos);

  int get photoCount => _photos.length;

  bool get hasPhotos => _photos.isNotEmpty;

  bool get canAddMorePhotos => _photos.length < maxPhotos;

  void addPhoto(String path) {
    if (_photos.length < maxPhotos) {
      _photos.add(MediaItem(path: path, isVideo: false));
      notifyListeners();
    }
  }

  void removePhoto(int index) {
    if (index >= 0 && index < _photos.length) {
      _photos.removeAt(index);
      notifyListeners();
    }
  }

  void removePhotoByPath(String path) {
    _photos.removeWhere((photo) => photo.path == path);
    notifyListeners();
  }

  void clearAll() {
    _photos.clear();
    notifyListeners();
  }

  MediaItem? getPhoto(int index) {
    if (index >= 0 && index < _photos.length) {
      return _photos[index];
    }
    return null;
  }
}
