import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app.dart';

/// Animated Apple-style activity rings (Move / Exercise / Stand).
///
/// Faithful to Apple's Activity rings: three concentric tracks, drawn clockwise
/// from 12 o'clock, round caps, a per-ring gradient that brightens along the
/// sweep, and a soft bloom when a ring exceeds 100%.
class ActivityRings extends StatefulWidget {
  final double movePercent;
  final double exercisePercent;
  final double standPercent;
  final double size;
  final VoidCallback? onTap;

  const ActivityRings({
    super.key,
    required this.movePercent,
    required this.exercisePercent,
    required this.standPercent,
    this.size = 220,
    this.onTap,
  });

  @override
  State<ActivityRings> createState() => _ActivityRingsState();
}

class _ActivityRingsState extends State<ActivityRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(covariant ActivityRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-animate whenever the goals change so new logs feel alive.
    if (oldWidget.movePercent != widget.movePercent ||
        oldWidget.exercisePercent != widget.exercisePercent ||
        oldWidget.standPercent != widget.standPercent) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final p = _anim.value;
            return CustomPaint(
              size: Size.square(widget.size),
              painter: _RingsPainter(
                movePct: widget.movePercent * p,
                exercisePct: widget.exercisePercent * p,
                standPct: widget.standPercent * p,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double movePct;
  final double exercisePct;
  final double standPct;

  _RingsPainter({
    required this.movePct,
    required this.exercisePct,
    required this.standPct,
  });

  // Ring order outer -> inner: Stand, Exercise, Move (same as Apple Watch).
  static const _ringGap = 6.0;
  static const _stroke = 17.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2 - _stroke / 2 - 2;

    final rings = [
      (AppTheme.stand, standPct, outerRadius),
      (
        AppTheme.exercise,
        exercisePct,
        outerRadius - _stroke - _ringGap,
      ),
      (
        AppTheme.move,
        movePct,
        outerRadius - 2 * (_stroke + _ringGap),
      ),
    ];

    for (final (color, pct, radius) in rings) {
      _drawRing(canvas, center, radius, color, pct);
    }
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double pct,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * pct.clamp(0.0, 1.0);

    // Dimmed track.
    final track = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (pct <= 0.0001) return;

    // Gradient sweep: brighter toward the leading cap, like watchOS.
    final gradColors = [
      color.withValues(alpha: 0.75),
      color,
      Color.lerp(color, Colors.white, 0.18)!,
    ];
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        transform: const GradientRotation(start),
        colors: gradColors,
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect);
    canvas.drawArc(rect, start, sweep, false, sweepPaint);

    // Soft bloom around the lit arc.
    if (pct > 0.03) {
      final glow = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawArc(rect, start, sweep, false, glow);
    }

    // Over-100%: bright overlay ring, Apple's "closed ring" flourish.
    if (pct > 1.0) {
      final over = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round;
      final extra = 2 * math.pi * ((pct - 1.0).clamp(0.0, 1.0));
      canvas.drawArc(rect, start, extra, false, over);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) {
    return old.movePct != movePct ||
        old.exercisePct != exercisePct ||
        old.standPct != standPct;
  }
}

/// Hero card wrapping the rings with live legends — the centerpiece of the
/// Apple Fitness Summary screen.
class ActivityRingsSummary extends StatelessWidget {
  final double move;
  final double exercise;
  final double stand;
  final String moveValue;
  final String exerciseValue;
  final String standValue;
  final String moveLabel;
  final String exerciseLabel;
  final String standLabel;
  final double size;
  final VoidCallback? onTap;

  const ActivityRingsSummary({
    super.key,
    required this.move,
    required this.exercise,
    required this.stand,
    this.moveValue = '',
    this.exerciseValue = '',
    this.standValue = '',
    this.moveLabel = 'Move',
    this.exerciseLabel = 'Exercise',
    this.standLabel = 'Stand',
    this.size = 220,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: AppTheme.glassSheen,
            color: AppTheme.surface,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              ActivityRings(
                movePercent: move,
                exercisePercent: exercise,
                standPercent: stand,
                size: size,
                onTap: onTap,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _RingLegend(
                      color: AppTheme.move,
                      label: moveLabel,
                      value: moveValue,
                      percent: move,
                    ),
                  ),
                  Expanded(
                    child: _RingLegend(
                      color: AppTheme.exercise,
                      label: exerciseLabel,
                      value: exerciseValue,
                      percent: exercise,
                    ),
                  ),
                  Expanded(
                    child: _RingLegend(
                      color: AppTheme.stand,
                      label: standLabel,
                      value: standValue,
                      percent: stand,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final double percent;

  const _RingLegend({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final closed = percent >= 1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value.isEmpty
              ? '${(percent * 100).toStringAsFixed(0)}%'
              : value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          closed ? '$label · Closed' : label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: closed ? color : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
