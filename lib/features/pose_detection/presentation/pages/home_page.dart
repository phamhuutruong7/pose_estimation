import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/constants.dart';
import '../bloc/pose_detection_bloc.dart';
import '../bloc/pose_detection_event.dart';
import '../widgets/responsive_home_layout.dart';
import 'camera_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),      body: ResponsiveHomeLayout(
        onStartCamera: () => _startPoseDetection(context),
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
