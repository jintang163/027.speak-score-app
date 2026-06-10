import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

class OfflineSyncService {
  static const _queueKey = 'pending_checkin_queue';
  final TodoService _todoService = TodoService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  void init() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) {
      final hasConnection =
          results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        syncPendingItems();
      }
    });
  }

  Future<void> enqueue(int taskId, String audioFilePath, int duration) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey);
    final queue = queueJson != null
        ? List<Map<String, dynamic>>.from(
            jsonDecode(queueJson) as List,
          )
        : <Map<String, dynamic>>[];

    queue.add({
      'taskId': taskId,
      'audioFilePath': audioFilePath,
      'duration': duration,
      'queuedAt': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  Future<void> syncPendingItems() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey);
    if (queueJson == null) return;

    final queue = List<Map<String, dynamic>>.from(
      jsonDecode(queueJson) as List,
    );
    if (queue.isEmpty) return;

    final failedItems = <Map<String, dynamic>>[];

    for (final item in queue) {
      final success = await _todoService.submitCheckin(
        item['taskId'] as int,
        item['audioFilePath'] as String,
        item['duration'] as int,
      );
      if (!success) {
        failedItems.add(item);
      }
    }

    await prefs.setString(_queueKey, jsonEncode(failedItems));
  }

  Future<List<Map<String, dynamic>>> getPendingItems() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey);
    if (queueJson == null) return [];
    return List<Map<String, dynamic>>.from(
      jsonDecode(queueJson) as List,
    );
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
