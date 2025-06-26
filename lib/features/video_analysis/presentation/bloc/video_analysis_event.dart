import 'package:equatable/equatable.dart';

import '../../domain/entities/video_item.dart';

abstract class VideoAnalysisEvent extends Equatable {
  const VideoAnalysisEvent();

  @override
  List<Object?> get props => [];
}

class ImportVideosEvent extends VideoAnalysisEvent {}

class LoadVideoHistoryEvent extends VideoAnalysisEvent {}

class SelectVideoEvent extends VideoAnalysisEvent {
  final VideoItem video;

  const SelectVideoEvent(this.video);

  @override
  List<Object> get props => [video];
}

class RemoveVideoFromHistoryEvent extends VideoAnalysisEvent {
  final String videoId;

  const RemoveVideoFromHistoryEvent(this.videoId);

  @override
  List<Object> get props => [videoId];
}

class ClearVideoHistoryEvent extends VideoAnalysisEvent {}

class SaveVideoToHistoryEvent extends VideoAnalysisEvent {
  final VideoItem video;

  const SaveVideoToHistoryEvent(this.video);

  @override
  List<Object> get props => [video];
}
