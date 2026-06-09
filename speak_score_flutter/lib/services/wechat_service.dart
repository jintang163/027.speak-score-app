import 'dart:async';
import 'package:fluwx/fluwx.dart';
import 'package:flutter/foundation.dart';

class WechatService {
  static const String _appId = 'YOUR_WECHAT_APP_ID';
  static const String _universalLink = 'YOUR_UNIVERSAL_LINK';
  static const String _scope = 'snsapi_userinfo';
  static const String _state = 'speak_score_auth';

  static final WechatService _instance = WechatService._internal();
  factory WechatService() => _instance;
  WechatService._internal();

  final StreamController<String> _authCodeController =
      StreamController<String>.broadcast();
  Stream<String> get authCodeStream => _authCodeController.stream;

  bool _initialized = false;

  Future<bool> registerWxApi() async {
    if (_initialized) return true;

    try {
      final result = await registerWxApi(
        appId: _appId,
        universalLink: _universalLink,
      );
      _initialized = result;
      return result;
    } catch (e) {
      debugPrint('registerWxApi error: $e');
      return false;
    }
  }

  Future<bool> isWeChatInstalled() async {
    try {
      return await isWeChatInstalled;
    } catch (e) {
      debugPrint('isWeChatInstalled error: $e');
      return false;
    }
  }

  Future<bool> sendWeChatAuth() async {
    try {
      final installed = await isWeChatInstalled();
      if (!installed) {
        debugPrint('WeChat is not installed');
        return false;
      }

      weChatResponseEventHandler.listen((response) {
        if (response is WeChatAuthResponse) {
          if (response.errCode == 0 && response.code != null) {
            _authCodeController.add(response.code!);
          } else {
            debugPrint(
                'WeChat auth failed: errCode=${response.errCode}, errStr=${response.errStr}');
          }
        }
      });

      final result = sendWeChatAuth(
        scope: _scope,
        state: _state,
      );
      return result;
    } catch (e) {
      debugPrint('sendWeChatAuth error: $e');
      return false;
    }
  }

  void dispose() {
    _authCodeController.close();
  }
}
