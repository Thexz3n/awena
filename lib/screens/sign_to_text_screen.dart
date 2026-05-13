import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/localization_provider.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Sign-to-Text screen.
///
/// IMPORTANT: The actual sign-detection pipeline (camera + ML model) is left
/// for you to wire in manually. This screen exposes a clean integration
/// surface — implement the TODOs in [_startDetection], [_stopDetection], and
/// [_speakOutLoud], and call [_pushDetectedText] every time your model emits a
/// new translation. History saving and clipboard are already wired.
class SignToTextScreen extends StatefulWidget {
  const SignToTextScreen({super.key});

  @override
  State<SignToTextScreen> createState() => _SignToTextScreenState();
}

class _SignToTextScreenState extends State<SignToTextScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  String _translatedText = '';
  double _confidence = 0.0;

  late AnimationController _pulseCtrl;
  final HistoryService _history = HistoryService();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─── Detection lifecycle (YOU implement these) ────────────────────────────
  Future<void> _startDetection() async {
    // TODO: open camera, load ML model, start frame stream.
    // When the model emits a translated sentence, call _pushDetectedText().
  }

  Future<void> _stopDetection() async {
    // TODO: tear down camera and model.
  }

  Future<void> _speakOutLoud(String text) async {
    // TODO: integrate flutter_tts (or your preferred engine) here.
  }

  /// Hook your sign-detection model into this method.
  /// It writes to the UI AND saves the entry to the backend.
  void _pushDetectedText(String text, {double? confidence}) {
    if (!mounted) return;
    setState(() {
      _translatedText = text;
      if (confidence != null) _confidence = confidence;
    });
    _saveToHistory(text, confidence);
  }

  Future<void> _saveToHistory(String text, double? confidence) async {
    if (text.trim().isEmpty) return;
    try {
      await _history.save(
        type: TranslationType.signToText,
        translatedText: text,
        confidence: confidence,
      );
    } catch (_) {
      // History saving is best-effort; never block translation UX on it.
    }
  }

  // ─── Toggle ────────────────────────────────────────────────────────────────
  Future<void> _toggleRecording() async {
    setState(() => _isRecording = !_isRecording);
    if (_isRecording) {
      setState(() {
        _translatedText = '';
        _confidence = 0.0;
      });
      await _startDetection();
    } else {
      await _stopDetection();
    }
  }

  Future<void> _copyText() async {
    if (_translatedText.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _translatedText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.l10n.tr('stt_copied')),
      backgroundColor: AppColors.teal,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    loc.tr('stt_title'),
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_isRecording ? AppColors.teal : AppColors.accent)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (_isRecording
                                ? AppColors.teal
                                : AppColors.accent)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LiveDot(
                          color: _isRecording
                              ? AppColors.teal
                              : AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isRecording
                              ? loc.tr('stt_recording')
                              : loc.tr('stt_standby'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _isRecording
                                ? AppColors.teal
                                : AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                loc.tr('stt_subtitle'),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 16),

            // ─── Camera preview placeholder ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                padding: EdgeInsets.zero,
                borderRadius: 24,
                borderColor: AppColors.accent.withOpacity(0.3),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: AppColors.surface,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: RadialGradient(
                            colors: [
                              AppColors.accent.withOpacity(0.05),
                              AppColors.surface,
                            ],
                          ),
                        ),
                      ),
                      if (_isRecording) const ScanLineAnimation(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: CornerBrackets(
                          color: _isRecording
                              ? AppColors.teal
                              : AppColors.accent,
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (_, __) => Transform.scale(
                                scale: _isRecording
                                    ? 1.0 + _pulseCtrl.value * 0.08
                                    : 1.0,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accent.withOpacity(0.12),
                                    border: Border.all(
                                      color:
                                          AppColors.accent.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.sign_language_rounded,
                                    color: AppColors.accent,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isRecording
                                  ? loc.tr('stt_detecting')
                                  : loc.tr('stt_camera_active'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isRecording && _confidence > 0)
                        PositionedDirectional(
                          top: 14,
                          end: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.teal.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.analytics_rounded,
                                    size: 12, color: AppColors.teal),
                                const SizedBox(width: 4),
                                Text(
                                  '${(_confidence * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms),
                        ),
                    ],
                  ),
                ),
              ),
            ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            // ─── Translation output ────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const LiveDot(color: AppColors.teal),
                          const SizedBox(width: 8),
                          Text(
                            loc.tr('stt_live_translation'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            loc.language.code.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: _translatedText.isEmpty
                            ? Center(
                                child: Text(
                                  loc.tr('stt_waiting'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color:
                                        AppColors.textMuted.withOpacity(0.5),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : Text(
                                _translatedText,
                                style: GoogleFonts.syne(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ).animate().fadeIn(duration: 300.ms),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Action buttons ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlineBtn(
                      label: loc.tr('stt_copy'),
                      icon: Icons.copy_rounded,
                      onTap: _copyText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      label: loc.tr('stt_speak'),
                      icon: Icons.volume_up_rounded,
                      onTap: () => _speakOutLoud(_translatedText),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Record button ────────────────────────────────
            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isRecording
                        ? AppColors.pinkGradient
                        : AppColors.accentGradient,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isRecording ? AppColors.pink : AppColors.accent)
                                .withOpacity(0.3 + _pulseCtrl.value * 0.15),
                        blurRadius: 20 + _pulseCtrl.value * 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording
                        ? Icons.stop_rounded
                        : Icons.fiber_manual_record_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _isRecording
                  ? loc.tr('stt_tap_stop')
                  : loc.tr('stt_tap_start'),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
