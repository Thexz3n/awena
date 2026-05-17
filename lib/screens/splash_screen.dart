import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/localization_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/language_picker.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  void _goToHome() {
    final auth = context.read<AuthProvider>();
    final next = auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.teal.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _LogoRing(controller: _ringCtrl)
                        .animate()
                        .scale(
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.5, 0.5),
                        )
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: 32),
                    Text(
                      loc.tr('app_name'),
                      style: GoogleFonts.syne(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [AppColors.accent, AppColors.teal],
                          ).createShader(
                              const Rect.fromLTWH(0, 0, 250, 50)),
                        letterSpacing: -1,
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.3, curve: Curves.easeOut),
                    const SizedBox(height: 12),
                    Text(
                      loc.tr('app_tagline'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    )
                        .animate(delay: 350.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2),
                    const Spacer(flex: 2),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _Pill(
                            label: loc.tr('splash_pill_realtime'),
                            icon: Icons.speed_rounded),
                        _Pill(
                            label: loc.tr('splash_pill_twoway'),
                            icon: Icons.swap_horiz_rounded),
                        _Pill(
                            label: loc.tr('splash_pill_offline'),
                            icon: Icons.offline_bolt_rounded),
                        _Pill(
                            label: loc.tr('splash_pill_accessible'),
                            icon: Icons.accessibility_new_rounded),
                      ],
                    ).animate(delay: 500.ms).fadeIn(duration: 600.ms),
                    const SizedBox(height: 40),
                    GradientButton(
                      label: loc.tr('splash_get_started'),
                      icon: Icons.arrow_forward_rounded,
                      onTap: _goToHome,
                    )
                        .animate(delay: 650.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.3),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _goToLogin,
                      child: Text(
                        loc.tr('splash_have_account'),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ).animate(delay: 750.ms).fadeIn(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Language switcher pinned at the top-right - Moved to end to receive events
            Positioned(
              top: 12,
              right: 16,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => LanguagePicker.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language_rounded,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          loc.language.shortCode,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoRing extends StatelessWidget {
  final AnimationController controller;
  const _LogoRing({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => Transform.rotate(
              angle: controller.value * 2 * 3.14159,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.transparent),
                  gradient: SweepGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.0),
                      AppColors.accent,
                      AppColors.teal,
                      AppColors.accent.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bg,
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.accentGradient,
            ),
            child: const Icon(
              Icons.sign_language_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Pill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
