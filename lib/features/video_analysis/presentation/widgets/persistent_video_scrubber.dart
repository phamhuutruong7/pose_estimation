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
  }

  void _startScrubbing(double localX, double totalWidth) {
    setState(() {
      _isDragging = true;
      _wasPlayingBeforeScrub = widget.player.state.playing;
    });
    
    // Pause video during scrubbing
    if (_wasPlayingBeforeScrub) {
      widget.player.pause();
    }
    
    _updateScrubbingPosition(localX, totalWidth);
  }

  void _updateScrubbing(double localX, double totalWidth) {
    if (!_isDragging) return;
    _updateScrubbingPosition(localX, totalWidth);
  }

  void _updateScrubbingPosition(double localX, double totalWidth) {
    final progress = (localX / totalWidth).clamp(0.0, 1.0);
    final newPosition = Duration(
      milliseconds: (widget.duration.inMilliseconds * progress).round(),
    );
    
    setState(() {
      _scrubbingPosition = newPosition;
    });
    
    // Update video frame immediately for preview
    widget.onSeek(newPosition);
  }

  void _endScrubbing() {
    if (!_isDragging) return;
    
    setState(() {
      _isDragging = false;
    });
    
    // Keep video paused after scrubbing - user needs to manually play
  }

  void _handleTap(double localX, double totalWidth) {
    final progress = (localX / totalWidth).clamp(0.0, 1.0);
    final newPosition = Duration(
      milliseconds: (widget.duration.inMilliseconds * progress).round(),
    );
    
    widget.onSeek(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    final currentPosition = _isDragging ? _scrubbingPosition : widget.position;
    final progress = widget.duration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;    return Container(
      color: Colors.transparent, // Make transparent since parent handles opacity
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Remove the thin progress bar at top since we have the detailed scrubber
          
          // Current time display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(currentPosition),
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
          
          // Detailed scrubber with fine time divisions
          Container(
            height: 80,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    _handleTap(details.localPosition.dx, constraints.maxWidth);
                  },
                  onPanStart: (details) {
                    _startScrubbing(details.localPosition.dx, constraints.maxWidth);
                  },
                  onPanUpdate: (details) {
                    _updateScrubbing(details.localPosition.dx, constraints.maxWidth);
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
                    child: Stack(
                      children: [
                        // Fine ruler marks
                        _buildFineRulerMarks(constraints.maxWidth),
                        
                        // Progress fill
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                      Theme.of(context).primaryColor.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Scrubber handle
                        _buildScrubberHandle(progress, constraints.maxWidth),
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

  Widget _buildFineRulerMarks(double totalWidth) {
    return CustomPaint(
      size: Size(totalWidth, 80),
      painter: FineRulerMarksPainter(
        totalDuration: widget.duration,
        totalWidth: totalWidth,
        isDragging: _isDragging,
      ),
    );
  }

  Widget _buildScrubberHandle(double progress, double totalWidth) {
    final handlePosition = (progress * totalWidth).clamp(8.0, totalWidth - 8.0);
    
    return Positioned(
      left: handlePosition - 8,
      top: 24,
      child: Container(
        width: 16,
        height: 32,
        decoration: BoxDecoration(
          color: _isDragging 
              ? Colors.white
              : Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isDragging
                ? Theme.of(context).primaryColor
                : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: _isDragging
                  ? Theme.of(context).primaryColor
                  : Colors.white,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);

    if (_isDragging) {
      // Show more precision when scrubbing
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:'
               '${minutes.toString().padLeft(2, '0')}:'
               '${seconds.toString().padLeft(2, '0')}'
               '.${(milliseconds / 100).floor()}';
      } else {
        return '${minutes.toString().padLeft(2, '0')}:'
               '${seconds.toString().padLeft(2, '0')}'
               '.${(milliseconds / 100).floor()}';
      }
    } else {
      // Normal time display
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
    double microInterval = secondaryInterval / 5; // Very fine marks

    // Draw micro marks (finest)
    if (isDragging) {
      paint.color = Colors.white.withValues(alpha: 0.2);
      for (double t = 0; t <= durationSeconds; t += microInterval) {
        final x = (t / durationSeconds) * totalWidth;
        if (x <= totalWidth) {
          canvas.drawLine(
            Offset(x, size.height - 5),
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
            Offset(x, size.height - 12),
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
          Offset(x, size.height - 20),
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
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          );
          textPainter.layout();
          
          final labelX = (x - textPainter.width / 2).clamp(0.0, totalWidth - textPainter.width);
          textPainter.paint(canvas, Offset(labelX, 5));
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
