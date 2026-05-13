import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/localization_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/language_picker.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final loc = context.read<LocalizationProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder)),
        title: Text(loc.tr('profile_logout_confirm_title'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(loc.tr('profile_logout_confirm_msg'),
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.tr('cancel'),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.tr('profile_logout_btn'),
                style: const TextStyle(color: AppColors.pink)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final loc = context.read<LocalizationProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder)),
        title: Text(loc.tr('profile_delete_confirm_title'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(loc.tr('profile_delete_confirm_msg'),
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.tr('cancel'),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.tr('profile_delete_btn'),
                style: const TextStyle(color: AppColors.pink)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    try {
      await context.read<AuthProvider>().deleteAccount();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.pink),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              // ─── Header ──────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Icon(
                        loc.isRtl
                            ? Icons.arrow_forward_ios_rounded
                            : Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loc.tr('profile_title'),
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // ─── User card ───────────────────────────────────────
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.pinkGradient,
                      ),
                      child: Center(
                        child: Text(
                          user?.initial ?? '?',
                          style: GoogleFonts.syne(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? '—',
                            style: GoogleFonts.syne(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 24),

              // ─── Settings section ────────────────────────────────
              _SectionHeader(label: loc.tr('profile_settings'))
                  .animate(delay: 200.ms)
                  .fadeIn(),

              const SizedBox(height: 8),

              _SettingTile(
                icon: Icons.language_rounded,
                color: AppColors.accent,
                label: loc.tr('profile_language'),
                trailing: Text(
                  loc.language.displayName,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                ),
                onTap: () => LanguagePicker.show(context),
              ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.05),

              const SizedBox(height: 24),

              // ─── Account section ─────────────────────────────────
              _SectionHeader(label: loc.tr('profile_account'))
                  .animate(delay: 300.ms)
                  .fadeIn(),

              const SizedBox(height: 8),

              _SettingTile(
                icon: Icons.lock_outline_rounded,
                color: AppColors.teal,
                label: loc.tr('profile_change_password'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ),
              ).animate(delay: 350.ms).fadeIn().slideX(begin: -0.05),

              const SizedBox(height: 8),

              _SettingTile(
                icon: Icons.logout_rounded,
                color: AppColors.pink,
                label: loc.tr('profile_logout'),
                onTap: () => _confirmLogout(context),
              ).animate(delay: 400.ms).fadeIn().slideX(begin: -0.05),

              const SizedBox(height: 8),

              _SettingTile(
                icon: Icons.delete_outline_rounded,
                color: AppColors.pink,
                label: loc.tr('profile_delete_account'),
                onTap: () => _confirmDelete(context),
              ).animate(delay: 450.ms).fadeIn().slideX(begin: -0.05),

              const SizedBox(height: 24),

              // ─── About ───────────────────────────────────────────
              _SectionHeader(label: loc.tr('profile_about'))
                  .animate(delay: 500.ms)
                  .fadeIn(),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.accent, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      loc.fmt('profile_version', ['1.0.0']),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 550.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) trailing!,
          const SizedBox(width: 6),
          Icon(
            loc.isRtl
                ? Icons.arrow_back_ios_rounded
                : Icons.arrow_forward_ios_rounded,
            size: 12,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
