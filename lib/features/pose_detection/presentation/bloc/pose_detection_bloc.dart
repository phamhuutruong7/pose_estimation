import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/detect_pose.dart';
import '../../domain/usecases/get_available_cameras.dart';
import '../../domain/repositories/pose_repository.dart';
import 'pose_detection_event.dart';
import 'pose_detection_state.dart';

class PoseDetectionBloc extends Bloc<PoseDetectionEvent, PoseDetectionState> {
  final GetAvailableCameras getAvailableCameras;
  final DetectPose detectPose;
  final PoseRepository repository;

  PoseDetectionBloc({
    required this.getAvailableCameras,
    required this.detectPose,
    required this.repository,
  }) : super(PoseDetectionInitial()) {
    on<InitializeCameraEvent>(_onInitializeCamera);
    on<StartPoseDetectionEvent>(_onStartPoseDetection);
    on<ProcessCameraImageEvent>(_onProcessCameraImage);
    on<StopPoseDetectionEvent>(_onStopPoseDetection);
    on<DisposeCameraEvent>(_onDisposeCamera);
  }

  Future<void> _onInitializeCamera(
    InitializeCameraEvent event,
    Emitter<PoseDetectionState> emit,
  ) async {
    emit(PoseDetectionLoading());

    final camerasResult = await getAvailableCameras(NoParams());
    final initResult = await repository.initializePoseDetection();

    camerasResult.fold(
      (failure) => emit(const PoseDetectionError(message: 'Failed to get cameras')),
      (cameras) {
        initResult.fold(
          (failure) => emit(const PoseDetectionError(message: 'Failed to initialize pose detection')),
          (_) {
            if (cameras.isNotEmpty) {
              emit(CameraInitialized(
                cameras: cameras,
                selectedCamera: cameras.first,
              ));
            } else {
              emit(const PoseDetectionError(message: 'No cameras available'));
            }
          },
        );
      },
    );
  }

  Future<void> _onStartPoseDetection(
    StartPoseDetectionEvent event,
    Emitter<PoseDetectionState> emit,
  ) async {
    if (state is CameraInitialized) {
      final currentState = state as CameraInitialized;
      emit(PoseDetectionActive(
        cameras: currentState.cameras,
        selectedCamera: currentState.selectedCamera,
      ));
    }
  }

  Future<void> _onProcessCameraImage(
    ProcessCameraImageEvent event,
    Emitter<PoseDetectionState> emit,
  ) async {
    if (state is PoseDetectionActive) {
      final currentState = state as PoseDetectionActive;
      
      final result = await detectPose(event.image);
      result.fold(
        (failure) {
          // Don't emit error for individual frame failures, just continue
        },
        (pose) {
          emit(currentState.copyWith(currentPose: pose));
        },
      );
    }
  }

  Future<void> _onStopPoseDetection(
    StopPoseDetectionEvent event,
    Emitter<PoseDetectionState> emit,
  ) async {
    if (state is PoseDetectionActive) {
      final currentState = state as PoseDetectionActive;
      emit(CameraInitialized(
        cameras: currentState.cameras,
        selectedCamera: currentState.selectedCamera,
      ));
    }
  }

  Future<void> _onDisposeCamera(
    DisposeCameraEvent event,
    Emitter<PoseDetectionState> emit,
  ) async {
    await repository.disposePoseDetection();
    emit(PoseDetectionInitial());
  }
}
