import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_info.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;
  UserInfo? _userInfo;
  bool _isLoading = true;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  UserInfo? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> loadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accessToken = await _secureStorage.read(key: 'access_token');
      _refreshToken = await _secureStorage.read(key: 'refresh_token');

      final userInfoJson = await _secureStorage.read(key: 'user_info');
      if (userInfoJson != null) {
        try {
          _userInfo = UserInfo.fromJson(
            jsonDecode(userInfoJson) as Map<String, dynamic>,
          );
        } catch (_) {
          _userInfo = null;
        }
      }
    } catch (_) {
      _accessToken = null;
      _refreshToken = null;
      _userInfo = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persistTokens(TokenResponse tokenResponse) async {
    _accessToken = tokenResponse.accessToken;
    _refreshToken = tokenResponse.refreshToken;
    _userInfo = tokenResponse.userInfo;

    if (_accessToken != null) {
      await _secureStorage.write(key: 'access_token', value: _accessToken);
    }
    if (_refreshToken != null) {
      await _secureStorage.write(key: 'refresh_token', value: _refreshToken);
    }
    if (_userInfo != null) {
      await _secureStorage.write(
        key: 'user_info',
        value: jsonEncode(_userInfo!.toJson()),
      );
    }
  }

  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _userInfo = null;
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user_info');
  }

  Future<bool> loginByPhone(String phone, String code) async {
    try {
      final response = await _apiClient.post(
        '/auth/phone-login',
        data: {'phone': phone, 'code': code},
      );

      final tokenResponse = TokenResponse.fromJson(
        response.data['data'] ?? response.data,
      );
      await _persistTokens(tokenResponse);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('loginByPhone error: $e');
      return false;
    }
  }

  Future<bool> sendSmsCode(String phone) async {
    try {
      await _apiClient.post('/auth/sms-code', data: {'phone': phone});
      return true;
    } catch (e) {
      debugPrint('sendSmsCode error: $e');
      return false;
    }
  }

  Future<bool> loginByWechat(String code) async {
    try {
      final response = await _apiClient.post(
        '/auth/wechat-login',
        data: {'code': code},
      );

      final tokenResponse = TokenResponse.fromJson(
        response.data['data'] ?? response.data,
      );
      await _persistTokens(tokenResponse);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('loginByWechat error: $e');
      return false;
    }
  }

  Future<bool> register({
    required String phone,
    required String code,
    required String nickname,
    required String roleCode,
    required int schoolId,
    required String classCode,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'phone': phone,
          'code': code,
          'nickname': nickname,
          'roleCode': roleCode,
          'schoolId': schoolId,
          'classCode': classCode,
        },
      );

      final tokenResponse = TokenResponse.fromJson(
        response.data['data'] ?? response.data,
      );
      await _persistTokens(tokenResponse);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('register error: $e');
      return false;
    }
  }

  Future<bool> wechatRegister({
    required String phone,
    required String smsCode,
    required String nickname,
    required String roleCode,
    required String wechatCode,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/wechat-register',
        data: {
          'phone': phone,
          'smsCode': smsCode,
          'nickname': nickname,
          'roleCode': roleCode,
          'wechatCode': wechatCode,
        },
      );

      final tokenResponse = TokenResponse.fromJson(
        response.data['data'] ?? response.data,
      );
      await _persistTokens(tokenResponse);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('wechatRegister error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {
      // ignore logout API errors, still clear local state
    }
    await _clearTokens();
    notifyListeners();
  }

  Future<bool> refreshToken() async {
    try {
      final response = await _apiClient.post(
        '/auth/refresh',
        data: {'refreshToken': _refreshToken},
      );

      final tokenResponse = TokenResponse.fromJson(
        response.data['data'] ?? response.data,
      );
      await _persistTokens(tokenResponse);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('refreshToken error: $e');
      await _clearTokens();
      notifyListeners();
      return false;
    }
  }
}
