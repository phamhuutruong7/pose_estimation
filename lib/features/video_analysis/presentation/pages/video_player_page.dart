import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/video_item.dart';
import '../widgets/drawing_overlay.dart';
import '../widgets/drawing_toolbar.dart';

class VideoPlayerPage extends StatefulWidget {
  final VideoItem video;

  const VideoPlayerPage({
    super.key,
    required this.video,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  
  // Drawing functionality
  DrawingTool _selectedDrawingTool = DrawingTool.none;
  final GlobalKey<DrawingOverlayState> _drawingOverlayKey = GlobalKey<DrawingOverlayState>();
  bool _hasDrawings = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _hideControlsTimer();
  }  void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(File(widget.video.path));
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        
        // Listen to position changes to update the controller
        _controller.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
        // Show error dialog
        _showErrorDialog('Video playback is not supported on this platform. Error: ${e.toString()}');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Player Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to video list
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _hideControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _hideControlsTimer();
    }
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
      _hideControlsTimer();
    }
  }
  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _controller.setPlaybackSpeed(speed);
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Speed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            return ListTile(
              title: Text('${speed}x'),
              leading: Radio<double>(
                value: speed,
                groupValue: _playbackSpeed,
                onChanged: (value) {
                  if (value != null) {
                    _changePlaybackSpeed(value);
                    Navigator.pop(context);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    } else {      return '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildErrorOrLoadingState() {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: ResponsiveHelper.getIconSize(context),
            color: Colors.white.withValues(alpha: 0.7),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context, large: true)),
          Text(
            'Loading video...',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveHelper.getTitleFontSize(context),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),
          Text(
            'If this takes too long, video playback might not be supported on this platform.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: ResponsiveHelper.getBodyFontSize(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context, large: true)),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  void _onDrawingToolSelected(DrawingTool tool) {
    setState(() {
      _selectedDrawingTool = tool;
    });
  }

  void _onClearDrawings() {
    _drawingOverlayKey.currentState?.clearDrawings();
    setState(() {
      _hasDrawings = false;
    });
  }

  void _onDrawingStateChanged() {
    _updateDrawingState();
  }

  void _updateDrawingState() {
    setState(() {
      _hasDrawings = _drawingOverlayKey.currentState?.lines.isNotEmpty ?? false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [            // Video Player or Error State with Drawing Overlay
            Center(
              child: _isInitialized
                  ? DrawingOverlay(
                      key: _drawingOverlayKey,
                      isEnabled: _selectedDrawingTool != DrawingTool.none,
                      currentTool: _selectedDrawingTool,
                      onDrawingStateChanged: _onDrawingStateChanged,
                      child: GestureDetector(
                        onTap: _selectedDrawingTool == DrawingTool.none ? _toggleControls : null,
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    )
                  : _buildErrorOrLoadingState(),
            ),
            
            // Top Controls (Back button and video title)
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: ResponsiveHelper.getResponsivePadding(context),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.video.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Center Play/Pause Button
            if (_showControls && _isInitialized)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),            // Bottom Built-in Video Controller
            if (_showControls && _isInitialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: ResponsiveHelper.getResponsivePadding(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Time and speed controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_controller.value.position),
                              style: const TextStyle(color: Colors.white),
                            ),
                            GestureDetector(
                              onTap: () {
                                _showSpeedDialog();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_playbackSpeed}x',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Video progress slider
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: Theme.of(context).primaryColor,
                            bufferedColor: Colors.white.withValues(alpha: 0.3),
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Drawing Toolbar (Right Side)
            if (_isInitialized)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: DrawingToolbar(
                    selectedTool: _selectedDrawingTool,
                    onToolSelected: _onDrawingToolSelected,
                    onClearDrawings: _onClearDrawings,
                    hasDrawings: _hasDrawings,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
