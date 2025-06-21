import 'package:dartz/dartz.dart';
import 'package:camera/camera.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/pose_repository.dart';

class GetAvailableCameras implements UseCase<List<CameraDescription>, NoParams> {
  final PoseRepository repository;

  GetAvailableCameras(this.repository);

  @override
  Future<Either<Failure, List<CameraDescription>>> call(NoParams params) async {
    return await repository.getAvailableCameras();
  }
}
