import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/video_item.dart';
import '../repositories/video_repository.dart';

class ImportVideo implements UseCase<VideoItem?, NoParams> {
  final VideoRepository repository;

  ImportVideo(this.repository);

  @override
  Future<Either<Failure, VideoItem?>> call(NoParams params) async {
    return await repository.importVideo();
  }
}
