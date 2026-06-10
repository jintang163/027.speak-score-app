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
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get('/notifications',
        queryParameters: {'page': page, 'size': size});
    final data = response.data['data'];
    if (data is Map && data.containsKey('content')) {
      return (data['content'] as List)
          .map((e) => NotifyMessage.fromJson(e))
          .toList();
    }
    return [];
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
}
