import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app.dart';

/// Frosted "liquid glass" card — translucent fill, backdrop blur, hairline
/// specular border. The standard surface for 2026-era glassmorphic UI.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Color? borderColor;
  final Color? fillColor;
  final List<BoxShadow>? shadows;
  final bool showBorder;
  final bool blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 22,
    this.borderColor,
    this.fillColor,
    this.shadows,
    this.showBorder = true,
    this.blur = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillColor ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.07),
                width: 1,
              )
            : null,
        gradient: AppTheme.glassSheen,
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
      ),
      child: child,
    );

    if (!blur) return base;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: base,
      ),
    );
  }
}

class PillTag extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;

  const PillTag({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatefulWidget {
  final String value;
  final String label;
  final double? change;
  final Color? changeColor;
  final IconData? icon;
  final Color? iconColor;
  final double? progress;
  final bool animated;

  const MetricTile({
    super.key,
    required this.value,
    required this.label,
    this.change,
    this.changeColor,
    this.icon,
    this.iconColor,
    this.progress,
    this.animated = true,
  });

  @override
  State<MetricTile> createState() => _MetricTileState();
}

class _MetricTileState extends State<MetricTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_ctrl);
    Future.delayed(
      widget.animated ? const Duration(milliseconds: 60) : Duration.zero,
      () {
        if (mounted) _ctrl.forward();
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildTile(context);
    if (!widget.animated) return child;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: child,
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        gradient: AppTheme.glassSheen,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.icon != null) ...[
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (widget.iconColor ?? AppTheme.accent)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: widget.iconColor ?? AppTheme.accent,
                  ),
                ),
                const Spacer(),
                if (widget.change != null)
                  _ChangeChip(
                    change: widget.change!,
                    color: widget.changeColor,
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Text(
            widget.value,
            style: (theme.textTheme.displaySmall ?? const TextStyle()).copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.label,
            style: (theme.textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: AppTheme.textSecondary),
          ),
          if (widget.progress != null) ...[
            const SizedBox(height: 10),
            _ProgressTrack(progress: widget.progress!),
          ],
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  final double change;
  final Color? color;

  const _ChangeChip({required this.change, this.color});

  @override
  Widget build(BuildContext context) {
    final isUp = change >= 0;
    final accent = color ?? (isUp ? AppTheme.green : AppTheme.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${isUp ? '+' : ''}${change.toStringAsFixed(1)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  final double progress;

  const _ProgressTrack({required this.progress});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.accent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 4,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(color: AppTheme.border),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
