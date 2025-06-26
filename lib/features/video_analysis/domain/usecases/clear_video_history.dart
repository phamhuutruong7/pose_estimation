import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/video_repository.dart';

class ClearVideoHistory implements UseCase<void, NoParams> {
  final VideoRepository repository;

  ClearVideoHistory(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.clearVideoHistory();
  }
}
