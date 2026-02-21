import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

class ScreamDetector {
  late Interpreter _interpreter;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/scream_model.tflite');
      _isModelLoaded = true;
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future<bool> detectScream(Float32List audioData) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    if (!_isModelLoaded) {
      return false;
    }

    // Extract MFCC features (simplified)
    final features = _extractMFCC(audioData);
    
    // Reshape input for the model
    final input = features.reshape([1, features.length]);
    
    // Run inference
    final output = List.filled(2, 0.0).reshape([1, 2]);
    _interpreter.run(input, output);
    
    // Get the probability of scream
    final screamProbability = output[0][1];
    
    // Return true if probability is above threshold
    return screamProbability > 0.7;
  }

  List<double> _extractMFCC(Float32List audioData) {
    // This is a simplified version of MFCC extraction
    // In a real implementation, you would use a proper signal processing library
    
    // For demonstration, we'll just return a subset of the audio data
    const featureSize = 13; // Common MFCC feature size
    final step = (audioData.length / featureSize).floor();
    
    final features = <double>[];
    for (int i = 0; i < featureSize; i++) {
      final index = i * step;
      if (index < audioData.length) {
        features.add(audioData[index]);
      } else {
        features.add(0.0);
      }
    }
    
    return features;
  }

  void dispose() {
    if (_isModelLoaded) {
      _interpreter.close();
    }
  }
}