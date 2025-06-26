import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/video_item.dart';
import '../repositories/video_repository.dart';

class GetVideoHistory implements UseCase<List<VideoItem>, NoParams> {
  final VideoRepository repository;

  GetVideoHistory(this.repository);

  @override
  Future<Either<Failure, List<VideoItem>>> call(NoParams params) async {
    return await repository.getVideoHistory();
  }
}
