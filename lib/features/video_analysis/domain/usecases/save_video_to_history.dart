import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/video_item.dart';
import '../repositories/video_repository.dart';

class SaveVideoToHistory implements UseCase<void, VideoItem> {
  final VideoRepository repository;

  SaveVideoToHistory(this.repository);

  @override
  Future<Either<Failure, void>> call(VideoItem video) async {
    return await repository.saveVideoToHistory(video);
  }
}
