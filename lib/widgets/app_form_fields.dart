import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// A polished input field with inline validation, focus glow, and a leading icon.
///
/// Design notes:
/// - Border subtly glows in accent color on focus.
/// - When [errorText] is non-null, the border becomes pink and a small inline
///   message appears below with a slide-in animation.
/// - Optional [suffixIcon] (commonly the password visibility toggle).
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String? errorText;
  final String? helperText;
  final bool autofocus;
  final bool readOnly;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.errorText,
    this.helperText,
    this.autofocus = false,
    this.readOnly = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final Color borderColor;
    if (hasError) {
      borderColor = AppColors.pink.withOpacity(0.7);
    } else if (_focused) {
      borderColor = AppColors.accent.withOpacity(0.7);
    } else {
      borderColor = AppColors.cardBorder;
    }

    final Color iconColor;
    if (hasError) {
      iconColor = AppColors.pink;
    } else if (_focused) {
      iconColor = AppColors.accent;
    } else {
      iconColor = AppColors.textMuted;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: (_focused || hasError) ? 1.5 : 1,
              ),
              boxShadow: [
                if (_focused && !hasError)
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.10),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                if (hasError)
                  BoxShadow(
                    color: AppColors.pink.withOpacity(0.08),
                    blurRadius: 12,
                  ),
              ],
            ),
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 14, vertical: 2),
            child: Row(
              children: [
                Icon(widget.icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    onSubmitted: widget.onSubmitted,
                    onChanged: widget.onChanged,
                    autofocus: widget.autofocus,
                    readOnly: widget.readOnly,
                    cursorColor: AppColors.accent,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16),
                      isDense: false,
                    ),
                  ),
                ),
                if (widget.suffixIcon != null) widget.suffixIcon!,
              ],
            ),
          ),
        ),
        // Inline error / helper text
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: hasError
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 4, top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 13, color: AppColors.pink),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.errorText!,
                          style: const TextStyle(
                            color: AppColors.pink,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 180.ms).slideY(
                    begin: -0.3, duration: 180.ms, curve: Curves.easeOut)
              : (widget.helperText != null
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(
                          start: 4, top: 6),
                      child: Text(
                        widget.helperText!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
        ),
      ],
    );
  }
}

/// Polished password visibility toggle for use as a suffix icon.
class PasswordToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onTap;
  const PasswordToggle({
    super.key,
    required this.obscured,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            obscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            key: ValueKey(obscured),
            color: AppColors.textMuted,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Polished toast overlay, used for server-side errors and successes.
/// Slides down from the top, auto-dismisses, and can be tapped to dismiss.
class AppToast {
  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    ToastKind kind = ToastKind.error,
    Duration duration = const Duration(seconds: 4),
  }) {
    _dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        kind: kind,
        onDismiss: _dismiss,
      ),
    );
    _current = entry;
    overlay.insert(entry);

    Future.delayed(duration, () {
      if (_current == entry) _dismiss();
    });
  }

  static void _dismiss() {
    _current?.remove();
    _current = null;
  }
}

enum ToastKind { error, success, info }

class _ToastView extends StatefulWidget {
  final String message;
  final ToastKind kind;
  final VoidCallback onDismiss;
  const _ToastView({
    required this.message,
    required this.kind,
    required this.onDismiss,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _slide = Tween(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (widget.kind) {
      case ToastKind.success:
        color = AppColors.teal;
        icon = Icons.check_circle_outline_rounded;
        break;
      case ToastKind.info:
        color = AppColors.accent;
        icon = Icons.info_outline_rounded;
        break;
      case ToastKind.error:
        color = AppColors.pink;
        icon = Icons.error_outline_rounded;
        break;
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary call-to-action button with built-in loading state. The shimmer +
/// scale press effect makes the button feel substantial; while [loading] is
/// true it shows a centered spinner and ignores taps.
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool loading;
  final Gradient gradient;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
    this.gradient = AppColors.accentGradient,
    this.height = 56,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.loading ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.loading
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(widget.loading ? 0.18 : 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: widget.loading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        if (widget.icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(widget.icon, color: Colors.white, size: 18),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny dot used in animated brand markers etc.
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulseDot({super.key, required this.color, this.size = 8});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4 + _ctrl.value * 0.4),
                blurRadius: 8 + _ctrl.value * 6,
                spreadRadius: _ctrl.value * 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
