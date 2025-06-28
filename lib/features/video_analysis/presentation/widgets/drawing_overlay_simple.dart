import 'package:flutter/material.dart';
import 'drawing_toolbar_new.dart'; // Import for DrawingTool enum

class DrawingLine {
  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;
  final DateTime timestamp;

  DrawingLine({
    required this.start,
    required this.end,
    this.color = Colors.blue, // Blue for lines
    this.strokeWidth = 3.0,
    required this.timestamp,
  });
}

class DrawingRectangle {
  final Offset topLeft;
  final Offset bottomRight;
  final Color color;
  final double strokeWidth;
  final DateTime timestamp;

  DrawingRectangle({
    required this.topLeft,
    required this.bottomRight,
    this.color = Colors.green, // Green for rectangles
    this.strokeWidth = 3.0,
    required this.timestamp,
  });

  Rect get rect => Rect.fromPoints(topLeft, bottomRight);
}

class DrawingCircle {
  final Offset center;
  final double radius;
  final Color color;
  final double strokeWidth;
  final DateTime timestamp;

  DrawingCircle({
    required this.center,
    required this.radius,
    this.color = Colors.red, // Red for circles
    this.strokeWidth = 3.0,
    required this.timestamp,
  });
}

class DrawingOverlay extends StatefulWidget {
  final Widget child;
  final bool isEnabled;
  final DrawingTool currentTool;
  final VoidCallback? onDrawingStateChanged;

  const DrawingOverlay({
    super.key,
    required this.child,
    this.isEnabled = false,
    this.currentTool = DrawingTool.none,
    this.onDrawingStateChanged,
  });

  @override
  State<DrawingOverlay> createState() => DrawingOverlayState();
}

class DrawingOverlayState extends State<DrawingOverlay> {
  final List<DrawingLine> _lines = [];
  final List<DrawingRectangle> _rectangles = [];
  final List<DrawingCircle> _circles = [];
  
  // Drawing state
  bool _isDrawing = false;
  Offset? _startPoint;
  Offset? _currentPoint;

  // Getter methods for external access
  List<DrawingLine> get lines => _lines;
  List<DrawingRectangle> get rectangles => _rectangles;
  List<DrawingCircle> get circles => _circles;

