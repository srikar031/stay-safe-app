import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:stay_safe_app/services/scream_detector.dart';

class AudioService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ScreamDetector _screamDetector = ScreamDetector();
  bool _isRecording = false;
  
  // Callback when a scream is detected
  Function()? onScreamDetected;

  Future<void> init() async {
    await _screamDetector.loadModel();
  }

  Future<void> startMonitoring() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final stream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            bitRate: 128000,
            sampleRate: 44100,
          ),
        );

        _isRecording = true;
        
        stream.listen((data) async {
          // Convert PCM bytes to Float32List for the detector
          final samples = <double>[];
          for (int i = 0; i < data.length; i += 2) {
            final sample = (data[i] | (data[i+1] << 8)) / 32768.0;
            samples.add(sample);
          }
          
          final floatData = Float32List.fromList(samples);
          bool isScream = await _screamDetector.detectScream(floatData);
          
          if (isScream && onScreamDetected != null) {
            onScreamDetected!();
          }
        });
      }
    } catch (e) {
      print("Audio monitoring error: $e");
    }
  }

  Future<void> stopMonitoring() async {
    try {
      await _audioRecorder.stop();
      _isRecording = false;
    } catch (e) {
      print(e);
    }
  }

  void dispose() {
    _audioRecorder.dispose();
    _screamDetector.dispose();
  }
}