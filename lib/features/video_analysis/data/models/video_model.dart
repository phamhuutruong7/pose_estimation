import '../../domain/entities/video_item.dart';

class VideoModel extends VideoItem {
  const VideoModel({
    required super.id,
    required super.name,
    required super.path,
    super.thumbnailPath,
    required super.duration,
    required super.addedDate,
    required super.sizeInBytes,
  });

  factory VideoModel.fromVideoItem(VideoItem videoItem) {
    return VideoModel(
      id: videoItem.id,
      name: videoItem.name,
      path: videoItem.path,
      thumbnailPath: videoItem.thumbnailPath,
      duration: videoItem.duration,
      addedDate: videoItem.addedDate,
      sizeInBytes: videoItem.sizeInBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'thumbnailPath': thumbnailPath,
      'duration': duration.inMilliseconds,
      'addedDate': addedDate.toIso8601String(),
      'sizeInBytes': sizeInBytes,
    };
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      thumbnailPath: json['thumbnailPath'],
      duration: Duration(milliseconds: json['duration']),
      addedDate: DateTime.parse(json['addedDate']),
      sizeInBytes: json['sizeInBytes'],
    );
  }
}
