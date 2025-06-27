import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:async';

import '../../domain/entities/video_item.dart';

abstract class VideoDataSource {
  Future<VideoItem?> importVideo();
  Future<List<VideoItem>> getVideoHistory();
  Future<void> saveVideoToHistory(VideoItem video);
  Future<void> removeVideoFromHistory(String videoId);
  Future<void> removeVideosFromHistory(List<String> videoIds);
  Future<void> clearVideoHistory();
}

class VideoDataSourceImpl implements VideoDataSource {
  static const String _storageKey = 'video_history';
  final List<VideoItem> _videoHistory = [];
  bool _isLoaded = false;

  Future<void> _loadVideoHistory() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _videoHistory.clear();
        
        for (final jsonItem in jsonList) {
          try {
            final videoItem = VideoItem.fromJson(jsonItem as Map<String, dynamic>);
            // Verify the video file still exists before adding to history
            if (await File(videoItem.path).exists()) {
              _videoHistory.add(videoItem);
            } else {
              // Clean up thumbnail if video file no longer exists
              await _cleanupThumbnail(videoItem.thumbnailPath);
            }
          } catch (e) {
            print('Error loading video item from storage: $e');
          }
        }
      }
      
      _isLoaded = true;
      print('Loaded ${_videoHistory.length} videos from storage');
    } catch (e) {
      print('Error loading video history: $e');
      _isLoaded = true;
    }
  }

  Future<void> _saveVideoHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList = 
          _videoHistory.map((video) => video.toJson()).toList();
      final String jsonString = json.encode(jsonList);
      await prefs.setString(_storageKey, jsonString);
      print('Saved ${_videoHistory.length} videos to storage');
    } catch (e) {
      print('Error saving video history: $e');
    }
  }

  @override
  Future<VideoItem?> importVideo() async {
    try {
      // Load existing videos first
      await _loadVideoHistory();
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final filePath = file.path!;
        
        // Check if this video is already imported (prevent duplicates)
        // Use file name and size for duplicate detection since cached paths are different each time
        final existingVideos = _videoHistory.where((video) => 
          video.name == file.name && video.sizeInBytes == file.size
        );
        if (existingVideos.isNotEmpty) {
          final existingVideo = existingVideos.first;
          print('Video already imported: ${file.name} (${file.size} bytes)');
          return existingVideo; // Return existing video instead of creating duplicate
        }
        
        // Generate thumbnail for the video
        final thumbnailPath = await _generateVideoThumbnail(filePath);
        
        final videoItem = VideoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          path: filePath,
          name: file.name,
          sizeInBytes: file.size,
          duration: Duration.zero, // Will be determined when video loads
          thumbnailPath: thumbnailPath,
          addedDate: DateTime.now(),
        );
        
        // Add to history and save
        await saveVideoToHistory(videoItem);
        
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
      
      // Try using video_thumbnail package first (works on Android)
      try {
        print('Attempting to generate thumbnail using video_thumbnail package...');
        final String? videoThumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: thumbnailPath,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 240,
          maxWidth: 320,
          timeMs: 1000, // Extract frame at 1 second
          quality: 75,
        );
        
        if (videoThumbnailPath != null && await File(videoThumbnailPath).exists()) {
          print('✓ Thumbnail generated successfully using video_thumbnail: $videoThumbnailPath');
          return videoThumbnailPath;
        }
      } catch (e) {
        print('✗ video_thumbnail generation failed: $e');
      }
      
      // Fallback to FFmpeg for desktop platforms
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
            print('  → To enable video thumbnails on desktop, install FFmpeg:');
            print('    1. Download from https://ffmpeg.org/download.html');
            print('    2. Extract to C:\\ffmpeg\\');  
            print('    3. Add C:\\ffmpeg\\bin to your system PATH');
            print('    4. Restart the application');
          }
        }
      }
      
      print('ℹ Using placeholder thumbnail - No thumbnail generation method available');
      print('  For actual video frame thumbnails, ensure video_thumbnail package works on this platform');
      
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
    await _loadVideoHistory();
    return List.from(_videoHistory);
  }

  @override
  Future<void> saveVideoToHistory(VideoItem video) async {
    await _loadVideoHistory();
    
    // Remove if already exists (to avoid duplicates)
    // Use name and size for duplicate detection
    _videoHistory.removeWhere((item) => 
      item.name == video.name && item.sizeInBytes == video.sizeInBytes);
    
    // Add to beginning of list (most recent first)
    _videoHistory.insert(0, video);
    
    // Keep only last 50 videos (increased from 20)
    if (_videoHistory.length > 50) {
      final videosToRemove = _videoHistory.sublist(50);
      for (final videoToRemove in videosToRemove) {
        await _cleanupThumbnail(videoToRemove.thumbnailPath);
      }
      _videoHistory.removeRange(50, _videoHistory.length);
    }
    
    await _saveVideoHistory();
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
    await _loadVideoHistory();
    
    // Find the video to get its thumbnail path before removing
    final videoToRemove = _videoHistory.where((item) => item.id == videoId).firstOrNull;
    if (videoToRemove != null) {
      // Clean up the thumbnail file
      await _cleanupThumbnail(videoToRemove.thumbnailPath);
    }
    _videoHistory.removeWhere((item) => item.id == videoId);
    
    await _saveVideoHistory();
  }

  @override
  Future<void> clearVideoHistory() async {
    await _loadVideoHistory();
    
    // Clean up all thumbnail files
    for (final video in _videoHistory) {
      await _cleanupThumbnail(video.thumbnailPath);
    }
    _videoHistory.clear();
    
    await _saveVideoHistory();
  }

  // Add method to remove multiple videos (for bulk deletion)
  @override
  Future<void> removeVideosFromHistory(List<String> videoIds) async {
    await _loadVideoHistory();
    
    print('Removing ${videoIds.length} videos from history: $videoIds');
    
    for (final videoId in videoIds) {
      final videoToRemove = _videoHistory.where((item) => item.id == videoId).firstOrNull;
      if (videoToRemove != null) {
        print('Removing video: ${videoToRemove.name}');
        await _cleanupThumbnail(videoToRemove.thumbnailPath);
      } else {
        print('Video not found for deletion: $videoId');
      }
    }
    
    final removedCount = _videoHistory.where((item) => videoIds.contains(item.id)).length;
    _videoHistory.removeWhere((item) => videoIds.contains(item.id));
    
    print('Successfully removed $removedCount videos. Remaining: ${_videoHistory.length}');
    
    await _saveVideoHistory();
  }
}
