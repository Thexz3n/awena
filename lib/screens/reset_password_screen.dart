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
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? prefilledToken;
  const ResetPasswordScreen({super.key, this.prefilledToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _tokenCtrl;
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _tokenFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();
  late final AnimationController _bgCtrl;

  bool _o1 = true, _o2 = true;
  bool _loading = false;
  bool _submitted = false;
  String? _tokenErr;
  String? _newErr;
  String? _confirmErr;

  final _service = AuthService();

  @override
  void initState() {
    super.initState();
    _tokenCtrl = TextEditingController(text: widget.prefilledToken ?? '');
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _tokenCtrl.addListener(() {
      if (!_submitted) return;
      final loc = context.read<LocalizationProvider>();
      setState(() => _tokenErr = Validators.token(_tokenCtrl.text, loc));
    });
    _newCtrl.addListener(() {
      if (!_submitted) return;
      final loc = context.read<LocalizationProvider>();
      setState(() {
        _newErr = Validators.password(_newCtrl.text, loc, strict: true);
        _confirmErr = Validators.confirmPassword(
            _confirmCtrl.text, _newCtrl.text, loc);
      });
    });
    _confirmCtrl.addListener(() {
      if (!_submitted) return;
      final loc = context.read<LocalizationProvider>();
      setState(() => _confirmErr = Validators.confirmPassword(
          _confirmCtrl.text, _newCtrl.text, loc));
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _tokenCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _tokenFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = context.read<LocalizationProvider>();
    final tokenErr = Validators.token(_tokenCtrl.text, loc);
    final newErr = Validators.password(_newCtrl.text, loc, strict: true);
    final confirmErr = Validators.confirmPassword(
        _confirmCtrl.text, _newCtrl.text, loc);

    setState(() {
      _submitted = true;
      _tokenErr = tokenErr;
      _newErr = newErr;
      _confirmErr = confirmErr;
    });

    if (tokenErr != null) {
      _tokenFocus.requestFocus();
      return;
    }
    if (newErr != null) {
      _newFocus.requestFocus();
      return;
    }
    if (confirmErr != null) {
      _confirmFocus.requestFocus();
      return;
    }

    setState(() => _loading = true);
    final result = await _service.resetPassword(
      token: _tokenCtrl.text.trim(),
      newPassword: _newCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      AppToast.show(
        context,
        message: loc.tr('rp_success'),
        kind: ToastKind.success,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } else {
      AppToast.show(
        context,
        message:
            (result['message'] as String?) ?? loc.tr('rp_invalid'),
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
            _ResetBackdrop(controller: _bgCtrl),
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
                        icon: Icons.shield_outlined,
                        color: AppColors.teal,
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
                      loc.tr('rp_title'),
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
                      loc.tr('rp_subtitle'),
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ).animate(delay: 280.ms).fadeIn(),

                    const SizedBox(height: 32),

                    AppTextField(
                      controller: _tokenCtrl,
                      focusNode: _tokenFocus,
                      hint: loc.tr('rp_token'),
                      icon: Icons.vpn_key_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      errorText: _tokenErr,
                      onSubmitted: (_) => _newFocus.requestFocus(),
                    ).animate(delay: 350.ms).fadeIn().slideX(begin: -0.05),

                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _newCtrl,
                      focusNode: _newFocus,
                      hint: loc.tr('rp_new'),
                      icon: Icons.lock_outline_rounded,
                      obscureText: _o1,
                      textInputAction: TextInputAction.next,
                      errorText: _newErr,
                      onSubmitted: (_) => _confirmFocus.requestFocus(),
                      suffixIcon: PasswordToggle(
                        obscured: _o1,
                        onTap: () => setState(() => _o1 = !_o1),
                      ),
                    ).animate(delay: 400.ms).fadeIn().slideX(begin: -0.05),

                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _confirmCtrl,
                      focusNode: _confirmFocus,
                      hint: loc.tr('rp_confirm'),
                      icon: Icons.lock_outline_rounded,
                      obscureText: _o2,
                      textInputAction: TextInputAction.done,
                      errorText: _confirmErr,
                      onSubmitted: (_) => _submit(),
                      suffixIcon: PasswordToggle(
                        obscured: _o2,
                        onTap: () => setState(() => _o2 = !_o2),
                      ),
                    ).animate(delay: 450.ms).fadeIn().slideX(begin: -0.05),

                    const SizedBox(height: 28),

                    PrimaryButton(
                      label: loc.tr('rp_submit'),
                      icon: Icons.check_rounded,
                      loading: _loading,
                      gradient: const LinearGradient(
                        colors: [AppColors.teal, AppColors.accent],
                      ),
                      onTap: _submit,
                    )
                        .animate(delay: 520.ms)
                        .fadeIn()
                        .slideY(begin: 0.15),
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

class _ResetBackdrop extends StatelessWidget {
  final AnimationController controller;
  const _ResetBackdrop({required this.controller});

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
              left: -100 + math.cos(t) * 20,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.teal.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100 + math.cos(t) * 30,
              right: -80 + math.sin(t * 1.3) * 20,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.12),
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
