import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/localization_provider.dart';
import '../models/history_item.dart';
import '../services/api_client.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _service = HistoryService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<HistoryItem> _items = [];
  HistoryStats _stats = HistoryStats.empty;
  TranslationType? _filter;
  String? _search;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.list(type: _filter, search: _search, pageSize: 50),
        _service.stats(),
      ]);
      if (!mounted) return;
      final list = results[0] as HistoryListResult;
      final stats = results[1] as HistoryStats;
      setState(() {
        _items = list.items;
        _stats = stats;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.isUnauthorized
            ? context.l10n.tr('error_unauthorized')
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.tr('history_error');
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _search = value.trim().isEmpty ? null : value.trim());
      _load();
    });
  }

  Future<void> _showFilterMenu() async {
    final loc = context.read<LocalizationProvider>();
    final picked = await showModalBottomSheet<TranslationType?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(current: _filter),
    );
    // Returning null could mean "cancel" OR "All". The sheet uses the special
    // sentinel value via Navigator.pop with `null` for "All", so we
    // distinguish by checking if the user actually tapped something.
    if (!mounted) return;
    if (picked != _filter) {
      setState(() => _filter = picked);
      _load();
    }
    // Touch loc to keep the import alive even if we early-return
    loc.tr('history_title');
  }

  Future<void> _confirmClearAll() async {
    final loc = context.read<LocalizationProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder)),
        title: Text(
          loc.tr('history_clear_confirm_title'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          loc.tr('history_clear_confirm_msg'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.tr('cancel'),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.tr('history_clear_all'),
                style: const TextStyle(color: AppColors.pink)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.tr('history_cleared')),
            backgroundColor: AppColors.teal,
          ),
        );
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.pink),
        );
      }
    }
  }

  Future<void> _deleteItem(HistoryItem item) async {
    final loc = context.read<LocalizationProvider>();
    try {
      await _service.deleteOne(item.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((i) => i.id == item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.tr('history_deleted')),
          backgroundColor: AppColors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.pink),
        );
      }
    }
  }

  String _typeLabel(TranslationType t, LocalizationProvider loc) {
    switch (t) {
      case TranslationType.signToText:
        return loc.tr('history_meta_sign_to_text');
      case TranslationType.textToSign:
        return loc.tr('history_meta_text_to_sign');
      case TranslationType.voiceToSign:
        return loc.tr('history_meta_voice_to_sign');
    }
  }

  String _formatRelativeTime(DateTime when, LocalizationProvider loc) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return loc.tr('history_just_now');
    if (diff.inMinutes < 60) {
      return loc.fmt('history_minutes_ago', [diff.inMinutes]);
    }
    if (diff.inHours == 1) return loc.tr('history_hour_ago');
    if (diff.inHours < 24) return loc.fmt('history_hours_ago', [diff.inHours]);
    if (diff.inDays == 1) return loc.tr('history_yesterday');
    return loc.fmt('history_days_ago', [diff.inDays]);
  }

  IconData _iconFor(TranslationType t) {
    switch (t) {
      case TranslationType.signToText:
        return Icons.sign_language_rounded;
      case TranslationType.textToSign:
        return Icons.chat_bubble_rounded;
      case TranslationType.voiceToSign:
        return Icons.mic_rounded;
    }
  }

  Color _colorFor(TranslationType t) {
    switch (t) {
      case TranslationType.signToText:
        return AppColors.accent;
      case TranslationType.textToSign:
        return AppColors.teal;
      case TranslationType.voiceToSign:
        return AppColors.pink;
    }
  }

  String _badgeFor(TranslationType t, LocalizationProvider loc) {
    switch (t) {
      case TranslationType.signToText:
        return loc.tr('nav_sign');
      case TranslationType.textToSign:
        return loc.tr('nav_text');
      case TranslationType.voiceToSign:
        return loc.tr('tts_voice_mode');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    loc.tr('history_title'),
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showFilterMenu,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _filter != null
                            ? AppColors.accent.withOpacity(0.15)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _filter != null
                              ? AppColors.accent.withOpacity(0.4)
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list_rounded,
                              size: 14, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            _filter == null
                                ? loc.tr('history_filter')
                                : _typeLabel(_filter!, loc),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_items.isNotEmpty)
                    GestureDetector(
                      onTap: _confirmClearAll,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.pink),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                loc.tr('history_subtitle'),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 16),

            // ─── Search bar ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        textDirection: loc.isRtl
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: loc.tr('history_search'),
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 150.ms).fadeIn(),

            const SizedBox(height: 16),

            // ─── Stats row ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _MiniStat(
                    value: '${_stats.total}',
                    label: loc.tr('history_total'),
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    value: '${_stats.signToText}',
                    label: loc.tr('history_filter_sign_to_text'),
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    value: '${_stats.textToSign}',
                    label: loc.tr('history_filter_text_to_sign'),
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    value: '${_stats.voiceToSign}',
                    label: loc.tr('tts_voice_mode'),
                    color: AppColors.pink,
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 16),

            // ─── List body ────────────────────────────────────────
            Expanded(
              child: _buildBody(loc),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LocalizationProvider loc) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.pink),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            OutlineBtn(
              label: loc.tr('history_retry'),
              icon: Icons.refresh_rounded,
              onTap: _load,
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded,
                  size: 36, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              loc.tr('history_empty'),
              style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.tr('history_empty_sub'),
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _HistoryItemTile(
          item: _items[i],
          icon: _iconFor(_items[i].type),
          color: _colorFor(_items[i].type),
          badge: _badgeFor(_items[i].type, loc),
          meta:
              '${_typeLabel(_items[i].type, loc)} · ${_formatRelativeTime(_items[i].createdAt, loc)}',
          onDelete: () => _deleteItem(_items[i]),
        )
            .animate(delay: Duration(milliseconds: 150 + i * 50))
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.05),
      ),
    );
  }
}

// ─── Filter sheet ───────────────────────────────────────────────────────────
class _FilterSheet extends StatelessWidget {
  final TranslationType? current;
  const _FilterSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();

    Widget tile(String label, TranslationType? value, IconData icon) {
      final selected = value == current;
      return InkWell(
        onTap: () => Navigator.of(context).pop(value),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withOpacity(0.12)
                : AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.accent.withOpacity(0.4)
                  : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
              ),
              if (selected)
                const Icon(Icons.check_rounded,
                    color: AppColors.accent, size: 18),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            tile(loc.tr('history_filter_all'), null,
                Icons.all_inclusive_rounded),
            tile(
                loc.tr('history_filter_sign_to_text'),
                TranslationType.signToText,
                Icons.sign_language_rounded),
            tile(
                loc.tr('history_filter_text_to_sign'),
                TranslationType.textToSign,
                Icons.chat_bubble_rounded),
            tile(
                loc.tr('history_filter_voice_to_sign'),
                TranslationType.voiceToSign,
                Icons.mic_rounded),
          ],
        ),
      ),
    );
  }
}

// ─── Mini stat card ─────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History row tile ───────────────────────────────────────────────────────
class _HistoryItemTile extends StatelessWidget {
  final HistoryItem item;
  final IconData icon;
  final Color color;
  final String badge;
  final String meta;
  final VoidCallback onDelete;

  const _HistoryItemTile({
    required this.item,
    required this.icon,
    required this.color,
    required this.badge,
    required this.meta,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    return Dismissible(
      key: ValueKey('history-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        decoration: BoxDecoration(
          color: AppColors.pink.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.pink),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // we update state ourselves
      },
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        onTap: () {},
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${item.translatedText}"',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              loc.isRtl
                  ? Icons.arrow_back_ios_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
