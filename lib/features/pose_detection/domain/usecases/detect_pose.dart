import 'package:dartz/dartz.dart';
import 'package:camera/camera.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/pose.dart';
import '../repositories/pose_repository.dart';

class DetectPose implements UseCase<Pose?, CameraImage> {
  final PoseRepository repository;

  DetectPose(this.repository);

  @override
  Future<Either<Failure, Pose?>> call(CameraImage image) async {
    return await repository.detectPose(image);
  }
}
