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

class DrawingRectangle {
  final Offset topLeft;
  final Offset bottomRight;
  final Color color;
  final double strokeWidth;
  final DateTime timestamp;

  DrawingRectangle({
    required this.topLeft,
    required this.bottomRight,
    this.color = Colors.yellow,
    this.strokeWidth = 3.0,
    required this.timestamp,
  });

  Rect get rect => Rect.fromPoints(topLeft, bottomRight);

  // Get corner points for interaction
  List<Offset> get cornerPoints => [
    topLeft,
    Offset(bottomRight.dx, topLeft.dy), // top right
    bottomRight,
    Offset(topLeft.dx, bottomRight.dy), // bottom left
  ];

  // Get the size of the rectangle
  Size get size => Size(
    (bottomRight.dx - topLeft.dx).abs(),
    (bottomRight.dy - topLeft.dy).abs(),
  );
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
  State<DrawingOverlay> createState() => DrawingOverlayState();
}

class DrawingOverlayState extends State<DrawingOverlay> {
  final List<DrawingLine> _lines = [];
  final List<DrawingRectangle> _rectangles = [];
  final List<DrawingCircle> _circles = [];

  // Line drawing state
  Offset? _firstPoint;
  Offset? _currentEndPoint;
  bool _isDrawingLine = false;
  bool _isDraggingEndPoint = false;

  // Rectangle drawing state
  Offset? _rectStartPoint;
  Offset? _rectCurrentPoint;
  bool _isDrawingRectangle = false;
  int? _dragCornerIndex;
  int? _selectedRectangleIndex;

  // Circle drawing state
  Offset? _circleCenter;
  double _circleRadius = 0;
  bool _isDrawingCircle = false;
  int? _selectedCircleIndex;

  // General dragging state
  bool _isDraggingShape = false;
  Offset? _dragOffset;

  List<DrawingLine> get lines => _lines;
  List<DrawingRectangle> get rectangles => _rectangles;
  List<DrawingCircle> get circles => _circles;

  void _onTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;

    switch (widget.currentTool) {
      case DrawingTool.line:
        _handleLineTap(details);
        break;
      case DrawingTool.rectangle:
        _handleRectangleTap(details);
        break;
      case DrawingTool.circle:
        _handleCircleTap(details);
        break;
      default:
        break;
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isEnabled) return;

    switch (widget.currentTool) {
      case DrawingTool.eraser:
        _handleEraserStart(details);
        break;
      case DrawingTool.line:
        if (_isDrawingLine && _firstPoint != null) {
          _handleLinePointDragStart(details);
        }
        break;
      case DrawingTool.rectangle:
        _handleRectangleDragStart(details);
        break;
      case DrawingTool.circle:
        _handleCircleDragStart(details);
        break;
      default:
        break;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled) return;

    switch (widget.currentTool) {
      case DrawingTool.eraser:
        _handleEraserUpdate(details);
        break;
      case DrawingTool.line:
        if (_isDraggingEndPoint) {
          _handleLinePointDragUpdate(details);
        }
        break;
      case DrawingTool.rectangle:
        _handleRectangleDragUpdate(details);
        break;
      case DrawingTool.circle:
        _handleCircleDragUpdate(details);
        break;
      default:
        break;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isEnabled) return;

