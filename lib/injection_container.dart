import 'package:get_it/get_it.dart';

import 'features/pose_detection/data/datasources/pose_detection_datasource.dart';
import 'features/pose_detection/data/repositories/pose_repository_impl.dart';
import 'features/pose_detection/domain/repositories/pose_repository.dart';
import 'features/pose_detection/domain/usecases/detect_pose.dart';
import 'features/pose_detection/domain/usecases/get_available_cameras.dart';
import 'features/pose_detection/presentation/bloc/pose_detection_bloc.dart';

// Video Analysis imports
import 'features/video_analysis/data/datasources/video_datasource.dart';
import 'features/video_analysis/data/repositories/video_repository_impl.dart';
import 'features/video_analysis/domain/repositories/video_repository.dart';
import 'features/video_analysis/domain/usecases/clear_video_history.dart';
import 'features/video_analysis/domain/usecases/get_video_history.dart';
import 'features/video_analysis/domain/usecases/import_video.dart';
import 'features/video_analysis/domain/usecases/remove_video_from_history.dart';
import 'features/video_analysis/domain/usecases/remove_videos_from_history.dart';
import 'features/video_analysis/domain/usecases/save_video_to_history.dart';
import 'features/video_analysis/presentation/bloc/video_analysis_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Pose Detection
  // BLoC
  sl.registerFactory(
    () => PoseDetectionBloc(
      getAvailableCameras: sl(),
      detectPose: sl(),
      repository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAvailableCameras(sl()));
  sl.registerLazySingleton(() => DetectPose(sl()));

  // Repository
  sl.registerLazySingleton<PoseRepository>(
    () => PoseRepositoryImpl(dataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<PoseDetectionDataSource>(
    () => PoseDetectionDataSourceImpl(),
  );

  //! Features - Video Analysis
  // BLoC
  sl.registerFactory(
    () => VideoAnalysisBloc(
      importVideo: sl(),
      getVideoHistory: sl(),
      saveVideoToHistory: sl(),
      removeVideoFromHistory: sl(),
      removeVideosFromHistory: sl(),
      clearVideoHistory: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => ImportVideo(sl()));
  sl.registerLazySingleton(() => GetVideoHistory(sl()));
  sl.registerLazySingleton(() => SaveVideoToHistory(sl()));
  sl.registerLazySingleton(() => RemoveVideoFromHistory(sl()));
  sl.registerLazySingleton(() => RemoveVideosFromHistory(sl()));
  sl.registerLazySingleton(() => ClearVideoHistory(sl()));

  // Repository
  sl.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(dataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<VideoDataSource>(
    () => VideoDataSourceImpl(),
  );
}
