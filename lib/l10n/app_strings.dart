// ─────────────────────────────────────────────────────────────────────────────
//  Signslator — Localized strings (English + Kurdish Sorani)
//  ─────────────────────────────────────────────────────────────────────────────
//  Every user-facing string in the app lives here.
//  Add new strings to BOTH maps. Access via:
//      AppStrings.of(context).get('key')
//   or AppStrings.of(context)['key']
//   or, more concisely via the LocalizationProvider extension:
//      context.tr('key')
// ─────────────────────────────────────────────────────────────────────────────

class AppStrings {
  static const Map<String, Map<String, String>> _values = {
    'en': _en,
    'ckb': _ku,
  };

  final String languageCode;
  const AppStrings(this.languageCode);

  String get(String key) {
    final table = _values[languageCode] ?? _ku;
    return table[key] ?? _ku[key] ?? key;
  }

  String operator [](String key) => get(key);

  /// Substitute {0}, {1}, ... in the translated string with [args].
  String fmt(String key, List<Object> args) {
    var s = get(key);
    for (var i = 0; i < args.length; i++) {
      s = s.replaceAll('{$i}', args[i].toString());
    }
    return s;
  }
}

// ─── ENGLISH ─────────────────────────────────────────────────────────────────
const Map<String, String> _en = {
  // App
  'app_name': 'Awêna',
  'app_tagline': 'Bridging the gap between\nsign language and the world',

  // Splash
  'splash_get_started': 'Get Started',
  'splash_have_account': 'Already have an account? Sign in',
  'splash_pill_realtime': 'Real-time',
  'splash_pill_twoway': 'Two-way',
  'splash_pill_offline': 'Offline-ready',
  'splash_pill_accessible': 'Accessible',

  // Login
  'login_title': 'Welcome\nback',
  'login_subtitle': 'Sign in to continue translating',
  'login_email': 'Email address',
  'login_password': 'Password',
  'login_forgot': 'Forgot password?',
  'login_button': 'Sign In',
  'login_or_continue': 'or continue with',
  'social_google': 'Google',
  'social_facebook': 'Facebook',
  'login_no_account': "Don't have an account? ",
  'login_signup_link': 'Sign up',
  'login_empty_fields': 'Please enter both email and password',
  'login_failed': 'Login failed. Please try again.',
  'login_success': 'Login successful.',
  // Inline validation
  'err_email_required': 'Email is required',
  'err_email_invalid': 'Please enter a valid email',
  'err_password_required': 'Password is required',
  'err_password_short': 'Password must be at least 8 characters',
  'err_password_needs_letter': 'Add at least one letter',
  'err_password_needs_digit': 'Add at least one number',
  'err_name_required': 'Name is required',
  'err_name_short': 'Name must be at least 2 characters',
  'err_confirm_required': 'Please confirm your password',
  'err_token_required': 'Reset code is required',
  'err_network': 'Network error. Check your connection.',
  'err_server': 'Something went wrong. Please try again.',
  'err_invalid_credentials': 'Wrong email or password',
  'err_email_taken': 'This email is already registered',

  // Signup
  'signup_title': 'Create\naccount',
  'signup_subtitle': 'Join to break communication barriers',
  'signup_name': 'Full name',
  'signup_email': 'Email address',
  'signup_password': 'Password',
  'signup_confirm': 'Confirm password',
  'signup_button': 'Create Account',
  'signup_have_account': 'Already have an account? ',
  'signup_login_link': 'Sign in',
  'signup_terms_required': 'Please agree to the Terms of Service and Privacy Policy',
  'signup_fill_all': 'Please fill in all fields',
  'signup_pwd_mismatch': 'Passwords do not match',
  'signup_pwd_weak': 'Weak',
  'signup_pwd_fair': 'Fair',
  'signup_pwd_strong': 'Strong',
  'signup_terms_prefix': 'I agree to the ',
  'signup_terms': 'Terms of Service',
  'signup_terms_and': ' and ',
  'signup_privacy': 'Privacy Policy',
  'signup_success': 'Account created successfully! Please log in.',
  'signup_failed': 'Signup failed. Please try again.',

  // Home
  'home_hello': 'Hello, {0} 👋',
  'home_what_translate': 'What would you like to translate today?',
  'home_sign_to_text': 'Sign to Text',
  'home_sign_to_text_sub': 'Use camera to recognize sign language in real-time',
  'home_text_to_sign': 'Text to Sign',
  'home_text_to_sign_sub': 'Convert words or speech into animated sign language',
  'home_badge_live': 'Live',
  'home_badge_both': 'Both ways',
  'home_signs_translated': 'Signs translated',
  'home_sessions_month': 'Sessions this month',
  'home_quick_actions': 'Quick actions',
  'home_history': 'History',
  'home_language': 'Language',
  'home_settings': 'Settings',
  'home_pro_tip': 'Pro tip',
  'home_pro_tip_text': 'Ensure good lighting for faster and more accurate sign recognition.',

  // Bottom nav
  'nav_home': 'Home',
  'nav_sign': 'Sign',
  'nav_text': 'Text',
  'nav_history': 'History',

  // Sign-to-Text
  'stt_title': 'Sign to Text',
  'stt_subtitle': 'Point your camera at sign language gestures',
  'stt_recording': 'Recording',
  'stt_standby': 'Standby',
  'stt_detecting': 'Detecting gestures...',
  'stt_camera_active': 'Camera active',
  'stt_live_translation': 'Live translation',
  'stt_waiting': 'Waiting for signs...',
  'stt_copy': 'Copy text',
  'stt_speak': 'Speak aloud',
  'stt_tap_start': 'Tap to start recording',
  'stt_tap_stop': 'Tap to stop',
  'stt_copied': 'Translation copied to clipboard',
  'stt_saved': 'Saved to history',

  // Text-to-Sign
  'tts_title': 'Text to Sign',
  'tts_subtitle': 'Convert spoken words or text into animated sign language',
  'tts_type_mode': 'Type',
  'tts_voice_mode': 'Voice',
  'tts_input_hint': 'Type words here… e.g. "Good morning"',
  'tts_listening': 'Listening… speak now',
  'tts_tap_speak': 'Tap to speak',
  'tts_sign_output': 'Sign output',
  'tts_share': 'Share',
  'tts_animate': 'Animate',
  'tts_common_signs': 'Common signs',
  'tts_saved': 'Saved to history',

  // History
  'history_title': 'History',
  'history_subtitle': 'Your translation history',
  'history_filter': 'Filter',
  'history_filter_all': 'All',
  'history_filter_sign_to_text': 'Sign → Text',
  'history_filter_text_to_sign': 'Text → Sign',
  'history_filter_voice_to_sign': 'Voice → Sign',
  'history_search': 'Search translations…',
  'history_total': 'Total',
  'history_empty': 'No translations yet',
  'history_empty_sub': 'Your translations will appear here',
  'history_loading': 'Loading…',
  'history_error': 'Could not load history',
  'history_retry': 'Retry',
  'history_clear_all': 'Clear all',
  'history_clear_confirm_title': 'Clear all history?',
  'history_clear_confirm_msg': 'This will permanently delete all your translation history.',
  'history_cleared': 'History cleared',
  'history_delete': 'Delete',
  'history_deleted': 'Item deleted',
  'history_meta_sign_to_text': 'Sign → Text',
  'history_meta_text_to_sign': 'Text → Sign',
  'history_meta_voice_to_sign': 'Voice → Sign',
  'history_just_now': 'just now',
  'history_minutes_ago': '{0} mins ago',
  'history_hour_ago': '1 hr ago',
  'history_hours_ago': '{0} hrs ago',
  'history_yesterday': 'Yesterday',
  'history_days_ago': '{0} days ago',

  // Profile / Settings
  'profile_title': 'Profile',
  'profile_settings': 'Settings',
  'profile_language': 'Language',
  'profile_account': 'Account',
  'profile_change_password': 'Change password',
  'profile_logout': 'Log out',
  'profile_logout_confirm_title': 'Log out?',
  'profile_logout_confirm_msg': 'You will need to sign in again.',
  'profile_logout_btn': 'Log out',
  'profile_delete_account': 'Delete account',
  'profile_delete_confirm_title': 'Delete account?',
  'profile_delete_confirm_msg':
      'This will permanently delete your account and all your translations.',
  'profile_delete_btn': 'Delete',
  'profile_save': 'Save changes',
  'profile_saved': 'Profile updated',
  'profile_about': 'About',
  'profile_version': 'Version {0}',

  // Change password
  'cp_title': 'Change password',
  'cp_current': 'Current password',
  'cp_new': 'New password',
  'cp_confirm': 'Confirm new password',
  'cp_submit': 'Update password',
  'cp_success': 'Password updated successfully',
  'cp_mismatch': 'New passwords do not match',
  'cp_same': 'New password must differ from the current one',
  'cp_wrong_current': 'Current password is incorrect',

  // Forgot password
  'fp_title': 'Forgot password',
  'fp_subtitle': 'Enter your email and we will send you a reset code',
  'fp_email': 'Email address',
  'fp_submit': 'Send reset code',
  'fp_check_email': 'If the email is registered, a reset code has been sent.',
  'fp_have_token': 'I have a reset code',

  // Reset password
  'rp_title': 'Reset password',
  'rp_subtitle': 'Enter your reset code and a new password',
  'rp_token': 'Reset code',
  'rp_new': 'New password',
  'rp_confirm': 'Confirm new password',
  'rp_submit': 'Reset password',
  'rp_success': 'Password reset. Please sign in.',
  'rp_invalid': 'Invalid or expired reset code',

  // Language picker
  'lang_picker_title': 'Choose language',
  'lang_english': 'English',
  'lang_kurdish': 'کوردی (سۆرانی)',

  // Generic
  'cancel': 'Cancel',
  'confirm': 'Confirm',
  'ok': 'OK',
  'yes': 'Yes',
  'no': 'No',
  'save': 'Save',
  'edit': 'Edit',
  'delete': 'Delete',
  'retry': 'Retry',
  'loading': 'Loading…',
  'error_generic': 'Something went wrong',
  'error_network': 'Network error. Please check your connection.',
  'error_server': 'Server error. Please try again later.',
  'error_unauthorized': 'Session expired. Please sign in again.',
};

