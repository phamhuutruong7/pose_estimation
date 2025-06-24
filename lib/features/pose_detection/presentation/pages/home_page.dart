import 'package:flutter/material.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/services/version_update_service.dart';
import '../widgets/responsive_home_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Initialize version checking after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionUpdateService.initializeVersionCheck(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Add version check action button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAppInfo(),
            tooltip: 'App Info',
          ),
        ],
      ),
      body: const ResponsiveHomeLayout(),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: VersionUpdateService.getCurrentVersion(),
              builder: (context, snapshot) {
                return Text('Version: ${snapshot.data ?? 'Loading...'}');
              },
            ),
            FutureBuilder<String>(
              future: VersionUpdateService.getCurrentBuildNumber(),
              builder: (context, snapshot) {
                return Text('Build: ${snapshot.data ?? 'Loading...'}');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                VersionUpdateService.manualVersionCheck(context);
              },
              child: const Text('Check for Updates'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
