import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';

import '../bloc/pose_detection_bloc.dart';
import '../bloc/pose_detection_state.dart';
import '../bloc/pose_detection_event.dart';
import '../../domain/entities/pose.dart';
import 'responsive_camera_layout.dart';

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
          // Reset detecting flag after a short delay
          Future.delayed(const Duration(milliseconds: 100), () {
            _isDetecting = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoseDetectionBloc, PoseDetectionState>(      builder: (context, state) {
        List<Pose> detectedPoses = [];
        
        if (state is PoseDetectionActive && state.currentPose != null) {
          detectedPoses = [state.currentPose!];
        }

        return ResponsiveCameraLayout(
          cameraController: _cameraController,
          detectedPoses: detectedPoses,
          isDetecting: _isDetecting && state is PoseDetectionActive,
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
