import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart';

class AudioService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Timer? _timer;

  Future<void> startRecording(Function(Float32List) onAudioData) async {
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
        
        stream.listen((data) {
          final samples = <double>[];
          for (int i = 0; i < data.length; i += 2) {
            final sample = (data[i] | (data[i+1] << 8)) / 32768.0;
            samples.add(sample);
          }
          onAudioData(Float32List.fromList(samples));
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> stopRecording() async {
    try {
      await _audioRecorder.stop();
      _isRecording = false;
      _timer?.cancel();
    } catch (e) {
      print(e);
    }
  }

  Future<Float32List?> _getAudioData() async {
    // This method is no longer needed with the stream-based approach
    return null;
  }
}