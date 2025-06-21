import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';

abstract class PoseDetectionEvent extends Equatable {
  const PoseDetectionEvent();

  @override
  List<Object> get props => [];
}

class InitializeCameraEvent extends PoseDetectionEvent {}

class StartPoseDetectionEvent extends PoseDetectionEvent {}

class StopPoseDetectionEvent extends PoseDetectionEvent {}

class ProcessCameraImageEvent extends PoseDetectionEvent {
  final CameraImage image;

  const ProcessCameraImageEvent(this.image);

  @override
  List<Object> get props => [image];
}

class DisposeCameraEvent extends PoseDetectionEvent {}
