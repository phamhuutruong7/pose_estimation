import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:async';

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
        
        // Generate thumbnail for the video
        final thumbnailPath = await _generateVideoThumbnail(file.path!);
        
        final videoItem = VideoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          path: file.path!,
          name: file.name,
          sizeInBytes: file.size,
          duration: Duration.zero, // Will be determined when video loads
          thumbnailPath: thumbnailPath,
          addedDate: DateTime.now(),
        );
        
        return videoItem;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to import video: $e');
    }
  }

  Future<String?> _generateVideoThumbnail(String videoPath) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String thumbnailsDir = path.join(appDocDir.path, 'thumbnails');
      
      // Create thumbnails directory if it doesn't exist
      final Directory thumbDir = Directory(thumbnailsDir);
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }
      
      // Generate a unique filename for the thumbnail
      final String videoFileName = path.basenameWithoutExtension(videoPath);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String thumbnailPath = path.join(thumbnailsDir, '${videoFileName}_${timestamp}.jpg');
      
      print('Attempting to generate thumbnail for: $videoPath');
      
      // Try using FFmpeg if available
      try {
        print('Attempting to generate thumbnail using FFmpeg...');
        final String ffmpegThumbnailPath = await _generateThumbnailWithFFmpeg(videoPath, thumbnailPath);
        if (await File(ffmpegThumbnailPath).exists()) {
          print('✓ Thumbnail generated successfully using FFmpeg: $ffmpegThumbnailPath');
          return ffmpegThumbnailPath;
        }
      } catch (e) {
        print('✗ FFmpeg thumbnail generation failed: $e');
        if (e.toString().contains('No such file or directory') || 
            e.toString().contains('not recognized') ||
            e.toString().contains('cannot run')) {
          print('  → FFmpeg is not installed or not in PATH');
          print('  → To enable video thumbnails, install FFmpeg:');
          print('    1. Download from https://ffmpeg.org/download.html');
          print('    2. Extract to C:\\ffmpeg\\');  
          print('    3. Add C:\\ffmpeg\\bin to your system PATH');
          print('    4. Restart the application');
        }
      }
      
      print('ℹ Using placeholder thumbnail - FFmpeg not available');
      print('  For actual video frame thumbnails, please install FFmpeg');
      
      return null; // Use placeholder thumbnail
    } catch (e) {
      print('Error in video thumbnail generation: $e');
      return null;
    }
  }

  Future<String> _generateThumbnailWithFFmpeg(String videoPath, String thumbnailPath) async {
    // Try to use FFmpeg to extract a thumbnail
    print('Running FFmpeg command: ffmpeg -i "$videoPath" -ss 1 -vframes 1 -vf scale=320:240 -y "$thumbnailPath"');
    
    final ProcessResult result = await Process.run(
      'ffmpeg',
      [
        '-i', videoPath,           // Input video
        '-ss', '1',                // Seek to 1 second
        '-vframes', '1',           // Extract 1 frame
        '-vf', 'scale=320:240',    // Scale to thumbnail size
        '-y',                      // Overwrite output file
        thumbnailPath,             // Output thumbnail path
      ],
      runInShell: true,
    );
    
    if (result.exitCode == 0) {
      print('FFmpeg completed successfully');
      return thumbnailPath;
    } else {
      print('FFmpeg stderr: ${result.stderr}');
      print('FFmpeg stdout: ${result.stdout}');
      throw Exception('FFmpeg failed with exit code ${result.exitCode}: ${result.stderr}');
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

  Future<void> _cleanupThumbnail(String? thumbnailPath) async {
    if (thumbnailPath != null) {
      try {
        final File thumbnailFile = File(thumbnailPath);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      } catch (e) {
        print('Error cleaning up thumbnail: $e');
      }
    }
  }

  @override
  Future<void> removeVideoFromHistory(String videoId) async {
    // Find the video to get its thumbnail path before removing
    final videoToRemove = _videoHistory.where((item) => item.id == videoId).firstOrNull;
    if (videoToRemove != null) {
      // Clean up the thumbnail file
      await _cleanupThumbnail(videoToRemove.thumbnailPath);
    }
    _videoHistory.removeWhere((item) => item.id == videoId);
  }

  @override
  Future<void> clearVideoHistory() async {
    // Clean up all thumbnail files
    for (final video in _videoHistory) {
      await _cleanupThumbnail(video.thumbnailPath);
    }
    _videoHistory.clear();
  }
}
