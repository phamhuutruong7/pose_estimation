import '../../domain/entities/pose.dart';

class PoseModel extends Pose {
  const PoseModel({
    required super.landmarks,
    required super.timestamp,
  });

  factory PoseModel.fromPose(Pose pose) {
    return PoseModel(
      landmarks: pose.landmarks,
      timestamp: pose.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'landmarks': landmarks.map((landmark) => {
        'x': landmark.x,
        'y': landmark.y,
        'z': landmark.z,
        'visibility': landmark.visibility,
      }).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PoseModel.fromJson(Map<String, dynamic> json) {
    return PoseModel(
      landmarks: (json['landmarks'] as List)
          .map((landmarkJson) => PoseLandmark(
                x: landmarkJson['x'],
                y: landmarkJson['y'],
                z: landmarkJson['z'],
                visibility: landmarkJson['visibility'],
              ))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
