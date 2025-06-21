import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart' as core_exceptions;
import '../../../../core/errors/failures.dart';
import '../../domain/entities/pose.dart';
import '../../domain/repositories/pose_repository.dart';
import '../datasources/pose_detection_datasource.dart';

class PoseRepositoryImpl implements PoseRepository {
  final PoseDetectionDataSource dataSource;

  PoseRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<CameraDescription>>> getAvailableCameras() async {    try {
      final cameras = await dataSource.getAvailableCameras();
      return Right(cameras);
    } on core_exceptions.CameraException {
      return Left(CameraFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Pose?>> detectPose(CameraImage image) async {    try {
      final pose = await dataSource.detectPose(image);
      return Right(pose);
    } on core_exceptions.PoseDetectionException {
      return Left(PoseDetectionFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> initializePoseDetection() async {    try {
      await dataSource.initializePoseDetection();
      return const Right(null);
    } on core_exceptions.PoseDetectionException {
      return Left(PoseDetectionFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> disposePoseDetection() async {    try {
      await dataSource.disposePoseDetection();
      return const Right(null);
    } on core_exceptions.PoseDetectionException {
      return Left(PoseDetectionFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
