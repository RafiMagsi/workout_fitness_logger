import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app.dart';

/// App shell: ambient background glows, the branch navigator, and a floating
/// "liquid glass" tab bar with a center Log action (the 2026 multi-tab
/// pattern — translucent, blurred, pill-shaped, icon-first).
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBody: true,
      body: Stack(
        children: [
          const _AmbientBackground(),
          navigationShell,
        ],
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          _GlassTabBar(
            currentIndex: navigationShell.currentIndex,
            onSelected: _go,
          ),
          Positioned(
            top: -18,
            child: LogButton(onTap: () => context.push('/log')),
          ),
        ],
      ),
    );
  }
}

/// Soft drifting color fields behind the UI — modern dark apps light the
/// canvas instead of using flat black.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _AmbientPainter(),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void glow(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    glow(Offset(size.width * 0.15, -size.height * 0.02), size.width * 0.9,
        AppTheme.move.withValues(alpha: 0.10));
    glow(Offset(size.width * 0.95, size.height * 0.12), size.width * 0.7,
        AppTheme.accent.withValues(alpha: 0.08));
    glow(Offset(size.width * 0.5, size.height * 1.02), size.width * 1.1,
        AppTheme.stand.withValues(alpha: 0.05));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const _GlassTabBar({
    required this.currentIndex,
    required this.onSelected,
  });

  static const _tabs = [
    _TabData(Icons.grid_view_rounded, 'Summary'),
    _TabData(Icons.trending_up_rounded, 'Trends'),
    _TabData(Icons.emoji_events_rounded, 'Awards'),
    _TabData(Icons.event_note_rounded, 'History'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++) ...[
                  // Center gap for the Log button: with four tabs (two on
                  // each side) this lands the gap at the true horizontal
                  // center of the bar.
                  if (i == 2) const SizedBox(width: 76),
                  Expanded(
                    child: _TabButton(
                      data: _tabs[i],
                      selected: i == currentIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final _TabData data;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.textPrimary : AppTheme.textTertiary;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.icon,
              size: 20,
              color: selected ? AppTheme.accent : color,
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Center Log button — rendered as part of the bar via Stack in build order.
/// (Kept as its own widget for reuse.)
class LogButton extends StatelessWidget {
  final VoidCallback onTap;

  const LogButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4E9CFF), Color(0xFF0A84FF), Color(0xFF0066DB)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.55),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                blurRadius: 6,
                spreadRadius: -2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _TabData {
  final IconData icon;
  final String label;

  const _TabData(this.icon, this.label);
}
