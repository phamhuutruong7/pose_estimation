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
  bool _isDrawingLine = false;

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
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled) return;
    
    if (widget.currentTool == DrawingTool.eraser) {
      _handleEraserUpdate(details);
    }
  }

  void _handleLineTap(TapDownDetails details) {
    if (_firstPoint == null) {
      // First tap - record starting point
      setState(() {
        _firstPoint = details.localPosition;
        _isDrawingLine = true;
      });
    } else {
      // Second tap - complete the line
      setState(() {
        _lines.add(DrawingLine(
          start: _firstPoint!,
          end: details.localPosition,
          timestamp: DateTime.now(),
        ));
        _firstPoint = null;
        _isDrawingLine = false;
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
      _isDrawingLine = false;
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
              child: CustomPaint(
                painter: DrawingPainter(
                  lines: _lines,
                  firstPoint: _firstPoint,
                  isDrawingLine: _isDrawingLine,
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
  final bool isDrawingLine;
  final DrawingTool currentTool;

  DrawingPainter({
    required this.lines,
    this.firstPoint,
    required this.isDrawingLine,
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

    // Draw the first point if we're in drawing mode
    if (firstPoint != null && isDrawingLine) {
      paint.color = Colors.yellow.withOpacity(0.8);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(firstPoint!, 6, paint);
      
      // Draw a pulsing ring around the first point to indicate drawing mode
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.color = Colors.yellow.withOpacity(0.6);
      canvas.drawCircle(firstPoint!, 10, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
