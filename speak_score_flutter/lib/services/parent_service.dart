import 'package:speak_score_flutter/models/user_info.dart';
import 'package:speak_score_flutter/services/api_client.dart';

class ParentService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ParentStudent>> getMyChildren() async {
    try {
      final response = await _apiClient.get('/parent/children');
      final data = response.data['data'];
      if (data is List) {
        return data
            .map((e) => ParentStudent.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<ParentStudent?> bindChild({
    required String phone,
    String? relation,
    String? studentName,
  }) async {
    try {
      final response = await _apiClient.post('/parent/bind', data: {
        'phone': phone,
        if (relation != null) 'relation': relation,
        if (studentName != null) 'studentName': studentName,
      });
      final data = response.data['data'];
      if (data != null) {
        return ParentStudent.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> unbindChild(int studentId) async {
    try {
      await _apiClient.delete('/parent/unbind/$studentId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setPrimary(int studentId, bool isPrimary) async {
    try {
      await _apiClient.put(
        '/parent/primary/$studentId',
        queryParameters: {'isPrimary': isPrimary},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ParentStudent>> getStudentParents(int studentId) async {
    try {
      final response = await _apiClient.get('/parent/student/$studentId/parents');
      final data = response.data['data'];
      if (data is List) {
        return data
            .map((e) => ParentStudent.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
