import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import '../../../../core/errors/exceptions.dart' as core_exceptions;
import '../models/pose_model.dart';
import '../../domain/entities/pose.dart' as domain;

abstract class PoseDetectionDataSource {
  Future<List<CameraDescription>> getAvailableCameras();
  Future<PoseModel?> detectPose(CameraImage image);
  Future<void> initializePoseDetection();
  Future<void> disposePoseDetection();
}

class PoseDetectionDataSourceImpl implements PoseDetectionDataSource {
  late PoseDetector _poseDetector;

  @override
  Future<void> initializePoseDetection() async {
    try {      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(),
      );
    } catch (e) {
      throw core_exceptions.PoseDetectionException();
    }
  }

  @override
  Future<void> disposePoseDetection() async {
    try {      await _poseDetector.close();
    } catch (e) {
      throw core_exceptions.PoseDetectionException();
    }
  }
  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    try {      return await availableCameras();
    } catch (e) {
      throw core_exceptions.CameraException();
    }
  }

  @override
  Future<PoseModel?> detectPose(CameraImage image) async {
    try {
      final inputImage = _convertCameraImageToInputImage(image);
      final poses = await _poseDetector.processImage(inputImage);
      
      if (poses.isEmpty) return null;
        final pose = poses.first;
      final landmarks = pose.landmarks.values.map((landmark) {
        return domain.PoseLandmark(
          x: landmark.x,
          y: landmark.y,
          z: landmark.z,
          visibility: landmark.likelihood,
        );
      }).toList();

      return PoseModel(
        landmarks: landmarks,
        timestamp: DateTime.now(),      );
    } catch (e) {
      throw core_exceptions.PoseDetectionException();
    }
  }

  InputImage _convertCameraImageToInputImage(CameraImage cameraImage) {
    // Convert CameraImage to InputImage for ML Kit processing
    final bytes = _concatenatePlanes(cameraImage.planes);
    final imageSize = Size(
      cameraImage.width.toDouble(),
      cameraImage.height.toDouble(),
    );

    final imageRotation = InputImageRotation.rotation0deg;
    final inputImageFormat = InputImageFormat.nv21;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: cameraImage.planes[0].bytesPerRow,
      ),
    );
  }
  Uint8List _concatenatePlanes(List<Plane> planes) {
    final List<int> allBytes = <int>[];
    for (final plane in planes) {
      allBytes.addAll(plane.bytes);
    }
    return Uint8List.fromList(allBytes);
  }
}
