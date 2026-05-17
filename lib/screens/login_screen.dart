import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/localization_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_form_fields.dart';
import '../widgets/language_picker.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Inline validation state. We only show errors AFTER the user submits once,
  // so we don't annoy them while they're still typing.
  bool _submitted = false;
  String? _emailErr;
  String? _passwordErr;

  late final AnimationController _ringCtrl;
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _emailCtrl.addListener(_revalidateEmail);
    _passwordCtrl.addListener(_revalidatePassword);
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _bgCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _revalidateEmail() {
    if (!_submitted) return;
    final loc = context.read<LocalizationProvider>();
    setState(() => _emailErr = Validators.email(_emailCtrl.text, loc));
  }

  void _revalidatePassword() {
    if (!_submitted) return;
    final loc = context.read<LocalizationProvider>();
    setState(
        () => _passwordErr = Validators.password(_passwordCtrl.text, loc));
  }

  Future<void> _handleLogin() async {
    final loc = context.read<LocalizationProvider>();
    final emailErr = Validators.email(_emailCtrl.text, loc);
    final pwErr = Validators.password(_passwordCtrl.text, loc);

    setState(() {
      _submitted = true;
      _emailErr = emailErr;
      _passwordErr = pwErr;
    });

    if (emailErr != null) {
      _emailFocus.requestFocus();
      return;
    }
    if (pwErr != null) {
      _passwordFocus.requestFocus();
      return;
    }

    setState(() => _isLoading = true);
    final result = await context
        .read<AuthProvider>()
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      AppToast.show(
        context,
        message: mapServerError(result['message']?.toString(), loc),
        kind: ToastKind.error,
      );
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    final loc = context.read<LocalizationProvider>();
    final result = await context.read<AuthProvider>().loginWithSocial(provider);

    if (!mounted) return;

    if (result['success'] == true) {
      AppToast.show(
        context,
        message: loc.isRtl
            ? 'بەسەرکەوتوویی چوویتە ژوورەوە! بەخێربێیت.'
            : 'Login successful! Welcome back to Awêna.',
        kind: ToastKind.success,
      );
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else if (result['message'] != 'Cancelled or failed.') {
      AppToast.show(
        context,
        message: mapServerError(result['message']?.toString(), loc),
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [
            _AnimatedBackdrop(controller: _bgCtrl),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),

                    // ─── Brand row ──────────────────────────────────
                    Row(
                      children: [
                        _BrandMark(ringCtrl: _ringCtrl)
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(
                              curve: Curves.elasticOut,
                              duration: 700.ms,
                              begin: const Offset(0.4, 0.4),
                            ),
                        const SizedBox(width: 12),
                        Text(
                          loc.tr('app_name'),
                          style: GoogleFonts.syne(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  AppColors.teal,
                                ],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 150, 30)),
                          ),
                        ).animate(delay: 150.ms).fadeIn(),
                      ],
                    ),

                    const SizedBox(height: 44),

                    // ─── Title ──────────────────────────────────────
                    Text(
                      loc.tr('login_title'),
                      style: GoogleFonts.syne(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.05,
                        letterSpacing: -1.2,
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2, curve: Curves.easeOut),

                    const SizedBox(height: 10),

                    Text(
                      loc.tr('login_subtitle'),
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ).animate(delay: 280.ms).fadeIn(),

                    const SizedBox(height: 36),

                    // ─── Email ──────────────────────────────────────
                    AppTextField(
                      controller: _emailCtrl,
                      focusNode: _emailFocus,
                      hint: loc.tr('login_email'),
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      errorText: _emailErr,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    )
                        .animate(delay: 350.ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.05),

                    const SizedBox(height: 14),

                    // ─── Password ───────────────────────────────────
                    AppTextField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      hint: loc.tr('login_password'),
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      errorText: _passwordErr,
                      onSubmitted: (_) => _handleLogin(),
                      suffixIcon: PasswordToggle(
                        obscured: _obscurePassword,
                        onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    )
                        .animate(delay: 420.ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.05),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          loc.tr('login_forgot'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate(delay: 480.ms).fadeIn(),

                    const SizedBox(height: 22),

                    // ─── Submit ─────────────────────────────────────
                    PrimaryButton(
                      label: loc.tr('login_button'),
                      icon: Icons.arrow_forward_rounded,
                      loading: _isLoading,
                      onTap: _handleLogin,
                    )
                        .animate(delay: 530.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.15),

                    const SizedBox(height: 26),

                    // ─── Divider ────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                AppColors.cardBorder,
                              ]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            loc.tr('login_or_continue'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppColors.cardBorder,
                                Colors.transparent,
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ).animate(delay: 580.ms).fadeIn(),

                    const SizedBox(height: 18),

                    // ─── Social ─────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            label: loc.tr('social_google'),
                            icon: Icons.g_mobiledata_rounded,
                            iconSize: 28,
                            onTap: () => _handleSocialLogin('google'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            label: loc.tr('social_facebook'),
                            icon: Icons.facebook_rounded,
                            iconSize: 22,
                            onTap: () => _handleSocialLogin('facebook'),
                          ),
                        ),
                      ],
                    ).animate(delay: 640.ms).fadeIn(),

                    const SizedBox(height: 32),

                    // ─── Switch to signup ───────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const SignupScreen(),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration:
                                const Duration(milliseconds: 400),
                          ),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: loc.tr('login_no_account'),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextSpan(
                                text: loc.tr('login_signup_link'),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate(delay: 700.ms).fadeIn(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Language pill (top-end) - Moved to end of Stack to receive events
            PositionedDirectional(
              top: 12,
              end: 16,
              child: SafeArea(
                child: _LanguagePill(
                  language: loc.language,
                  onTap: () => LanguagePicker.show(context),
                ).animate(delay: 200.ms).fadeIn(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══ Decorative Brand Mark ════════════════════════════════════════════════
class _BrandMark extends StatelessWidget {
  final AnimationController ringCtrl;
  const _BrandMark({required this.ringCtrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: ringCtrl,
            builder: (_, __) => Transform.rotate(
              angle: ringCtrl.value * 2 * math.pi,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
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
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bg,
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.sign_language_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══ Animated Backdrop ═══════════════════════════════════════════════════
class _AnimatedBackdrop extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBackdrop({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              top: -140 + math.sin(t) * 30,
              right: -80 + math.cos(t) * 20,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 60 + math.cos(t) * 30,
              left: -100 + math.sin(t * 1.3) * 30,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.teal.withOpacity(0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 220 + math.sin(t * 0.7) * 20,
              left: -50 + math.cos(t * 0.7) * 30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.pink.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══ Language Pill ═══════════════════════════════════════════════════════
class _LanguagePill extends StatelessWidget {
  final AppLanguage language;
  final VoidCallback onTap;
  const _LanguagePill({required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                language.shortCode,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══ Social Button ═══════════════════════════════════════════════════════
class _SocialButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconSize = 22,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  size: widget.iconSize, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
