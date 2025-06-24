import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:io';

import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/video_item.dart';
import '../widgets/persistent_video_scrubber.dart';

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
  bool _showControls = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _hideControlsTimer();
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
  }

  void _hideControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _player.state.playing) {
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
    if (_player.state.playing) {
      _player.pause();
    } else {
      _player.play();
      _hideControlsTimer();
    }
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
                groupValue: _player.state.rate,
                onChanged: (value) {
                  if (value != null) {
                    _player.setRate(value);
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
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Main video area with controls
            Expanded(
              child: Stack(
                children: [
                  // Video Player
                  Center(
                    child: _isInitialized
                        ? GestureDetector(
                            onTap: _toggleControls,
                            child: Video(controller: _controller),
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
                  
                  // Top Controls (Video title and additional controls)
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
                          padding: ResponsiveHelper.getResponsivePadding(context).copyWith(
                            left: 70, // Make space for the permanent back button
                          ),
                          child: Row(
                            children: [
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
                          child: StreamBuilder(
                            stream: _player.stream.playing,
                            builder: (context, snapshot) {
                              final isPlaying = snapshot.data ?? false;
                              return Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                  // Speed Control (only when controls visible)
                  if (_showControls && _isInitialized)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: _showSpeedDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: StreamBuilder(
                            stream: _player.stream.rate,
                            builder: (context, snapshot) {
                              final rate = snapshot.data ?? 1.0;
                              return Text(
                                '${rate}x',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Persistent Bottom Scrubber (Always Visible)
            if (_isInitialized)
              StreamBuilder(
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
