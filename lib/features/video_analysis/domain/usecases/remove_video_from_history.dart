import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/video_repository.dart';

class RemoveVideoFromHistory implements UseCase<void, String> {
  final VideoRepository repository;

  RemoveVideoFromHistory(this.repository);

  @override
  Future<Either<Failure, void>> call(String videoId) async {
    return await repository.removeVideoFromHistory(videoId);
  }
}
