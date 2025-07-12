import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';

class FlipbookCaptureScreen extends ConsumerStatefulWidget {
  const FlipbookCaptureScreen({super.key});

  @override
  ConsumerState<FlipbookCaptureScreen> createState() =>
      _FlipbookCaptureScreenState();
}

class _FlipbookCaptureScreenState extends ConsumerState<FlipbookCaptureScreen> {
  CameraController? _cameraController;
  late final photoNotifier = ref.read(photoProvider.notifier);
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
        );
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> capturePhoto() async {
    try {
      final photoFile = await photoNotifier.captureWithGphoto2();
      if (photoFile != null) {
        final imageBytes = await photoFile.readAsBytes();
        await photoNotifier.addPhoto(imageBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo captured successfully!')),
        );
      } else {
        // Fallback to camera controller if gphoto2 fails
        if (_cameraController != null &&
            _cameraController!.value.isInitialized) {
          final image = await _cameraController!.takePicture();
          final imageBytes = await image.readAsBytes();
          await photoNotifier.addPhoto(imageBytes);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo captured with camera!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to capture photo - camera not available.'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flipbook Capture')),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: capturePhoto,
              child: const Text('Capture Photo'),
            ),
          ),
        ],
      ),
    );
  }
}
