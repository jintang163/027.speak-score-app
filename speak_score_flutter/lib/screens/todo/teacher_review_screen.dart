import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:speak_score_flutter/models/speech_score_result.dart';
import 'package:speak_score_flutter/models/todo_info.dart';
import 'package:speak_score_flutter/services/audio_recorder_service.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

enum TeacherReviewState { idle, recording, recorded, playing, uploading }

class TeacherReviewScreen extends StatefulWidget {
  final int itemId;
  final String? studentAudioUrl;
  final String? referenceText;
  final TodoItem? item;

  const TeacherReviewScreen({
    super.key,
    required this.itemId,
    this.studentAudioUrl,
    this.referenceText,
    this.item,
  });

  @override
  State<TeacherReviewScreen> createState() => _TeacherReviewScreenState();
}

class _TeacherReviewScreenState extends State<TeacherReviewScreen> {
  final TodoService _todoService = TodoService();
  final AudioRecorderService _audioService = AudioRecorderService();
  final AudioPlayer _studentAudioPlayer = AudioPlayer();
  final TextEditingController _feedbackController = TextEditingController();

  SpeechScoreResult? _scoreResult;
  TeacherReviewState _state = TeacherReviewState.idle;
  String? _recordingPath;
  int _recordingDuration = 0;
  double _teacherScore = 80;
  bool _isStudentPlaying = false;
  bool _isLoading = true;
  Timer? _durationTimer;
  StreamSubscription<Amplitude>? _amplitudeSub;
  double _currentAmplitude = 0;

