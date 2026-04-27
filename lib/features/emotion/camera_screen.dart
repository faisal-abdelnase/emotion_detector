import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../core/emotion_service.dart';

class CameraScreen extends StatefulWidget {
  final EmotionService service;

  const CameraScreen({super.key, required this.service});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  String _emotion = "Detecting...";
  bool _processing = false;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = "No cameras available";
        });
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      // Start image stream for real-time processing
      await _controller!.startImageStream((CameraImage image) {
        _processCameraImage(image);
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Camera error: $e";
        });
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_processing || !mounted) return;

    _processing = true;

    try {
      // Convert YUV420 to grayscale image
      final Uint8List yPlane = image.planes[0].bytes;
      final int width = image.width;
      final int height = image.height;

      // Create grayscale image from Y plane
      final grayscaleImage = img.Image(width: width, height: height);
      
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int index = y * image.planes[0].bytesPerRow + x;
          final int luminance = yPlane[index];
          grayscaleImage.setPixel(x, y, img.ColorRgb8(luminance, luminance, luminance));
        }
      }

      // Run prediction
      final result = widget.service.predictFromCamera(grayscaleImage);

      if (mounted) {
        setState(() {
          _emotion = result;
        });
      }
    } catch (e) {
      debugPrint("Processing error: $e");
    } finally {
      _processing = false;
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Camera")),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),

          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text("Emotion",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    _emotion,
                    style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}