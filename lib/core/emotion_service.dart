import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class EmotionService {
  late Interpreter _interpreter;

  final List<String> labels = [
    "Angry",
    "Disgust",
    "Fear",
    "Happy",
    "Neutral",
    "Sad",
    "Surprise"
  ];

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/ai_models/emotion_model.tflite',
      options: InterpreterOptions()..threads = 4,
    );
  }

  /// 🔹 image from gallery
  String predict(Uint8List bytes) {
    final image = img.decodeImage(bytes)!;

    final resized = img.copyResize(image, width: 48, height: 48);
    final gray = img.grayscale(resized);

    var input = [
      List.generate(
        48,
        (y) => List.generate(
          48,
          (x) {
            final pixel = gray.getPixel(x, y);
            return [img.getLuminance(pixel) / 255.0];
          },
        ),
      )
    ];

    var output = List.generate(1, (_) => List.filled(7, 0.0));

    _interpreter.run(input, output);

    return labels[_maxIndex(output[0])];
  }

  /// 🔹 realtime camera
  String predictFromCamera(img.Image image) {
    final resized = img.copyResize(image, width: 48, height: 48);
    final gray = img.grayscale(resized);

    var input = [
      List.generate(
        48,
        (y) => List.generate(
          48,
          (x) {
            return [img.getLuminance(gray.getPixel(x, y)) / 255.0];
          },
        ),
      )
    ];

    var output = List.generate(1, (_) => List.filled(7, 0.0));

    _interpreter.run(input, output);

    return labels[_maxIndex(output[0])];
  }

  int _maxIndex(List<double> list) {
    int index = 0;
    double max = list[0];

    for (int i = 1; i < list.length; i++) {
      if (list[i] > max) {
        max = list[i];
        index = i;
      }
    }
    return index;
  }
}