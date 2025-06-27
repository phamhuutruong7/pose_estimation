import 'package:equatable/equatable.dart';

import '../../domain/entities/video_item.dart';

abstract class VideoAnalysisState extends Equatable {
  const VideoAnalysisState();

  @override
  List<Object?> get props => [];
}

class VideoAnalysisInitial extends VideoAnalysisState {}

class VideoAnalysisLoading extends VideoAnalysisState {}

class VideoAnalysisError extends VideoAnalysisState {
  final String message;

  const VideoAnalysisError(this.message);

  @override
  List<Object> get props => [message];
}

class VideoHistoryLoaded extends VideoAnalysisState {
  final List<VideoItem> videos;

  const VideoHistoryLoaded(this.videos);

  @override
  List<Object> get props => [videos];
}

class VideoSelected extends VideoAnalysisState {
  final VideoItem selectedVideo;
  final List<VideoItem> videoHistory;

  const VideoSelected({
    required this.selectedVideo,
    required this.videoHistory,
  });

  @override
  List<Object> get props => [selectedVideo, videoHistory];
}

class VideoImportSuccess extends VideoAnalysisState {
  final String message;
  final List<VideoItem> videos;

  const VideoImportSuccess({
    required this.message,
    required this.videos,
  });

  @override
  List<Object> get props => [message, videos];
}

class VideoRemovalSuccess extends VideoAnalysisState {
  final List<VideoItem> videos;

  const VideoRemovalSuccess(this.videos);

  @override
  List<Object> get props => [videos];
}
