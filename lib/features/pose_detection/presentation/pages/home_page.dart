import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/constants.dart';
import '../bloc/pose_detection_bloc.dart';
import '../bloc/pose_detection_event.dart';
import 'camera_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.accessibility_new,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: AppConstants.largePadding),
              const Text(
                'Pose Estimation App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              const Text(
                'Detect and track human poses in real-time using your device camera.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: AppConstants.largePadding * 2),
              ElevatedButton(
                onPressed: () => _startPoseDetection(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt),
                    SizedBox(width: AppConstants.smallPadding),
                    Text(
                      'Start Camera',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startPoseDetection(BuildContext context) {
    context.read<PoseDetectionBloc>().add(InitializeCameraEvent());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CameraPage(),
      ),
    );
  }
}
