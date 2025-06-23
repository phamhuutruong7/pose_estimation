import 'package:flutter/material.dart';

/// Utility class for responsive design based on screen orientation and size
class ResponsiveHelper {
  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get screen width
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get responsive padding based on orientation
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isLandscape(context)) {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);
    }
    return const EdgeInsets.all(16.0);
  }

  /// Get responsive font size for titles
  static double getTitleFontSize(BuildContext context) {
    if (isLandscape(context)) {
      return 24.0;
    }
    return 28.0;
  }

  /// Get responsive font size for body text
  static double getBodyFontSize(BuildContext context) {
    if (isLandscape(context)) {
      return 14.0;
    }
    return 16.0;
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context) {
    if (isLandscape(context)) {
      return 80.0;
    }
    return 100.0;
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, {bool large = false}) {
    final baseSpacing = large ? 24.0 : 16.0;
    if (isLandscape(context)) {
      return baseSpacing * 0.75;
    }
    return baseSpacing;
  }

  /// Check if screen width is considered tablet size
  static bool isTablet(BuildContext context) {
    return getWidth(context) >= 600;
  }

  /// Get appropriate cross axis count for grid layouts
  static int getCrossAxisCount(BuildContext context) {
    if (isTablet(context)) {
      return isLandscape(context) ? 4 : 3;
    }
    return isLandscape(context) ? 2 : 1;
  }

  /// Get appropriate aspect ratio for camera view
  static double getCameraAspectRatio(BuildContext context) {
    if (isLandscape(context)) {
      // In landscape, use a wider aspect ratio
      return 16 / 9;
    }
    // In portrait, use a taller aspect ratio
    return 9 / 16;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get responsive button padding
  static EdgeInsets getButtonPadding(BuildContext context) {
    if (isLandscape(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
    }
    return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);
  }
}
