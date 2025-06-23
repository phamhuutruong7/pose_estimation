import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/pose.dart';
import 'pose_painter.dart';

class ResponsiveCameraLayout extends StatelessWidget {
  final CameraController? cameraController;
  final List<Pose> detectedPoses;
  final bool isDetecting;

  const ResponsiveCameraLayout({
    super.key,
    required this.cameraController,
    required this.detectedPoses,
    required this.isDetecting,
  });

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (ResponsiveHelper.isLandscape(context)) {
      return _buildLandscapeLayout(context);
    }
    return _buildPortraitLayout(context);
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      children: [
        // Camera view takes most of the screen
        Expanded(
          flex: 4,
          child: _buildCameraPreview(context),
        ),
        // Bottom section with controls and info
        Expanded(
          flex: 1,
          child: _buildControlsSection(context),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      children: [
        // Camera view takes most of the width
        Expanded(
          flex: 3,
          child: _buildCameraPreview(context),
        ),
        // Side panel with controls and info
        Expanded(
          flex: 1,
          child: _buildControlsSection(context),
        ),
      ],
    );
  }
  Widget _buildCameraPreview(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          AspectRatio(
            aspectRatio: cameraController!.value.aspectRatio,
            child: CameraPreview(cameraController!),
          ),          // Pose overlay
          if (detectedPoses.isNotEmpty)
            ...detectedPoses.map((pose) => CustomPaint(
              painter: PosePainter(
                pose: pose,
                imageSize: Size(
                  cameraController!.value.previewSize!.height,
                  cameraController!.value.previewSize!.width,
                ),
              ),
              child: Container(),
            )),
          // Detection status indicator
          Positioned(
            top: ResponsiveHelper.getSpacing(context),
            right: ResponsiveHelper.getSpacing(context),
            child: _buildDetectionIndicator(context),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: ResponsiveHelper.isLandscape(context)
            ? const Border(left: BorderSide(color: Colors.white24))
            : const Border(top: BorderSide(color: Colors.white24)),
      ),
      child: ResponsiveHelper.isLandscape(context)
          ? _buildLandscapeControls(context)
          : _buildPortraitControls(context),
    );
  }

  Widget _buildPortraitControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPoseCountInfo(context),
        _buildDetectionInfo(context),
        _buildOrientationIcon(context),
      ],
    );
  }

  Widget _buildLandscapeControls(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPoseCountInfo(context),
        const Divider(color: Colors.white24),
        _buildDetectionInfo(context),
        const Divider(color: Colors.white24),
        _buildOrientationIcon(context),
      ],
    );
  }

  Widget _buildPoseCountInfo(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${detectedPoses.length}',
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveHelper.getTitleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Poses',
          style: TextStyle(
            color: Colors.white70,
            fontSize: ResponsiveHelper.getBodyFontSize(context) - 2,
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionInfo(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDetecting ? Icons.visibility : Icons.visibility_off,
          color: isDetecting ? Colors.green : Colors.red,
          size: ResponsiveHelper.getBodyFontSize(context) + 8,
        ),
        Text(
          isDetecting ? 'Active' : 'Paused',
          style: TextStyle(
            color: Colors.white70,
            fontSize: ResponsiveHelper.getBodyFontSize(context) - 2,
          ),
        ),
      ],
    );
  }

  Widget _buildOrientationIcon(BuildContext context) {
    return Icon(
      ResponsiveHelper.isLandscape(context)
          ? Icons.stay_current_landscape
          : Icons.stay_current_portrait,
      color: Colors.white70,
      size: ResponsiveHelper.getBodyFontSize(context) + 8,
    );
  }

  Widget _buildDetectionIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDetecting ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isDetecting ? 'LIVE' : 'PAUSED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
