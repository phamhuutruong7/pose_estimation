import 'package:flutter/material.dart';

import '../../../../core/utils/constants.dart';
import '../widgets/responsive_home_layout.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),      body: const ResponsiveHomeLayout(),
    );
  }
}
