import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:object_detection/Controller/camera_controller.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ObjectController>(
        init: ObjectController(),
        builder: (controller) {
          if (!controller.isCameraInitialized.value) {
            return const Center(child: Text('Loading Preview'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Camera Preview
                  CameraPreview(controller.cameraController),

                  // Bounding Box
                  if (controller.label.isNotEmpty)
                    Positioned(
                      left: controller.x * screenWidth,
                      top: controller.y * screenHeight,
                      child: Container(
                        height: controller.h * screenHeight,
                        width: controller.w * screenWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: controller.isInPosition.value
                                ? Colors.green
                                : Colors.yellow,
                            width: 2.0,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: controller.isInPosition.value
                                    ? Colors.green.withOpacity(0.7)
                                    : Colors.yellow.withOpacity(0.7),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                controller.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Guidance Message
                  Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      color: Colors.black54,
                      child: Obx(() => Text(
                            controller.guidance.value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
