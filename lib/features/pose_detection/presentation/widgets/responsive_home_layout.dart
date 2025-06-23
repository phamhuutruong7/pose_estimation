import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_helper.dart';

class ResponsiveHomeLayout extends StatelessWidget {
  final VoidCallback onStartCamera;

  const ResponsiveHomeLayout({
    super.key,
    required this.onStartCamera,
  });

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
            SizedBox(height: ResponsiveHelper.getSpacing(context)),
            Text(
              'Detect and track human poses in real-time using your device camera.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveHelper.getBodyFontSize(context),
                color: Colors.grey,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context, large: true) * 2),
            _buildStartButton(context),
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
                children: [
                  Text(
                    'Detect and track human poses in real-time using your device camera.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getBodyFontSize(context),
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getSpacing(context, large: true)),
                  _buildStartButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return ElevatedButton(
      onPressed: onStartCamera,
      style: ElevatedButton.styleFrom(
        padding: ResponsiveHelper.getButtonPadding(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_alt),
          SizedBox(width: ResponsiveHelper.getSpacing(context) * 0.5),
          Text(
            'Start Camera',
            style: TextStyle(fontSize: ResponsiveHelper.getBodyFontSize(context)),
          ),
        ],
      ),
    );
  }
}
