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
  Duration _scrubbingPosition = Duration.zero;
  bool _wasPlayingBeforeScrub = false;

  @override
  void initState() {
    super.initState();
    _scrubbingPosition = widget.position;
  }

  @override
  void didUpdateWidget(PersistentVideoScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _scrubbingPosition = widget.position;
    }
  }  void _endScrubbing() {
    if (!_isDragging) return;
    
    setState(() {
      _isDragging = false;
    });
    
    // Keep video paused after scrubbing - user needs to manually play
  }

  // Fixed pivot position (1/3 from left)
  double get _pivotPosition => 0.33;

  // Timeline scale factor (how much longer than screen width)
  double get _timelineScale => 3.0;

  // Calculate the offset of the timeline based on current position
  double _calculateTimelineOffset(double screenWidth, Duration currentPosition) {
    if (widget.duration.inMilliseconds == 0) return 0;
    
    final progress = currentPosition.inMilliseconds / widget.duration.inMilliseconds;
    final timelineWidth = screenWidth * _timelineScale;
    final pivotX = screenWidth * _pivotPosition;
    
    // Offset so the current position aligns with the pivot
    return pivotX - (progress * timelineWidth);
  }
  void _handleTapOnFlowingTimeline(double localX, double screenWidth) {
    final pivotX = screenWidth * _pivotPosition;
    
    // Calculate the distance from tap to pivot
    final distanceFromPivot = localX - pivotX;
    final timelineWidth = screenWidth * _timelineScale;
    
    // Convert distance to progress
    final currentProgress = widget.position.inMilliseconds / widget.duration.inMilliseconds;
    final progressChange = distanceFromPivot / timelineWidth;
    final newProgress = (currentProgress + progressChange).clamp(0.0, 1.0);
    
    final newPosition = Duration(
      milliseconds: (widget.duration.inMilliseconds * newProgress).round(),
    );
    
    widget.onSeek(newPosition);
  }

  void _startScrubbingFlowingTimeline(double localX, double screenWidth) {
    setState(() {
      _isDragging = true;
      _wasPlayingBeforeScrub = widget.player.state.playing;
    });
    
    // Pause video during scrubbing
    if (_wasPlayingBeforeScrub) {
      widget.player.pause();
    }
    
    _updateScrubbingFlowingTimeline(localX, screenWidth);
  }
  void _updateScrubbingFlowingTimeline(double localX, double screenWidth) {
    if (!_isDragging) return;
    
    final pivotX = screenWidth * _pivotPosition;
    
    // Calculate the distance from drag to pivot
    final distanceFromPivot = localX - pivotX;
    final timelineWidth = screenWidth * _timelineScale;
    
    // Convert distance to progress
    final currentProgress = _scrubbingPosition.inMilliseconds / widget.duration.inMilliseconds;
    final progressChange = distanceFromPivot / timelineWidth;
    final newProgress = (currentProgress + progressChange).clamp(0.0, 1.0);
    
    final newPosition = Duration(
      milliseconds: (widget.duration.inMilliseconds * newProgress).round(),
    );
    
    setState(() {
      _scrubbingPosition = newPosition;
    });
    
    // Update video frame immediately for preview
    widget.onSeek(newPosition);
  }

  Widget _buildFlowingTimeline(double screenWidth, Duration currentPosition) {
    final timelineWidth = screenWidth * _timelineScale;
    final timelineOffset = _calculateTimelineOffset(screenWidth, currentPosition);
    
    return Positioned(
      left: timelineOffset,
      top: 0,
      child: Container(
        width: timelineWidth,
        height: 40,
        child: CustomPaint(
          size: Size(timelineWidth, 40),
          painter: FlowingTimelinePainter(
            totalDuration: widget.duration,
            totalWidth: timelineWidth,
            isDragging: _isDragging,
          ),
        ),
      ),
    );
  }

  Widget _buildFixedPivot(double screenWidth) {
    final pivotX = screenWidth * _pivotPosition;
    
    return Positioned(
      left: pivotX - 2, // Center the 4px wide line
      top: 0,
      child: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }@override
  Widget build(BuildContext context) {
    final currentPosition = _isDragging ? _scrubbingPosition : widget.position;

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
                  _formatCurrentPosition(currentPosition),
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
          
          // Flowing Timeline Scrubber
          Container(
            height: 40,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    _handleTapOnFlowingTimeline(details.localPosition.dx, constraints.maxWidth);
                  },
                  onPanStart: (details) {
                    _startScrubbingFlowingTimeline(details.localPosition.dx, constraints.maxWidth);
                  },
                  onPanUpdate: (details) {
                    _updateScrubbingFlowingTimeline(details.localPosition.dx, constraints.maxWidth);
                  },
                  onPanEnd: (details) {
                    _endScrubbing();
                  },
                  child: Container(
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
                          // Flowing timeline background
                          _buildFlowingTimeline(constraints.maxWidth, currentPosition),
                          
                          // Fixed pivot indicator
                          _buildFixedPivot(constraints.maxWidth),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),        ],
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

class FlowingTimelinePainter extends CustomPainter {
  final Duration totalDuration;
  final double totalWidth;
  final bool isDragging;

  FlowingTimelinePainter({
    required this.totalDuration,
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

    // Draw micro marks (finest)
    if (isDragging) {
      paint.color = Colors.white.withValues(alpha: 0.2);
      for (double t = 0; t <= durationSeconds; t += microInterval) {
        final x = (t / durationSeconds) * totalWidth;
        if (x >= 0 && x <= totalWidth) {
          canvas.drawLine(
            Offset(x, size.height - 3),
            Offset(x, size.height),
            paint,
          );
        }
      }
    }

    // Draw secondary marks (minor)
    paint.color = Colors.white.withValues(alpha: 0.4);
    paint.strokeWidth = 1;
    for (double t = 0; t <= durationSeconds; t += secondaryInterval) {
      if (t % primaryInterval != 0) { // Don't draw over primary marks
        final x = (t / durationSeconds) * totalWidth;
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
    for (double t = 0; t <= durationSeconds; t += primaryInterval) {
      final x = (t / durationSeconds) * totalWidth;
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

class FineRulerMarksPainter extends CustomPainter {
  final Duration totalDuration;
  final double totalWidth;
  final bool isDragging;

  FineRulerMarksPainter({
    required this.totalDuration,
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
    double microInterval = secondaryInterval / 5; // Very fine marks    // Draw micro marks (finest)
    if (isDragging) {
      paint.color = Colors.white.withValues(alpha: 0.2);
      for (double t = 0; t <= durationSeconds; t += microInterval) {
        final x = (t / durationSeconds) * totalWidth;
        if (x <= totalWidth) {
          canvas.drawLine(
            Offset(x, size.height - 3), // Adjusted for smaller height
            Offset(x, size.height),
            paint,
          );
        }
      }
    }

    // Draw secondary marks (minor)
    paint.color = Colors.white.withValues(alpha: 0.4);
    paint.strokeWidth = 1;
    for (double t = 0; t <= durationSeconds; t += secondaryInterval) {
      if (t % primaryInterval != 0) { // Don't draw over primary marks
        final x = (t / durationSeconds) * totalWidth;
        if (x <= totalWidth) {
          canvas.drawLine(
            Offset(x, size.height - 6), // Adjusted for smaller height
            Offset(x, size.height),
            paint,
          );
        }
      }
    }

    // Draw primary marks (major) with labels
    paint.color = Colors.white.withValues(alpha: 0.8);
    paint.strokeWidth = 2;
    for (double t = 0; t <= durationSeconds; t += primaryInterval) {
      final x = (t / durationSeconds) * totalWidth;
      if (x <= totalWidth) {
        // Draw major tick mark
        canvas.drawLine(
          Offset(x, size.height - 10), // Adjusted for smaller height
          Offset(x, size.height),
          paint,
        );

        // Draw time label
        if (x < totalWidth - 30) {
          final timeLabel = _formatSecondsForLabel(t.round());
          textPainter.text = TextSpan(
            text: timeLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 9, // Slightly smaller font for smaller height
              fontWeight: FontWeight.w500,
            ),
          );
          textPainter.layout();
          
          final labelX = (x - textPainter.width / 2).clamp(0.0, totalWidth - textPainter.width);
          textPainter.paint(canvas, Offset(labelX, 2)); // Adjusted position
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
