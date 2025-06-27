import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/video_item.dart';
import '../../domain/repositories/video_repository.dart';
import '../datasources/video_datasource.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoDataSource dataSource;

  VideoRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, VideoItem?>> importVideo() async {
    try {
      final video = await dataSource.importVideo();
      return Right(video);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<VideoItem>>> getVideoHistory() async {
    try {
      final videos = await dataSource.getVideoHistory();
      return Right(videos);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> saveVideoToHistory(VideoItem video) async {
    try {
      await dataSource.saveVideoToHistory(video);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> removeVideoFromHistory(String videoId) async {
    try {
      await dataSource.removeVideoFromHistory(videoId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> clearVideoHistory() async {
    try {
      await dataSource.clearVideoHistory();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
