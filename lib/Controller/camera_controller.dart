import 'dart:developer';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ObjectController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFlite();
  }

  @override
  void dispose() {
    stopCamera();
    Tflite.close();
    super.dispose();
  }

  late CameraController cameraController;
  late List<CameraDescription> camera;

  var isCameraInitialized = false.obs;
  var cameraCount = 0;
  var isCapturing = false.obs;

  // Current values
  var x = 0.0;
  var y = 0.0;
  var w = 0.0;
  var h = 0.0;
  var label = '';
  var prevX = 0.0;
  var prevY = 0.0;
  var prevW = 0.0;
  var prevH = 0.0;
  final smoothingFactor = 0.3;

  // Guidance and state variables
  var guidance = ''.obs;
  var isInPosition = false.obs;
  var stableFrameCount = 0;
  var capturedImage = Rx<Uint8List?>(null);

  // Constants for position checking
  final positionTolerance = 0.2;
  final requiredStableFrames = 8;
  final minConfidence = 0.45;

// close camera
  Future<void> stopCamera() async {
    if (cameraController.value.isInitialized) {
      await cameraController.stopImageStream();
      await cameraController.dispose();
    }
  }

//retake
  Future<void> resumeCamera() async {
    if (!isCapturing.value) {
      await initCamera();
    }
  }

  double smooth(double current, double previous) {
    return previous + smoothingFactor * (current - previous);
  }

// Guidance function
  void updateGuidance() {
    if (isCapturing.value) return;

    final objectCenterX = x + w / 2;
    final objectCenterY = y + h / 2;

    if (objectCenterX < 0.3) {
      guidance.value = "Move object right";
      isInPosition.value = false;
      stableFrameCount = 0;
      return;
    }
    if (objectCenterX > 0.7) {
      guidance.value = "Move object left";
      isInPosition.value = false;
      stableFrameCount = 0;
      return;
    }

    if (objectCenterY < 0.3) {
      guidance.value = "Move object down";
      isInPosition.value = false;
      stableFrameCount = 0;
      return;
    }
    if (objectCenterY > 0.7) {
      guidance.value = "Move object up";
      isInPosition.value = false;
      stableFrameCount = 0;
      return;
    }

    final objectArea = w * h;
    if (objectArea < 0.1) {
      guidance.value = "Move closer to object";
      isInPosition.value = false;
      stableFrameCount = 0;
      return;
    }
    if (objectArea > 0.9) {
      guidance.value = "Move away from object";
      isInPosition.value = false;
      stableFrameCount = 0;
      return;
    }

    guidance.value = "Hold steady...";
    isInPosition.value = true;
    stableFrameCount++;

    if (stableFrameCount >= requiredStableFrames) {
      guidance.value = "Perfect!";
      captureImage();
    }
  }

//capture image after recognition
  Future<void> captureImage() async {
    if (isCapturing.value) return;

    try {
      isCapturing.value = true;
      await cameraController.stopImageStream();

      final image = await cameraController.takePicture();
      final bytes = await image.readAsBytes();
      capturedImage.value = bytes;

      // Navigate to preview screen
      await Get.toNamed('/preview');

      // Reset capture state
      isCapturing.value = false;
      stableFrameCount = 0;

      // Resume camera after returning from preview
      await resumeCamera();
    } catch (e) {
      guidance.value = "Failed to capture. Try again.";
      stableFrameCount = 0;
      isCapturing.value = false;
      await resumeCamera();
    }
  }

//start the camera
  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      camera = await availableCameras();
      cameraController = CameraController(
        camera[0],
        ResolutionPreset.max,
        enableAudio: false,
      );
      try {
        await cameraController.initialize();
        await cameraController.startImageStream((image) {
          if (isCapturing.value) return;

          cameraCount++;
          if (cameraCount % 10 == 0) {
            cameraCount = 0;
            objectDetector(image);
          }
        });
        isCameraInitialized(true);
        update();
      } catch (e) {
        log("$e");
      }
    } else {}
  }

//initialize tensor flow model
  initTFlite() async {
    try {
      await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
        isAsset: true,
        numThreads: 1,
        useGpuDelegate: false,
      );
    } catch (e) {
      log("$e");
    }
  }

//Object detection
  objectDetector(CameraImage image) async {
    if (isCapturing.value) return;

    try {
      final List<dynamic>? recognitions = await Tflite.detectObjectOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5,
        imageStd: 127.5,
        threshold: 0.4,
        numResultsPerClass: 1,
      );

      if (recognitions == null || recognitions.isEmpty) {
        resetValues();
        return;
      }

      final detection = recognitions.first;
      final num? confidence = detection['confidenceInClass'] as num?;

      if (confidence == null || confidence < minConfidence) {
        resetValues();
        return;
      }

      final rect = detection['rect'];
      final newX = (rect['x'] as num).toDouble();
      final newY = (rect['y'] as num).toDouble();
      final newW = (rect['w'] as num).toDouble();
      final newH = (rect['h'] as num).toDouble();

      x = smooth(newX, prevX);
      y = smooth(newY, prevY);
      w = smooth(newW, prevW);
      h = smooth(newH, prevH);

      prevX = x;
      prevY = y;
      prevW = w;
      prevH = h;

      label = detection['detectedClass']?.toString() ?? '';
      updateGuidance();
      update();
    } catch (e) {
      resetValues();
    }
  }

  void resetValues() {
    if (!isCapturing.value) {
      label = '';
      x = 0.0;
      y = 0.0;
      w = 0.0;
      h = 0.0;
      prevX = 0.0;
      prevY = 0.0;
      prevW = 0.0;
      prevH = 0.0;
      guidance.value = "No object detected";
      isInPosition.value = false;
      stableFrameCount = 0;
      update();
    }
  }
}
