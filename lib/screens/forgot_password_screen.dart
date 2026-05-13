import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/localization_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_form_fields.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _service = AuthService();
  late final AnimationController _bgCtrl;

  bool _loading = false;
  bool _submitted = false;
  String? _emailErr;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    _emailCtrl.addListener(() {
      if (!_submitted) return;
      final loc = context.read<LocalizationProvider>();
      setState(() => _emailErr = Validators.email(_emailCtrl.text, loc));
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _emailCtrl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = context.read<LocalizationProvider>();
    final emailErr = Validators.email(_emailCtrl.text, loc);

    setState(() {
      _submitted = true;
      _emailErr = emailErr;
    });
    if (emailErr != null) {
      _emailFocus.requestFocus();
      return;
    }

    setState(() => _loading = true);
    final result = await _service.forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);

    AppToast.show(
      context,
      message: (result['message'] as String?) ?? loc.tr('fp_check_email'),
      kind: ToastKind.success,
    );

    // DEBUG-mode token shortcut.
    final token = result['reset_token'] as String?;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(prefilledToken: token),
      ),
    );
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
            _RecoveryBackdrop(controller: _bgCtrl),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BackButton(loc: loc)
                        .animate()
                        .fadeIn(duration: 300.ms),
                    const SizedBox(height: 36),

                    Center(
                      child: const _RecoveryIcon(
                        icon: Icons.lock_reset_rounded,
                        color: AppColors.accent,
                      )
                          .animate()
                          .scale(
                            curve: Curves.elasticOut,
                            duration: 700.ms,
                            begin: const Offset(0.4, 0.4),
                          )
                          .fadeIn(),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      loc.tr('fp_title'),
                      style: GoogleFonts.syne(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.1,
                        letterSpacing: -0.8,
                      ),
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

                    const SizedBox(height: 10),

                    Text(
                      loc.tr('fp_subtitle'),
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ).animate(delay: 280.ms).fadeIn(),

                    const SizedBox(height: 32),

                    AppTextField(
                      controller: _emailCtrl,
                      focusNode: _emailFocus,
                      hint: loc.tr('fp_email'),
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      errorText: _emailErr,
                      onSubmitted: (_) => _submit(),
                    ).animate(delay: 350.ms).fadeIn().slideX(begin: -0.05),

                    const SizedBox(height: 28),

                    PrimaryButton(
                      label: loc.tr('fp_submit'),
                      icon: Icons.send_rounded,
                      loading: _loading,
                      onTap: _submit,
                    )
                        .animate(delay: 420.ms)
                        .fadeIn()
                        .slideY(begin: 0.15),

                    const SizedBox(height: 18),

                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ResetPasswordScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.vpn_key_outlined,
                            size: 14, color: AppColors.accent),
                        label: Text(
                          loc.tr('fp_have_token'),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate(delay: 500.ms).fadeIn(),
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

class _BackButton extends StatelessWidget {
  final LocalizationProvider loc;
  const _BackButton({required this.loc});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.7),
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
    );
  }
}

class _RecoveryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _RecoveryIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
        ),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, size: 40, color: color),
    );
  }
}

class _RecoveryBackdrop extends StatelessWidget {
  final AnimationController controller;
  const _RecoveryBackdrop({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              top: -80 + math.sin(t) * 20,
              right: -100 + math.cos(t) * 20,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120 + math.cos(t) * 30,
              left: -80 + math.sin(t * 1.3) * 20,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.teal.withOpacity(0.1),
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
