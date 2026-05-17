// ─────────────────────────────────────────────────────────────────────────────
//  LocalizationProvider
//  ─────────────────────────────────────────────────────────────────────────────
//  Holds the current UI language and persists it.
//  Wrap MaterialApp with ChangeNotifierProvider<LocalizationProvider>.
//  Read with:   context.watch<LocalizationProvider>()  (rebuild)
//               context.read<LocalizationProvider>()   (no rebuild)
//  Translate:   context.tr('login_button')
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

enum AppLanguage {
  english('en', 'English', TextDirection.ltr),
  kurdish('ckb', 'کوردی (سۆرانی)', TextDirection.rtl);

  final String code;
  final String displayName;
  final TextDirection direction;

  const AppLanguage(this.code, this.displayName, this.direction);

  String get shortCode => code == 'ckb' ? 'KU' : code.toUpperCase();

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.kurdish,
    );
  }

  Locale get locale {
    // Sorani: language=ckb, script=Arab, region=IQ.
    // We use 'ckb' here to match ckb_localizations package and standard codes.
    if (this == AppLanguage.kurdish) return const Locale('ckb', 'IQ');
    return const Locale('en', 'US');
  }
}

class LocalizationProvider extends ChangeNotifier {
  static const _prefsKey = 'app_language';

  AppLanguage _language = AppLanguage.kurdish;
  AppStrings _strings = const AppStrings('ckb');
  bool _initialized = false;

  AppLanguage get language => _language;
  AppStrings get strings => _strings;
  bool get isInitialized => _initialized;
  bool get isRtl => _language.direction == TextDirection.rtl;
  Locale get locale => _language.locale;

  /// Read saved language from prefs and apply it.
  /// Call once at app startup, before runApp.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null) {
      _language = AppLanguage.fromCode(code);
      _strings = AppStrings(_language.code);
    }
    _initialized = true;
  }

  /// Switch language and persist it locally.
  Future<void> setLanguage(AppLanguage lang) async {
    if (lang == _language) return;
    _language = lang;
    _strings = AppStrings(lang.code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, lang.code);
  }

  /// Convenience: pass the API language code (`'en'` / `'ckb'`).
  Future<void> setLanguageCode(String code) =>
      setLanguage(AppLanguage.fromCode(code));

  String tr(String key) => _strings.get(key);
  String fmt(String key, List<Object> args) => _strings.fmt(key, args);
}

// ─── Convenience extension on BuildContext ──────────────────────────────────
extension LocalizationX on BuildContext {
  /// Translate a key.  e.g.   context.tr('login_button')
  String tr(String key) => watch<LocalizationProvider>().tr(key);

  /// Translate with positional arguments. e.g. context.fmt('home_hello', ['Aram'])
  String fmt(String key, List<Object> args) =>
      watch<LocalizationProvider>().fmt(key, args);

  /// Read-only accessor (no rebuild).
  LocalizationProvider get l10n => read<LocalizationProvider>();
}
