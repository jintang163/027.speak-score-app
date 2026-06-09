import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/material_info.dart';

class MaterialService {
  final ApiClient _apiClient = ApiClient();

  Future<List<MaterialInfo>> searchMaterials({
    String? keyword,
    String? materialType,
    int? tagId,
    int? schoolId,
    int? classId,
    int? gradeLevel,
    String? scope,
    String? reviewStatus,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      if (keyword != null) 'keyword': keyword,
      if (materialType != null) 'materialType': materialType,
      if (tagId != null) 'tagId': tagId,
      if (schoolId != null) 'schoolId': schoolId,
      if (classId != null) 'classId': classId,
      if (gradeLevel != null) 'gradeLevel': gradeLevel,
      if (scope != null) 'scope': scope,
      if (reviewStatus != null) 'reviewStatus': reviewStatus,
      'page': page,
      'size': size,
    };

    final response = await _apiClient.get('/materials/search', queryParameters: queryParams);
    final data = response.data['data'];
    if (data is Map && data.containsKey('content')) {
      return (data['content'] as List).map((e) => MaterialInfo.fromJson(e)).toList();
    } else if (data is List) {
      return data.map((e) => MaterialInfo.fromJson(e)).toList();
    }
    return [];
  }

  Future<MaterialInfo?> getMaterialDetail(int id) async {
    final response = await _apiClient.get('/materials/$id');
    final data = response.data['data'];
    if (data != null) {
      return MaterialInfo.fromJson(data);
    }
    return null;
  }

  Future<MaterialInfo?> uploadMaterial({
    required String filePath,
    required String fileName,
    required String title,
    required String materialType,
    String? description,
    List<int>? tagIds,
    String scope = 'SCHOOL',
    int? schoolId,
    int? classId,
    int? gradeLevel,
    ProgressCallback? onSendProgress,
  }) async {
    final requestJson = {
      'title': title,
      'materialType': materialType,
      'description': description,
      'scope': scope,
      'schoolId': schoolId,
      'classId': classId,
      'gradeLevel': gradeLevel,
      'tagIds': tagIds,
    };

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'request': MultipartFile.fromString(
        requestJson.toString(),
        filename: 'request.json',
      ),
    });

    final response = await _apiClient.dio.post(
      '/materials/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onSendProgress,
    );

    final data = response.data['data'];
    return data != null ? MaterialInfo.fromJson(data) : null;
  }

  Future<bool> deleteMaterial(int id) async {
    try {
      await _apiClient.delete('/materials/$id');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reviewMaterial(int id, String action, {String? comment}) async {
    try {
      await _apiClient.post('/materials/$id/review', data: {
        'action': action,
        'comment': comment,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<MaterialTag>> getAllTags() async {
    final response = await _apiClient.get('/materials/tags');
    final data = response.data['data'];
    if (data is List) {
      return data.map((e) => MaterialTag.fromJson(e)).toList();
    }
    return [];
  }

  Future<MaterialTag?> createTag(String tagName) async {
    try {
      final response = await _apiClient.post('/materials/tags', data: {'tagName': tagName});
      final data = response.data['data'];
      return data != null ? MaterialTag.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<MaterialInfo>> getPendingReviewMaterials(int schoolId, {int page = 0, int size = 20}) async {
    final response = await _apiClient.get('/materials/pending-review', queryParameters: {
      'schoolId': schoolId,
      'page': page,
      'size': size,
    });
    final data = response.data['data'];
    if (data is Map && data.containsKey('content')) {
      return (data['content'] as List).map((e) => MaterialInfo.fromJson(e)).toList();
    }
    return [];
  }

  Future<String?> getVideoPlayUrl(int id) async {
    try {
      final response = await _apiClient.get('/materials/$id/play-url');
      return response.data['data'] as String?;
    } catch (_) {
      return null;
    }
  }
}
