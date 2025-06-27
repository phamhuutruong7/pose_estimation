import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class PersistentVideoScrubber extends StatefulWidget {
  final Player player;
  final Duration duration;
  final Duration position;
  final Function(Duration) onSeek;

  const PersistentVideoScrubber({
    super.key,
    required this.player,
    required this.duration,
    required this.position,
    required this.onSeek,
  });

  @override
  State<PersistentVideoScrubber> createState() => _PersistentVideoScrubberState();
}

class _PersistentVideoScrubberState extends State<PersistentVideoScrubber> {
  bool _isDragging = false;
  bool _wasPlayingBeforeScrub = false;
  
  // Touch and drag state
  double? _dragStartX;
  Duration? _dragStartTime;
  
  // 10 seconds visible window
  static const double _visibleDurationSeconds = 10.0;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(PersistentVideoScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _wasPlayingBeforeScrub = widget.player.state.playing;
      _dragStartX = details.localPosition.dx;
      _dragStartTime = widget.position;
    });
    
    if (_wasPlayingBeforeScrub) {
      widget.player.pause();
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, double screenWidth) {
    if (!_isDragging || _dragStartX == null || _dragStartTime == null) return;
    
    // Calculate how far we've dragged horizontally
    // Invert deltaX: drag left = fast forward, drag right = rewind
    final deltaX = _dragStartX! - details.localPosition.dx;
    
    // Convert deltaX to time delta based on the 10-second visible window
    // More responsive: each pixel represents a smaller time unit
    final pixelsPerSecond = screenWidth / _visibleDurationSeconds;
    final deltaSeconds = deltaX / pixelsPerSecond;
    final deltaTime = Duration(milliseconds: (deltaSeconds * 1000).round());
    
    // Calculate new time position
    final newTime = Duration(
      milliseconds: (_dragStartTime!.inMilliseconds + deltaTime.inMilliseconds)
        .clamp(0, widget.duration.inMilliseconds)
    );
    
    // Seek to the new position for real-time preview
    widget.onSeek(newTime);
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragStartX = null;
      _dragStartTime = null;
    });
    
    // Keep video paused after scrubbing - user can tap play button to continue
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent, // Make transparent since parent handles opacity
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current time display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatCurrentPosition(widget.position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDuration(widget.duration),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Fixed Timeline with Touch and Drag
          Container(
            height: 40,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        // Touch and drag sensitive timeline area
                        GestureDetector(
                          onPanStart: (details) {
                            _handlePanStart(details);
                          },
                          onPanUpdate: (details) {
                            _handlePanUpdate(details, screenWidth);
                          },
                          onPanEnd: (details) {
                            _handlePanEnd(details);
                          },
                          child: Container(
                            width: screenWidth,
                            height: 40,
                            child: CustomPaint(
                              size: Size(screenWidth, 40),
                              painter: ScrollableTimelinePainter(
                                totalDuration: widget.duration,
                                currentPosition: widget.position,
                                totalWidth: screenWidth,
                                isDragging: _isDragging,
                              ),
                            ),
                          ),
                        ),
                        
                        // Fixed pivot indicator at left side (20% from left)
                        Positioned(
                          left: screenWidth * 0.2 - 6, // Center the 12px wide pivot
                          top: 8,
                          child: Container(
                            width: 12,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.black,
                              size: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrentPosition(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);

    // Always show 3-digit milliseconds for current position
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}'
             '.${milliseconds.toString().padLeft(3, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}'
             '.${milliseconds.toString().padLeft(3, '0')}';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    // Simple format for total duration (no milliseconds)
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
  }
}

class ScrollableTimelinePainter extends CustomPainter {
  final Duration totalDuration;
  final Duration currentPosition;
  final double totalWidth;
  final bool isDragging;

  ScrollableTimelinePainter({
    required this.totalDuration,
    required this.currentPosition,
    required this.totalWidth,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final durationSeconds = totalDuration.inSeconds;
    if (durationSeconds == 0) return;

    // Fixed pivot position (20% from left)
    final pivotX = totalWidth * 0.2;
    
    // Current time in seconds
    final currentSeconds = currentPosition.inSeconds.toDouble() + 
                          (currentPosition.inMilliseconds % 1000) / 1000.0;

    // Calculate appropriate intervals based on video duration
    double primaryInterval; // seconds
    double secondaryInterval; // seconds
    
    if (durationSeconds <= 30) {
      primaryInterval = 5; // Major marks every 5 seconds
      secondaryInterval = 1; // Minor marks every 1 second
    } else if (durationSeconds <= 120) {
      primaryInterval = 10; // Major marks every 10 seconds
      secondaryInterval = 2; // Minor marks every 2 seconds
    } else if (durationSeconds <= 300) {
      primaryInterval = 30; // Major marks every 30 seconds
      secondaryInterval = 5; // Minor marks every 5 seconds
    } else if (durationSeconds <= 900) {
      primaryInterval = 60; // Major marks every minute
      secondaryInterval = 10; // Minor marks every 10 seconds
    } else {
      primaryInterval = 120; // Major marks every 2 minutes
      secondaryInterval = 30; // Minor marks every 30 seconds
    }

    // Add even finer marks when dragging for precision
    double microInterval = secondaryInterval / 5; // Very fine marks

    // Scale: 10 seconds visible window with pivot fixed at 20%
    final secondsPerPixel = 10.0 / totalWidth; // 10 seconds across full width
    
    // Calculate time range to show (centered around current time, but with pivot offset)
    final pivotTimeOffset = (pivotX * secondsPerPixel); // How much time the pivot represents
    final timeStart = currentSeconds - pivotTimeOffset;
    final timeEnd = timeStart + 10.0; // 10 second window

    // Draw micro marks (finest) - only when dragging
    if (isDragging) {
      paint.color = Colors.white.withValues(alpha: 0.2);
      for (double t = (timeStart / microInterval).floor() * microInterval; 
           t <= timeEnd; 
           t += microInterval) {
        if (t >= 0 && t <= durationSeconds) {
          final x = pivotX + (t - currentSeconds) / secondsPerPixel;
          if (x >= 0 && x <= totalWidth) {
            canvas.drawLine(
              Offset(x, size.height - 3),
              Offset(x, size.height),
              paint,
            );
          }
        }
      }
    }

    // Draw secondary marks (minor)
    paint.color = Colors.white.withValues(alpha: 0.4);
    paint.strokeWidth = 1;
    for (double t = (timeStart / secondaryInterval).floor() * secondaryInterval; 
         t <= timeEnd; 
         t += secondaryInterval) {
      if (t >= 0 && t <= durationSeconds && t % primaryInterval != 0) {
        final x = pivotX + (t - currentSeconds) / secondsPerPixel;
        if (x >= 0 && x <= totalWidth) {
          canvas.drawLine(
            Offset(x, size.height - 6),
            Offset(x, size.height),
            paint,
          );
        }
      }
    }

    // Draw primary marks (major) with labels
    paint.color = Colors.white.withValues(alpha: 0.8);
    paint.strokeWidth = 2;
    for (double t = (timeStart / primaryInterval).floor() * primaryInterval; 
         t <= timeEnd; 
         t += primaryInterval) {
      if (t >= 0 && t <= durationSeconds) {
        final x = pivotX + (t - currentSeconds) / secondsPerPixel;
        if (x >= 0 && x <= totalWidth) {
          // Draw major tick mark
          canvas.drawLine(
            Offset(x, size.height - 10),
            Offset(x, size.height),
            paint,
          );

          // Draw time label
          if (x >= 15 && x <= totalWidth - 15) { // Only show labels with enough space
            final timeLabel = _formatSecondsForLabel(t.round());
            textPainter.text = TextSpan(
              text: timeLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            );
            textPainter.layout();
            
            final labelX = (x - textPainter.width / 2).clamp(0.0, totalWidth - textPainter.width);
            textPainter.paint(canvas, Offset(labelX, 2));
          }
        }
      }
    }
  }

  String _formatSecondsForLabel(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${seconds}s';
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
