import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/video_item.dart';

abstract class VideoRepository {
  Future<Either<Failure, VideoItem?>> importVideo();
  Future<Either<Failure, List<VideoItem>>> getVideoHistory();
  Future<Either<Failure, void>> saveVideoToHistory(VideoItem video);
  Future<Either<Failure, void>> removeVideoFromHistory(String videoId);
  Future<Either<Failure, void>> clearVideoHistory();
}