    switch (widget.currentTool) {
      case DrawingTool.line:
        if (_isDraggingEndPoint) {
          _handleLinePointDragEnd();
        }
        break;
      case DrawingTool.rectangle:
        _handleRectangleDragEnd();
        break;
      case DrawingTool.circle:
        _handleCircleDragEnd();
        break;
      default:
        break;
    }
  }

  // Line handling methods
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
      final double distance =
          (details.localPosition - _currentEndPoint!).distance;

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
        _lines.add(
          DrawingLine(
            start: _firstPoint!,
            end: _currentEndPoint!,
            timestamp: DateTime.now(),
          ),
        );
        _firstPoint = null;
        _currentEndPoint = null;
        _isDrawingLine = false;
        _isDraggingEndPoint = false;
      });
      widget.onDrawingStateChanged?.call();
    }
  }

  // Rectangle handling methods
  void _handleRectangleTap(TapDownDetails details) {
    // Check if tapping on existing rectangle to select/move it
    for (int i = 0; i < _rectangles.length; i++) {
      if (_rectangles[i].rect.contains(details.localPosition)) {
        setState(() {
          _selectedRectangleIndex = i;
          _isDraggingShape = false;
          _dragOffset = details.localPosition - _rectangles[i].topLeft;
        });
        return;
      }
    }

    // Start new rectangle if not selecting existing one
    setState(() {
      _rectStartPoint = details.localPosition;
      _rectCurrentPoint = details.localPosition;
      _isDrawingRectangle = true;
      _selectedRectangleIndex = null;
    });
  }

  void _handleRectangleDragStart(DragStartDetails details) {
    if (_selectedRectangleIndex != null) {
      // Check if dragging a corner
      final rect = _rectangles[_selectedRectangleIndex!];
      const double cornerTolerance = 20.0;

      for (int i = 0; i < rect.cornerPoints.length; i++) {
        if ((details.localPosition - rect.cornerPoints[i]).distance <=
            cornerTolerance) {
          setState(() {
            _dragCornerIndex = i;
            _isDraggingShape = false;
          });
          return;
        }
      }

      // Start moving the whole rectangle
      setState(() {
        _isDraggingShape = true;
        _dragCornerIndex = null;
      });
    } else if (_isDrawingRectangle) {
      // Continue drawing rectangle
      setState(() {
        _rectCurrentPoint = details.localPosition;
      });
    }
  }

  void _handleRectangleDragUpdate(DragUpdateDetails details) {
    if (_selectedRectangleIndex != null) {
      if (_dragCornerIndex != null) {
        // Resize rectangle by dragging corner
        _resizeRectangleCorner(details.localPosition);
      } else if (_isDraggingShape) {
        // Move entire rectangle
        _moveRectangle(details.localPosition);
      }
    } else if (_isDrawingRectangle) {
      // Update rectangle size while drawing
      setState(() {
        _rectCurrentPoint = details.localPosition;
      });
    }
  }

  void _handleRectangleDragEnd() {
    if (_isDrawingRectangle &&
        _rectStartPoint != null &&
        _rectCurrentPoint != null) {
      // Complete rectangle creation
      setState(() {
        _rectangles.add(
          DrawingRectangle(
            topLeft: Offset(
              _rectStartPoint!.dx < _rectCurrentPoint!.dx
                  ? _rectStartPoint!.dx
                  : _rectCurrentPoint!.dx,
              _rectStartPoint!.dy < _rectCurrentPoint!.dy
                  ? _rectStartPoint!.dy
                  : _rectCurrentPoint!.dy,
            ),
            bottomRight: Offset(
              _rectStartPoint!.dx > _rectCurrentPoint!.dx
                  ? _rectStartPoint!.dx
                  : _rectCurrentPoint!.dx,
              _rectStartPoint!.dy > _rectCurrentPoint!.dy
                  ? _rectStartPoint!.dy
                  : _rectCurrentPoint!.dy,
            ),
            timestamp: DateTime.now(),
          ),
        );
        _rectStartPoint = null;
        _rectCurrentPoint = null;
        _isDrawingRectangle = false;
      });
      widget.onDrawingStateChanged?.call();
    }

    // Reset drag states
    setState(() {
      _dragCornerIndex = null;
      _isDraggingShape = false;
    });
  }

  void _resizeRectangleCorner(Offset newPosition) {
    if (_selectedRectangleIndex == null || _dragCornerIndex == null) return;

    final rect = _rectangles[_selectedRectangleIndex!];
    Offset newTopLeft = rect.topLeft;
    Offset newBottomRight = rect.bottomRight;

    switch (_dragCornerIndex!) {
      case 0: // top left
        newTopLeft = newPosition;
        break;
      case 1: // top right
        newTopLeft = Offset(rect.topLeft.dx, newPosition.dy);
        newBottomRight = Offset(newPosition.dx, rect.bottomRight.dy);
        break;
      case 2: // bottom right
        newBottomRight = newPosition;
        break;
      case 3: // bottom left
        newTopLeft = Offset(newPosition.dx, rect.topLeft.dy);
        newBottomRight = Offset(rect.bottomRight.dx, newPosition.dy);
        break;
    }

    setState(() {
      _rectangles[_selectedRectangleIndex!] = DrawingRectangle(
        topLeft: newTopLeft,
        bottomRight: newBottomRight,
        timestamp: rect.timestamp,
      );
    });
  }

  void _moveRectangle(Offset newPosition) {
    if (_selectedRectangleIndex == null || _dragOffset == null) return;

    final rect = _rectangles[_selectedRectangleIndex!];
    final newTopLeft = newPosition - _dragOffset!;
    final size = rect.bottomRight - rect.topLeft;

    setState(() {
      _rectangles[_selectedRectangleIndex!] = DrawingRectangle(
        topLeft: newTopLeft,
        bottomRight: newTopLeft + size,
        timestamp: rect.timestamp,
      );
    });
  }

  // Circle handling methods
  void _handleCircleTap(TapDownDetails details) {
    // Check if tapping on existing circle to select/move it
    for (int i = 0; i < _circles.length; i++) {
      final circle = _circles[i];
      if ((details.localPosition - circle.center).distance <= circle.radius) {
        setState(() {
          _selectedCircleIndex = i;
          _isDraggingShape = false;
          _dragOffset = details.localPosition - circle.center;
        });
        return;
      }
    }

    // Start new circle - first tap sets center
    setState(() {
      _circleCenter = details.localPosition;
      _circleRadius = 0;
      _isDrawingCircle = true;
      _selectedCircleIndex = null;
    });
  }

  void _handleCircleDragStart(DragStartDetails details) {
    if (_selectedCircleIndex != null) {
      // Start moving the circle
      setState(() {
        _isDraggingShape = true;
      });
    } else if (_isDrawingCircle && _circleCenter != null) {
      // Start expanding radius from center
      setState(() {
        _circleRadius = (details.localPosition - _circleCenter!).distance;
      });
    }
  }

  void _handleCircleDragUpdate(DragUpdateDetails details) {
    if (_selectedCircleIndex != null && _isDraggingShape) {
      // Move circle
      _moveCircle(details.localPosition);
    } else if (_isDrawingCircle && _circleCenter != null) {
      // Update radius while drawing
      setState(() {
        _circleRadius = (details.localPosition - _circleCenter!).distance;
      });
    }
  }

  void _handleCircleDragEnd() {
    if (_isDrawingCircle && _circleCenter != null && _circleRadius > 10) {
      // Complete circle creation (minimum radius of 10)
      setState(() {
        _circles.add(
          DrawingCircle(
            center: _circleCenter!,
            radius: _circleRadius,
            timestamp: DateTime.now(),
          ),
        );
        _circleCenter = null;
        _circleRadius = 0;
        _isDrawingCircle = false;
      });
      widget.onDrawingStateChanged?.call();
    } else if (_isDrawingCircle) {
      // Cancel circle creation if radius too small
      setState(() {
        _circleCenter = null;
        _circleRadius = 0;
        _isDrawingCircle = false;
      });
    }

    // Reset drag states
    setState(() {
      _isDraggingShape = false;
    });
  }

  void _moveCircle(Offset newPosition) {
    if (_selectedCircleIndex == null || _dragOffset == null) return;

    final circle = _circles[_selectedCircleIndex!];
    final newCenter = newPosition - _dragOffset!;

    setState(() {
      _circles[_selectedCircleIndex!] = DrawingCircle(
        center: newCenter,
        radius: circle.radius,
        timestamp: circle.timestamp,
      );
    });
  }

  // Eraser handling methods
  void _handleEraserStart(DragStartDetails details) {
    _checkAndRemoveShapeAt(details.localPosition);
  }

  void _handleEraserUpdate(DragUpdateDetails details) {
    _checkAndRemoveShapeAt(details.localPosition);
  }

  void _checkAndRemoveShapeAt(Offset position) {
    const double tolerance = 20.0;

    // Check circles first (easiest to calculate)
    for (int i = _circles.length - 1; i >= 0; i--) {
      final circle = _circles[i];
      if ((position - circle.center).distance <= circle.radius + tolerance) {
        setState(() {
          _circles.removeAt(i);
        });
        widget.onDrawingStateChanged?.call();
        return;
      }
    }

    // Check rectangles
    for (int i = _rectangles.length - 1; i >= 0; i--) {
      final rect = _rectangles[i];
      if (rect.rect.inflate(tolerance).contains(position)) {
        setState(() {
          _rectangles.removeAt(i);
        });
        widget.onDrawingStateChanged?.call();
        return;
      }
    }

    // Check lines
    for (int i = _lines.length - 1; i >= 0; i--) {
      final line = _lines[i];
      if (_isPointNearLine(position, line.start, line.end, tolerance)) {
        setState(() {
          _lines.removeAt(i);
        });
        widget.onDrawingStateChanged?.call();
        return;
      }
    }
  }

  bool _isPointNearLine(
    Offset point,
    Offset lineStart,
    Offset lineEnd,
    double tolerance,
  ) {
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
      closestPoint = Offset(lineStart.dx + param * C, lineStart.dy + param * D);
    }

    final double distance = (point - closestPoint).distance;
    return distance <= tolerance;
  }

  void clearDrawings() {
    setState(() {
      _lines.clear();
      _rectangles.clear();
      _circles.clear();
      _firstPoint = null;
      _currentEndPoint = null;
      _isDrawingLine = false;
      _isDraggingEndPoint = false;
      _rectStartPoint = null;
      _rectCurrentPoint = null;
      _isDrawingRectangle = false;
      _dragCornerIndex = null;
      _selectedRectangleIndex = null;
      _circleCenter = null;
      _circleRadius = 0;
      _isDrawingCircle = false;
      _selectedCircleIndex = null;
      _isDraggingShape = false;
      _dragOffset = null;
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
                  rectangles: _rectangles,
                  circles: _circles,
                  firstPoint: _firstPoint,
                  currentEndPoint: _currentEndPoint,
                  isDrawingLine: _isDrawingLine,
                  isDraggingEndPoint: _isDraggingEndPoint,
                  rectStartPoint: _rectStartPoint,
                  rectCurrentPoint: _rectCurrentPoint,
                  isDrawingRectangle: _isDrawingRectangle,
                  circleCenter: _circleCenter,
                  circleRadius: _circleRadius,
                  isDrawingCircle: _isDrawingCircle,
                  currentTool: widget.currentTool,
                  selectedRectangleIndex: _selectedRectangleIndex,
                  selectedCircleIndex: _selectedCircleIndex,
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
  final List<DrawingRectangle> rectangles;
  final List<DrawingCircle> circles;
  final Offset? firstPoint;
  final Offset? currentEndPoint;
  final bool isDrawingLine;
  final bool isDraggingEndPoint;
  final Offset? rectStartPoint;
  final Offset? rectCurrentPoint;
  final bool isDrawingRectangle;
  final Offset? circleCenter;
  final double circleRadius;
  final bool isDrawingCircle;
  final DrawingTool currentTool;
  final int? selectedRectangleIndex;
  final int? selectedCircleIndex;

  DrawingPainter({
    required this.lines,
    required this.rectangles,
    required this.circles,
    this.firstPoint,
    this.currentEndPoint,
    required this.isDrawingLine,
    required this.isDraggingEndPoint,
    this.rectStartPoint,
    this.rectCurrentPoint,
    required this.isDrawingRectangle,
    this.circleCenter,
    required this.circleRadius,
    required this.isDrawingCircle,
    this.currentTool = DrawingTool.none,
    this.selectedRectangleIndex,
    this.selectedCircleIndex,
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

    // Draw completed rectangles
    for (int i = 0; i < rectangles.length; i++) {
      final rectangle = rectangles[i];
      paint.color = rectangle.color;
      paint.strokeWidth = rectangle.strokeWidth;
      paint.style = PaintingStyle.stroke;
      canvas.drawRect(rectangle.rect, paint);

      // Draw corner handles for selected rectangle
      if (selectedRectangleIndex == i) {
        paint.style = PaintingStyle.fill;
        paint.color = Colors.white;
        for (final corner in rectangle.cornerPoints) {
          canvas.drawCircle(corner, 6, paint);
        }
        paint.style = PaintingStyle.stroke;
        paint.color = rectangle.color;
        for (final corner in rectangle.cornerPoints) {
          canvas.drawCircle(corner, 6, paint);
        }
      }
    }

    // Draw completed circles
    for (int i = 0; i < circles.length; i++) {
      final circle = circles[i];
      paint.color = circle.color;
      paint.strokeWidth = circle.strokeWidth;
      paint.style = PaintingStyle.stroke;
      canvas.drawCircle(circle.center, circle.radius, paint);

      // Draw center point for selected circle
      if (selectedCircleIndex == i) {
        paint.style = PaintingStyle.fill;
        paint.color = Colors.white;
        canvas.drawCircle(circle.center, 6, paint);
        paint.style = PaintingStyle.stroke;
        paint.color = circle.color;
        canvas.drawCircle(circle.center, 6, paint);
      }
    }

    // Draw current line being created
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

    // Draw current rectangle being created
    if (isDrawingRectangle &&
        rectStartPoint != null &&
        rectCurrentPoint != null) {
      final rect = Rect.fromPoints(rectStartPoint!, rectCurrentPoint!);
      paint.color = Colors.yellow.withOpacity(0.7);
      paint.strokeWidth = 3.0;
      paint.style = PaintingStyle.stroke;
      canvas.drawRect(rect, paint);

      // Draw corner indicators
      paint.style = PaintingStyle.fill;
      paint.color = Colors.yellow.withOpacity(0.9);
      canvas.drawCircle(rectStartPoint!, 4, paint);
      canvas.drawCircle(rectCurrentPoint!, 4, paint);
    }

    // Draw current circle being created
    if (isDrawingCircle && circleCenter != null) {
      paint.color = Colors.yellow.withOpacity(0.7);
      paint.strokeWidth = 3.0;
      paint.style = PaintingStyle.stroke;

      if (circleRadius > 0) {
        canvas.drawCircle(circleCenter!, circleRadius, paint);
      }

      // Draw center point
      paint.style = PaintingStyle.fill;
      paint.color = Colors.yellow.withOpacity(0.9);
      canvas.drawCircle(circleCenter!, 6, paint);

      // Draw radius line while dragging
      if (circleRadius > 0) {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1.0;
        paint.color = Colors.yellow.withOpacity(0.5);
        final radiusEnd = circleCenter! + Offset(circleRadius, 0);
        canvas.drawLine(circleCenter!, radiusEnd, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
