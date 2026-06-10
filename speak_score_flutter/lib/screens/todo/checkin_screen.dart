import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:speak_score_flutter/services/audio_recorder_service.dart';
import 'package:speak_score_flutter/services/offline_sync_service.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

enum CheckinState { idle, recording, recorded, playing, uploading }

class CheckinScreen extends StatefulWidget {
  final int taskId;
  final String? referenceText;
  final String? materialTitle;

  const CheckinScreen({
    super.key,
    required this.taskId,
    this.referenceText,
    this.materialTitle,
  });

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final AudioRecorderService _audioService = AudioRecorderService();
  final TodoService _todoService = TodoService();

  CheckinState _state = CheckinState.idle;
  String? _recordingPath;
  int _recordingDuration = 0;
  double _uploadProgress = 0;
  Timer? _durationTimer;
  StreamSubscription<Amplitude>? _amplitudeSub;
  double _currentAmplitude = 0;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _amplitudeSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    await _audioService.requestPermission();
  }

  Future<void> _startRecording() async {
    final granted = await _audioService.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('需要麦克风权限才能录音'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final started = await _audioService.startRecording();
    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('录音启动失败'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() {
      _state = CheckinState.recording;
      _recordingDuration = 0;
      _currentAmplitude = 0;
    });

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });
      if (_recordingDuration >= 60) {
        _stopRecording();
      }
    });

    _amplitudeSub = _audioService.amplitudeStream?.listen((amplitude) {
      setState(() {
        _currentAmplitude =
            ((amplitude.current + 60) / 60).clamp(0.0, 1.0);
      });
    });
  }

  Future<void> _stopRecording() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _amplitudeSub?.cancel();
    _amplitudeSub = null;

    final path = await _audioService.stopRecording();
    setState(() {
      _state = CheckinState.recorded;
      _recordingPath = path;
    });
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;
    setState(() => _state = CheckinState.playing);
    await _audioService.playRecording(_recordingPath!);
    if (mounted) {
      setState(() => _state = CheckinState.recorded);
    }
  }

  Future<void> _stopPlayback() async {
    await _audioService.stopPlayback();
    setState(() => _state = CheckinState.recorded);
  }

  Future<void> _reRecord() async {
    if (_recordingPath != null) {
      await _audioService.deleteRecording(_recordingPath!);
    }
    setState(() {
      _state = CheckinState.idle;
      _recordingPath = null;
      _recordingDuration = 0;
      _currentAmplitude = 0;
    });
    _startRecording();
  }

  Future<void> _submit() async {
    if (_recordingPath == null) return;

    setState(() {
      _state = CheckinState.uploading;
      _uploadProgress = 0;
    });

    try {
      final success = await _todoService.submitCheckin(
        widget.taskId,
        _recordingPath!,
        _recordingDuration,
      );

      if (!mounted) return;

      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('提交成功'),
            content: const Text('你的朗读打卡已提交，等待评分中...'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(true);
                },
                child: const Text('好的'),
              ),
            ],
          ),
        );
      } else {
        await _enqueueOffline();
      }
    } catch (_) {
      if (mounted) {
        await _enqueueOffline();
      }
    }
  }

  Future<void> _enqueueOffline() async {
    if (_recordingPath == null) return;
    try {
      await OfflineSyncService().enqueue(
        widget.taskId,
        _recordingPath!,
        _recordingDuration,
      );
      if (mounted) {
        setState(() => _state = CheckinState.recorded);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('网络不佳，已保存到离线队列，有网时自动提交'),
            backgroundColor: Colors.orange[700],
            action: SnackBarAction(
              label: '查看',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = CheckinState.recorded);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('提交失败，请重试'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.materialTitle ?? '朗读打卡'),
      ),
      body: Column(
        children: [
          _buildReferenceTextSection(),
          const Spacer(),
          _buildWaveformSection(),
          const SizedBox(height: 16),
          _buildTimerDisplay(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReferenceTextSection() {
    if (widget.referenceText == null || widget.referenceText!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, size: 20, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  '参考文本',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Text(
                    widget.referenceText!,
                    style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey[800]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformSection() {
    if (_state != CheckinState.recording && _state != CheckinState.playing) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 80,
      child: CustomPaint(
        painter: WaveformPainter(amplitude: _currentAmplitude),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Text(
      '${_formatDuration(_recordingDuration)} / 1:00',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: _state == CheckinState.recording ? Colors.red : Colors.grey[700],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildRecordButton(),
          if (_state == CheckinState.recorded ||
              _state == CheckinState.playing)
            _buildPlayButton(),
          if (_state == CheckinState.recorded) _buildReRecordButton(),
          if (_state == CheckinState.recorded) _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    final isRecording = _state == CheckinState.recording;
    return FloatingActionButton(
      heroTag: 'record',
      onPressed: isRecording ? _stopRecording : _startRecording,
      backgroundColor: isRecording ? Colors.red : Colors.blue,
      child: Icon(isRecording ? Icons.stop : Icons.mic, size: 32),
    );
  }

  Widget _buildPlayButton() {
    final isPlaying = _state == CheckinState.playing;
    return FloatingActionButton(
      heroTag: 'play',
      onPressed: isPlaying ? _stopPlayback : _playRecording,
      backgroundColor: Colors.orange,
      mini: true,
      child: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
    );
  }

  Widget _buildReRecordButton() {
    return FloatingActionButton(
      heroTag: 'rerecord',
      onPressed: _reRecord,
      backgroundColor: Colors.grey[600],
      mini: true,
      child: const Icon(Icons.refresh),
    );
  }

  Widget _buildSubmitButton() {
    return FloatingActionButton(
      heroTag: 'submit',
      onPressed: _state == CheckinState.uploading ? null : _submit,
      backgroundColor: Colors.green,
      mini: true,
      child: _state == CheckinState.uploading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.send),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double amplitude;

  WaveformPainter({required this.amplitude});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final barCount = (size.width / 6).floor();
    final barWidth = 3.0;
    final gap = (size.width - barCount * barWidth) / (barCount + 1);

    for (int i = 0; i < barCount; i++) {
      final x = gap + i * (barWidth + gap);
      final normalizedPos = (i / barCount - 0.5).abs() * 2;
      final barAmplitude = amplitude * (1.0 - normalizedPos * 0.5);
      final barHeight =
          (4 + barAmplitude * (centerY - 4)).clamp(4.0, centerY);

      canvas.drawLine(
        Offset(x, centerY - barHeight),
        Offset(x, centerY + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.amplitude != amplitude;
  }
}
