class SpeechScoreResult {
  final double? overallScore;
  final double? pronunciationScore;
  final double? fluencyScore;
  final double? completenessScore;
  final double? accuracyScore;
  final List<ErrorWord>? errorWords;
  final bool? success;
  final String? errorMessage;

  SpeechScoreResult({
    this.overallScore,
    this.pronunciationScore,
    this.fluencyScore,
    this.completenessScore,
    this.accuracyScore,
    this.errorWords,
    this.success,
    this.errorMessage,
  });

  factory SpeechScoreResult.fromJson(Map<String, dynamic> json) {
    final errorWordsList = json['errorWords'] as List?;
    return SpeechScoreResult(
      overallScore: (json['overallScore'] as num?)?.toDouble(),
      pronunciationScore: (json['pronunciationScore'] as num?)?.toDouble(),
      fluencyScore: (json['fluencyScore'] as num?)?.toDouble(),
      completenessScore: (json['completenessScore'] as num?)?.toDouble(),
      accuracyScore: (json['accuracyScore'] as num?)?.toDouble(),
      errorWords: errorWordsList
          ?.map((e) => ErrorWord.fromJson(e as Map<String, dynamic>))
          .toList(),
      success: json['success'] as bool?,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

class ErrorWord {
  final String? word;
  final double? score;
  final String? errorType;
  final int? startIndex;
  final int? endIndex;

  ErrorWord({
    this.word,
    this.score,
    this.errorType,
    this.startIndex,
    this.endIndex,
  });

  factory ErrorWord.fromJson(Map<String, dynamic> json) => ErrorWord(
        word: json['word'] as String?,
        score: (json['score'] as num?)?.toDouble(),
        errorType: json['errorType'] as String?,
        startIndex: json['startIndex'] as int?,
        endIndex: json['endIndex'] as int?,
      );
}
