import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../workout/domain/workout_entry.dart';
import '../../../workout/domain/metrics.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../../../../core/theme/app.dart';

/// History screen — Apple Fitness style grouped timeline: sticky day headers,
/// glass workout cards with metric chips, and notes.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(workoutEntriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: entriesAsync.when(
          data: (entries) => _buildBody(context, ref, entries),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Something went wrong.\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, List<WorkoutEntry> entries) {
    if (entries.isEmpty) {
      return const _EmptyHistory();
    }

    final grouped = _groupByDate(entries);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(workoutEntriesProvider),
      color: AppTheme.accent,
      backgroundColor: AppTheme.surfaceRaised,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('History',
                      style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${entries.length} workout${entries.length == 1 ? '' : 's'} logged',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          for (final group in grouped.entries) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Row(
                  children: [
                    Text(
                      _dateLabel(group.key),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.textTertiary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _dateSubtitle(group.key),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: group.value.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _HistoryCard(
                  entry: group.value[index],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140 + MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<WorkoutEntry>> _groupByDate(List<WorkoutEntry> entries) {
    final map = <DateTime, List<WorkoutEntry>>{};
    for (final entry in entries) {
      final day = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      map.putIfAbsent(day, () => []).add(entry);
    }
    return map;
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return DateFormat('MMMM d').format(date).toUpperCase();
  }

  String _dateSubtitle(DateTime date) => DateFormat('EEEE').format(date);
}

class _HistoryCard extends StatelessWidget {
  final WorkoutEntry entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentFor(entry.exerciseType);
    final metricAccent = _metricAccent(entry.metricType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        gradient: AppTheme.glassSheen,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child:
                    Icon(_iconFor(entry.exerciseType), color: accent, size: 22),
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
                      '${DateFormat('h:mm a').format(entry.timestamp)} · '
                      '${entry.durationMinutes.toStringAsFixed(0)} min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: metricAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: metricAccent.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '${entry.displayValue} ${entry.displayUnit}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: metricAccent,
                  ),
                ),
              ),
            ],
          ),
          if (entry.note != null && entry.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.format_quote_rounded,
                    size: 15, color: AppTheme.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _accentFor(ExerciseType type) => switch (type) {
        ExerciseType.running => AppTheme.move,
        ExerciseType.cycling => AppTheme.accent,
        ExerciseType.yoga => AppTheme.purple,
        ExerciseType.strength => AppTheme.exercise,
        ExerciseType.walking => AppTheme.stand,
        ExerciseType.swimming => AppTheme.blue,
        ExerciseType.other => AppTheme.textSecondary,
      };

  Color _metricAccent(FitnessMetricType type) => switch (type) {
        FitnessMetricType.move => AppTheme.move,
        FitnessMetricType.exercise => AppTheme.exercise,
        FitnessMetricType.stand => AppTheme.stand,
        FitnessMetricType.weight => AppTheme.purple,
        FitnessMetricType.steps => AppTheme.accent,
        FitnessMetricType.heartRate => AppTheme.red,
        FitnessMetricType.activeMinutes => AppTheme.orange,
        _ => AppTheme.accent,
      };

  IconData _iconFor(ExerciseType type) => switch (type) {
        ExerciseType.running => Icons.directions_run_rounded,
        ExerciseType.cycling => Icons.directions_bike_rounded,
        ExerciseType.yoga => Icons.self_improvement_rounded,
        ExerciseType.strength => Icons.fitness_center_rounded,
        ExerciseType.walking => Icons.directions_walk_rounded,
        ExerciseType.swimming => Icons.pool_rounded,
        ExerciseType.other => Icons.fitness_center_outlined,
      };
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Icon(
                Icons.event_note_rounded,
                size: 40,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            Text('No workouts yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Your logged workouts will appear here,\ngrouped by day.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
