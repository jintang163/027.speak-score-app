import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:speak_score_flutter/models/speech_score_result.dart';
import 'package:speak_score_flutter/models/todo_info.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

class ScoreDetailScreen extends StatefulWidget {
  final int itemId;
  final String? audioUrl;
  final String? referenceText;
  final TodoItem? item;

  const ScoreDetailScreen({
    super.key,
    required this.itemId,
    this.audioUrl,
    this.referenceText,
    this.item,
  });

  @override
  State<ScoreDetailScreen> createState() => _ScoreDetailScreenState();
}

class _ScoreDetailScreenState extends State<ScoreDetailScreen> {
  final TodoService _todoService = TodoService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _teacherAudioPlayer = AudioPlayer();

  SpeechScoreResult? _scoreResult;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isTeacherPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadScoreDetail();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
    _teacherAudioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isTeacherPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _teacherAudioPlayer.dispose();
    super.dispose();
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

  Future<void> _playStudentAudio() async {
    if (widget.audioUrl == null || widget.audioUrl!.isEmpty) return;
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      try {
        await _audioPlayer.play(UrlSource(widget.audioUrl!));
      } catch (_) {
        if (mounted) setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _playTeacherAudio() async {
    final teacherAudioUrl = widget.item?.teacherAudioUrl;
    if (teacherAudioUrl == null || teacherAudioUrl.isEmpty) return;
    if (_isTeacherPlaying) {
      await _teacherAudioPlayer.stop();
      setState(() => _isTeacherPlaying = false);
    } else {
      setState(() => _isTeacherPlaying = true);
      try {
        await _teacherAudioPlayer.play(UrlSource(teacherAudioUrl));
      } catch (_) {
        if (mounted) setState(() => _isTeacherPlaying = false);
      }
    }
  }

  List<InlineSpan> _buildReferenceTextSpans() {
    final text = widget.referenceText ?? '';
    final errorWords = _scoreResult?.errorWords ?? [];
    if (errorWords.isEmpty || text.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <InlineSpan>[];
    final sortedErrors = List<ErrorWord>.from(errorWords)
      ..sort((a, b) => (a.startIndex ?? 0).compareTo(b.startIndex ?? 0));

    int currentPos = 0;
    for (final err in sortedErrors) {
      final start = err.startIndex ?? 0;
      final end = err.endIndex ?? start;
      if (start > currentPos) {
        spans.add(TextSpan(text: text.substring(currentPos, start)));
      }
      if (end <= text.length) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text.substring(start, end),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  err.score?.toStringAsFixed(0) ?? '',
                  style: TextStyle(
                    color: _getScoreColor(err.score),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      currentPos = end;
    }
    if (currentPos < text.length) {
      spans.add(TextSpan(text: text.substring(currentPos)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('评分详情'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadScoreDetail,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOverallScoreSection(),
                    const SizedBox(height: 16),
                    _buildSubScoresSection(),
                    const SizedBox(height: 16),
                    _buildReferenceTextSection(),
                    const SizedBox(height: 16),
                    _buildStudentAudioSection(),
                    if (_hasTeacherReview()) ...[
                      const SizedBox(height: 16),
                      _buildTeacherReviewSection(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverallScoreSection() {
    final score = _scoreResult?.overallScore;
    final color = _getScoreColor(score);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '综合评分',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CircularProgressIndicator(
                      value: (score ?? 0) / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        score?.toStringAsFixed(0) ?? '--',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubScoresSection() {
    final scores = [
      ('发音', _scoreResult?.pronunciationScore),
      ('流利度', _scoreResult?.fluencyScore),
      ('完整度', _scoreResult?.completenessScore),
      ('准确度', _scoreResult?.accuracyScore),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: scores.map((s) {
        final label = s.$1;
        final score = s.$2;
        final color = _getScoreColor(score);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(
                      score?.toStringAsFixed(0) ?? '--',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (score ?? 0) / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 15, height: 1.8, color: Colors.grey[800]),
                children: _buildReferenceTextSpans(),
              ),
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
                onPressed: (widget.audioUrl == null || widget.audioUrl!.isEmpty)
                    ? null
                    : _playStudentAudio,
                backgroundColor: Colors.blue,
                child: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasTeacherReview() {
    final item = widget.item;
    if (item == null) return false;
    return item.teacherScore != null ||
        (item.teacherFeedback != null && item.teacherFeedback!.isNotEmpty) ||
        (item.teacherAudioUrl != null && item.teacherAudioUrl!.isNotEmpty);
  }

  Widget _buildTeacherReviewSection() {
    final item = widget.item!;
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
                  '教师评语',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (item.teacherScore != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Text('评分：', style: TextStyle(fontSize: 14)),
                    Text(
                      item.teacherScore!.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(item.teacherScore),
                      ),
                    ),
                  ],
                ),
              ),
            if (item.teacherFeedback != null && item.teacherFeedback!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('评语：',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(item.teacherFeedback!,
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            if (item.teacherAudioUrl != null && item.teacherAudioUrl!.isNotEmpty)
              Row(
                children: [
                  const Text('语音评语：', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _playTeacherAudio,
                    backgroundColor: Colors.purple,
                    child: Icon(_isTeacherPlaying ? Icons.stop : Icons.play_arrow),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
