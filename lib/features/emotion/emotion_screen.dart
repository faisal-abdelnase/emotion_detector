import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/emotion_service.dart';
import 'camera_screen.dart';

class EmotionScreen extends StatefulWidget {
  const EmotionScreen({super.key});

  @override
  State<EmotionScreen> createState() => _EmotionScreenState();
}

class _EmotionScreenState extends State<EmotionScreen> {
  final EmotionService service = EmotionService();

  Uint8List? imageBytes;
  String result = "No Emotion";
  bool loading = false;

  @override
  void initState() {
    super.initState();
    service.loadModel();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      loading = true;
    });

    final bytes = await file.readAsBytes();

    await Future.delayed(const Duration(milliseconds: 300));

    final res = service.predict(bytes);

    setState(() {
      imageBytes = bytes;
      result = res;
      loading = false;
    });
  }

  void openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CameraScreen(service: service)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(title: const Text("Emotion Detector")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// IMAGE
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: imageBytes == null
                  ? const Center(child: Text("No Image"))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(imageBytes!, fit: BoxFit.cover),
                    ),
            ),

            const SizedBox(height: 20),

            if (loading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Processing..."),
                ],
              ),

            const SizedBox(height: 20),

            Text(
              result,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: pickImage,
                    child: const Text("Gallery", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: openCamera,
                    child: const Text("Camera", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}