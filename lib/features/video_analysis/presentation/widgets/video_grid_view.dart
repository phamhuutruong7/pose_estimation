import 'package:flutter/material.dart';
import 'dart:io';

import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/video_item.dart';

class VideoGridView extends StatelessWidget {
  final List<VideoItem> videos;
  final Set<String> selectedVideoIds;
  final Function(VideoItem) onVideoTap;
  final Function(VideoItem) onVideoLongPress;
  final Function(String) onSelectionToggle;

  const VideoGridView({
    super.key,
    required this.videos,
    required this.selectedVideoIds,
    required this.onVideoTap,
    required this.onVideoLongPress,
    required this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.isLandscape(context)
        ? (ResponsiveHelper.isTablet(context) ? 4 : 3)
        : 2;

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,          crossAxisSpacing: ResponsiveHelper.getSpacing(context),
          mainAxisSpacing: ResponsiveHelper.getSpacing(context),
          childAspectRatio: 0.9,
        ),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          final isSelected = selectedVideoIds.contains(video.id);
          
          return VideoThumbnailCard(
            video: video,
            isSelected: isSelected,
            onTap: () => onVideoTap(video),
            onLongPress: () => onVideoLongPress(video),
            onSelectionToggle: () => onSelectionToggle(video.id),
            showSelectionMode: selectedVideoIds.isNotEmpty,
          );
        },
      ),
    );
  }
}

class VideoThumbnailCard extends StatelessWidget {
  final VideoItem video;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSelectionToggle;
  final bool showSelectionMode;

  const VideoThumbnailCard({
    super.key,
    required this.video,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectionToggle,
    required this.showSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: _buildThumbnail(),
                  ),
                ),
                // Video name
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    video.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            // Selection checkbox overlay
            if (showSelectionMode)
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: onSelectionToggle,
                  child: Container(
                    width: 24,
                    height: 24,                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.white.withValues(alpha: 0.8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
            // Play icon overlay
            if (!showSelectionMode)
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (video.thumbnailPath != null && File(video.thumbnailPath!).existsSync()) {
      return Image.file(
        File(video.thumbnailPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderThumbnail();
        },
      );
    }
    return _buildPlaceholderThumbnail();
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.video_library,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}
