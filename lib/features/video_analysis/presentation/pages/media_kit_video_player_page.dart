import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:io';

import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/video_item.dart';
import '../widgets/persistent_video_scrubber.dart';
import '../widgets/drawing_overlay.dart';
import '../widgets/drawing_toolbar.dart';

class MediaKitVideoPlayerPage extends StatefulWidget {
  final VideoItem video;

  const MediaKitVideoPlayerPage({
    super.key,
    required this.video,
  });

  @override
  State<MediaKitVideoPlayerPage> createState() => _MediaKitVideoPlayerPageState();
}

class _MediaKitVideoPlayerPageState extends State<MediaKitVideoPlayerPage> {
  late final Player _player;
  late final VideoController _controller;
  bool _isInitialized = false;
  bool _isMuted = false;
  double _volumeBeforeMute = 1.0;
  bool _showPlayPauseButton = false;
  
  // Drawing functionality
  DrawingTool _selectedDrawingTool = DrawingTool.none;
  final GlobalKey<DrawingOverlayState> _drawingOverlayKey = GlobalKey<DrawingOverlayState>();
  bool _hasDrawings = false;

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

  void _onUndoLast() {
    _drawingOverlayKey.currentState?.undoLastLine();
    _updateDrawingState();
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
  void initState() {
    super.initState();
    _initializePlayer();
  }
  void _initializePlayer() async {
    try {
      _player = Player();
      _controller = VideoController(_player);
      
      // Format the file path properly for MediaKit
      String videoPath = widget.video.path;
      if (Platform.isWindows) {
        // For Windows, use file:/// protocol
        videoPath = 'file:///${widget.video.path}';
      } else {
        // For Android/other platforms, just use the file path
        videoPath = widget.video.path;
      }
      
      await _player.open(Media(videoPath));
      
      setState(() {
        _isInitialized = true;
      });
      
      // Auto-play
      await _player.play();
    } catch (e) {
      debugPrint('Error initializing media_kit player: $e');
      if (mounted) {
        _showErrorDialog('Video playback failed: ${e.toString()}');
      }
    }
  }  void _togglePlayPause() async {
    debugPrint('Toggle play/pause triggered - Current playing state: ${_player.state.playing}');
    
    // Show button immediately
    setState(() {
      _showPlayPauseButton = true;
    });

    try {
      // Use async operations to ensure state is properly updated
      if (_player.state.playing) {
        debugPrint('Pausing video...');
        await _player.pause();
      } else {
        debugPrint('Playing video...');
        await _player.play();
      }
      
      debugPrint('Toggle completed - New playing state: ${_player.state.playing}');
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }

    // Hide the button after 1 second
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showPlayPauseButton = false;
        });
      }
    });
  }

  void _toggleMute() {
    setState(() {
      if (_isMuted) {
        // Unmute: restore previous volume
        _player.setVolume(_volumeBeforeMute);
        _isMuted = false;
      } else {
        // Mute: save current volume and set to 0
        _volumeBeforeMute = _player.state.volume;
        _player.setVolume(0.0);
        _isMuted = true;
      }
    });
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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [            // Full-height Video Player with Drawing Overlay
            Positioned.fill(
              child: _isInitialized
                  ? DrawingOverlay(
                      key: _drawingOverlayKey,
                      isEnabled: _selectedDrawingTool != DrawingTool.none,
                      onDrawingStateChanged: _onDrawingStateChanged,
                      child: GestureDetector(
                        onTap: _selectedDrawingTool == DrawingTool.none ? _togglePlayPause : null,
                        behavior: HitTestBehavior.opaque,
                        child: Video(
                          controller: _controller,
                          controls: NoVideoControls,
                        ),
                      ),
                    )
                  : _buildLoadingState(),
            ),
            
            // Permanent Back Button (Always Visible)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back to video list',
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
                    onUndoLast: _onUndoLast,
                    hasDrawings: _hasDrawings,
                  ),
                ),
              ),
            
            // Mute/Unmute Button (Top-Right)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: StreamBuilder(
                  stream: _player.stream.volume,
                  builder: (context, snapshot) {
                    final volume = snapshot.data ?? 1.0;
                    final isMuted = volume == 0.0;
                    return IconButton(
                      icon: Icon(
                        isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: _toggleMute,
                      tooltip: isMuted ? 'Unmute' : 'Mute',
                    );
                  },
                ),
              ),            ),
              // Big Play/Pause Button (Center, appears temporarily)
            if (_showPlayPauseButton && _isInitialized)
              Center(
                child: AnimatedOpacity(
                  opacity: _showPlayPauseButton ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: StreamBuilder(
                      stream: _player.stream.playing,
                      builder: (context, snapshot) {
                        // Use the latest state from the stream, fallback to player state
                        final isPlaying = snapshot.hasData 
                            ? snapshot.data! 
                            : _player.state.playing;
                        return Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 60,
                        );
                      },
                    ),
                  ),
                ),
              ),
            
            // Video Scrubber Overlay (Bottom with 50% opacity)
            if (_isInitialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5), // 50% opacity
                  ),
                  child: StreamBuilder(
                    stream: _player.stream.position,
                    builder: (context, positionSnapshot) {
                      return StreamBuilder(
                        stream: _player.stream.duration,
                        builder: (context, durationSnapshot) {
                          final position = positionSnapshot.data ?? Duration.zero;
                          final duration = durationSnapshot.data ?? Duration.zero;
                          
                          return PersistentVideoScrubber(
                            player: _player,
                            duration: duration,
                            position: position,
                            onSeek: (newPosition) {
                              _player.seek(newPosition);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
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
          SizedBox(height: ResponsiveHelper.getSpacing(context, large: true)),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }
}
