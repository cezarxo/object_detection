import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:object_detection/Views/camera_view.dart';
import 'package:object_detection/Views/preview_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Object Detection',
      theme: ThemeData(
          useMaterial3: false,
          colorScheme:
              ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent)),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const CameraView()),
        GetPage(name: '/preview', page: () => const PreviewScreen()),
      ],
    );
  }
}