  void clearDrawings() {
    setState(() {
      _lines.clear();
      _rectangles.clear();
      _circles.clear();
    });
    widget.onDrawingStateChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    print('DrawingOverlay build: isEnabled=${widget.isEnabled}, currentTool=${widget.currentTool}');
    return Stack(
      children: [
        widget.child,
        // Always show existing drawings, but only allow interaction when enabled
        Positioned.fill(
          child: CustomPaint(
            painter: DrawingPainter(
              lines: _lines,
              rectangles: _rectangles,
              circles: _circles,
              isDrawing: _isDrawing && widget.isEnabled,
              startPoint: _startPoint,
              currentPoint: _currentPoint,
              currentTool: widget.currentTool,
            ),
            child: widget.isEnabled ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: _onTapDown,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                color: Colors.transparent,
                // Add a visual indicator when drawing is enabled
                child: widget.currentTool != DrawingTool.none 
                  ? Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Drawing: ${widget.currentTool.name}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    )
                  : null,
              ),
            ) : Container(),
          ),
        ),
      ],
    );
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isEnabled || widget.currentTool == DrawingTool.none) return;
    
    print('TapDown: Tool=${widget.currentTool}, Position=${details.localPosition}, Enabled=${widget.isEnabled}');
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isEnabled || widget.currentTool == DrawingTool.none) return;
    
    print('PanStart: Tool=${widget.currentTool}, Position=${details.localPosition}');
    
    setState(() {
      _isDrawing = true;
      _startPoint = details.localPosition;
      _currentPoint = details.localPosition;
    });
    
    // For eraser, start removing immediately
    if (widget.currentTool == DrawingTool.eraser) {
      _removeShapeAt(details.localPosition);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled || !_isDrawing) return;
    
    setState(() {
      _currentPoint = details.localPosition;
    });
    
    // For eraser, continue removing
    if (widget.currentTool == DrawingTool.eraser) {
      _removeShapeAt(details.localPosition);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isEnabled || !_isDrawing || _startPoint == null || _currentPoint == null) {
      setState(() {
        _isDrawing = false;
        _startPoint = null;
        _currentPoint = null;
      });
      return;
    }
    
    print('PanEnd: Creating ${widget.currentTool} from $_startPoint to $_currentPoint');
    
    // Create the shape based on current tool
    switch (widget.currentTool) {
      case DrawingTool.line:
        _lines.add(DrawingLine(
          start: _startPoint!,
          end: _currentPoint!,
          timestamp: DateTime.now(),
        ));
        break;
      case DrawingTool.rectangle:
        _rectangles.add(DrawingRectangle(
          topLeft: Offset(
            _startPoint!.dx < _currentPoint!.dx ? _startPoint!.dx : _currentPoint!.dx,
            _startPoint!.dy < _currentPoint!.dy ? _startPoint!.dy : _currentPoint!.dy,
          ),
          bottomRight: Offset(
            _startPoint!.dx > _currentPoint!.dx ? _startPoint!.dx : _currentPoint!.dx,
            _startPoint!.dy > _currentPoint!.dy ? _startPoint!.dy : _currentPoint!.dy,
          ),
          timestamp: DateTime.now(),
        ));
        break;
      case DrawingTool.circle:
        final radius = (_currentPoint! - _startPoint!).distance;
        if (radius > 5) { // Minimum radius
          _circles.add(DrawingCircle(
            center: _startPoint!,
            radius: radius,
            timestamp: DateTime.now(),
          ));
        }
        break;
      case DrawingTool.eraser:
        // Erasing is handled in pan start/update
        break;
      case DrawingTool.none:
        break;
    }
    
    setState(() {
      _isDrawing = false;
      _startPoint = null;
      _currentPoint = null;
    });
    
    widget.onDrawingStateChanged?.call();
  }

  void _removeShapeAt(Offset position) {
    const double tolerance = 20.0;
    bool removed = false;
    
    // Check circles first
    for (int i = _circles.length - 1; i >= 0; i--) {
      final circle = _circles[i];
      if ((position - circle.center).distance <= circle.radius + tolerance) {
        setState(() {
          _circles.removeAt(i);
        });
        removed = true;
        break;
      }
    }
    
    if (!removed) {
      // Check rectangles
      for (int i = _rectangles.length - 1; i >= 0; i--) {
        final rect = _rectangles[i];
        if (rect.rect.inflate(tolerance).contains(position)) {
          setState(() {
            _rectangles.removeAt(i);
          });
          removed = true;
          break;
        }
      }
    }
    
    if (!removed) {
      // Check lines
      for (int i = _lines.length - 1; i >= 0; i--) {
        final line = _lines[i];
        if (_distanceToLineSegment(position, line.start, line.end) <= tolerance) {
          setState(() {
            _lines.removeAt(i);
          });
          break;
        }
      }
    }
    
    if (removed) {
      widget.onDrawingStateChanged?.call();
    }
  }

  double _distanceToLineSegment(Offset point, Offset lineStart, Offset lineEnd) {
    final A = point.dx - lineStart.dx;
    final B = point.dy - lineStart.dy;
    final C = lineEnd.dx - lineStart.dx;
    final D = lineEnd.dy - lineStart.dy;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    
    if (lenSq == 0) return (point - lineStart).distance;
    
    final param = dot / lenSq;
    
    Offset projection;
    if (param < 0) {
      projection = lineStart;
    } else if (param > 1) {
      projection = lineEnd;
    } else {
      projection = Offset(lineStart.dx + param * C, lineStart.dy + param * D);
    }
    
    return (point - projection).distance;
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingLine> lines;
  final List<DrawingRectangle> rectangles;
  final List<DrawingCircle> circles;
  final bool isDrawing;
  final Offset? startPoint;
  final Offset? currentPoint;
  final DrawingTool currentTool;

  DrawingPainter({
    required this.lines,
    required this.rectangles,
    required this.circles,
    required this.isDrawing,
    this.startPoint,
    this.currentPoint,
    required this.currentTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw all existing lines
    for (final line in lines) {
      paint.color = line.color;
      paint.strokeWidth = line.strokeWidth;
      canvas.drawLine(line.start, line.end, paint);
    }

    // Draw all existing rectangles
    for (final rectangle in rectangles) {
      paint.color = rectangle.color;
      paint.strokeWidth = rectangle.strokeWidth;
      canvas.drawRect(rectangle.rect, paint);
    }

    // Draw all existing circles
    for (final circle in circles) {
      paint.color = circle.color;
      paint.strokeWidth = circle.strokeWidth;
      canvas.drawCircle(circle.center, circle.radius, paint);
    }

    // Draw current shape being created
    if (isDrawing && startPoint != null && currentPoint != null) {
      paint.strokeWidth = 3.0;
      paint.color = _getToolColor(currentTool).withValues(alpha: 0.7);
      
      switch (currentTool) {
        case DrawingTool.line:
          canvas.drawLine(startPoint!, currentPoint!, paint);
          break;
        case DrawingTool.rectangle:
          final rect = Rect.fromPoints(startPoint!, currentPoint!);
          canvas.drawRect(rect, paint);
          break;
        case DrawingTool.circle:
          final radius = (currentPoint! - startPoint!).distance;
          canvas.drawCircle(startPoint!, radius, paint);
          break;
        case DrawingTool.eraser:
          // Draw eraser cursor
          paint.color = Colors.red.withValues(alpha: 0.5);
          paint.strokeWidth = 2.0;
          canvas.drawCircle(currentPoint!, 15, paint);
          break;
        case DrawingTool.none:
          break;
      }
    }
  }

  Color _getToolColor(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.line:
        return Colors.blue;
      case DrawingTool.rectangle:
        return Colors.green;
      case DrawingTool.circle:
        return Colors.red;
      case DrawingTool.eraser:
        return Colors.red;
      case DrawingTool.none:
        return Colors.white;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
