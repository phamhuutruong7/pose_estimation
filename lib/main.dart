import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/pose_detection/presentation/bloc/pose_detection_bloc.dart';
import 'features/pose_detection/presentation/pages/home_page.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pose Estimation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => di.sl<PoseDetectionBloc>(),
        child: const HomePage(),
      ),
    );
  }
}
