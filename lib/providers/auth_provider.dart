// ─────────────────────────────────────────────────────────────────────────────
//  AuthProvider — app-wide user state.
//  ─────────────────────────────────────────────────────────────────────────────
//  Holds the current UserModel (or null), keeps it in sync with the backend,
//  and pushes language changes to both the LocalizationProvider and the API.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';

import '../l10n/localization_provider.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/social_auth_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final UserService _users = UserService();
  final LocalizationProvider l10n;

  UserModel? _user;
  bool _loading = false;

  AuthProvider(this.l10n);

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;

  // ─── Restore session on app start ────────────────────────────────────────
  Future<void> bootstrap() async {
    _setLoading(true);
    try {
      if (await ApiClient.instance.isLoggedIn()) {
        _user = await _users.getMe();
        // Sync UI language with the user's saved preference.
        await l10n.setLanguageCode(_user!.language);
      }
    } catch (_) {
      _user = null;
      await ApiClient.instance.clearTokens();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Login flow ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    _setLoading(true);
    final result = await _auth.login(email, password);
    if (result['success'] == true && result['user'] is UserModel) {
      _user = result['user'] as UserModel;
      // The user's saved language wins over the device default.
      await l10n.setLanguageCode(_user!.language);
    }
    _setLoading(false);
    return result;
  }

  // ─── Social Login ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> loginWithSocial(String provider) async {
    _setLoading(true);
    try {
      String? token;
      if (provider == 'google') {
        token = await SocialAuthService.instance.signInWithGoogle();
      } else if (provider == 'facebook') {
        token = await SocialAuthService.instance.signInWithFacebook();
      }

      if (token == null) {
        _setLoading(false);
        return {'success': false, 'message': 'Cancelled or failed.'};
      }

      final result = await _auth.loginWithSocial(
        provider: provider,
        token: token,
      );

      if (result['success'] == true && result['user'] is UserModel) {
        _user = result['user'] as UserModel;
        await l10n.setLanguageCode(_user!.language);
      }
      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Social login failed: $e'};
    }
  }

  // ─── Signup flow ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> signup(
      String name, String email, String password) {
    return _auth.signup(name, email, password);
  }

  // ─── Logout ──────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.logout();
    _user = null;
    notifyListeners();
  }

  // ─── Refresh user (e.g. after profile edit) ──────────────────────────────
  Future<void> refreshUser() async {
    try {
      _user = await _users.getMe();
      notifyListeners();
    } catch (_) {/* swallow */}
  }

  // ─── Update profile (name / avatar / language) ───────────────────────────
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    String? language,
  }) async {
    final updated = await _users.updateProfile(
      name: name,
      avatarUrl: avatarUrl,
      language: language,
    );
    _user = updated;
    if (language != null) {
      await l10n.setLanguageCode(language);
    }
    notifyListeners();
  }

  // ─── Convenience: switch language (local + backend if logged in) ─────────
  Future<void> setLanguage(AppLanguage lang) async {
    await l10n.setLanguage(lang);
    if (_user != null) {
      try {
        await _users.updateProfile(language: lang.code);
        _user = _user!.copyWith(language: lang.code);
        notifyListeners();
      } catch (_) {/* offline is fine; local is already updated */}
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _users.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> deleteAccount() async {
    await _users.deleteAccount();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
