import '../models/user_info.dart';
import 'api_client.dart';

class OrganizationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<School>> getSchools() async {
    try {
      final response = await _apiClient.get('/org/schools');
      final data = response.data['data'] ?? response.data;
      final list = data is List ? data : <dynamic>[];
      return list
          .map((e) => School.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Grade>> getGradesBySchool(int schoolId) async {
    try {
      final response =
          await _apiClient.get('/org/grades/school/$schoolId');
      final data = response.data['data'] ?? response.data;
      final list = data is List ? data : <dynamic>[];
      return list
          .map((e) => Grade.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ClassInfo>> getClassesByGrade(int gradeId) async {
    try {
      final response =
          await _apiClient.get('/org/classes/grade/$gradeId');
      final data = response.data['data'] ?? response.data;
      final list = data is List ? data : <dynamic>[];
      return list
          .map((e) => ClassInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ClassInfo>> getClassesBySchool(int schoolId) async {
    try {
      final response =
          await _apiClient.get('/org/classes/school/$schoolId');
      final data = response.data['data'] ?? response.data;
      final list = data is List ? data : <dynamic>[];
      return list
          .map((e) => ClassInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<ClassInfo> joinClassByCode(String classCode) async {
    try {
      final response = await _apiClient.post(
        '/org/classes/join',
        data: {'classCode': classCode},
      );
      final data = response.data['data'] ?? response.data;
      return ClassInfo.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserInfo>> getPendingMembers(int classId) async {
    try {
      final response =
          await _apiClient.get('/org/classes/$classId/pending-members');
      final data = response.data['data'] ?? response.data;
      final list = data is List ? data : <dynamic>[];
      return list
          .map((e) => UserInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> approveMember(int memberId) async {
    try {
      await _apiClient.post('/org/classes/members/$memberId/approve');
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> importStudents(int classId, String filePath, String fileName) async {
    try {
      await _apiClient.upload(
        '/org/classes/$classId/import-students',
        filePath: filePath,
        fileName: fileName,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserInfo>> getStudentsByClass(int classId) async {
    try {
      final response =
          await _apiClient.get('/teacher/students/class/$classId');
      final data = response.data['data'] ?? response.data;
      final list = data is List ? data : <dynamic>[];
      return list
          .map((e) => UserInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
