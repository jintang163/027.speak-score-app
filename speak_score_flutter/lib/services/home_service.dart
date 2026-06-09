import '../models/user_info.dart';
import 'api_client.dart';

class HomeService {
  final ApiClient _apiClient = ApiClient();

  Future<HomeMenu> getHomeMenus() async {
    try {
      final response = await _apiClient.get('/home/menus');
      final data = response.data['data'] ?? response.data;
      return HomeMenu.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserInfo> getUserInfo() async {
    try {
      final response = await _apiClient.get('/user/me');
      final data = response.data['data'] ?? response.data;
      return UserInfo.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
