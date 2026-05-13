import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/localization_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _o1 = true, _o2 = true, _o3 = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = context.read<LocalizationProvider>();
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.tr('signup_fill_all')),
        backgroundColor: AppColors.pink,
      ));
      return;
    }
    if (next != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.tr('cp_mismatch')),
        backgroundColor: AppColors.pink,
      ));
      return;
    }
    if (next == current) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.tr('cp_same')),
        backgroundColor: AppColors.pink,
      ));
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().changePassword(
            currentPassword: current,
            newPassword: next,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.tr('cp_success')),
        backgroundColor: AppColors.teal,
      ));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppColors.pink,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.tr('error_generic')),
        backgroundColor: AppColors.pink,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(title: loc.tr('cp_title'))
                    .animate()
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 32),
                _PasswordField(
                  controller: _currentCtrl,
                  hint: loc.tr('cp_current'),
                  obscure: _o1,
                  onToggle: () => setState(() => _o1 = !_o1),
                ).animate(delay: 150.ms).fadeIn().slideX(begin: -0.05),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _newCtrl,
                  hint: loc.tr('cp_new'),
                  obscure: _o2,
                  onToggle: () => setState(() => _o2 = !_o2),
                ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.05),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _confirmCtrl,
                  hint: loc.tr('cp_confirm'),
                  obscure: _o3,
                  onToggle: () => setState(() => _o3 = !_o3),
                ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.05),
                const SizedBox(height: 32),
                _loading
                    ? Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                    : GradientButton(
                        label: loc.tr('cp_submit'),
                        icon: Icons.check_rounded,
                        onTap: _submit,
                      ).animate(delay: 320.ms).fadeIn().slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    return Row(
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
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.syne(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
