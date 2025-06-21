import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';

import '../../domain/entities/pose.dart';

abstract class PoseDetectionState extends Equatable {
  const PoseDetectionState();

  @override
  List<Object?> get props => [];
}

class PoseDetectionInitial extends PoseDetectionState {}

class PoseDetectionLoading extends PoseDetectionState {}

class CameraInitialized extends PoseDetectionState {
  final List<CameraDescription> cameras;
  final CameraDescription selectedCamera;

  const CameraInitialized({
    required this.cameras,
    required this.selectedCamera,
  });

  @override
  List<Object> get props => [cameras, selectedCamera];
}

class PoseDetectionActive extends PoseDetectionState {
  final List<CameraDescription> cameras;
  final CameraDescription selectedCamera;
  final Pose? currentPose;

  const PoseDetectionActive({
    required this.cameras,
    required this.selectedCamera,
    this.currentPose,
  });

  @override
  List<Object?> get props => [cameras, selectedCamera, currentPose];

  PoseDetectionActive copyWith({
    List<CameraDescription>? cameras,
    CameraDescription? selectedCamera,
    Pose? currentPose,
  }) {
    return PoseDetectionActive(
      cameras: cameras ?? this.cameras,
      selectedCamera: selectedCamera ?? this.selectedCamera,
      currentPose: currentPose ?? this.currentPose,
    );
  }
}

class PoseDetectionError extends PoseDetectionState {
  final String message;

  const PoseDetectionError({required this.message});

  @override
  List<Object> get props => [message];
}
