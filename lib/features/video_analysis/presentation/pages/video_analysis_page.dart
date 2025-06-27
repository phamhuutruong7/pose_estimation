import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/video_item.dart';
import '../bloc/video_analysis_event.dart';
import '../bloc/video_analysis_state.dart';
import '../bloc/video_analysis_bloc.dart';
import '../widgets/video_grid_view.dart';
import 'media_kit_video_player_page.dart';

class VideoAnalysisPage extends StatefulWidget {
  const VideoAnalysisPage({super.key});

  @override
  State<VideoAnalysisPage> createState() => _VideoAnalysisPageState();
}

class _VideoAnalysisPageState extends State<VideoAnalysisPage> {
  Set<String> _selectedVideoIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    // Delay BLoC access to ensure provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VideoAnalysisBloc>().add(LoadVideoHistoryEvent());
      }
    });
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
              // Dispatch delete event to BLoC
              for (String videoId in _selectedVideoIds) {
                context.read<VideoAnalysisBloc>().add(RemoveVideoFromHistoryEvent(videoId));
              }
              _clearSelection();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
              onPressed: () {
                context.read<VideoAnalysisBloc>().add(ImportVideosEvent());
              },
              icon: const Icon(Icons.add),
              tooltip: 'Import videos',
            ),
          ],
        ],
      ),
      body: BlocConsumer<VideoAnalysisBloc, VideoAnalysisState>(
        listener: (context, state) {
          if (state is VideoAnalysisError) {
            _showErrorSnackBar(state.message);
          } else if (state is VideoImportSuccess) {
            _showSuccessSnackBar(state.message);
            // Clear selection after successful operations
            _clearSelection();
          } else if (state is VideoRemovalSuccess) {
            _showSuccessSnackBar('Videos deleted successfully');
            // Clear selection after successful removal
            _clearSelection();
          }
        },
        builder: (context, state) {
          return _buildBody(state);
        },
      ),
      floatingActionButton: BlocBuilder<VideoAnalysisBloc, VideoAnalysisState>(
        builder: (context, state) {
          final videos = _getVideosFromState(state);
          return videos.isNotEmpty && !_isSelectionMode
              ? FloatingActionButton(
                  onPressed: () {
                    context.read<VideoAnalysisBloc>().add(ImportVideosEvent());
                  },
                  child: const Icon(Icons.add),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBody(VideoAnalysisState state) {
    if (state is VideoAnalysisLoading) {
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

    final videos = _getVideosFromState(state);
    
    if (videos.isEmpty) {
      return _buildEmptyState();
    }

    return VideoGridView(
      videos: videos,
      selectedVideoIds: _selectedVideoIds,
      onVideoTap: (video) {
        if (_isSelectionMode) {
          _toggleSelection(video.id);
        } else {
          // Save video to history before playing
          context.read<VideoAnalysisBloc>().add(SaveVideoToHistoryEvent(video));
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

  List<VideoItem> _getVideosFromState(VideoAnalysisState state) {
    if (state is VideoHistoryLoaded) {
      return state.videos;
    } else if (state is VideoImportSuccess) {
      return state.videos;
    } else if (state is VideoRemovalSuccess) {
      return state.videos;
    }
    return [];
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
              onPressed: () {
                context.read<VideoAnalysisBloc>().add(ImportVideosEvent());
              },
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
