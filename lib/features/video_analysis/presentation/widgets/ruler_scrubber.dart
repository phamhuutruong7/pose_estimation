import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class RulerScrubber extends StatefulWidget {
  final Player player;
  final Duration duration;
  final Duration position;
  final Function(Duration) onSeek;
  final bool enableScrubbing;

  const RulerScrubber({
    super.key,
    required this.player,
    required this.duration,
    required this.position,
    required this.onSeek,
    this.enableScrubbing = true,
  });

  @override
  State<RulerScrubber> createState() => _RulerScrubberState();
}

class _RulerScrubberState extends State<RulerScrubber> {
  bool _isDragging = false;
  Duration _scrubbingPosition = Duration.zero;
  bool _wasPlayingBeforeScrub = false;

  @override
  void initState() {
    super.initState();
    _scrubbingPosition = widget.position;
  }

  void _startScrubbing(double localX, double totalWidth) {
    if (!widget.enableScrubbing) return;
    
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
    
    // Optionally resume playback if it was playing before
    // For this implementation, we keep it paused as requested
    // If you want to resume: if (_wasPlayingBeforeScrub) widget.player.play();
  }

  void _handleTap(double localX, double totalWidth) {
    if (!widget.enableScrubbing) return;
    
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
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current time display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _formatDuration(currentPosition),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Ruler scrubber
        Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Ruler marks
                      _buildRulerMarks(constraints.maxWidth),
                      
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
                                    Theme.of(context).primaryColor.withValues(alpha: 0.6),
                                    Theme.of(context).primaryColor,
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
    );
  }

  Widget _buildRulerMarks(double totalWidth) {
    final durationSeconds = widget.duration.inSeconds;
    final secondsPerPixel = durationSeconds / totalWidth;
    
    // Calculate appropriate tick interval
    int tickInterval = 1; // Start with 1 second
    if (secondsPerPixel > 0.5) tickInterval = 5;
    if (secondsPerPixel > 2) tickInterval = 10;
    if (secondsPerPixel > 5) tickInterval = 30;
    if (secondsPerPixel > 10) tickInterval = 60;
    
    final tickCount = (durationSeconds / tickInterval).ceil();
    
    return CustomPaint(
      size: Size(totalWidth, 60),
      painter: RulerMarksPainter(
        tickInterval: tickInterval,
        tickCount: tickCount,
        totalDuration: widget.duration,
        totalWidth: totalWidth,
      ),
    );
  }

  Widget _buildScrubberHandle(double progress, double totalWidth) {
    final handlePosition = (progress * totalWidth).clamp(12.0, totalWidth - 12.0);
    
    return Positioned(
      left: handlePosition - 12,
      top: 18,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _isDragging 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.9)
              : Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isDragging
            ? const Icon(
                Icons.drag_indicator,
                color: Colors.white,
                size: 12,
              )
            : const Icon(
                Icons.circle,
                color: Colors.white,
                size: 8,
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

class RulerMarksPainter extends CustomPainter {
  final int tickInterval;
  final int tickCount;
  final Duration totalDuration;
  final double totalWidth;

  RulerMarksPainter({
    required this.tickInterval,
    required this.tickCount,
    required this.totalDuration,
    required this.totalWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= tickCount; i++) {
      final timeInSeconds = i * tickInterval;
      final x = (timeInSeconds / totalDuration.inSeconds) * totalWidth;
      
      if (x > totalWidth) break;

      // Major tick every 5 intervals or at significant time marks
      final isMajorTick = i % 5 == 0 || timeInSeconds % 60 == 0;
      final tickHeight = isMajorTick ? 20.0 : 12.0;
      final tickY = size.height - tickHeight - 5;

      // Draw tick mark
      canvas.drawLine(
        Offset(x, tickY),
        Offset(x, tickY + tickHeight),
        paint..strokeWidth = isMajorTick ? 2 : 1,
      );

      // Draw time label for major ticks
      if (isMajorTick && x < totalWidth - 30) {
        final timeLabel = _formatSeconds(timeInSeconds);
        textPainter.text = TextSpan(
          text: timeLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        );
        textPainter.layout();
        
        final labelX = (x - textPainter.width / 2).clamp(0.0, totalWidth - textPainter.width);
        textPainter.paint(canvas, Offset(labelX, size.height - textPainter.height - 2));
      }
    }

    // Draw minor tick marks between major ones for better granularity
    final minorInterval = tickInterval / 5;
    if (minorInterval >= 1) {
      final minorPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 0.5;

      for (int i = 0; i < totalDuration.inSeconds; i++) {
        if (i % tickInterval != 0 && i % minorInterval.round() == 0) {
          final x = (i / totalDuration.inSeconds) * totalWidth;
          if (x <= totalWidth) {
            canvas.drawLine(
              Offset(x, size.height - 8 - 5),
              Offset(x, size.height - 5),
              minorPaint,
            );
          }
        }
      }
    }
  }

  String _formatSeconds(int totalSeconds) {
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
