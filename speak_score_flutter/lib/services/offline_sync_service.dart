import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;

  static const _queueKey = 'pending_checkin_queue';
  final TodoService _todoService = TodoService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  OfflineSyncService._internal();

  void init() {
    if (_initialized) return;
    _initialized = true;

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
      final filePath = item['audioFilePath'] as String;
      final file = File(filePath);
      if (!await file.exists()) {
        continue;
      }

      try {
        final success = await _todoService.submitCheckin(
          item['taskId'] as int,
          filePath,
          item['duration'] as int,
        );
        if (success) {
          try {
            await file.delete();
          } catch (_) {}
        } else {
          failedItems.add(item);
        }
      } catch (_) {
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

  Future<int> getPendingCount() async {
    final items = await getPendingItems();
    return items.length;
  }

  void dispose() {
    _connectivitySub?.cancel();
    _initialized = false;
  }
}
