// ─── Language picker ────────────────────────────────────────────────────────
//  Reusable bottom sheet for switching between English and Kurdish (Sorani).
//  Persists locally and (when logged in) pushes the change to the backend.
// ───────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/localization_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LanguagePicker {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _LanguagePickerSheet(),
    );
  }
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet();

  Future<void> _pick(BuildContext context, AppLanguage lang) async {
    // Try via AuthProvider so the choice is also pushed to the backend.
    final auth = context.read<AuthProvider?>();
    if (auth != null) {
      await auth.setLanguage(lang);
    } else {
      await context.read<LocalizationProvider>().setLanguage(lang);
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.language_rounded,
                    color: AppColors.accent, size: 22),
                const SizedBox(width: 10),
                Text(
                  loc.tr('lang_picker_title'),
                  style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (final lang in AppLanguage.values)
              _LangTile(
                language: lang,
                isCurrent: lang == loc.language,
                onTap: () => _pick(context, lang),
              ),
          ],
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final AppLanguage language;
  final bool isCurrent;
  final VoidCallback onTap;

  const _LangTile({
    required this.language,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.accent.withOpacity(0.12)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent
                ? AppColors.accent.withOpacity(0.4)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.accent.withOpacity(0.2)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                language == AppLanguage.english ? '🇬🇧' : '🇮🇶',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                language.displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isCurrent
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (isCurrent)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 22),
          ],
        ),
      ),
    );
  }
}