  @override
  void initState() {
    super.initState();
    _loadScoreDetail();
    _requestPermission();
    _studentAudioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isStudentPlaying = false);
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _amplitudeSub?.cancel();
    _feedbackController.dispose();
    _audioService.dispose();
    _studentAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    await _audioService.requestPermission();
  }

  Future<void> _loadScoreDetail() async {
    setState(() => _isLoading = true);
    try {
      final result = await _todoService.getScoreDetail(widget.itemId);
      if (mounted) {
        setState(() {
          _scoreResult = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getScoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _playStudentAudio() async {
    if (widget.studentAudioUrl == null || widget.studentAudioUrl!.isEmpty) return;
    if (_isStudentPlaying) {
      await _studentAudioPlayer.stop();
      setState(() => _isStudentPlaying = false);
    } else {
      setState(() => _isStudentPlaying = true);
      try {
        await _studentAudioPlayer.play(UrlSource(widget.studentAudioUrl!));
      } catch (_) {
        if (mounted) setState(() => _isStudentPlaying = false);
      }
    }
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
      _state = TeacherReviewState.recording;
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
      _state = TeacherReviewState.recorded;
      _recordingPath = path;
    });
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;
    setState(() => _state = TeacherReviewState.playing);
    await _audioService.playRecording(_recordingPath!);
    if (mounted) {
      setState(() => _state = TeacherReviewState.recorded);
    }
  }

  Future<void> _stopPlayback() async {
    await _audioService.stopPlayback();
    setState(() => _state = TeacherReviewState.recorded);
  }

  Future<void> _reRecord() async {
    if (_recordingPath != null) {
      await _audioService.deleteRecording(_recordingPath!);
    }
    setState(() {
      _state = TeacherReviewState.idle;
      _recordingPath = null;
      _recordingDuration = 0;
      _currentAmplitude = 0;
    });
    _startRecording();
  }

  Future<void> _submit() async {
    final feedback = _feedbackController.text.trim();
    setState(() => _state = TeacherReviewState.uploading);
    try {
      final success = await _todoService.teacherReview(
        widget.itemId,
        _teacherScore,
        feedback.isEmpty ? null : feedback,
        audioFilePath: _recordingPath,
      );

      if (!mounted) return;

      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('批改成功'),
            content: const Text('您的批改已提交成功'),
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
        setState(() => _state = TeacherReviewState.recorded);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提交失败，请重试'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _state = TeacherReviewState.recorded);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提交失败，请重试'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作业批改'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildReferenceTextSection(),
                  const SizedBox(height: 16),
                  _buildStudentAudioSection(),
                  const SizedBox(height: 16),
                  _buildAIScoreSection(),
                  const SizedBox(height: 16),
                  _buildScoreInputSection(),
                  const SizedBox(height: 16),
                  _buildFeedbackSection(),
                  const SizedBox(height: 16),
                  _buildRecordingSection(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildReferenceTextSection() {
    if (widget.referenceText == null || widget.referenceText!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.referenceText!,
              style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentAudioSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, size: 20, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  '学生录音',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: FloatingActionButton(
                onPressed:
                    (widget.studentAudioUrl == null || widget.studentAudioUrl!.isEmpty)
                        ? null
                        : _playStudentAudio,
                backgroundColor: Colors.blue,
                child: Icon(_isStudentPlaying ? Icons.stop : Icons.play_arrow),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIScoreSection() {
    final aiScore = _scoreResult?.overallScore;
    if (aiScore == null) return const SizedBox.shrink();
    final color = _getScoreColor(aiScore);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'AI 评分',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                aiScore.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, size: 20, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  '教师评分',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _teacherScore,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: _teacherScore.round().toString(),
                    activeColor: _getScoreColor(_teacherScore),
                    onChanged: (value) {
                      setState(() => _teacherScore = value);
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(_teacherScore),
                    ),
                    controller: TextEditingController(
                        text: _teacherScore.round().toString()),
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null) {
                        setState(() {
                          _teacherScore = parsed.clamp(0.0, 100.0);
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rate_review, size: 20, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  '文字评语',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '请输入文字评语...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.record_voice_over, size: 20, color: Colors.red[700]),
                const SizedBox(width: 8),
                const Text(
                  '语音评语',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_state == TeacherReviewState.recording) ...[
              SizedBox(
                height: 60,
                child: CustomPaint(
                  painter: WaveformPainter(amplitude: _currentAmplitude),
                  size: Size.infinite,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${_formatDuration(_recordingDuration)} / 1:00',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
            if (_state != TeacherReviewState.recording &&
                _state != TeacherReviewState.playing)
              Center(
                child: Text(
                  _recordingPath != null
                      ? '已录制 ${_formatDuration(_recordingDuration)}'
                      : '点击下方按钮录制语音评语',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRecordButton(),
                if (_state == TeacherReviewState.recorded ||
                    _state == TeacherReviewState.playing)
                  _buildPlayButton(),
                if (_state == TeacherReviewState.recorded)
                  _buildReRecordButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    final isRecording = _state == TeacherReviewState.recording;
    return FloatingActionButton(
      heroTag: 'teacher_record',
      onPressed: isRecording ? _stopRecording : _startRecording,
      backgroundColor: isRecording ? Colors.red : Colors.blue,
      child: Icon(isRecording ? Icons.stop : Icons.mic, size: 28),
    );
  }

  Widget _buildPlayButton() {
    final isPlaying = _state == TeacherReviewState.playing;
    return FloatingActionButton(
      heroTag: 'teacher_play',
      onPressed: isPlaying ? _stopPlayback : _playRecording,
      backgroundColor: Colors.orange,
      mini: true,
      child: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
    );
  }

  Widget _buildReRecordButton() {
    return FloatingActionButton(
      heroTag: 'teacher_rerecord',
      onPressed: _reRecord,
      backgroundColor: Colors.grey[600],
      mini: true,
      child: const Icon(Icons.refresh),
    );
  }

  Widget _buildSubmitButton() {
    final isUploading = _state == TeacherReviewState.uploading;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: isUploading ? null : _submit,
        icon: isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send),
        label: Text(isUploading ? '提交中...' : '提交批改'),
        style: FilledButton.styleFrom(backgroundColor: Colors.green),
      ),
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
