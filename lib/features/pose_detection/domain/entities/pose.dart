import 'package:equatable/equatable.dart';

class PoseLandmark extends Equatable {
  final double x;
  final double y;
  final double z;
  final double visibility;

  const PoseLandmark({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });

  @override
  List<Object> get props => [x, y, z, visibility];
}

class Pose extends Equatable {
  final List<PoseLandmark> landmarks;
  final DateTime timestamp;

  const Pose({
    required this.landmarks,
    required this.timestamp,
  });

  @override
  List<Object> get props => [landmarks, timestamp];
}
