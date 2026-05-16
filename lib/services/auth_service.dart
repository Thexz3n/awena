// ─────────────────────────────────────────────────────────────────────────────
//  AuthService — talks to the FastAPI backend.
//  ─────────────────────────────────────────────────────────────────────────────
//  Drop-in replacement for the old PHP-targeting AuthService. The login() and
//  signup() methods keep the same {success, message} contract so the existing
//  login/signup screens work unchanged.
// ─────────────────────────────────────────────────────────────────────────────
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient.instance;

  // ─── Sign up ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      final data = await _api.post('/auth/signup', auth: false, body: {
        'name': name,
        'email': email,
        'password': password,
      });
      return {
        'success': true,
        'message': data is Map ? data['message'] : 'Account created.',
        'user': data is Map && data['user'] != null
            ? UserModel.fromJson(Map<String, dynamic>.from(data['user']))
            : null,
      };
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final data = await _api.post('/auth/login', auth: false, body: {
        'email': email,
        'password': password,
      }) as Map<String, dynamic>;

      await _api.saveTokens(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );

      final user = UserModel.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );

      return {
        'success': true,
        'message': data['message'] ?? 'Login successful.',
        'user': user,
      };
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── Social Login ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> loginWithSocial({
    required String provider, // 'google' or 'facebook'
    required String token,
  }) async {
    try {
      final data = await _api.post('/auth/social', auth: false, body: {
        'provider': provider,
        'token': token,
      }) as Map<String, dynamic>;

      await _api.saveTokens(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );

      final user = UserModel.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );

      return {
        'success': true,
        'message': data['message'] ?? 'Login successful.',
        'user': user,
      };
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final refresh = await _api.getRefreshToken();
    try {
      await _api.post(
        '/auth/logout',
        body: refresh != null ? {'refresh_token': refresh} : null,
      );
    } catch (_) {
      // Ignore network errors here — we still clear tokens locally.
    } finally {
      await _api.clearTokens();
    }
  }

  // ─── Forgot password ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final data = await _api.post(
        '/auth/forgot-password',
        auth: false,
        body: {'email': email},
      );
      return {
        'success': true,
        'message': data is Map ? data['message'] : 'Reset code sent.',
        'reset_token': data is Map ? data['reset_token'] : null, // dev only
      };
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  // ─── Reset password ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final data = await _api.post(
        '/auth/reset-password',
        auth: false,
        body: {'token': token, 'new_password': newPassword},
      );
      return {
        'success': true,
        'message': data is Map ? data['message'] : 'Password reset.',
      };
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  // ─── Status helpers ───────────────────────────────────────────────────────
  Future<bool> isLoggedIn() => _api.isLoggedIn();
  Future<String?> getToken() => _api.getAccessToken();
}
