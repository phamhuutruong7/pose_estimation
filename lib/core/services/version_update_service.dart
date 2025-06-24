import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppVersionInfo {
  final String currentVersion;
  final String storeVersion;
  final bool hasUpdate;
  final bool isCriticalUpdate;

  AppVersionInfo({
    required this.currentVersion,
    required this.storeVersion,
    required this.hasUpdate,
    required this.isCriticalUpdate,
  });
}

class VersionUpdateService {
  static const String _playStoreBaseUrl = 'https://play.google.com/store/apps/details?id=';
    // Replace with your actual package name when publishing
  static const String _packageName = 'com.example.poseestimation.pose_estimation';
  
  /// Check if app update is available from Play Store
  static Future<AppVersionInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // Get store version from Play Store
      final storeVersion = await _getPlayStoreVersion();
      
      if (storeVersion != null) {
        final hasUpdate = _compareVersions(currentVersion, storeVersion) < 0;
        final isCriticalUpdate = hasUpdate && _isCriticalUpdate(currentVersion, storeVersion);
        
        return AppVersionInfo(
          currentVersion: currentVersion,
          storeVersion: storeVersion,
          hasUpdate: hasUpdate,
          isCriticalUpdate: isCriticalUpdate,
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }
  
  /// Get version from Play Store (scraping)
  static Future<String?> _getPlayStoreVersion() async {
    try {
      final url = '$_playStoreBaseUrl$_packageName';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Parse the HTML to extract version
        final body = response.body;
        final versionRegex = RegExp(r'Current Version.*?>([\d\.]+)<');
        final match = versionRegex.firstMatch(body);
        
        if (match != null) {
          return match.group(1);
        }
        
        // Alternative regex patterns
        final altRegex = RegExp(r'"softwareVersion":"([\d\.]+)"');
        final altMatch = altRegex.firstMatch(body);
        if (altMatch != null) {
          return altMatch.group(1);
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting Play Store version: $e');
      return null;
    }
  }
  
  /// Compare version strings (returns -1 if v1 < v2, 0 if equal, 1 if v1 > v2)
  static int _compareVersions(String v1, String v2) {
    final version1Parts = v1.split('.').map(int.parse).toList();
    final version2Parts = v2.split('.').map(int.parse).toList();
    
    final maxLength = [version1Parts.length, version2Parts.length].reduce((a, b) => a > b ? a : b);
    
    // Pad shorter version with zeros
    while (version1Parts.length < maxLength) version1Parts.add(0);
    while (version2Parts.length < maxLength) version2Parts.add(0);
    
    for (int i = 0; i < maxLength; i++) {
      if (version1Parts[i] < version2Parts[i]) return -1;
      if (version1Parts[i] > version2Parts[i]) return 1;
    }
    
    return 0;
  }
  
  /// Check if update is critical (force update)
  static bool _isCriticalUpdate(String currentVersion, String storeVersion) {
    final current = currentVersion.split('.').map(int.parse).toList();
    final store = storeVersion.split('.').map(int.parse).toList();
    
    // Force update if major version difference is >= 2
    if (store.isNotEmpty && current.isNotEmpty) {
      return (store[0] - current[0]) >= 2;
    }
    
    return false;
  }
  
  /// Get current app version
  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('Error getting current version: $e');
      return '1.0.0';
    }
  }
  
  /// Get current build number
  static Future<String> getCurrentBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      debugPrint('Error getting build number: $e');
      return '1';
    }
  }
  
  /// Open Play Store for update
  static Future<void> openPlayStore() async {
    final url = '$_playStoreBaseUrl$_packageName';
    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('Could not launch Play Store URL: $url');
      }
    } catch (e) {
      debugPrint('Error opening Play Store: $e');
    }
  }
  
  /// Show update dialog
  static Future<bool> showUpdateDialog({
    required BuildContext context,
    required AppVersionInfo versionInfo,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: !versionInfo.isCriticalUpdate,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => !versionInfo.isCriticalUpdate,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.system_update,
                  color: versionInfo.isCriticalUpdate ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  versionInfo.isCriticalUpdate ? 'Required Update' : 'Update Available',
                  style: TextStyle(
                    color: versionInfo.isCriticalUpdate ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  versionInfo.isCriticalUpdate
                      ? 'A critical update is required to continue using the app.'
                      : 'A new version of the app is available.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Version: ${versionInfo.currentVersion}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Latest Version: ${versionInfo.storeVersion}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                if (versionInfo.isCriticalUpdate) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This update is mandatory. The app cannot be used without updating.',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (!versionInfo.isCriticalUpdate)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Later'),
                ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  openPlayStore();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: versionInfo.isCriticalUpdate ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(versionInfo.isCriticalUpdate ? 'Update Now' : 'Update'),
              ),
            ],
          ),
        );
      },
    ) ?? false;
  }
  
  /// Initialize version checking when app starts
  static Future<void> initializeVersionCheck(BuildContext context) async {
    try {
      final versionInfo = await checkForUpdate();
      if (versionInfo != null && versionInfo.hasUpdate) {
        // Small delay to ensure the UI is ready
        await Future.delayed(const Duration(seconds: 1));
        
        if (context.mounted) {
          final shouldUpdate = await showUpdateDialog(
            context: context,
            versionInfo: versionInfo,
          );
          
          // If it's a force update and user somehow dismissed, show again
          if (versionInfo.isCriticalUpdate && !shouldUpdate && context.mounted) {
            _showForceUpdateLoop(context, versionInfo);
          }
        }
      }
    } catch (e) {
      debugPrint('Error in version check initialization: $e');
    }
  }
  
  /// Keep showing force update dialog until user updates
  static Future<void> _showForceUpdateLoop(BuildContext context, AppVersionInfo versionInfo) async {
    while (context.mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        final shouldUpdate = await showUpdateDialog(
          context: context,
          versionInfo: versionInfo,
        );
        if (shouldUpdate) break;
      }
    }
  }
  
  /// Manual version check (can be called from settings or menu)
  static Future<void> manualVersionCheck(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final versionInfo = await checkForUpdate();
      
      // Close loading indicator
      if (context.mounted) Navigator.of(context).pop();
      
      if (context.mounted) {
        if (versionInfo != null && versionInfo.hasUpdate) {
          await showUpdateDialog(
            context: context,
            versionInfo: versionInfo,
          );
        } else {
          // Show "up to date" message
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Up to Date'),
                ],
              ),
              content: const Text('You are using the latest version of the app.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close loading indicator
      if (context.mounted) Navigator.of(context).pop();
      
      // Show error message
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: const Text('Unable to check for updates. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
