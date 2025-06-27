import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive_helper.dart';
import '../../../../injection_container.dart' as di;
import '../../../video_analysis/presentation/bloc/video_analysis_bloc.dart';
import '../../../video_analysis/presentation/pages/video_analysis_page.dart';

class ResponsiveHomeLayout extends StatelessWidget {
  const ResponsiveHomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isLandscape(context)) {
      return _buildLandscapeLayout(context);
    }
    return _buildPortraitLayout(context);
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.accessibility_new,
              size: ResponsiveHelper.getIconSize(context),
              color: Colors.blue,
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context, large: true)),
            Text(
              'Pose Estimation App',
              style: TextStyle(
                fontSize: ResponsiveHelper.getTitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context)),            Text(
              'Choose your analysis mode',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveHelper.getBodyFontSize(context),
                color: Colors.grey,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context, large: true) * 2),
            _buildModeButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Row(
          children: [
            // Left side - Icon and title
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.accessibility_new,
                    size: ResponsiveHelper.getIconSize(context),
                    color: Colors.blue,
                  ),
                  SizedBox(height: ResponsiveHelper.getSpacing(context)),
                  Text(
                    'Pose Estimation App',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getTitleFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getSpacing(context, large: true)),
            // Right side - Description and button
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [                  Text(
                    'Choose your analysis mode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getBodyFontSize(context),
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getSpacing(context, large: true)),
                  _buildModeButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildModeButtons(BuildContext context) {
    return Column(
      children: [
        // Video Analyze Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider<VideoAnalysisBloc>(
                    create: (_) => di.sl<VideoAnalysisBloc>(),
                    child: const VideoAnalysisPage(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.video_library),
            label: Text(
              'Video Analyze',
              style: TextStyle(fontSize: ResponsiveHelper.getBodyFontSize(context)),
            ),
            style: ElevatedButton.styleFrom(
              padding: ResponsiveHelper.getButtonPadding(context),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),
        // Real-time Analyze Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to real-time analyze page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Real-time Analyze mode - Coming soon!')),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: Text(
              'Real-time Analyze',
              style: TextStyle(fontSize: ResponsiveHelper.getBodyFontSize(context)),
            ),
            style: ElevatedButton.styleFrom(
              padding: ResponsiveHelper.getButtonPadding(context),
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
