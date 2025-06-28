import 'package:flutter/material.dart';
import 'drawing_toolbar.dart'; // Import for DrawingTool enum

class DrawingPoint {
  final Offset point;
  final DateTime timestamp;

  DrawingPoint({required this.point, required this.timestamp});
}

class DrawingLine {
  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;
  final DateTime timestamp;

  DrawingLine({
    required this.start,
    required this.end,
    this.color = Colors.yellow,
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
  DrawingOverlayState createState() => DrawingOverlayState();
}

class DrawingOverlayState extends State<DrawingOverlay> {
  final List<DrawingLine> _lines = [];
  Offset? _firstPoint;
  Offset? _currentEndPoint;
  bool _isDrawingLine = false;
  bool _isDraggingEndPoint = false;

  List<DrawingLine> get lines => _lines;

  void _onTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;
    
    if (widget.currentTool == DrawingTool.line) {
      _handleLineTap(details);
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isEnabled) return;
    
    if (widget.currentTool == DrawingTool.eraser) {
      _handleEraserStart(details);
    } else if (widget.currentTool == DrawingTool.line && _isDrawingLine && _firstPoint != null) {
      // Check if we're starting to drag from near the current end point
      _handleLinePointDragStart(details);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled) return;
    
    if (widget.currentTool == DrawingTool.eraser) {
      _handleEraserUpdate(details);
    } else if (widget.currentTool == DrawingTool.line && _isDraggingEndPoint) {
      _handleLinePointDragUpdate(details);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isEnabled) return;
    
    if (widget.currentTool == DrawingTool.line && _isDraggingEndPoint) {
      _handleLinePointDragEnd();
    }
  }

  void _handleLineTap(TapDownDetails details) {
    if (_firstPoint == null) {
      // First tap - record starting point
      setState(() {
        _firstPoint = details.localPosition;
        _isDrawingLine = true;
        _currentEndPoint = null;
        _isDraggingEndPoint = false;
      });
    } else if (!_isDraggingEndPoint) {
      // Second tap - set initial end point, ready for dragging
      setState(() {
        _currentEndPoint = details.localPosition;
        _isDraggingEndPoint = false; // Will be set to true when dragging starts
      });
    }
  }

  void _handleLinePointDragStart(DragStartDetails details) {
    if (_firstPoint != null && _currentEndPoint != null) {
      // Check if the drag start is near the current end point
      const double tolerance = 30.0;
      final double distance = (details.localPosition - _currentEndPoint!).distance;
      
      if (distance <= tolerance) {
        setState(() {
          _isDraggingEndPoint = true;
        });
      }
    }
  }

  void _handleLinePointDragUpdate(DragUpdateDetails details) {
    if (_firstPoint != null && _isDraggingEndPoint) {
      setState(() {
        _currentEndPoint = details.localPosition;
      });
    }
  }

  void _handleLinePointDragEnd() {
    if (_firstPoint != null && _currentEndPoint != null) {
      // Complete the line
      setState(() {
        _lines.add(DrawingLine(
          start: _firstPoint!,
          end: _currentEndPoint!,
          timestamp: DateTime.now(),
        ));
        _firstPoint = null;
        _currentEndPoint = null;
        _isDrawingLine = false;
        _isDraggingEndPoint = false;
      });
      widget.onDrawingStateChanged?.call();
    }
  }

  void _handleEraserStart(DragStartDetails details) {
    _checkAndRemoveLineAt(details.localPosition);
  }

  void _handleEraserUpdate(DragUpdateDetails details) {
    _checkAndRemoveLineAt(details.localPosition);
  }

  void _checkAndRemoveLineAt(Offset position) {
    const double tolerance = 20.0; // Increased tolerance for easier erasing
    
    for (int i = _lines.length - 1; i >= 0; i--) {
      final line = _lines[i];
      if (_isPointNearLine(position, line.start, line.end, tolerance)) {
        setState(() {
          _lines.removeAt(i);
        });
        widget.onDrawingStateChanged?.call();
        break; // Only remove one line per drag point
      }
    }
  }

  bool _isPointNearLine(Offset point, Offset lineStart, Offset lineEnd, double tolerance) {
    // Calculate distance from point to line segment
    final double A = point.dx - lineStart.dx;
    final double B = point.dy - lineStart.dy;
    final double C = lineEnd.dx - lineStart.dx;
    final double D = lineEnd.dy - lineStart.dy;

    final double dot = A * C + B * D;
    final double lenSq = C * C + D * D;
    
    if (lenSq == 0) {
      // Line start and end are the same point
      return (point - lineStart).distance <= tolerance;
    }
    
    double param = dot / lenSq;

    Offset closestPoint;
    if (param < 0) {
      closestPoint = lineStart;
    } else if (param > 1) {
      closestPoint = lineEnd;
    } else {
      closestPoint = Offset(
        lineStart.dx + param * C,
        lineStart.dy + param * D,
      );
    }

    final double distance = (point - closestPoint).distance;
    return distance <= tolerance;
  }

  void clearDrawings() {
    setState(() {
      _lines.clear();
      _firstPoint = null;
      _currentEndPoint = null;
      _isDrawingLine = false;
      _isDraggingEndPoint = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isEnabled)
          Positioned.fill(
            child: GestureDetector(
              onTapDown: _onTapDown,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: DrawingPainter(
                  lines: _lines,
                  firstPoint: _firstPoint,
                  currentEndPoint: _currentEndPoint,
                  isDrawingLine: _isDrawingLine,
                  isDraggingEndPoint: _isDraggingEndPoint,
                  currentTool: widget.currentTool,
                ),
                child: Container(),
              ),
            ),
          ),
      ],
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingLine> lines;
  final Offset? firstPoint;
  final Offset? currentEndPoint;
  final bool isDrawingLine;
  final bool isDraggingEndPoint;
  final DrawingTool currentTool;

  DrawingPainter({
    required this.lines,
    this.firstPoint,
    this.currentEndPoint,
    required this.isDrawingLine,
    required this.isDraggingEndPoint,
    this.currentTool = DrawingTool.none,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw completed lines
    for (final line in lines) {
      paint.color = line.color;
      paint.strokeWidth = line.strokeWidth;
      canvas.drawLine(line.start, line.end, paint);
      
      // Draw small circles at the endpoints
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(line.start, 4, paint);
      canvas.drawCircle(line.end, 4, paint);
      paint.style = PaintingStyle.stroke;
    }

    // Draw the current line being created
    if (firstPoint != null && isDrawingLine) {
      paint.color = Colors.yellow.withOpacity(0.8);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(firstPoint!, 6, paint);
      
      // Draw a pulsing ring around the first point to indicate drawing mode
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.color = Colors.yellow.withOpacity(0.6);
      canvas.drawCircle(firstPoint!, 10, paint);
      
      // If we have a current end point, draw the preview line
      if (currentEndPoint != null) {
        paint.color = Colors.yellow.withOpacity(0.7);
        paint.strokeWidth = 3.0;
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(firstPoint!, currentEndPoint!, paint);
        
        // Draw the end point
        paint.style = PaintingStyle.fill;
        paint.color = Colors.yellow.withOpacity(0.9);
        canvas.drawCircle(currentEndPoint!, 6, paint);
        
        // Draw a visual indicator that this point can be dragged
        if (!isDraggingEndPoint) {
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 2;
          paint.color = Colors.white.withOpacity(0.8);
          canvas.drawCircle(currentEndPoint!, 12, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
