// User profile API: read/update profile, change password, delete account.
import '../models/user_model.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _api = ApiClient.instance;

  Future<UserModel> getMe() async {
    final data = await _api.get('/users/me') as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateProfile({
    String? name,
    String? avatarUrl,
    String? language, // 'en' or 'ckb'
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (language != null) body['language'] = language;

    final data = await _api.patch('/users/me', body: body) as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.patch('/users/me/password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<void> deleteAccount() async {
    await _api.delete('/users/me');
    await _api.clearTokens();
  }
}
