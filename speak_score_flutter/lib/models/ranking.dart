
class RankItem {
  final int userId;
  final String userName;
  final String? avatar;
  final double score;
  final int rank;
  final int taskCount;
  final double averageScore;
  final List<double>? recentScores;

  RankItem({
    required this.userId,
    required this.userName,
    this.avatar,
    required this.score,
    required this.rank,
    required this.taskCount,
    required this.averageScore,
    this.recentScores,
  });

  factory RankItem.fromJson(Map<String, dynamic> json) {
    return RankItem(
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? '',
      avatar: json['avatar'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      rank: json['rank'] as int? ?? -1,
      taskCount: json['taskCount'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      recentScores: (json['recentScores'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'avatar': avatar,
      'score': score,
      'rank': rank,
      'taskCount': taskCount,
      'averageScore': averageScore,
      'recentScores': recentScores,
    };
  }
}

class RankingData {
  final String rankType;
  final String period;
  final int? totalCount;
  final List<RankItem> rankings;
  final RankItem? myRank;

  RankingData({
    required this.rankType,
    required this.period,
    this.totalCount,
    required this.rankings,
    this.myRank,
  });

  factory RankingData.fromJson(Map<String, dynamic> json) {
    return RankingData(
      rankType: json['rankType'] as String? ?? '',
      period: json['period'] as String? ?? '',
      totalCount: json['totalCount'] as int?,
      rankings: (json['rankings'] as List<dynamic>?)
              ?.map((e) => RankItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      myRank: json['myRank'] != null
          ? RankItem.fromJson(json['myRank'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rankType': rankType,
      'period': period,
      'totalCount': totalCount,
      'rankings': rankings.map((e) => e.toJson()).toList(),
      'myRank': myRank?.toJson(),
    };
  }
}

class ClassRankItem {
  final int classId;
  final String className;
  final String? gradeName;
  final double averageScore;
  final int rank;
  final int studentCount;
  final int? completedTaskCount;

  ClassRankItem({
    required this.classId,
    required this.className,
    this.gradeName,
    required this.averageScore,
    required this.rank,
    required this.studentCount,
    this.completedTaskCount,
  });

  factory ClassRankItem.fromJson(Map<String, dynamic> json) {
    return ClassRankItem(
      classId: json['classId'] as int,
      className: json['className'] as String? ?? '',
      gradeName: json['gradeName'] as String?,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      rank: json['rank'] as int? ?? 0,
      studentCount: json['studentCount'] as int? ?? 0,
      completedTaskCount: json['completedTaskCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'className': className,
      'gradeName': gradeName,
      'averageScore': averageScore,
      'rank': rank,
      'studentCount': studentCount,
      'completedTaskCount': completedTaskCount,
    };
  }
}
