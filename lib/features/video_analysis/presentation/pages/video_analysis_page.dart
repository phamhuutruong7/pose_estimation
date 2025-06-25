import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
// import 'package:video_thumbnail/video_thumbnail.dart'; // TODO: Not supported on Windows
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/video_item.dart';
import '../widgets/video_grid_view.dart';
import 'media_kit_video_player_page.dart';

class VideoAnalysisPage extends StatefulWidget {
  const VideoAnalysisPage({super.key});

  @override
  State<VideoAnalysisPage> createState() => _VideoAnalysisPageState();
}

class _VideoAnalysisPageState extends State<VideoAnalysisPage> {
  List<VideoItem> _videos = [];
  Set<String> _selectedVideoIds = {};
  bool _isLoading = false;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadSavedVideos();
  }

  Future<void> _loadSavedVideos() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Load videos from local storage/database
      // For now, we'll start with an empty list
      setState(() => _videos = []);
    } catch (e) {
      _showErrorSnackBar('Failed to load videos: $e');    } finally {
      setState(() => _isLoading = false);
    }  }
  Future<void> _importVideos() async {
    try {
      // Show loading state
      setState(() => _isLoading = true);
      
      // Use different picker strategies based on platform
      FilePickerResult? result;
      
      if (Platform.isAndroid) {
        // For Android, use custom type with specific extensions
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: true,
          allowedExtensions: ['mp4', 'avi', 'mov', 'mkv', 'wmv', '3gp'],
        );
      } else {
        // For other platforms (Windows, iOS, etc.), use video type
        result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: true,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        int successCount = 0;
        int totalCount = result.files.length;
        
        for (final file in result.files) {
          if (file.path != null) {
            try {
              await _processVideoFile(file.path!);
              successCount++;
            } catch (e) {
              debugPrint('Failed to process ${file.name}: $e');
            }
          }
        }
        
        if (successCount > 0) {
          _showSuccessSnackBar('$successCount of $totalCount video(s) imported successfully');
        } else {
          _showErrorSnackBar('Failed to import any videos. Please check file formats.');
        }
      } else {
        // User cancelled the picker
        debugPrint('File picker cancelled by user');
      }
    } catch (e) {
      debugPrint('File picker error: $e');
      String errorMessage = 'Failed to open file picker';
      
      if (e.toString().contains('Permission denied')) {
        errorMessage = 'Permission denied. Please grant storage access in Settings.';
      } else if (e.toString().contains('allowedExtensions')) {
        errorMessage = 'File type configuration error. Please try again.';
      } else {
        errorMessage = 'Failed to open file picker: ${e.toString()}';
      }
      
      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processVideoFile(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = path.basename(filePath);
      final fileSize = await file.length();
      
      // Generate thumbnail
      final thumbnailPath = await _generateThumbnail(filePath);
      
      // Create video item
      final videoItem = VideoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        path: filePath,
        thumbnailPath: thumbnailPath,
        duration: const Duration(seconds: 0), // TODO: Get actual duration
        addedDate: DateTime.now(),
        sizeInBytes: fileSize,
      );      
      setState(() {
        _videos.add(videoItem);
      });
    } catch (e) {
      debugPrint('Error processing video file: $e');
    }
  }

  Future<String?> _generateThumbnail(String videoPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailDir = Directory('${appDir.path}/thumbnails');
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }
        final fileName = path.basenameWithoutExtension(videoPath);
      final thumbnailPath = '${thumbnailDir.path}/$fileName.jpg';
      
      // TODO: Add thumbnail generation for all platforms
      // video_thumbnail package doesn't support Windows yet
      
      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  void _toggleSelection(String videoId) {
    setState(() {
      if (_selectedVideoIds.contains(videoId)) {
        _selectedVideoIds.remove(videoId);
        if (_selectedVideoIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedVideoIds.add(videoId);
        _isSelectionMode = true;
      }
    });
  }

  void _deleteSelectedVideos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Videos'),
        content: Text(
          'Are you sure you want to delete ${_selectedVideoIds.length} selected video(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _performDeleteVideos();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performDeleteVideos() {
    setState(() {
      _videos.removeWhere((video) => _selectedVideoIds.contains(video.id));
      _selectedVideoIds.clear();
      _isSelectionMode = false;
    });
    _showSuccessSnackBar('Videos deleted successfully');
  }

  void _clearSelection() {
    setState(() {
      _selectedVideoIds.clear();
      _isSelectionMode = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode 
            ? '${_selectedVideoIds.length} selected' 
            : 'Video Analysis'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              onPressed: _deleteSelectedVideos,
              icon: const Icon(Icons.delete),
              tooltip: 'Delete selected',
            ),
            IconButton(
              onPressed: _clearSelection,
              icon: const Icon(Icons.clear),
              tooltip: 'Clear selection',
            ),
          ] else ...[
            IconButton(
              onPressed: _importVideos,
              icon: const Icon(Icons.add),
              tooltip: 'Import videos',
            ),
          ],
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _videos.isNotEmpty && !_isSelectionMode
          ? FloatingActionButton(
              onPressed: _importVideos,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing videos...'),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return _buildEmptyState();
    }    return VideoGridView(
      videos: _videos,
      selectedVideoIds: _selectedVideoIds,
      onVideoTap: (video) {
        if (_isSelectionMode) {
          _toggleSelection(video.id);
        } else {
          // Navigate to video player
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MediaKitVideoPlayerPage(video: video),
            ),
          );
        }
      },
      onVideoLongPress: (video) {
        _toggleSelection(video.id);
      },
      onSelectionToggle: _toggleSelection,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: ResponsiveHelper.getIconSize(context),
              color: Colors.grey,
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context, large: true)),
            Text(
              'No videos imported yet',
              style: TextStyle(
                fontSize: ResponsiveHelper.getTitleFontSize(context),
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context)),
            Text(
              'Import videos to start analyzing poses',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveHelper.getBodyFontSize(context),
                color: Colors.grey,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context, large: true) * 2),
            ElevatedButton.icon(
              onPressed: _importVideos,
              icon: const Icon(Icons.add),
              label: const Text('Import Videos'),
              style: ElevatedButton.styleFrom(
                padding: ResponsiveHelper.getButtonPadding(context),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
