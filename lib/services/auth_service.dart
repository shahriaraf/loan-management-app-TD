import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _api = ApiClient();
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post(ApiConstants.login, data: {
      'email': email.trim(),
      'password': password,
    });

    final data = response.data;
    // Backend may return { token, user } or { accessToken, user }
    final token = data['token'] ?? data['accessToken'] ?? data['access_token'];
    final userData = data['user'] ?? data;

    if (token != null) {
      await _api.setToken(token.toString());
      final user = UserModel.fromJson(userData is Map<String, dynamic> ? userData : data);
      await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
      return {'success': true, 'user': user, 'requires2FA': data['requires2FA'] == true};
    }

    throw Exception(data['message'] ?? 'Login failed');
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _api.get(ApiConstants.me);
      final user = UserModel.fromJson(response.data is Map ? response.data : response.data['user'] ?? {});
      await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
      return user;
    } catch (_) {
      // Fallback to cached
      final cached = await _storage.read(key: 'user_data');
      if (cached != null) {
        return UserModel.fromJson(jsonDecode(cached));
      }
      return null;
    }
  }

  Future<UserModel?> getCachedUser() async {
    final cached = await _storage.read(key: 'user_data');
    if (cached != null) {
      return UserModel.fromJson(jsonDecode(cached));
    }
    return null;
  }

  Future<void> logout() async {
    await _api.clearToken();
  }

  Future<bool> isLoggedIn() async {
    return await _api.hasToken;
  }
}
