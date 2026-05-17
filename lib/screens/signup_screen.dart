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
import 'home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  bool _submitted = false;
  String? _nameErr;
  String? _emailErr;
  String? _passwordErr;
  String? _confirmErr;
  String? _termsErr;

  int _passwordStrength = 0;
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _nameCtrl.addListener(_revalidateName);
    _emailCtrl.addListener(_revalidateEmail);
    _passwordCtrl.addListener(() {
      _calcStrength();
      _revalidatePassword();
      _revalidateConfirm();
    });
    _confirmCtrl.addListener(_revalidateConfirm);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _calcStrength() {
    final v = _passwordCtrl.text;
    int s = 0;
    if (v.length >= 6) s += 2;
    if (v.length >= 10) s += 2;
    if (RegExp(r'[A-Z]').hasMatch(v)) s += 1;
    if (RegExp(r'[0-9]').hasMatch(v)) s += 1;
    if (RegExp(r'[!@#\$%^&*()_+\-=\[\]{};\x27:"\\|,.<>\/?]').hasMatch(v)) {
      s += 2;
    }
    setState(() => _passwordStrength = s);
  }

  void _revalidateName() {
    if (!_submitted) return;
    final loc = context.read<LocalizationProvider>();
    setState(() => _nameErr = Validators.name(_nameCtrl.text, loc));
  }

  void _revalidateEmail() {
    if (!_submitted) return;
    final loc = context.read<LocalizationProvider>();
    setState(() => _emailErr = Validators.email(_emailCtrl.text, loc));
  }

  void _revalidatePassword() {
    if (!_submitted) return;
    final loc = context.read<LocalizationProvider>();
    setState(() => _passwordErr =
        Validators.password(_passwordCtrl.text, loc, strict: true));
  }

  void _revalidateConfirm() {
    if (!_submitted) return;
    final loc = context.read<LocalizationProvider>();
    setState(() => _confirmErr = Validators.confirmPassword(
        _confirmCtrl.text, _passwordCtrl.text, loc));
  }

  Future<void> _handleSignUp() async {
    final loc = context.read<LocalizationProvider>();
    final nameErr = Validators.name(_nameCtrl.text, loc);
    final emailErr = Validators.email(_emailCtrl.text, loc);
    final pwErr = Validators.password(_passwordCtrl.text, loc, strict: true);
    final confirmErr = Validators.confirmPassword(
        _confirmCtrl.text, _passwordCtrl.text, loc);
    final termsErr =
        _agreedToTerms ? null : loc.tr('signup_terms_required');

    setState(() {
      _submitted = true;
      _nameErr = nameErr;
      _emailErr = emailErr;
      _passwordErr = pwErr;
      _confirmErr = confirmErr;
      _termsErr = termsErr;
    });

    if (nameErr != null) {
      _nameFocus.requestFocus();
      return;
    }
    if (emailErr != null) {
      _emailFocus.requestFocus();
      return;
    }
    if (pwErr != null) {
      _passwordFocus.requestFocus();
      return;
    }
    if (confirmErr != null) {
      _confirmFocus.requestFocus();
      return;
    }
    if (termsErr != null) {
      AppToast.show(context, message: termsErr, kind: ToastKind.error);
      return;
    }

    setState(() => _isLoading = true);
    final result = await context.read<AuthProvider>().signup(
          _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.teal,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  loc.tr('confirm'),
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            content: Text(
              loc.tr('signup_success'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const LoginScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                },
                child: Text(
                  loc.tr('ok'),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
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
            _SignupBackdrop(controller: _bgCtrl),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(24, 70, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Avatar ────────────────────────────────────
                    Center(
                      child: const _AvatarMark()
                          .animate()
                          .scale(
                            duration: 700.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.4, 0.4),
                          )
                          .fadeIn(),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      loc.tr('signup_title'),
                      style: GoogleFonts.syne(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.05,
                        letterSpacing: -1.2,
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2),

                    const SizedBox(height: 10),

                    Text(
                      loc.tr('signup_subtitle'),
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ).animate(delay: 280.ms).fadeIn(),

                    const SizedBox(height: 32),

                    // ─── Name ──────────────────────────────────────
                    AppTextField(
                      controller: _nameCtrl,
                      focusNode: _nameFocus,
                      hint: loc.tr('signup_name'),
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      errorText: _nameErr,
                      onSubmitted: (_) => _emailFocus.requestFocus(),
                    )
                        .animate(delay: 350.ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.05),

                    const SizedBox(height: 14),

                    // ─── Email ─────────────────────────────────────
                    AppTextField(
                      controller: _emailCtrl,
                      focusNode: _emailFocus,
                      hint: loc.tr('signup_email'),
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      errorText: _emailErr,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    )
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.05),

                    const SizedBox(height: 14),

                    // ─── Password + strength ───────────────────────
                    AppTextField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      hint: loc.tr('signup_password'),
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      errorText: _passwordErr,
                      onSubmitted: (_) => _confirmFocus.requestFocus(),
                      suffixIcon: PasswordToggle(
                        obscured: _obscurePassword,
                        onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    )
                        .animate(delay: 450.ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.05),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: _passwordCtrl.text.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: _StrengthMeter(
                                  strength: _passwordStrength),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 14),

                    // ─── Confirm ───────────────────────────────────
                    AppTextField(
                      controller: _confirmCtrl,
                      focusNode: _confirmFocus,
                      hint: loc.tr('signup_confirm'),
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      errorText: _confirmErr,
                      onSubmitted: (_) => _handleSignUp(),
                      suffixIcon: PasswordToggle(
                        obscured: _obscureConfirm,
                        onTap: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    )
                        .animate(delay: 500.ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.05),

                    const SizedBox(height: 22),

                    // ─── Terms ─────────────────────────────────────
                    InkWell(
                      onTap: () => setState(
                          () => _agreedToTerms = !_agreedToTerms),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _agreedToTerms
                                    ? AppColors.accent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _termsErr != null
                                      ? AppColors.pink
                                      : (_agreedToTerms
                                          ? AppColors.accent
                                          : AppColors.cardBorder),
                                  width: 1.5,
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration:
                                    const Duration(milliseconds: 180),
                                child: _agreedToTerms
                                    ? const Icon(Icons.check_rounded,
                                        key: ValueKey(true),
                                        color: Colors.white,
                                        size: 14)
                                    : const SizedBox(key: ValueKey(false)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: loc.tr('signup_terms_prefix'),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                        height: 1.5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: loc.tr('signup_terms'),
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: loc.tr('signup_terms_and'),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: loc.tr('signup_privacy'),
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: 550.ms).fadeIn(),

                    const SizedBox(height: 24),

                    // ─── Submit ────────────────────────────────────
                    PrimaryButton(
                      label: loc.tr('signup_button'),
                      icon: Icons.arrow_forward_rounded,
                      loading: _isLoading,
                      onTap: _handleSignUp,
                    )
                        .animate(delay: 600.ms)
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
                            loc.tr('login_or_continue'), // Reusing the 'OR' translation
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
                    ).animate(delay: 650.ms).fadeIn(),

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
                    ).animate(delay: 700.ms).fadeIn(),

                    const SizedBox(height: 32),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const LoginScreen(),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                          ),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: loc.tr('signup_have_account'),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: loc.tr('signup_login_link'),
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
                  ],
                ),
              ),
            ),

            // Top bar — back + language pill - Moved to end to receive events
            PositionedDirectional(
              top: 12,
              start: 16,
              end: 16,
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        loc.isRtl
                            ? Icons.arrow_forward_ios_rounded
                            : Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.card.withOpacity(0.7),
                        padding: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const Spacer(),
                    _LanguagePill(
                      language: loc.language,
                      onTap: () => LanguagePicker.show(context),
                    ).animate(delay: 200.ms).fadeIn(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══ Avatar Mark ═══════════════════════════════════════════════════════
class _AvatarMark extends StatelessWidget {
  const _AvatarMark();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.accentGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.4),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.teal.withOpacity(0.15),
                blurRadius: 28,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 52,
            color: Colors.white,
          ),
        ),
        PositionedDirectional(
          bottom: 0,
          end: 0,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.teal,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bg, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══ Strength Meter ════════════════════════════════════════════════════
class _StrengthMeter extends StatelessWidget {
  final int strength; // 0–8
  const _StrengthMeter({required this.strength});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    final pct = (strength / 8.0).clamp(0.0, 1.0);

    Color color;
    String label;
    if (strength <= 2) {
      color = AppColors.pink;
      label = loc.tr('signup_pwd_weak');
    } else if (strength <= 4) {
      color = AppColors.amber;
      label = loc.tr('signup_pwd_fair');
    } else {
      color = AppColors.teal;
      label = loc.tr('signup_pwd_strong');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = strength > i * 2;
            return Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: i < 3 ? 4 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled ? color : AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          child: Text(label),
        ),
      ],
    );
  }
}

// ═══ Animated Backdrop ═══════════════════════════════════════════════════
class _SignupBackdrop extends StatelessWidget {
  final AnimationController controller;
  const _SignupBackdrop({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              top: -100 + math.sin(t) * 30,
              left: -80 + math.cos(t) * 20,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.teal.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80 + math.cos(t) * 30,
              right: -100 + math.sin(t * 1.3) * 30,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.15),
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
