import '../l10n/localization_provider.dart';

/// Pure form-validation helpers. They take a LocalizationProvider so the
/// returned error messages match the user's language. Returning `null`
/// means the value is valid.
class Validators {
  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$",
  );

  static String? email(String? raw, LocalizationProvider loc) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return loc.tr('err_email_required');
    if (!_emailRegex.hasMatch(v)) return loc.tr('err_email_invalid');
    return null;
  }

  static String? password(String? raw, LocalizationProvider loc,
      {bool strict = false}) {
    final v = raw ?? '';
    if (v.isEmpty) return loc.tr('err_password_required');
    if (!strict) return null;
    if (v.length < 8) return loc.tr('err_password_short');
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
      return loc.tr('err_password_needs_letter');
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) {
      return loc.tr('err_password_needs_digit');
    }
    return null;
  }

  static String? name(String? raw, LocalizationProvider loc) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return loc.tr('err_name_required');
    if (v.length < 2) return loc.tr('err_name_short');
    return null;
  }

  static String? confirmPassword(
      String? raw, String original, LocalizationProvider loc) {
    final v = raw ?? '';
    if (v.isEmpty) return loc.tr('err_confirm_required');
    if (v != original) return loc.tr('signup_pwd_mismatch');
    return null;
  }

  static String? token(String? raw, LocalizationProvider loc) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return loc.tr('err_token_required');
    if (v.length != 6 || int.tryParse(v) == null) {
      return loc.isRtl
          ? 'کۆدەکە دەبێت ٦ ژمارە بێت'
          : 'Code must be exactly 6 digits';
    }
    return null;
  }
}

/// Maps server-side error messages to localized strings.
/// Falls back to the raw message if no mapping matches.
String mapServerError(String? raw, LocalizationProvider loc) {
  final m = (raw ?? '').toLowerCase();
  if (m.contains('network') ||
      m.contains('connection') ||
      m.contains('socket') ||
      m.contains('timeout')) {
    return loc.tr('err_network');
  }
  if (m.contains('invalid credentials') ||
      m.contains('incorrect email') ||
      m.contains('incorrect password') ||
      m.contains('wrong') ||
      (m.contains('email') && m.contains('password'))) {
    return loc.tr('err_invalid_credentials');
  }
  if (m.contains('already') &&
      (m.contains('registered') || m.contains('exist') || m.contains('use'))) {
    return loc.tr('err_email_taken');
  }
  if (raw != null && raw.isNotEmpty) return raw;
  return loc.tr('err_server');
}
