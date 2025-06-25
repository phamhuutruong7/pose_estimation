import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/utils/responsive_helper.dart';

class CustomVideoController extends StatefulWidget {
  final VideoPlayerController controller;
  final Function(Duration) onSeek;
  final Function(double) onPlaybackSpeedChanged;
  final double currentSpeed;

  const CustomVideoController({
    super.key,
    required this.controller,
    required this.onSeek,
    required this.onPlaybackSpeedChanged,
    required this.currentSpeed,
  });

  @override
  State<CustomVideoController> createState() => _CustomVideoControllerState();
}

class _CustomVideoControllerState extends State<CustomVideoController> {
  bool _isDragging = false;
  bool _showSpeedMenu = false;

  final List<double> _speedOptions = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed Control Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current time
              Text(
                _formatDuration(widget.controller.value.position),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Speed control button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showSpeedMenu = !_showSpeedMenu;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${widget.currentSpeed}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Total duration
              Text(
                _formatDuration(widget.controller.value.duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Custom Ruler-style Progress Bar
          _buildRulerProgressBar(),

          const SizedBox(height: 16),

          // Speed selection menu
          if (_showSpeedMenu) _buildSpeedMenu(),
        ],
      ),
    );
  }

  Widget _buildRulerProgressBar() {
    final duration = widget.controller.value.duration;
    final position = widget.controller.value.position;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final newProgress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
        final newPosition = Duration(
          milliseconds: (duration.inMilliseconds * newProgress).round(),
        );
        widget.onSeek(newPosition);
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background ruler marks
              _buildRulerMarks(),

              // Progress indicator
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.8),
                            Theme.of(context).primaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),

              // Draggable progress handle
              Positioned(
                left:
                    (progress *
                        (MediaQuery.of(context).size.width -
                            ResponsiveHelper.getResponsivePadding(
                                  context,
                                ).horizontal *
                                2)) -
                    12,
                top: 8,
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onPanUpdate: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(
                      details.globalPosition,
                    );
                    final newProgress = (localPosition.dx / box.size.width)
                        .clamp(0.0, 1.0);
                    final newPosition = Duration(
                      milliseconds: (duration.inMilliseconds * newProgress)
                          .round(),
                    );
                    widget.onSeek(newPosition);
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
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
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulerMarks() {
    const markCount = 20;
    return Row(
      children: List.generate(markCount, (index) {
        final isMainMark = index % 5 == 0;
        return Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: isMainMark ? 0.6 : 0.3),
                  width: isMainMark ? 2 : 1,
                ),
              ),
            ),
            child: isMainMark
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${(index * 5).toString()}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildSpeedMenu() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        spacing: 8,
        children: _speedOptions.map((speed) {
          final isSelected = speed == widget.currentSpeed;
          return GestureDetector(
            onTap: () {
              widget.onPlaybackSpeedChanged(speed);
              setState(() {
                _showSpeedMenu = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${speed}x',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
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
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }
}
