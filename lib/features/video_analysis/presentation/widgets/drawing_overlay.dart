import 'package:flutter/material.dart';

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
  final VoidCallback? onDrawingStateChanged;

  const DrawingOverlay({
    super.key,
    required this.child,
    this.isEnabled = false,
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

  void clearDrawings() {
    setState(() {
      _lines.clear();
      _firstPoint = null;
      _isDrawingLine = false;
    });
  }

  void undoLastLine() {
    if (_lines.isNotEmpty) {
      setState(() {
        _lines.removeLast();
      });
    } else if (_firstPoint != null) {
      setState(() {
        _firstPoint = null;
        _isDrawingLine = false;
      });
    }
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
              child: CustomPaint(
                painter: DrawingPainter(
                  lines: _lines,
                  firstPoint: _firstPoint,
                  isDrawingLine: _isDrawingLine,
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

  DrawingPainter({
    required this.lines,
    this.firstPoint,
    required this.isDrawingLine,
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
