
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ranking.dart';
import 'api_service.dart';

class RankingService {
  final ApiService _apiService = ApiService();

  Future<RankingData> getClassRanking({
    required int classId,
    String period = 'total',
    String type = 'student_total',
    int topN = 20,
  }) async {
    final response = await _apiService.get(
      '/rankings/class/$classId',
      queryParameters: {
        'period': period,
        'type': type,
        'topN': topN.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['code'] == 200) {
        return RankingData.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? '获取排行榜失败');
      }
    } else {
      throw Exception('获取排行榜失败');
    }
  }

  Future<RankingData> getSchoolStudentRanking({
    required int schoolId,
    String period = 'total',
    String type = 'student_total',
    int topN = 50,
  }) async {
    final response = await _apiService.get(
      '/rankings/school/$schoolId/students',
      queryParameters: {
        'period': period,
        'type': type,
        'topN': topN.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['code'] == 200) {
        return RankingData.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? '获取排行榜失败');
      }
    } else {
      throw Exception('获取排行榜失败');
    }
  }

  Future<List<ClassRankItem>> getClassAverageRanking({
    required int schoolId,
    String period = 'total',
    int topN = 20,
  }) async {
    final response = await _apiService.get(
      '/rankings/school/$schoolId/classes',
      queryParameters: {
        'period': period,
        'topN': topN.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['code'] == 200) {
        final List<dynamic> list = data['data'];
        return list.map((e) => ClassRankItem.fromJson(e)).toList();
      } else {
        throw Exception(data['message'] ?? '获取班级排行榜失败');
      }
    } else {
      throw Exception('获取班级排行榜失败');
    }
  }

  Future<RankItem> getStudentDetail(int userId) async {
    final response = await _apiService.get('/rankings/student/$userId');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['code'] == 200) {
        return RankItem.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? '获取学生详情失败');
      }
    } else {
      throw Exception('获取学生详情失败');
    }
  }

  Future<void> refreshRankings() async {
    final response = await _apiService.post('/rankings/refresh');
    if (response.statusCode != 200) {
      throw Exception('刷新排行榜失败');
    }
  }
}
