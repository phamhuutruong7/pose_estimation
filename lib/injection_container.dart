import 'package:get_it/get_it.dart';

import 'features/pose_detection/data/datasources/pose_detection_datasource.dart';
import 'features/pose_detection/data/repositories/pose_repository_impl.dart';
import 'features/pose_detection/domain/repositories/pose_repository.dart';
import 'features/pose_detection/domain/usecases/detect_pose.dart';
import 'features/pose_detection/domain/usecases/get_available_cameras.dart';
import 'features/pose_detection/presentation/bloc/pose_detection_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
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
}
