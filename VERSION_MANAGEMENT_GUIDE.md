# Version Management and Google Play Store Setup Guide

## Overview
This app now includes automatic version checking and update management that will:
- Check for updates from Google Play Store when the app starts
- Show update dialogs to users when new versions are available
- Force critical updates when necessary
- Allow manual version checking from the app info dialog

## Setup Instructions

### 1. Update App Package Name (Required before publishing)

**Important**: Change the package name from the example package name to your own unique identifier.

1. **Update Android package name** in `android/app/build.gradle.kts`:
   ```kotlin
   applicationId = "com.yourcompany.pose_estimation"  // Change this to your package
   ```

2. **Update version service** in `lib/core/services/version_update_service.dart`:
   ```dart
   static const String _packageName = 'com.yourcompany.pose_estimation';  // Match your Android package
   ```

3. **Update Android namespace** in `android/app/build.gradle.kts`:
   ```kotlin
   namespace = "com.yourcompany.pose_estimation"  // Match your package name
   ```

### 2. Version Management in pubspec.yaml

Update your app version in `pubspec.yaml` before each release:
```yaml
version: 1.0.0+1  # version+build_number
```

- **Version format**: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- **Example progression**:
  - `1.0.0+1` (Initial release)
  - `1.0.1+2` (Bug fix)
  - `1.1.0+3` (New features)
  - `2.0.0+4` (Major changes - triggers force update)

### 3. Google Play Console Setup

1. **Create Google Play Developer Account**
   - Go to https://play.google.com/console
   - Pay one-time $25 registration fee
   - Complete account verification

2. **Create New App**
   - Click "Create app"
   - Choose app name, language, and app/game type
   - Fill in content declarations

3. **App Content and Store Listing**
   - Add app icon, screenshots, and descriptions
   - Set up content rating
   - Add privacy policy URL
   - Complete store listing

### 4. Build and Upload App

1. **Build Release APK/AAB**:
   ```bash
   flutter build appbundle --release
   # or for APK:
   flutter build apk --release
   ```

2. **Upload to Play Console**
   - Go to "Release" > "Production"
   - Upload your `.aab` file (recommended) or `.apk`
   - Add release notes
   - Review and publish

### 5. Force Update Configuration

The app automatically determines force updates based on major version changes:

```dart
// In VersionUpdateService
static bool _isCriticalUpdate(String currentVersion, String storeVersion) {
  // Force update if major version difference is >= 2
  // Example: 1.0.0 -> 3.0.0 = force update
  //          1.0.0 -> 1.5.0 = optional update
}
```

**Customize force update logic**:
- Modify `_isCriticalUpdate()` method
- Add server-side configuration for critical updates
- Implement minimum supported version checks

### 6. How Version Checking Works

**Automatic Checking**:
- Runs when app starts (after 1 second delay)
- Scrapes Google Play Store page for latest version
- Compares with current app version
- Shows appropriate update dialog

**Manual Checking**:
- Users can tap info icon in app bar
- Shows current version and build number
- Includes "Check for Updates" button

**Update Dialog Types**:
- **Optional Update**: User can dismiss and update later
- **Force Update**: Cannot be dismissed, blocks app usage

### 7. Testing Version Updates

**Before Publishing**:
1. Test with mock data by modifying version strings
2. Test force update scenarios
3. Verify Play Store URL opens correctly

**After Publishing**:
1. Install production version
2. Update version in pubspec.yaml
3. Build and upload new version to Play Store
4. Test update flow with production app

### 8. Error Handling

The version service handles various error scenarios:
- Network connection issues
- Play Store page parsing failures
- Invalid version formats
- App store unavailable

**Fallback behavior**:
- Fails silently on errors
- Shows error dialog for manual checks
- Doesn't block app functionality

### 9. Customization Options

**Update Dialog Appearance**:
- Modify `showUpdateDialog()` method
- Change colors, text, and styling
- Add custom branding

**Version Check Frequency**:
- Currently checks on app start only
- Can add periodic checks
- Implement background version monitoring

**Custom Update Sources**:
- Replace Play Store scraping with API
- Use Firebase Remote Config
- Implement custom version endpoint

### 10. Release Checklist

Before each release:
- [ ] Update version in `pubspec.yaml`
- [ ] Test version checking functionality
- [ ] Verify package name is correct
- [ ] Build release version
- [ ] Test on physical device
- [ ] Upload to Play Console
- [ ] Test download and installation
- [ ] Verify update checking works with new version

## Support and Troubleshooting

**Common Issues**:

1. **Version not detected**: 
   - Verify package name matches exactly
   - Check Play Store URL accessibility
   - Ensure app is published and live

2. **Update dialog not showing**:
   - Check network connectivity
   - Verify version format in pubspec.yaml
   - Test with different version numbers

3. **Force update not working**:
   - Review `_isCriticalUpdate()` logic
   - Check version comparison algorithm
   - Verify major version differences

**Debug Information**:
- Check console logs for error messages
- Use Flutter Inspector for UI debugging
- Test on different devices and Android versions

## Security Considerations

- Version checking uses HTTPS requests
- No sensitive data transmitted
- Play Store URLs are verified before opening
- Update prompts cannot be injected externally

## Future Enhancements

Potential improvements:
- Server-side version management
- A/B testing for update prompts
- Staged rollout integration
- Custom update scheduling
- Offline update notifications