// ─── KURDISH (SORANI / Central Kurdish — کوردیی ناوەندی) ─────────────────────
const Map<String, String> _ku = {
  // App
  'app_name': 'ئاوێنە',
  'app_tagline': 'پردێک لە نێوان زمانی ئاماژەیی\nو جیهاندا',

  // Splash
  'splash_get_started': 'دەستپێبکە',
  'splash_have_account': 'هەژمارت هەیە؟ بچۆ ژوورەوە',
  'splash_pill_realtime': 'دەمی ڕاستەقینە',
  'splash_pill_twoway': 'دوولایەنە',
  'splash_pill_offline': 'بێ ئینتەرنێت',
  'splash_pill_accessible': 'دەستپێگەیشتوو',

  // Login
  'login_title': 'بەخێرهاتنەوە',
  'login_subtitle': 'بچۆ ژوورەوە بۆ بەردەوامبوون لە وەرگێڕان',
  'login_email': 'ناونیشانی ئیمەیڵ',
  'login_password': 'وشەی نهێنی',
  'login_forgot': 'وشەی نهێنیت لەبیر چووە؟',
  'login_button': 'چوونەژوورەوە',
  'login_or_continue': 'یان بەردەوامبە بە',
  'social_google': 'گۆگڵ',
  'social_facebook': 'فەیسبووک',
  'login_no_account': 'هەژمارت نییە؟ ',
  'login_signup_link': 'هەژمار دروستبکە',
  'login_empty_fields': 'تکایە ئیمەیڵ و وشەی نهێنی بنووسە',
  'login_failed': 'چوونەژوورەوە سەرکەوتوو نەبوو. تکایە دووبارە هەوڵبدەرەوە.',
  'login_success': 'چوونەژوورەوە سەرکەوتوو بوو.',
  // Inline validation
  'err_email_required': 'ئیمەیڵ پێویستە',
  'err_email_invalid': 'تکایە ئیمەیڵێکی دروست بنووسە',
  'err_password_required': 'وشەی نهێنی پێویستە',
  'err_password_short': 'وشەی نهێنی دەبێت لانیکەم ٨ پیت بێت',
  'err_password_needs_letter': 'لانیکەم یەک پیت زیاد بکە',
  'err_password_needs_digit': 'لانیکەم یەک ژمارە زیاد بکە',
  'err_name_required': 'ناو پێویستە',
  'err_name_short': 'ناو دەبێت لانیکەم ٢ پیت بێت',
  'err_confirm_required': 'تکایە وشەی نهێنی دووبارە بنووسە',
  'err_token_required': 'کۆدی گەڕاندنەوە پێویستە',
  'err_network': 'هەڵەی تۆڕ. پەیوەندیەکەت بپشکنە.',
  'err_server': 'هەڵەیەک ڕوویدا. تکایە دووبارە هەوڵبدەرەوە.',
  'err_invalid_credentials': 'ئیمەیڵ یان وشەی نهێنی هەڵەیە',
  'err_email_taken': 'ئەم ئیمەیڵە پێشتر تۆمارکراوە',

  // Signup
  'signup_title': 'دروستکردنی\nهەژمار',
  'signup_subtitle': 'بەشدارببە بۆ تێپەڕاندنی بەربەستە پەیوەندیەکان',
  'signup_name': 'ناوی تەواو',
  'signup_email': 'ناونیشانی ئیمەیڵ',
  'signup_password': 'وشەی نهێنی',
  'signup_confirm': 'دڵنیاکردنەوەی وشەی نهێنی',
  'signup_button': 'دروستکردنی هەژمار',
  'signup_have_account': 'پێشتر هەژمارت هەیە؟ ',
  'signup_login_link': 'بچۆ ژوورەوە',
  'signup_terms_required': 'تکایە ڕەزامەندی بدە بە مەرجەکان و سیاسەتی تایبەتمەندی',
  'signup_fill_all': 'تکایە هەموو خانەکان پڕبکەرەوە',
  'signup_pwd_mismatch': 'وشە نهێنیەکان وەک یەک نین',
  'signup_pwd_weak': 'لاواز',
  'signup_pwd_fair': 'مامناوەند',
  'signup_pwd_strong': 'بەهێز',
  'signup_terms_prefix': 'ڕەزامەندی دەدەم بە ',
  'signup_terms': 'مەرجەکانی بەکارهێنان',
  'signup_terms_and': ' و ',
  'signup_privacy': 'سیاسەتی تایبەتمەندی',
  'signup_success': 'هەژمار بە سەرکەوتوویی دروستکرا! تکایە بچۆ ژوورەوە.',
  'signup_failed': 'دروستکردنی هەژمار سەرکەوتوو نەبوو. هەوڵبدەرەوە.',

  // Home
  'home_hello': 'سڵاو، {0} 👋',
  'home_what_translate': 'ئەمڕۆ دەتەوێت چی وەربگێڕیت؟',
  'home_sign_to_text': 'ئاماژە بۆ دەق',
  'home_sign_to_text_sub': 'کامێرا بەکاربهێنە بۆ ناسینەوەی زمانی ئاماژەیی بە دەمی ڕاستەقینە',
  'home_text_to_sign': 'دەق بۆ ئاماژە',
  'home_text_to_sign_sub': 'وشە یان دەنگ بگۆڕە بۆ زمانی ئاماژەیی جوڵاو',
  'home_badge_live': 'ڕاستەوخۆ',
  'home_badge_both': 'دوولایەنە',
  'home_signs_translated': 'ئاماژەی وەرگێڕدراو',
  'home_sessions_month': 'دانیشتنی ئەم مانگە',
  'home_quick_actions': 'کارە خێراکان',
  'home_history': 'مێژوو',
  'home_language': 'زمان',
  'home_settings': 'ڕێکخستنەکان',
  'home_pro_tip': 'ئامۆژگاری',
  'home_pro_tip_text': 'دڵنیابە لە ڕووناکی باش بۆ ناسینەوەی خێراتر و ورتری ئاماژەکان.',

  // Bottom nav
  'nav_home': 'سەرەکی',
  'nav_sign': 'ئاماژە',
  'nav_text': 'دەق',
  'nav_history': 'مێژوو',

  // Sign-to-Text
  'stt_title': 'ئاماژە بۆ دەق',
  'stt_subtitle': 'کامێراکەت ئاراستەی جوڵە ئاماژەییەکان بکە',
  'stt_recording': 'تۆمارکردن',
  'stt_standby': 'چاوەڕوان',
  'stt_detecting': 'دۆزینەوەی جوڵەکان...',
  'stt_camera_active': 'کامێرا چالاکە',
  'stt_live_translation': 'وەرگێڕانی ڕاستەوخۆ',
  'stt_waiting': 'چاوەڕوانی ئاماژە...',
  'stt_copy': 'لەبەرگرتنەوەی دەق',
  'stt_speak': 'دەنگ',
  'stt_tap_start': 'دەستبدە بۆ دەستپێکردنی تۆمارکردن',
  'stt_tap_stop': 'دەستبدە بۆ ڕاگرتن',
  'stt_copied': 'وەرگێڕان لەبەرگیرایەوە',
  'stt_saved': 'پاشەکەوتکرا لە مێژوو',

  // Text-to-Sign
  'tts_title': 'دەق بۆ ئاماژە',
  'tts_subtitle': 'وشە یان دەنگ بگۆڕە بۆ ئاماژەی جوڵاو',
  'tts_type_mode': 'نووسین',
  'tts_voice_mode': 'دەنگ',
  'tts_input_hint': 'وشەکان لێرە بنووسە… بۆ نموونە "بەیانی باش"',
  'tts_listening': 'گوێگرتن… ئێستا قسەبکە',
  'tts_tap_speak': 'دەستبدە بۆ قسەکردن',
  'tts_sign_output': 'دەرئەنجامی ئاماژە',
  'tts_share': 'هاوبەشکردن',
  'tts_animate': 'جوڵاندن',
  'tts_common_signs': 'ئاماژە باوەکان',
  'tts_saved': 'پاشەکەوتکرا لە مێژوو',

  // History
  'history_title': 'مێژوو',
  'history_subtitle': 'مێژووی وەرگێڕانەکانت',
  'history_filter': 'فلتەر',
  'history_filter_all': 'هەموو',
  'history_filter_sign_to_text': 'ئاماژە ← دەق',
  'history_filter_text_to_sign': 'دەق ← ئاماژە',
  'history_filter_voice_to_sign': 'دەنگ ← ئاماژە',
  'history_search': 'گەڕان لە وەرگێڕانەکان…',
  'history_total': 'کۆ',
  'history_empty': 'هیچ وەرگێڕانێک نییە',
  'history_empty_sub': 'وەرگێڕانەکانت لێرە دەردەکەون',
  'history_loading': 'بارکردن…',
  'history_error': 'نەتوانرا مێژوو باربکرێت',
  'history_retry': 'دووبارە هەوڵبدە',
  'history_clear_all': 'سڕینەوەی هەموو',
  'history_clear_confirm_title': 'هەموو مێژوو بسڕێتەوە؟',
  'history_clear_confirm_msg': 'ئەمە بە تەواوی هەموو مێژووی وەرگێڕانەکانت دەسڕێتەوە.',
  'history_cleared': 'مێژوو سڕایەوە',
  'history_delete': 'سڕینەوە',
  'history_deleted': 'بڕگەکە سڕایەوە',
  'history_meta_sign_to_text': 'ئاماژە ← دەق',
  'history_meta_text_to_sign': 'دەق ← ئاماژە',
  'history_meta_voice_to_sign': 'دەنگ ← ئاماژە',
  'history_just_now': 'هەر ئێستا',
  'history_minutes_ago': '{0} خولەک پێش ئێستا',
  'history_hour_ago': '١ کاتژمێر پێش ئێستا',
  'history_hours_ago': '{0} کاتژمێر پێش ئێستا',
  'history_yesterday': 'دوێنێ',
  'history_days_ago': '{0} ڕۆژ پێش ئێستا',

  // Profile / Settings
  'profile_title': 'پرۆفایل',
  'profile_settings': 'ڕێکخستنەکان',
  'profile_language': 'زمان',
  'profile_account': 'هەژمار',
  'profile_change_password': 'گۆڕینی وشەی نهێنی',
  'profile_logout': 'چوونەدەرەوە',
  'profile_logout_confirm_title': 'دەچیتە دەرەوە؟',
  'profile_logout_confirm_msg': 'پێویستە دیسان بچیتە ژوورەوە.',
  'profile_logout_btn': 'چوونەدەرەوە',
  'profile_delete_account': 'سڕینەوەی هەژمار',
  'profile_delete_confirm_title': 'هەژمار بسڕێتەوە؟',
  'profile_delete_confirm_msg':
      'ئەمە بە تەواوی هەژمار و هەموو وەرگێڕانەکانت دەسڕێتەوە.',
  'profile_delete_btn': 'سڕینەوە',
  'profile_save': 'پاشەکەوتکردن',
  'profile_saved': 'پرۆفایل نوێکرایەوە',
  'profile_about': 'دەربارە',
  'profile_version': 'وەشان {0}',

  // Change password
  'cp_title': 'گۆڕینی وشەی نهێنی',
  'cp_current': 'وشەی نهێنی ئێستا',
  'cp_new': 'وشەی نهێنی نوێ',
  'cp_confirm': 'دڵنیاکردنەوەی وشەی نهێنی نوێ',
  'cp_submit': 'گۆڕینی وشەی نهێنی',
  'cp_success': 'وشەی نهێنی بە سەرکەوتوویی نوێکرایەوە',
  'cp_mismatch': 'وشە نهێنیە نوێکان وەک یەک نین',
  'cp_same': 'وشەی نهێنی نوێ پێویستە جیاواز بێت لە وشەی نهێنی ئێستا',
  'cp_wrong_current': 'وشەی نهێنی ئێستا هەڵەیە',

  // Forgot password
  'fp_title': 'وشەی نهێنیم لەبیرچووە',
  'fp_subtitle': 'ئیمەیڵەکەت بنووسە و کۆدی نوێکردنەوە بۆت دەنێرین',
  'fp_email': 'ناونیشانی ئیمەیڵ',
  'fp_submit': 'ناردنی کۆد',
  'fp_check_email': 'ئەگەر ئیمەیڵەکە تۆمارکراوە، کۆدی نوێکردنەوە نێردراوە.',
  'fp_have_token': 'کۆدی نوێکردنەوەم هەیە',

  // Reset password
  'rp_title': 'نوێکردنەوەی وشەی نهێنی',
  'rp_subtitle': 'کۆدەکەت و وشەی نهێنی نوێ بنووسە',
  'rp_token': 'کۆدی نوێکردنەوە',
  'rp_new': 'وشەی نهێنی نوێ',
  'rp_confirm': 'دڵنیاکردنەوەی وشەی نهێنی نوێ',
  'rp_submit': 'نوێکردنەوەی وشەی نهێنی',
  'rp_success': 'وشەی نهێنی نوێکرایەوە. تکایە بچۆ ژوورەوە.',
  'rp_invalid': 'کۆدەکە هەڵەیە یان بەسەرچووە',

  // Language picker
  'lang_picker_title': 'زمان هەڵبژێرە',
  'lang_english': 'English',
  'lang_kurdish': 'کوردی (سۆرانی)',

  // Generic
  'cancel': 'پاشگەزبوونەوە',
  'confirm': 'پشتڕاستکردنەوە',
  'ok': 'باشە',
  'yes': 'بەڵێ',
  'no': 'نەخێر',
  'save': 'پاشەکەوتکردن',
  'edit': 'دەستکاری',
  'delete': 'سڕینەوە',
  'retry': 'دووبارە هەوڵبدە',
  'loading': 'بارکردن…',
  'error_generic': 'هەڵەیەک ڕوویدا',
  'error_network': 'هەڵەی تۆڕ. تکایە پەیوەندیەکەت بپشکنە.',
  'error_server': 'هەڵەی سێرڤەر. تکایە دواتر هەوڵبدەرەوە.',
  'error_unauthorized': 'دانیشتن بەسەرچووە. تکایە دیسان بچۆ ژوورەوە.',
};
