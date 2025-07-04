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
    this.color = Colors.blue, // Changed to blue for lines
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
    this.color = Colors.green, // Changed to green for rectangles
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
    this.color = Colors.red, // Changed to red for circles
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
  int? _selectedLineIndex;
  
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
    
    print('TapDown: Tool=${widget.currentTool}, Position=${details.localPosition}');
    
    // For selection tools - check if clicking on existing shapes
    if (widget.currentTool == DrawingTool.none) {
      _selectShapeAt(details.localPosition);
      return;
    }
    
    // For drawing tools - start new shape creation
    switch (widget.currentTool) {
      case DrawingTool.line:
        print('Starting line drawing');
        _startLineDrawing(details.localPosition);
        break;
      case DrawingTool.rectangle:
        print('Starting rectangle drawing');
        _startRectangleDrawing(details.localPosition);
        break;
      case DrawingTool.circle:
        print('Starting circle drawing');
        _startCircleDrawing(details.localPosition);
        break;
      default:
        print('Unknown tool: ${widget.currentTool}');
        break;
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isEnabled) return;
    
    switch (widget.currentTool) {
      case DrawingTool.eraser:
        _handleEraserStart(details);
        break;
      default:
        // For drawing tools, pan start is handled in onTapDown
        break;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled) return;
    
    print('PanUpdate: Tool=${widget.currentTool}, Position=${details.localPosition}');
    
    switch (widget.currentTool) {
      case DrawingTool.eraser:
        _handleEraserUpdate(details);
        break;
      case DrawingTool.line:
        print('Updating line drawing: _isDrawingLine=$_isDrawingLine');
        _updateLineDrawing(details.localPosition);
        break;
      case DrawingTool.rectangle:
        print('Updating rectangle drawing: _isDrawingRectangle=$_isDrawingRectangle');
        _updateRectangleDrawing(details.localPosition);
        break;
      case DrawingTool.circle:
        print('Updating circle drawing: _isDrawingCircle=$_isDrawingCircle');
        _updateCircleDrawing(details.localPosition);
        break;
      default:
        break;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isEnabled) return;
    
    switch (widget.currentTool) {
      case DrawingTool.line:
        _finishLineDrawing();
        break;
      case DrawingTool.rectangle:
        _finishRectangleDrawing();
        break;
      case DrawingTool.circle:
        _finishCircleDrawing();
        break;
      default:
        break;
    }
  }

  // Selection methods
  void _selectShapeAt(Offset position) {
    // Clear current selection
    setState(() {
      _selectedLineIndex = null;
      _selectedRectangleIndex = null;
      _selectedCircleIndex = null;
    });
  }

  // Simplified drawing methods for LINE
  void _startLineDrawing(Offset position) {
    print('_startLineDrawing called with position: $position');
    setState(() {
      _firstPoint = position;
      _currentEndPoint = position;
      _isDrawingLine = true;
      // Clear any selections when starting to draw
      _selectedLineIndex = null;
      _selectedRectangleIndex = null;
      _selectedCircleIndex = null;
    });
    print('Line drawing state set: _isDrawingLine=$_isDrawingLine, _firstPoint=$_firstPoint');
  }

  void _updateLineDrawing(Offset position) {
    print('_updateLineDrawing called: _isDrawingLine=$_isDrawingLine, position=$position');
    if (_isDrawingLine) {
      setState(() {
        _currentEndPoint = position;
      });
    }
  }

  void _finishLineDrawing() {
    if (_isDrawingLine && _firstPoint != null && _currentEndPoint != null) {
      setState(() {
        _lines.add(DrawingLine(
          start: _firstPoint!,
          end: _currentEndPoint!,
          timestamp: DateTime.now(),
        ));
        _firstPoint = null;
        _currentEndPoint = null;
        _isDrawingLine = false;
      });
      widget.onDrawingStateChanged?.call();
    }
  }

  // Simplified drawing methods for RECTANGLE
  void _startRectangleDrawing(Offset position) {
    setState(() {
      _rectStartPoint = position;
      _rectCurrentPoint = position;
      _isDrawingRectangle = true;
      // Clear any selections when starting to draw
      _selectedLineIndex = null;
      _selectedRectangleIndex = null;
      _selectedCircleIndex = null;
    });
  }

  void _updateRectangleDrawing(Offset position) {
    if (_isDrawingRectangle) {
      setState(() {
        _rectCurrentPoint = position;
      });
    }
  }

  void _finishRectangleDrawing() {
    if (_isDrawingRectangle && _rectStartPoint != null && _rectCurrentPoint != null) {
      setState(() {
        _rectangles.add(DrawingRectangle(
          topLeft: Offset(
            _rectStartPoint!.dx < _rectCurrentPoint!.dx ? _rectStartPoint!.dx : _rectCurrentPoint!.dx,
            _rectStartPoint!.dy < _rectCurrentPoint!.dy ? _rectStartPoint!.dy : _rectCurrentPoint!.dy,
          ),
          bottomRight: Offset(
            _rectStartPoint!.dx > _rectCurrentPoint!.dx ? _rectStartPoint!.dx : _rectCurrentPoint!.dx,
            _rectStartPoint!.dy > _rectCurrentPoint!.dy ? _rectStartPoint!.dy : _rectCurrentPoint!.dy,
          ),
          timestamp: DateTime.now(),
        ));
        _rectStartPoint = null;
        _rectCurrentPoint = null;
        _isDrawingRectangle = false;
      });
      widget.onDrawingStateChanged?.call();
    }
  }

  // Simplified drawing methods for CIRCLE
  void _startCircleDrawing(Offset position) {
    setState(() {
      _circleCenter = position;
      _circleRadius = 0;
      _isDrawingCircle = true;
      // Clear any selections when starting to draw
      _selectedLineIndex = null;
      _selectedRectangleIndex = null;
      _selectedCircleIndex = null;
    });
  }

  void _updateCircleDrawing(Offset position) {
    if (_isDrawingCircle && _circleCenter != null) {
      setState(() {
        _circleRadius = (position - _circleCenter!).distance;
      });
    }
  }

  void _finishCircleDrawing() {
    if (_isDrawingCircle && _circleCenter != null && _circleRadius > 5) {
      setState(() {
        _circles.add(DrawingCircle(
          center: _circleCenter!,
          radius: _circleRadius,
          timestamp: DateTime.now(),
        ));
        _circleCenter = null;
        _circleRadius = 0;
        _isDrawingCircle = false;
      });
      widget.onDrawingStateChanged?.call();
    } else {
      // Cancel if radius is too small
      setState(() {
        _circleCenter = null;
        _circleRadius = 0;
        _isDrawingCircle = false;
      });
    }
  }

  // Rectangle handling methods
  void _handleRectangleTap(TapDownDetails details) {
    // Check if tapping on existing rectangle to select/move it
    for (int i = 0; i < _rectangles.length; i++) {
      if (_rectangles[i].rect.contains(details.localPosition)) {
        setState(() {
          _selectedRectangleIndex = i;
          _selectedLineIndex = null;
          _selectedCircleIndex = null;
        });
        return;
      }
    }
    
    // Deselect all if tapping on empty space
    setState(() {
      _selectedRectangleIndex = null;
      _selectedLineIndex = null;
      _selectedCircleIndex = null;
    });
  }

  void _handleRectangleDragStart(DragStartDetails details) {
    if (_selectedRectangleIndex != null) {
      // Check if dragging a corner
      final rect = _rectangles[_selectedRectangleIndex!];
      const double cornerTolerance = 20.0;
      
      for (int i = 0; i < rect.cornerPoints.length; i++) {
        if ((details.localPosition - rect.cornerPoints[i]).distance <= cornerTolerance) {
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
        _dragOffset = details.localPosition - rect.topLeft;
      });
    } else {
      // Start drawing new rectangle
      setState(() {
        _rectStartPoint = details.localPosition;
        _rectCurrentPoint = details.localPosition;
        _isDrawingRectangle = true;
        _selectedRectangleIndex = null;
        _selectedLineIndex = null;
        _selectedCircleIndex = null;
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
    if (_isDrawingRectangle && _rectStartPoint != null && _rectCurrentPoint != null) {
      // Complete rectangle creation
      setState(() {
        _rectangles.add(DrawingRectangle(
          topLeft: Offset(
            _rectStartPoint!.dx < _rectCurrentPoint!.dx ? _rectStartPoint!.dx : _rectCurrentPoint!.dx,
            _rectStartPoint!.dy < _rectCurrentPoint!.dy ? _rectStartPoint!.dy : _rectCurrentPoint!.dy,
          ),
          bottomRight: Offset(
            _rectStartPoint!.dx > _rectCurrentPoint!.dx ? _rectStartPoint!.dx : _rectCurrentPoint!.dx,
            _rectStartPoint!.dy > _rectCurrentPoint!.dy ? _rectStartPoint!.dy : _rectCurrentPoint!.dy,
          ),
          timestamp: DateTime.now(),
        ));
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
          _selectedLineIndex = null;
          _selectedRectangleIndex = null;
        });
        return;
      }
    }
    
    // Deselect all if tapping on empty space
    setState(() {
      _selectedCircleIndex = null;
      _selectedLineIndex = null;
      _selectedRectangleIndex = null;
    });
  }

  void _handleCircleDragStart(DragStartDetails details) {
    if (_selectedCircleIndex != null) {
      // Check if dragging from the edge (for resizing) or center (for moving)
      final circle = _circles[_selectedCircleIndex!];
      final distanceFromCenter = (details.localPosition - circle.center).distance;
      const double edgeTolerance = 20.0;
      
      if ((distanceFromCenter - circle.radius).abs() <= edgeTolerance) {
        // Dragging from edge - resize
        setState(() {
          _isDraggingShape = false; // Flag for resizing
        });
      } else {
        // Dragging from center or inside - move
        setState(() {
          _isDraggingShape = true;
          _dragOffset = details.localPosition - circle.center;
        });
      }
    } else {
      // Start drawing new circle
      setState(() {
        _circleCenter = details.localPosition;
        _circleRadius = 0;
        _isDrawingCircle = true;
        _selectedCircleIndex = null;
        _selectedLineIndex = null;
        _selectedRectangleIndex = null;
      });
    }
  }

  void _handleCircleDragUpdate(DragUpdateDetails details) {
    if (_selectedCircleIndex != null) {
      if (_isDraggingShape) {
        // Move circle
        _moveCircle(details.localPosition);
      } else {
        // Resize circle by changing radius
        final circle = _circles[_selectedCircleIndex!];
        final newRadius = (details.localPosition - circle.center).distance;
        setState(() {
          _circles[_selectedCircleIndex!] = DrawingCircle(
            center: circle.center,
            radius: newRadius,
            timestamp: circle.timestamp,
          );
        });
      }
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
        _circles.add(DrawingCircle(
          center: _circleCenter!,
          radius: _circleRadius,
          timestamp: DateTime.now(),
        ));
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
      _rectangles.clear();
      _circles.clear();
      _firstPoint = null;
      _currentEndPoint = null;
      _isDrawingLine = false;
      _isDraggingEndPoint = false;
      _selectedLineIndex = null;
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
        // Always show existing drawings, but only allow interaction when enabled
        Positioned.fill(
          child: CustomPaint(
            painter: DrawingPainter(
              lines: _lines,
              rectangles: _rectangles,
              circles: _circles,
              firstPoint: widget.isEnabled ? _firstPoint : null,
              currentEndPoint: widget.isEnabled ? _currentEndPoint : null,
              isDrawingLine: widget.isEnabled && _isDrawingLine,
              isDraggingEndPoint: widget.isEnabled && _isDraggingEndPoint,
              rectStartPoint: widget.isEnabled ? _rectStartPoint : null,
              rectCurrentPoint: widget.isEnabled ? _rectCurrentPoint : null,
              isDrawingRectangle: widget.isEnabled && _isDrawingRectangle,
              circleCenter: widget.isEnabled ? _circleCenter : null,
              circleRadius: widget.isEnabled ? _circleRadius : 0,
              isDrawingCircle: widget.isEnabled && _isDrawingCircle,
              currentTool: widget.currentTool,
              selectedRectangleIndex: widget.isEnabled ? _selectedRectangleIndex : null,
              selectedCircleIndex: widget.isEnabled ? _selectedCircleIndex : null,
              selectedLineIndex: widget.isEnabled ? _selectedLineIndex : null,
            ),
            child: Container(),
          ),
        ),
        // Only capture gestures when enabled
        if (widget.isEnabled)
          Positioned.fill(
            child: GestureDetector(
              onTapDown: _onTapDown,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(), // Transparent container to capture gestures
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
  final int? selectedLineIndex;

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
    this.selectedLineIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw completed lines
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      paint.color = line.color;
      paint.strokeWidth = line.strokeWidth;
      canvas.drawLine(line.start, line.end, paint);
      
      // Draw endpoints for all lines
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(line.start, 4, paint);
      canvas.drawCircle(line.end, 4, paint);
      paint.style = PaintingStyle.stroke;
      
      // Draw selection indicators for selected line
      if (selectedLineIndex == i) {
        // Draw larger endpoint handles
        paint.style = PaintingStyle.fill;
        paint.color = Colors.white;
        canvas.drawCircle(line.start, 8, paint);
        canvas.drawCircle(line.end, 8, paint);
        paint.style = PaintingStyle.stroke;
        paint.color = line.color;
        canvas.drawCircle(line.start, 8, paint);
        canvas.drawCircle(line.end, 8, paint);
        
        // Draw center point for moving
        final center = Offset(
          (line.start.dx + line.end.dx) / 2,
          (line.start.dy + line.end.dy) / 2,
        );
        paint.style = PaintingStyle.fill;
        paint.color = Colors.white;
        canvas.drawCircle(center, 6, paint);
        paint.style = PaintingStyle.stroke;
        paint.color = line.color;
        canvas.drawCircle(center, 6, paint);
      }
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
      paint.color = Colors.yellow.withValues(alpha: 0.8);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(firstPoint!, 6, paint);
      
      // Draw a pulsing ring around the first point to indicate drawing mode
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.color = Colors.yellow.withValues(alpha: 0.6);
      canvas.drawCircle(firstPoint!, 10, paint);
      
      // If we have a current end point, draw the preview line
      if (currentEndPoint != null) {
        paint.color = Colors.yellow.withValues(alpha: 0.7);
        paint.strokeWidth = 3.0;
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(firstPoint!, currentEndPoint!, paint);
        
        // Draw the end point
        paint.style = PaintingStyle.fill;
        paint.color = Colors.yellow.withValues(alpha: 0.9);
        canvas.drawCircle(currentEndPoint!, 6, paint);
        
        // Draw a visual indicator that this point can be dragged
        if (!isDraggingEndPoint) {
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 2;
          paint.color = Colors.white.withValues(alpha: 0.8);
          canvas.drawCircle(currentEndPoint!, 12, paint);
        }
      }
    }

    // Draw current rectangle being created
    if (isDrawingRectangle && rectStartPoint != null && rectCurrentPoint != null) {
      final rect = Rect.fromPoints(rectStartPoint!, rectCurrentPoint!);
      paint.color = Colors.yellow.withValues(alpha: 0.7);
      paint.strokeWidth = 3.0;
      paint.style = PaintingStyle.stroke;
      canvas.drawRect(rect, paint);
      
      // Draw corner indicators
      paint.style = PaintingStyle.fill;
      paint.color = Colors.yellow.withValues(alpha: 0.9);
      canvas.drawCircle(rectStartPoint!, 4, paint);
      canvas.drawCircle(rectCurrentPoint!, 4, paint);
    }

    // Draw current circle being created
    if (isDrawingCircle && circleCenter != null) {
      paint.color = Colors.yellow.withValues(alpha: 0.7);
      paint.strokeWidth = 3.0;
      paint.style = PaintingStyle.stroke;
      
      if (circleRadius > 0) {
        canvas.drawCircle(circleCenter!, circleRadius, paint);
      }
      
      // Draw center point
      paint.style = PaintingStyle.fill;
      paint.color = Colors.yellow.withValues(alpha: 0.9);
      canvas.drawCircle(circleCenter!, 6, paint);
      
      // Draw radius line while dragging
      if (circleRadius > 0) {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1.0;
        paint.color = Colors.yellow.withValues(alpha: 0.5);
        final radiusEnd = circleCenter! + Offset(circleRadius, 0);
        canvas.drawLine(circleCenter!, radiusEnd, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
