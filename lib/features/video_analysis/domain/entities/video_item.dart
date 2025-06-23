import 'package:equatable/equatable.dart';

class VideoItem extends Equatable {
  final String id;
  final String name;
  final String path;
  final String? thumbnailPath;
  final Duration duration;
  final DateTime addedDate;
  final int sizeInBytes;

  const VideoItem({
    required this.id,
    required this.name,
    required this.path,
    this.thumbnailPath,
    required this.duration,
    required this.addedDate,
    required this.sizeInBytes,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        thumbnailPath,
        duration,
        addedDate,
        sizeInBytes,
      ];

  VideoItem copyWith({
    String? id,
    String? name,
    String? path,
    String? thumbnailPath,
    Duration? duration,
    DateTime? addedDate,
    int? sizeInBytes,
  }) {
    return VideoItem(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      duration: duration ?? this.duration,
      addedDate: addedDate ?? this.addedDate,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
    );
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    final kb = sizeInBytes / 1024;
    final mb = kb / 1024;
    final gb = mb / 1024;

    if (gb >= 1) {
      return '${gb.toStringAsFixed(1)} GB';
    } else if (mb >= 1) {
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      return '${kb.toStringAsFixed(1)} KB';
    }
  }
}
