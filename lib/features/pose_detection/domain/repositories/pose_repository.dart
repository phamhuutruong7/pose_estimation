import 'package:dartz/dartz.dart';
import 'package:camera/camera.dart';

import '../../../../core/errors/failures.dart';
import '../entities/pose.dart';

abstract class PoseRepository {
  Future<Either<Failure, List<CameraDescription>>> getAvailableCameras();
  Future<Either<Failure, Pose?>> detectPose(CameraImage image);
  Future<Either<Failure, void>> initializePoseDetection();
  Future<Either<Failure, void>> disposePoseDetection();
}
