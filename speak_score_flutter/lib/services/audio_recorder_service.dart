import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final Record _recorder = Record();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _autoStopTimer;

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  Stream<Amplitude>? get amplitudeStream => _recorder.onAmplitudeChanged();

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission() == false) {
        final granted = await requestPermission();
        if (!granted) return false;
      }

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.start(
        path: path,
        encoder: AudioEncoder.aac,
      );

      _isRecording = true;
      _currentRecordingPath = path;

      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(const Duration(seconds: 60), () {
        if (_isRecording) {
          stopRecording();
        }
      });

      return true;
    } catch (_) {
      _isRecording = false;
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      _autoStopTimer?.cancel();
      _autoStopTimer = null;

      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (_) {
      _isRecording = false;
      return null;
    }
  }

  Future<void> playRecording(String filePath) async {
    if (_isPlaying) return;
    try {
      _isPlaying = true;
      await _player.play(DeviceFileSource(filePath));
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });
    } catch (_) {
      _isPlaying = false;
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (_) {
      _isPlaying = false;
    }
  }

  Future<void> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  void dispose() {
    _autoStopTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    _player.dispose();
  }
}
