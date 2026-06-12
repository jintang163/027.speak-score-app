import 'package:speak_score_flutter/models/speech_score_result.dart';
import 'package:speak_score_flutter/models/todo_info.dart';
import 'package:speak_score_flutter/services/api_client.dart';

class TodoService {
  final ApiClient _apiClient = ApiClient();

  Future<List<TodoTask>> getMyTodos({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
      'page': page,
      'size': size,
    };
    final response =
        await _apiClient.get('/todos/my', queryParameters: queryParams);
    final data = response.data['data'];
    if (data is Map && data.containsKey('content')) {
      return (data['content'] as List)
          .map((e) => TodoTask.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<List<TodoTask>> getCreatedTodos({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
      'page': page,
      'size': size,
    };
    final response =
        await _apiClient.get('/todos/created', queryParameters: queryParams);
    final data = response.data['data'];
    if (data is Map && data.containsKey('content')) {
      return (data['content'] as List)
          .map((e) => TodoTask.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<TodoTask?> getTodoDetail(int id) async {
    final response = await _apiClient.get('/todos/$id');
    final data = response.data['data'];
    return data != null ? TodoTask.fromJson(data) : null;
  }

  Future<TodoTask?> createTodo(Map<String, dynamic> request) async {
    final response = await _apiClient.post('/todos', data: request);
    final data = response.data['data'];
    return data != null ? TodoTask.fromJson(data) : null;
  }

  Future<TodoTask?> copyTask(int taskId) async {
    final response = await _apiClient.post('/todos/$taskId/copy');
    final data = response.data['data'];
    return data != null ? TodoTask.fromJson(data) : null;
  }

  Future<bool> completeTodoItem(int taskId,
      {String? feedback, double? score, String status = 'COMPLETED'}) async {
    try {
      await _apiClient.post('/todos/$taskId/complete',
          data: {'feedback': feedback, 'score': score, 'status': status});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> urgeTodo(int taskId, {String? message}) async {
    try {
      await _apiClient
          .post('/todos/$taskId/urge', data: {'message': message});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelTodo(int taskId) async {
    try {
      await _apiClient.delete('/todos/$taskId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<TodoTaskProgress?> getTaskProgress(int taskId) async {
    try {
      final response = await _apiClient.get('/todos/$taskId/progress');
      final data = response.data['data'];
      return data != null ? TodoTaskProgress.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<TodoTaskProgress>> getTaskProgressByClass({int? classId}) async {
    try {
      final queryParams = <String, dynamic>{
        if (classId != null) 'classId': classId,
      };
      final response = await _apiClient.get('/todos/class-progress',
          queryParameters: queryParams);
      final data = response.data['data'];
      if (data is List) {
        return data
            .map((e) => TodoTaskProgress.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<SchoolTaskStats?> getSchoolTaskStats(int schoolId) async {
    try {
      final response =
          await _apiClient.get('/todos/school-stats/$schoolId');
      final data = response.data['data'];
      return data != null ? SchoolTaskStats.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<NotifyMessage>> getNotifications({
    String? msgType,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      if (msgType != null) 'msgType': msgType,
    };
    final response = await _apiClient.get('/notifications',
        queryParameters: queryParams);
    final data = response.data['data'];
    if (data is Map && data.containsKey('content')) {
      return (data['content'] as List)
          .map((e) => NotifyMessage.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<Map<String, int>> getUnreadCountByType() async {
    try {
      final response = await _apiClient.get('/notifications/unread-count-by-type');
      final data = response.data['data'];
      if (data is Map) {
        return data.map((key, value) => MapEntry(key as String, (value as num).toInt()));
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/notifications/unread-count');
      return response.data['data'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> markAsRead(int messageId) async {
    try {
      await _apiClient.put('/notifications/$messageId/read');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _apiClient.put('/notifications/read-all');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitCheckin(
      int taskId, String audioFilePath, int durationInSeconds) async {
    try {
      await _apiClient.upload(
        '/todos/$taskId/checkin',
        filePath: audioFilePath,
        fileName: 'recording.aac',
        fieldName: 'audioFile',
        extraFields: {'duration': durationInSeconds},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<SpeechScoreResult?> getScoreDetail(int itemId) async {
    try {
      final res = await _apiClient.get('/todos/item/$itemId/score');
      if (res.data != null) {
        return SpeechScoreResult.fromJson(res.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<TodoItem?> getItemDetail(int itemId) async {
    try {
      final res = await _apiClient.get('/todos/item/$itemId');
      final data = res.data['data'];
      if (data != null) {
        return TodoItem.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> teacherReview(int itemId, double? score, String? feedback,
      {String? audioFilePath}) async {
    try {
      if (audioFilePath != null) {
        await _apiClient.upload(
          '/todos/item/$itemId/review',
          filePath: audioFilePath,
          fileName: 'teacher_review.aac',
          fieldName: 'audioFile',
          extraFields: {
            if (score != null) 'score': score.toString(),
            if (feedback != null) 'feedback': feedback,
          },
        );
      } else {
        final formData = {
          if (score != null) 'score': score.toString(),
          if (feedback != null) 'feedback': feedback,
        };
        await _apiClient.post('/todos/item/$itemId/review', data: formData);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
