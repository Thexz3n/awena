import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/localization_provider.dart';
import '../models/history_item.dart';
import '../providers/auth_provider.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/language_picker.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'sign_to_text_screen.dart';
import 'text_to_sign_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    _HomeTab(onSwitchTab: _switchTab),
    const SignToTextScreen(),
    const TextToSignScreen(),
    const HistoryScreen(),
  ];

  void _switchTab(int i) => setState(() => _currentIndex = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _switchTab,
      ),
    );
  }
}

// ─── Bottom Navigation ───────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: loc.tr('nav_home'),
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.sign_language_rounded,
              label: loc.tr('nav_sign'),
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavItem(
              icon: Icons.chat_bubble_rounded,
              label: loc.tr('nav_text'),
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: Icons.history_rounded,
              label: loc.tr('nav_history'),
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 20,
                color:
                    isActive ? AppColors.accent : AppColors.textMuted),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab Content ────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final ValueChanged<int> onSwitchTab;
  const _HomeTab({required this.onSwitchTab});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  HistoryStats _stats = HistoryStats.empty;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final s = await HistoryService().stats();
      if (!mounted) return;
      setState(() {
        _stats = s;
        _statsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _statsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    final user = context.watch<AuthProvider>().user;
    final greeting = user != null
        ? loc.fmt('home_hello', [user.firstName])
        : loc.tr('app_name');

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: _loadStats,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ─── Top bar ─────────────────────────────────────────
                    Row(
                      children: [
                        Text(
                          loc.tr('app_name'),
                          style: GoogleFonts.syne(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  AppColors.teal,
                                ],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 140, 30)),
                          ),
                        ),
                        const Spacer(),
                        // Language quick switch
                        GestureDetector(
                          onTap: () => LanguagePicker.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.language_rounded,
                                    size: 14, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  loc.language.shortCode,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Avatar → Profile
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.pinkGradient,
                            ),
                            child: Center(
                              child: Text(
                                user?.initial ?? 'S',
                                style: GoogleFonts.syne(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 28),

                    // ─── Greeting ───────────────────────────────────────────
                    Text(
                      greeting,
                      style: GoogleFonts.syne(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),

                    const SizedBox(height: 4),

                    Text(
                      loc.tr('home_what_translate'),
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ).animate(delay: 150.ms).fadeIn(),

                    const SizedBox(height: 24),

                    _ModeCard(
                      title: loc.tr('home_sign_to_text'),
                      subtitle: loc.tr('home_sign_to_text_sub'),
                      icon: Icons.sign_language_rounded,
                      gradientColors: const [
                        AppColors.accent,
                        Color(0xFF9E94FA)
                      ],
                      badge: loc.tr('home_badge_live'),
                      onTap: () => widget.onSwitchTab(1),
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

                    const SizedBox(height: 14),

                    _ModeCard(
                      title: loc.tr('home_text_to_sign'),
                      subtitle: loc.tr('home_text_to_sign_sub'),
                      icon: Icons.chat_bubble_outline_rounded,
                      gradientColors: const [
                        AppColors.teal,
                        Color(0xFF2ECC9E)
                      ],
                      badge: loc.tr('home_badge_both'),
                      onTap: () => widget.onSwitchTab(2),
                    ).animate(delay: 280.ms).fadeIn().slideY(begin: 0.2),

                    const SizedBox(height: 24),

                    // ─── Real stats ──────────────────────────────────────
                    Row(
                      children: [
                        StatCard(
                          value:
                              _statsLoading ? '…' : _stats.total.toString(),
                          label: loc.tr('home_signs_translated'),
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          value: _statsLoading
                              ? '…'
                              : _stats.sessionsThisMonth.toString(),
                          label: loc.tr('home_sessions_month'),
                          color: AppColors.teal,
                        ),
                      ],
                    ).animate(delay: 360.ms).fadeIn(),

                    const SizedBox(height: 24),

                    Text(
                      loc.tr('home_quick_actions'),
                      style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ).animate(delay: 420.ms).fadeIn(),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        _QuickBtn(
                          icon: Icons.history_rounded,
                          label: loc.tr('home_history'),
                          color: AppColors.accent,
                          onTap: () => widget.onSwitchTab(3),
                        ),
                        const SizedBox(width: 10),
                        _QuickBtn(
                          icon: Icons.language_rounded,
                          label: loc.tr('home_language'),
                          color: AppColors.teal,
                          onTap: () => LanguagePicker.show(context),
                        ),
                        const SizedBox(width: 10),
                        _QuickBtn(
                          icon: Icons.settings_rounded,
                          label: loc.tr('home_settings'),
                          color: AppColors.pink,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                        ),
                      ],
                    ).animate(delay: 460.ms).fadeIn(),

                    const SizedBox(height: 24),

                    const _TipCard().animate(delay: 520.ms).fadeIn(),

                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String badge;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.badge,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.first.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: GoogleFonts.syne(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                loc.isRtl
                    ? Icons.arrow_back_ios_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.15),
            AppColors.teal.withOpacity(0.1),
          ],
        ),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.15),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('home_pro_tip'),
                  style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  loc.tr('home_pro_tip_text'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
