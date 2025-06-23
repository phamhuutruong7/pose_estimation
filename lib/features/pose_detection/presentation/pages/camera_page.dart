import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pose_detection_bloc.dart';
import '../bloc/pose_detection_state.dart';
import '../bloc/pose_detection_event.dart';
import '../widgets/camera_view.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  @override
  void initState() {
    super.initState();
    // Hide status bar for better camera experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pose Detection'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<PoseDetectionBloc, PoseDetectionState>(
            builder: (context, state) {
              if (state is PoseDetectionActive) {
                return IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () {
                    context.read<PoseDetectionBloc>().add(StopPoseDetectionEvent());
                  },
                );
              } else if (state is CameraInitialized) {
                return IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    context.read<PoseDetectionBloc>().add(StartPoseDetectionEvent());
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<PoseDetectionBloc, PoseDetectionState>(
        builder: (context, state) {
          if (state is PoseDetectionLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing camera...'),
                ],
              ),
            );
          } else if (state is PoseDetectionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PoseDetectionBloc>().add(InitializeCameraEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );          } else if (state is CameraInitialized || state is PoseDetectionActive) {
            return const CameraView();
          }
          
          return const Center(
            child: Text('Initializing...'),
          );
        },
      ),
    );
  }
  @override
  void dispose() {
    // Restore system UI when leaving camera
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    context.read<PoseDetectionBloc>().add(DisposeCameraEvent());
    super.dispose();
  }
}
