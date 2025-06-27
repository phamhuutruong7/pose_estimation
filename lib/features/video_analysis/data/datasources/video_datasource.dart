import 'package:file_picker/file_picker.dart';

import '../../domain/entities/video_item.dart';

abstract class VideoDataSource {
  Future<VideoItem?> importVideo();
  Future<List<VideoItem>> getVideoHistory();
  Future<void> saveVideoToHistory(VideoItem video);
  Future<void> removeVideoFromHistory(String videoId);
  Future<void> clearVideoHistory();
}

class VideoDataSourceImpl implements VideoDataSource {
  // For simplicity, using in-memory storage
  // In a real app, you'd use local database (SQLite/Hive) or shared preferences
  final List<VideoItem> _videoHistory = [];

  @override
  Future<VideoItem?> importVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final videoItem = VideoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          path: file.path!,
          name: file.name,
          sizeInBytes: file.size,
          duration: Duration.zero, // Will be determined when video loads
          thumbnailPath: null,
          addedDate: DateTime.now(),
        );
        
        return videoItem;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to import video: $e');
    }
  }

  @override
  Future<List<VideoItem>> getVideoHistory() async {
    return List.from(_videoHistory);
  }

  @override
  Future<void> saveVideoToHistory(VideoItem video) async {
    // Remove if already exists (to avoid duplicates)
    _videoHistory.removeWhere((item) => item.path == video.path);
    
    // Add to beginning of list (most recent first)
    _videoHistory.insert(0, video);
    
    // Keep only last 20 videos
    if (_videoHistory.length > 20) {
      _videoHistory.removeRange(20, _videoHistory.length);
    }
  }

  @override
  Future<void> removeVideoFromHistory(String videoId) async {
    _videoHistory.removeWhere((item) => item.id == videoId);
  }

  @override
  Future<void> clearVideoHistory() async {
    _videoHistory.clear();
  }
}
