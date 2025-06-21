import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';

import '../bloc/pose_detection_bloc.dart';
import '../bloc/pose_detection_state.dart';
import '../bloc/pose_detection_event.dart';
import 'pose_painter.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _cameraController;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() {
    final state = context.read<PoseDetectionBloc>().state;
    if (state is CameraInitialized || state is PoseDetectionActive) {
      final cameraState = state as dynamic;
      _cameraController = CameraController(
        cameraState.selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _cameraController!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _startImageStream();
      });
    }
  }

  void _startImageStream() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _cameraController!.startImageStream((CameraImage image) {
        if (!_isDetecting) {
          _isDetecting = true;
          context.read<PoseDetectionBloc>().add(ProcessCameraImageEvent(image));
          // Add a small delay to prevent overwhelming the detector
          Future.delayed(const Duration(milliseconds: 100), () {
            _isDetecting = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        // Camera preview
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize!.height,
              height: _cameraController!.value.previewSize!.width,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
        // Pose overlay
        BlocBuilder<PoseDetectionBloc, PoseDetectionState>(
          builder: (context, state) {
            if (state is PoseDetectionActive && state.currentPose != null) {
              return CustomPaint(
                painter: PosePainter(
                  pose: state.currentPose!,
                  imageSize: _cameraController!.value.previewSize!,
                ),
                child: Container(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        // Status overlay
        Positioned(
          top: 16,
          left: 16,
          child: BlocBuilder<PoseDetectionBloc, PoseDetectionState>(
            builder: (context, state) {
              String status = 'Initializing...';
              Color statusColor = Colors.orange;

              if (state is PoseDetectionActive) {
                if (state.currentPose != null) {
                  status = 'Pose Detected';
                  statusColor = Colors.green;
                } else {
                  status = 'Detecting...';
                  statusColor = Colors.blue;
                }
              } else if (state is CameraInitialized) {
                status = 'Ready';
                statusColor = Colors.grey;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: statusColor,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
