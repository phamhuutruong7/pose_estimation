import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/clear_video_history.dart';
import '../../domain/usecases/get_video_history.dart';
import '../../domain/usecases/import_video.dart';
import '../../domain/usecases/remove_video_from_history.dart';
import '../../domain/usecases/save_video_to_history.dart';
import 'video_analysis_event.dart';
import 'video_analysis_state.dart';

class VideoAnalysisBloc extends Bloc<VideoAnalysisEvent, VideoAnalysisState> {
  final ImportVideo importVideo;
  final GetVideoHistory getVideoHistory;
  final SaveVideoToHistory saveVideoToHistory;
  final RemoveVideoFromHistory removeVideoFromHistory;
  final ClearVideoHistory clearVideoHistory;

  VideoAnalysisBloc({
    required this.importVideo,
    required this.getVideoHistory,
    required this.saveVideoToHistory,
    required this.removeVideoFromHistory,
    required this.clearVideoHistory,
  }) : super(VideoAnalysisInitial()) {
    on<ImportVideosEvent>(_onImportVideos);
    on<LoadVideoHistoryEvent>(_onLoadVideoHistory);
    on<SelectVideoEvent>(_onSelectVideo);
    on<SaveVideoToHistoryEvent>(_onSaveVideoToHistory);
    on<RemoveVideoFromHistoryEvent>(_onRemoveVideoFromHistory);
    on<ClearVideoHistoryEvent>(_onClearVideoHistory);
  }

  Future<void> _onImportVideos(
    ImportVideosEvent event,
    Emitter<VideoAnalysisState> emit,
  ) async {
    emit(VideoAnalysisLoading());

    final result = await importVideo(NoParams());
    
    await result.fold(
      (failure) async {
        if (!emit.isDone) {
          emit(const VideoAnalysisError('Failed to import video'));
        }
      },
      (video) async {
        if (video != null) {
          // Save to history
          await saveVideoToHistory(video);
          
          // Get updated history
          final historyResult = await getVideoHistory(NoParams());
          
          if (!emit.isDone) {
            historyResult.fold(
              (failure) => emit(VideoImportSuccess(
                message: 'Video imported successfully',
                videos: [video],
              )),
              (history) => emit(VideoImportSuccess(
                message: 'Video imported successfully',
                videos: history,
              )),
            );
          }
        } else {
          if (!emit.isDone) {
            emit(const VideoAnalysisError('No video selected'));
          }
        }
      },
    );
  }

  Future<void> _onLoadVideoHistory(
    LoadVideoHistoryEvent event,
    Emitter<VideoAnalysisState> emit,
  ) async {
    emit(VideoAnalysisLoading());

    final result = await getVideoHistory(NoParams());
    
    result.fold(
      (failure) => emit(const VideoAnalysisError('Failed to load video history')),
      (videos) => emit(VideoHistoryLoaded(videos)),
    );
  }

  Future<void> _onSelectVideo(
    SelectVideoEvent event,
    Emitter<VideoAnalysisState> emit,
  ) async {
    final historyResult = await getVideoHistory(NoParams());
    
    historyResult.fold(
      (failure) => emit(VideoSelected(
        selectedVideo: event.video,
        videoHistory: [event.video],
      )),
      (history) => emit(VideoSelected(
        selectedVideo: event.video,
        videoHistory: history,
      )),
    );
  }

  Future<void> _onSaveVideoToHistory(
    SaveVideoToHistoryEvent event,
    Emitter<VideoAnalysisState> emit,
  ) async {
    await saveVideoToHistory(event.video);
    
    final historyResult = await getVideoHistory(NoParams());
    historyResult.fold(
      (failure) => emit(const VideoAnalysisError('Failed to save video')),
      (history) => emit(VideoHistoryLoaded(history)),
    );
  }

  Future<void> _onRemoveVideoFromHistory(
    RemoveVideoFromHistoryEvent event,
    Emitter<VideoAnalysisState> emit,
  ) async {
    final result = await removeVideoFromHistory(event.videoId);
    
    await result.fold(
      (failure) async {
        if (!emit.isDone) {
          emit(const VideoAnalysisError('Failed to remove video'));
        }
      },
      (_) async {
        // Reload history after removal
        final historyResult = await getVideoHistory(NoParams());
        if (!emit.isDone) {
          historyResult.fold(
            (failure) => emit(const VideoAnalysisError('Failed to load updated history')),
            (history) => emit(VideoRemovalSuccess(history)),
          );
        }
      },
    );
  }

  Future<void> _onClearVideoHistory(
    ClearVideoHistoryEvent event,
    Emitter<VideoAnalysisState> emit,
  ) async {
    final result = await clearVideoHistory(NoParams());
    
    result.fold(
      (failure) => emit(const VideoAnalysisError('Failed to clear history')),
      (_) => emit(const VideoHistoryLoaded([])),
    );
  }
}
