import 'package:flutter/material.dart';
import '../../domain/workout_entry.dart';

class RecentSparkline extends StatelessWidget {
  final List<WorkoutEntry> entries;
  final String Function(WorkoutEntry) valueFormatter;
  final String Function(WorkoutEntry) durationFormatter;

  const RecentSparkline({
    super.key,
    required this.entries,
    required this.valueFormatter,
    required this.durationFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = entries.map((e) {
      if (e.exerciseType == ExerciseType.strength) {
        return e.durationMinutes.toDouble();
      }
      return e.value;
    }).toList();

    final maxValue = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 1.0;
    final minValue = values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : 0.0;
    final range = (maxValue - minValue).clamp(0.1, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 workouts',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF6C5CE7),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _SparklinePainter(
                  values: values,
                  maxValue: maxValue,
                  minValue: minValue,
                  range: range,
                  accentColor: const Color(0xFF6C5CE7),
                  fillColor: const Color(0xFF6C5CE7).withValues(alpha: 0.25),
                ),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _MiniEntryCard(
                  entry: entry,
                  valueFormatter: valueFormatter,
                  durationFormatter: durationFormatter,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniEntryCard extends StatelessWidget {
  final WorkoutEntry entry;
  final String Function(WorkoutEntry) valueFormatter;
  final String Function(WorkoutEntry) durationFormatter;

  const _MiniEntryCard({
    required this.entry,
    required this.valueFormatter,
    required this.durationFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(
            _iconFor(entry.exerciseType),
            size: 18,
            color: const Color(0xFF6C5CE7),
          ),
          const SizedBox(height: 4),
          Text(
            valueFormatter(entry),
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFFE2E8F0),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            durationFormatter(entry),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ExerciseType type) {
    return switch (type) {
      ExerciseType.running => Icons.directions_run_rounded,
      ExerciseType.cycling => Icons.directions_bike_rounded,
      ExerciseType.yoga => Icons.self_improvement_rounded,
      ExerciseType.strength => Icons.fitness_center_rounded,
      ExerciseType.walking => Icons.nordic_walking_rounded,
      ExerciseType.swimming => Icons.pool_rounded,
      ExerciseType.other => Icons.motorcycle_rounded,
    };
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final double minValue;
  final double range;
  final Color accentColor;
  final Color fillColor;

  _SparklinePainter({
    required this.values,
    required this.maxValue,
    required this.minValue,
    required this.range,
    required this.accentColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillColor, fillColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (values.length - 1);

    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = ((values[i] - minValue) / range).clamp(0.0, 1.0);
      final y = size.height - normalized * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height -
            (((values[i - 1] - minValue) / range).clamp(0.0, 1.0)) * size.height;
        path.cubicTo(prevX + stepX * 0.4, prevY, x - stepX * 0.4, y, x, y);
        fillPath.cubicTo(prevX + stepX * 0.4, prevY, x - stepX * 0.4, y, x, y);
      }
    }

    fillPath.lineTo((values.length - 1) * stepX, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) {
    return old.values != values || old.accentColor != accentColor;
  }
}
