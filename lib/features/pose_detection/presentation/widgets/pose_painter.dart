import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../../domain/entities/pose.dart';

class PosePainter extends CustomPainter {
  final Pose pose;
  final ui.Size imageSize;

  PosePainter({
    required this.pose,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Scale factors to convert pose coordinates to screen coordinates
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    // Draw pose landmarks as circles
    for (final landmark in pose.landmarks) {
      if (landmark.visibility > 0.5) {
        final x = landmark.x * scaleX;
        final y = landmark.y * scaleY;
        canvas.drawCircle(Offset(x, y), 4, paint);
      }
    }

    // Draw pose connections (simplified skeleton)
    _drawPoseConnections(canvas, size, scaleX, scaleY, linePaint);
  }

  void _drawPoseConnections(Canvas canvas, Size size, double scaleX, double scaleY, Paint paint) {
    // Define pose connections based on human body structure
    final connections = [
      // Head connections
      [0, 1], [1, 2], [2, 3], [3, 7], // Nose to left ear
      [0, 4], [4, 5], [5, 6], [6, 8], // Nose to right ear
      
      // Body connections
      [9, 10], // Mouth corners
      [11, 12], // Shoulders
      [11, 13], [13, 15], // Left arm
      [12, 14], [14, 16], // Right arm
      [11, 23], [12, 24], // Shoulders to hips
      [23, 24], // Hip connection
      [23, 25], [25, 27], [27, 29], [29, 31], // Left leg
      [24, 26], [26, 28], [28, 30], [30, 32], // Right leg
    ];

    for (final connection in connections) {
      if (connection[0] < pose.landmarks.length && 
          connection[1] < pose.landmarks.length) {
        final landmark1 = pose.landmarks[connection[0]];
        final landmark2 = pose.landmarks[connection[1]];

        if (landmark1.visibility > 0.5 && landmark2.visibility > 0.5) {
          final x1 = landmark1.x * scaleX;
          final y1 = landmark1.y * scaleY;
          final x2 = landmark2.x * scaleX;
          final y2 = landmark2.y * scaleY;

          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is PosePainter && oldDelegate.pose != pose;
  }
}
