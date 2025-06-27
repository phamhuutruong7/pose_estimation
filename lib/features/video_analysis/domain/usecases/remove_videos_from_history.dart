import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/video_repository.dart';

class RemoveVideosFromHistory implements UseCase<void, List<String>> {
  final VideoRepository repository;

  RemoveVideosFromHistory(this.repository);

  @override
  Future<Either<Failure, void>> call(List<String> videoIds) async {
    return await repository.removeVideosFromHistory(videoIds);
  }
}
