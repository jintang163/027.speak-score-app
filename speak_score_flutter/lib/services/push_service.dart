import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:getuiflut/getuiflut.dart';
import 'api_client.dart';

class PushService {
  static final PushService _instance = PushService._internal();
  factory PushService() => _instance;

  final Getuiflut _getuiSdk = Getuiflut();
  final ApiClient _apiClient = ApiClient();

  String? _clientId;
  bool _initialized = false;

  String? get clientId => _clientId;
  bool get isInitialized => _initialized;

  PushService._internal();

  Future<void> init() async {
    if (_initialized) return;

    try {
      _getuiSdk.addEventHandler(
        onReceiveClientId: (String clientId) async {
          _clientId = clientId;
          debugPrint('Getui clientId received: $clientId');
          await _registerDeviceToServer(clientId);
        },
        onReceiveMessageData: (Map<String, dynamic> message) async {
          debugPrint('Getui onReceiveMessageData: $message');
        },
        onNotificationMessageArrived: (Map<String, dynamic> message) async {
          debugPrint('Getui onNotificationMessageArrived: $message');
        },
        onNotificationMessageClicked: (Map<String, dynamic> message) async {
          debugPrint('Getui onNotificationMessageClicked: $message');
        },
        onRegisterDeviceToken: (String deviceToken) async {
          debugPrint('Getui deviceToken: $deviceToken');
        },
        onReceiveOnlineState: (bool online) async {
          debugPrint('Getui online state: $online');
        },
        onReceivePayload: (Map<String, dynamic> payload) async {
          debugPrint('Getui payload: $payload');
        },
        onAppLinkPayload: (String payload) async {
          debugPrint('Getui appLink payload: $payload');
        },
      );

      if (Platform.isAndroid) {
        _getuiSdk.initGetuiSdk;
      } else if (Platform.isIOS) {
        _getuiSdk.initGetuiSdk;
      }

      _initialized = true;
      debugPrint('Getui SDK initialized');
    } catch (e) {
      debugPrint('Getui SDK init error: $e');
    }
  }

  Future<void> _registerDeviceToServer(String clientId) async {
    try {
      await _apiClient.post('/user/device/register', data: {
        'deviceType': 'GETUI',
        'deviceToken': clientId,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'bundleId': 'com.speak.score',
      });
      debugPrint('Push device registered to server: $clientId');
    } catch (e) {
      debugPrint('Failed to register push device to server: $e');
    }
  }

  Future<void> reRegisterDevice() async {
    if (_clientId != null) {
      await _registerDeviceToServer(_clientId!);
    }
  }
}
