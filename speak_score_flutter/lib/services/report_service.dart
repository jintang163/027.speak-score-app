import 'package:speak_score_flutter/models/report_info.dart';
import 'package:speak_score_flutter/services/api_client.dart';

class ReportService {
  final ApiClient _apiClient = ApiClient();

  Future<StudentCalendar?> getStudentCalendar({
    int? studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (studentId != null) 'studentId': studentId,
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
      };
      final response = await _apiClient.get('/reports/student/calendar',
          queryParameters: queryParams);
      final data = response.data['data'];
      return data != null ? StudentCalendar.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  Future<StudentProgressSeries?> getStudentProgress({
    int? studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (studentId != null) 'studentId': studentId,
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
      };
      final response = await _apiClient.get('/reports/student/progress',
          queryParameters: queryParams);
      final data = response.data['data'];
      return data != null ? StudentProgressSeries.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  Future<ClassReport?> getClassReport({
    required int classId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
      };
      final response = await _apiClient.get('/reports/class/$classId/overview',
          queryParameters: queryParams);
      final data = response.data['data'];
      return data != null ? ClassReport.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<ClassComparison>> getClassComparison({
    required int schoolId,
    int? gradeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (gradeId != null) 'gradeId': gradeId,
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
      };
      final response = await _apiClient.get(
          '/reports/school/$schoolId/class-comparison',
          queryParameters: queryParams);
      final data = response.data['data'];
      if (data is List) {
        return data
            .map((e) => ClassComparison.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<String?> exportClassReport({
    required int classId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
      };
      final response = await _apiClient.download(
        '/reports/class/$classId/export',
        queryParameters: queryParams,
      );
      return response;
    } catch (_) {
      return null;
    }
  }

  Future<bool> sendReportByEmail({
    required int classId,
    required String email,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'email': email,
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
      };
      await _apiClient.post('/reports/class/$classId/send-email',
          queryParameters: queryParams);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
