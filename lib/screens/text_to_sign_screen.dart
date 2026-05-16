import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/localization_provider.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Text-to-Sign screen.
///
/// IMPORTANT: The actual STT (speech-to-text) pipeline is left for you to
/// wire in manually. Implement [_startListening], [_stopListening], and call
/// [_onVoiceTranscribed] when your STT engine emits a final transcript.
/// History saving is already wired through [_pickSign] and [_translateText].
class TextToSignScreen extends StatefulWidget {
  const TextToSignScreen({super.key});

  @override
  State<TextToSignScreen> createState() => _TextToSignScreenState();
}

class _TextToSignScreenState extends State<TextToSignScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final HistoryService _history = HistoryService();

  bool _voiceMode = false;
  bool _listening = false;
  String _currentSign = '👋';
  String _currentSignLabel = 'Hello';

  late AnimationController _bounceCtrl;

  // Common signs grid. The label is always English (it's a glyph name);
  // the spoken word stays multilingual via the user's input.
  final List<Map<String, String>> _signs = const [
    {'emoji': '👋', 'label': 'Hello'},
    {'emoji': '👍', 'label': 'Yes'},
    {'emoji': '👎', 'label': 'No'},
    {'emoji': '🙏', 'label': 'Please'},
    {'emoji': '❤️', 'label': 'Love'},
    {'emoji': '🤟', 'label': 'ILY'},
    {'emoji': '✋', 'label': 'Stop'},
    {'emoji': '🤙', 'label': 'Call'},
  ];

  int _selectedSignIndex = 0;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ─── Speech-to-text lifecycle (YOU implement) ─────────────────────────────
  Future<void> _startListening() async {
    // TODO: integrate speech_to_text (or your engine) here.
    // When a final transcript arrives, call _onVoiceTranscribed(text).
  }

  Future<void> _stopListening() async {
    // TODO: stop your engine.
  }

  /// Hook your STT engine into this method.
  void _onVoiceTranscribed(String text) {
    if (!mounted) return;
    setState(() {
      _listening = false;
      _controller.text = text;
    });
    _translateText(text, isVoice: true);
  }

  // ─── Translation logic ─────────────────────────────────────────────────────
  void _pickSign(int index) {
    setState(() {
      _selectedSignIndex = index;
      _currentSign = _signs[index]['emoji']!;
      _currentSignLabel = _signs[index]['label']!;
    });
    _bounceCtrl.forward(from: 0);
    _saveToHistory(
      sourceText: _signs[index]['label']!,
      translated: _currentSign,
      type: TranslationType.textToSign,
    );
  }

  void _translateText(String text, {bool isVoice = false}) {
    if (text.trim().isEmpty) return;
    // The actual text→sign translation logic happens in your model.
    // For now we just bounce the current emoji as a placeholder.
    _bounceCtrl.forward(from: 0);
    _saveToHistory(
      sourceText: text,
      translated: _currentSign,
      type:
          isVoice ? TranslationType.voiceToSign : TranslationType.textToSign,
    );
  }

  Future<void> _saveToHistory({
    required String sourceText,
    required String translated,
    required TranslationType type,
  }) async {
    try {
      await _history.save(
        type: type,
        sourceText: sourceText,
        translatedText: translated,
      );
    } catch (_) {/* best-effort */}
  }

  Future<void> _toggleVoice() async {
    setState(() => _listening = !_listening);
    if (_listening) {
      await _startListening();
    } else {
      await _stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();

    // ─── Underlying screen content ────────────────────────────────────────────
    final Widget screenContent = Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ─── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(
                      loc.tr('tts_title'),
                      style: GoogleFonts.syne(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          _ToggleChip(
                            label: loc.tr('tts_type_mode'),
                            icon: Icons.keyboard_rounded,
                            active: !_voiceMode,
                            onTap: () => setState(() => _voiceMode = false),
                          ),
                          _ToggleChip(
                            label: loc.tr('tts_voice_mode'),
                            icon: Icons.mic_rounded,
                            active: _voiceMode,
                            onTap: () => setState(() => _voiceMode = true),
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
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    loc.tr('tts_subtitle'),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 16),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _voiceMode
                    ? _VoiceInput(
                        listening: _listening,
                        onToggle: _toggleVoice,
                      )
                    : _TextInput(
                        controller: _controller,
                        onSubmitted: (txt) => _translateText(txt),
                      ),
              ),

              const SizedBox(height: 14),

              // ─── Sign output ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  borderColor: AppColors.teal.withOpacity(0.3),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const LiveDot(color: AppColors.teal),
                          const SizedBox(width: 8),
                          Text(
                            loc.tr('tts_sign_output'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _bounceCtrl,
                        builder: (_, child) {
                          final curve = Curves.elasticOut.transform(
                            _bounceCtrl.value.clamp(0.0, 1.0),
                          );
                          return Transform.scale(
                            scale: 0.7 + curve * 0.3,
                            child: child,
                          );
                        },
                        child: Text(
                          _currentSign,
                          style: const TextStyle(fontSize: 60),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentSignLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlineBtn(
                              label: loc.tr('tts_share'),
                              icon: Icons.share_rounded,
                              color: AppColors.teal,
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GradientButton(
                              label: loc.tr('tts_animate'),
                              icon: Icons.play_arrow_rounded,
                              gradient: const LinearGradient(
                                colors: [AppColors.teal, AppColors.accent],
                              ),
                              onTap: () => _bounceCtrl.forward(from: 0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 14),

              // ─── Common signs grid ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('tts_common_signs'),
                      style: GoogleFonts.syne(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: _signs.length,
                      itemBuilder: (_, i) => _SignCell(
                        emoji: _signs[i]['emoji']!,
                        label: _signs[i]['label']!,
                        selected: _selectedSignIndex == i,
                        onTap: () => _pickSign(i),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    // ─── "Coming soon" overlay with blur ─────────────────────────────────────
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. The real screen (interactivity disabled while overlay is active)
          AbsorbPointer(child: screenContent),

          // 2. Full-screen blur & darken
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
            ),
          ),

          // 3. Centred availability card
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _ComingSoonCard(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Coming-soon overlay card ──────────────────────────────────────────────────
class _ComingSoonCard extends StatelessWidget {
  static const _url = 'https://text-to-sign-seven.vercel.app/';

  const _ComingSoonCard();

  Future<void> _openWebsite() async {
    final uri = Uri.parse(_url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.teal, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sign_language_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ).animate().scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 20),

              // Heading
              Text(
                'Coming Soon',
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 12),

              // Body message
              Text(
                'For now this feature is only available on our website at:',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.white.withOpacity(0.7),
                ),
              ).animate(delay: 180.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 8),

              Text(
                _url,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.teal,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ).animate(delay: 220.ms).fadeIn(),

              const SizedBox(height: 24),

              // CTA button
              GestureDetector(
                onTap: _openWebsite,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.teal, AppColors.accent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withOpacity(0.35),
                        blurRadius: 18,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.open_in_browser_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Click here to go to the website',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: 260.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.15, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 13,
                color: active ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  const _TextInput({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: TextField(
          controller: controller,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: onSubmitted,
          textDirection: loc.isRtl ? TextDirection.rtl : TextDirection.ltr,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            height: 1.6,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: loc.tr('tts_input_hint'),
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceInput extends StatelessWidget {
  final bool listening;
  final VoidCallback onToggle;

  const _VoiceInput({required this.listening, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: listening ? 1.08 : 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.pinkGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pink.withOpacity(listening ? 0.4 : 0.2),
                    blurRadius: listening ? 28 : 16,
                    spreadRadius: listening ? 4 : 0,
                  ),
                ],
              ),
              child: Icon(
                listening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          listening ? loc.tr('tts_listening') : loc.tr('tts_tap_speak'),
          style: TextStyle(
            fontSize: 13,
            color: listening ? AppColors.pink : AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SignCell extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SignCell({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.teal.withOpacity(0.1)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.teal.withOpacity(0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.teal : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
