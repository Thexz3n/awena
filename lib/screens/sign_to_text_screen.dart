import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
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
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  bool _isProcessingFrame = false;
  Timer? _frameTimer;
  final _history = HistoryService();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _pulseCtrl.dispose();
    _cameraController?.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    // Use front camera
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low, // Keep resolution low for faster transmission
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _startDetection() async {
    setState(() => _isRecording = true);
    _pulseCtrl.repeat(reverse: true);

    // ── Connect WebSocket ──────────────────────────────────────────
    // Port 8001 = gesture WebSocket server (main.py)
    // On mobile: replace localhost with your PC's local IP (e.g. 192.168.x.x)
    const wsUrl = String.fromEnvironment(
      'WS_URL',
      defaultValue: 'ws://localhost:8001/ws/recognize',
    );

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message as String);
          _pushDetectedText(
            data['gesture'] as String,
            (data['confidence'] as num).toDouble(),
          );
        },
        onError: (e) => debugPrint('WS error: $e'),
      );
    } catch (e) {
      debugPrint('WS connect failed: $e');
    }

    // ── Send frames every 200 ms (5 fps) ──────────────────────────
    // Uses takePicture() which works on BOTH mobile AND Flutter Web.
    // startImageStream() is NOT supported on Flutter Web.
    _frameTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _captureAndSend();
    });
  }

  Future<void> _captureAndSend() async {
    if (!_isRecording) return;
    if (_isProcessingFrame) return;
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_channel == null) return;

    _isProcessingFrame = true;
    try {
      final XFile file = await _cameraController!.takePicture();
      final List<int> bytes = await file.readAsBytes();
      final String base64Image = base64Encode(bytes);
      _channel!.sink.add(base64Image);
    } catch (e) {
      debugPrint('Frame capture error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _stopDetection() async {
    _frameTimer?.cancel();
    _frameTimer = null;
    setState(() => _isRecording = false);
    _pulseCtrl.stop();
    await _channel?.sink.close();
    _channel = null;
  }

  void _pushDetectedText(String newWord, double confidence) {
    setState(() {
      _translatedText += ' $newWord';
      _confidence = confidence;
    });
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
    if (_isRecording) {
      await _stopDetection();
      await _saveToHistory(_translatedText, _confidence);
    } else {
      setState(() {
        _translatedText = '';
        _confidence = 0.0;
      });
      await _startDetection();
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

  Future<void> _speakOutLoud(String text) async {
    // TODO: wire up flutter_tts or platform TTS
    debugPrint('Speak: $text');
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_isRecording ? AppColors.teal : AppColors.accent)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            (_isRecording ? AppColors.teal : AppColors.accent)
                                .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LiveDot(
                          color:
                              _isRecording ? AppColors.teal : AppColors.accent,
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

            // ─── Camera preview ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                padding: EdgeInsets.zero,
                borderRadius: 24,
                borderColor: (_isRecording ? AppColors.teal : AppColors.accent)
                    .withOpacity(0.35),
                child: GestureDetector(
                  onTap: _toggleRecording,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: 200,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // ── Real camera feed ──────────────────────
                          if (_cameraController != null &&
                              _cameraController!.value.isInitialized)
                            CameraPreview(_cameraController!)
                          else
                            // ── Loading / placeholder ─────────────
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.accent.withOpacity(0.06),
                                    AppColors.surface,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: AppColors.accent,
                                      strokeWidth: 2,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      loc.tr('stt_camera_active'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── Scan line overlay while recording ─────
                          if (_isRecording) const ScanLineAnimation(),

                          // ── Corner brackets ───────────────────────
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: CornerBrackets(
                              color: _isRecording
                                  ? AppColors.teal
                                  : AppColors.accent,
                            ),
                          ),

                          // ── Tap-to-start hint (shown when not recording) ──
                          if (!_isRecording &&
                              _cameraController != null &&
                              _cameraController!.value.isInitialized)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.fiber_manual_record,
                                        color: AppColors.accent, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      loc.tr('stt_tap_start'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── Confidence badge ──────────────────────
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
                            loc.language.shortCode,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 70,
                        child: _translatedText.isEmpty
                            ? Center(
                                child: Text(
                                  loc.tr('stt_waiting'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textMuted.withOpacity(0.5),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : Text(
                                _translatedText,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.syne(
                                  fontSize: 16,
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
              _isRecording ? loc.tr('stt_tap_stop') : loc.tr('stt_tap_start'),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
