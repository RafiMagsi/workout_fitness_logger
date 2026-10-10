import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../domain/workout_entry.dart';
import '../../domain/metrics.dart';
import '../providers/workout_provider.dart';
import '../../../../core/theme/app.dart';
import '../../../../shared/widgets/activity_rings.dart';

/// Summary screen — the Apple Fitness home: hero activity rings, daily
/// metric tiles, streak, and latest workouts.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(workoutEntriesProvider);
    final progress = ref.watch(todayProgressProvider);
    final streak = ref.watch(streakDaysProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: entriesAsync.when(
          data: (entries) => _buildBody(context, ref, entries, progress, streak),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(error: '$error'),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<WorkoutEntry> entries,
    TodayProgress progress,
    int streak,
  ) {
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(workoutEntriesProvider),
      color: AppTheme.accent,
      backgroundColor: AppTheme.surfaceRaised,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Header ------------------------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Summary',
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, MMM d').format(now),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (streak > 0) StreakPill(days: streak),
                      const SizedBox(width: 10),
                      const _Avatar(initials: 'FT'),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ---- Hero rings -------------------------------------------
                  ActivityRingsSummary(
                    move: progress.movePercent,
                    exercise: progress.exercisePercent,
                    stand: progress.standPercent,
                    moveValue:
                        '${progress.totalMove.toStringAsFixed(0)} / 600 CAL',
                    exerciseValue:
                        '${progress.totalExerciseMinutes.toStringAsFixed(0)} / 30 MIN',
                    standValue: '${progress.totalStandHours} / 12 HRS',
                    size: 230,
                    onTap: () => context.go('/progress'),
                  )
                      .animate()
                      .fadeIn(duration: 450.ms)
                      .scale(
                        begin: const Offset(0.94, 0.94),
                        end: const Offset(1, 1),
                        duration: 450.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 22),

                  // ---- Today tiles ------------------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'Move',
                          value: progress.totalMove.toStringAsFixed(0),
                          unit: 'CAL',
                          percent: progress.movePercent,
                          color: AppTheme.move,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Exercise',
                          value: progress.totalExerciseMinutes
                              .toStringAsFixed(0),
                          unit: 'MIN',
                          percent: progress.exercisePercent,
                          color: AppTheme.exercise,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Stand',
                          value: '${progress.totalStandHours}',
                          unit: 'HRS',
                          percent: progress.standPercent,
                          color: AppTheme.stand,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 120.ms, duration: 400.ms),
                  const SizedBox(height: 14),

                  // ---- This week --------------------------------------------
                  _WeeklyCard(entries: entries)
                      .animate()
                      .fadeIn(delay: 180.ms, duration: 400.ms)
                      .slideY(begin: 0.05, end: 0, duration: 400.ms),
                  const SizedBox(height: 14),

                  // ---- All-time stats ---------------------------------------
                  _StatsStrip(entries: entries)
                      .animate()
                      .fadeIn(delay: 240.ms, duration: 400.ms),
                  const SizedBox(height: 24),

                  // ---- Latest workouts --------------------------------------
                  _SectionHeader(
                    title: 'Latest Workouts',
                    actionLabel: 'See All',
                    onAction: () => context.go('/history'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ---- Workout list -------------------------------------------------
          if (entries.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(onLog: () => context.push('/log')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: entries.length > 5 ? 5 : entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _WorkoutRow(entry: entries[index])
                      .animate()
                      .fadeIn(
                        delay: (150 + index * 60).ms,
                        duration: 350.ms,
                      )
                      .slideY(begin: 0.08, end: 0, duration: 350.ms);
                },
              ),
            ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 140 + MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }
}

/// Seven-day Move bar chart with weekly totals — the "scroll payoff" card.
class _WeeklyCard extends StatelessWidget {
  final List<WorkoutEntry> entries;

  const _WeeklyCard({required this.entries});

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    // Week starts Monday at midnight (midnight matters: inDays truncates).
    final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    final kcalByDay = List<double>.filled(7, 0);
    final workoutsByDay = List<int>.filled(7, 0);
    var weekKcal = 0.0;
    var weekMinutes = 0.0;
    var weekWorkouts = 0;

    for (final e in entries) {
      final diff = e.timestamp.difference(weekStart).inDays;
      if (diff < 0 || diff > 6 || e.timestamp.isAfter(now)) continue;
      weekWorkouts++;
      weekMinutes += e.durationMinutes;
      workoutsByDay[diff] += 1;
      if (e.metricType == FitnessMetricType.move) {
        kcalByDay[diff] += e.value;
        weekKcal += e.value;
      }
    }

    final maxKcal = [
      ...kcalByDay,
      600.0,
    ].reduce((a, b) => a > b ? a : b);
    final todayIndex = now.weekday - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        gradient: AppTheme.glassSheen,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'This Week',
                style: theme.textTheme.titleLarge?.copyWith(
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                '${weekKcal.toStringAsFixed(0)} kcal',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.move,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '$weekWorkouts workout${weekWorkouts == 1 ? '' : 's'} · '
            '${weekMinutes.toStringAsFixed(0)} min trained',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (workoutsByDay[i] > 0 && kcalByDay[i] > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                kcalByDay[i].toStringAsFixed(0),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: i == todayIndex
                                      ? AppTheme.move
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: maxKcal == 0
                                  ? 0.0
                                  : (kcalByDay[i] / maxKcal)
                                      .clamp(0.02, 1.0),
                            ),
                            duration: Duration(milliseconds: 700 + i * 90),
                            curve: Curves.easeOutCubic,
                            builder: (context, t, _) => SizedBox(
                              height: 58 * t,
                              child: _bar(i == todayIndex,
                                  workoutsByDay[i] > 0),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _labels[i],
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: i == todayIndex
                                  ? AppTheme.textPrimary
                                  : AppTheme.textTertiary,
                              fontWeight: i == todayIndex
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(bool isToday, bool hasWorkout) {
    final color = hasWorkout ? AppTheme.move : AppTheme.border;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: hasWorkout
              ? [
                  color.withValues(alpha: 0.55),
                  color,
                ]
              : [color.withValues(alpha: 0.5), color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: isToday && hasWorkout
            ? [
                BoxShadow(
                  color: AppTheme.move.withValues(alpha: 0.55),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
    );
  }
}

/// All-time totals strip — quick flex stats for the demo.
class _StatsStrip extends StatelessWidget {
  final List<WorkoutEntry> entries;

  const _StatsStrip({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var kcal = 0.0;
    var minutes = 0.0;
    for (final e in entries) {
      minutes += e.durationMinutes;
      if (e.metricType == FitnessMetricType.move) kcal += e.value;
    }

    final stats = [
      (Icons.fitness_center_rounded, '${entries.length}', 'Workouts',
          AppTheme.exercise),
      (Icons.schedule_rounded, (minutes / 60).toStringAsFixed(1), 'Hours',
          AppTheme.stand),
      (Icons.local_fire_department_rounded, kcal.toStringAsFixed(0), 'kcal',
          AppTheme.move),
    ];

    return Row(
      children: [
        for (final (icon, value, label, color) in stats) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                gradient: AppTheme.glassSheen,
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (icon != stats.last.$1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class StreakPill extends StatelessWidget {
  final int days;

  const StreakPill({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.move, const Color(0xFFFF6B4A)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppTheme.orange.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            '$days day${days == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;

  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A3A46), Color(0xFF1F1F28)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.accent,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: -0.3,
              ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final double percent;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final closed = percent >= 1.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        gradient: AppTheme.glassSheen,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.06)),
                  AnimatedFractionallySizedBox(
                    duration: 900.ms,
                    curve: Curves.easeOutCubic,
                    widthFactor: percent.clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: closed
                              ? [color, Colors.white]
                              : [color, color.withValues(alpha: 0.55)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: closed ? 10 : 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  final WorkoutEntry entry;

  const _WorkoutRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentFor(entry.exerciseType);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          gradient: AppTheme.glassSheen,
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(_iconFor(entry.exerciseType), color: accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.exerciseLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subtitle(entry),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(WorkoutEntry entry) {
    final time = DateFormat('h:mm a').format(entry.timestamp);
    final duration = '${entry.durationMinutes.toStringAsFixed(0)} min';
    // Skip a meaningless "0" value (e.g. active-minute logs).
    if (entry.value == 0) return '$time · $duration';
    return '$time · $duration · ${entry.displayValue} ${entry.displayUnit}';
  }

  Color _accentFor(ExerciseType type) {
    return switch (type) {
      ExerciseType.running => AppTheme.move,
      ExerciseType.cycling => AppTheme.accent,
      ExerciseType.yoga => AppTheme.purple,
      ExerciseType.strength => AppTheme.exercise,
      ExerciseType.walking => AppTheme.stand,
      ExerciseType.swimming => AppTheme.blue,
      ExerciseType.other => AppTheme.textSecondary,
    };
  }

  IconData _iconFor(ExerciseType type) {
    return switch (type) {
      ExerciseType.running => Icons.directions_run_rounded,
      ExerciseType.cycling => Icons.directions_bike_rounded,
      ExerciseType.yoga => Icons.self_improvement_rounded,
      ExerciseType.strength => Icons.fitness_center_rounded,
      ExerciseType.walking => Icons.directions_walk_rounded,
      ExerciseType.swimming => Icons.pool_rounded,
      ExerciseType.other => Icons.fitness_center_outlined,
    };
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onLog;

  const _EmptyState({required this.onLog});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.directions_run_rounded,
              size: 44,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 14),
            Text(
              'No workouts yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Log your first workout and watch\nyour rings come alive.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onLog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log Workout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Something went wrong.\n$error',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
