import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../workout/domain/workout_entry.dart';
import '../../../workout/domain/metrics.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../../../../core/theme/app.dart';

/// Trends screen — Apple Fitness style: metric pills, weekly bar chart with
/// gradients, big summary stats, and highlights.
class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  FitnessMetricType _selectedMetric = FitnessMetricType.move;
  int _periodDays = 7;

  static const _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(workoutEntriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: entriesAsync.when(
          data: (entries) => _buildBody(context, entries),
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

  Widget _buildBody(BuildContext context, List<WorkoutEntry> entries) {
    final today = DateTime.now();
    // Normalize to midnight or entries earlier in the week day leak into the
    // previous day's bucket (Duration.inDays truncates).
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );

    final metricEntries =
        entries.where((e) => e.metricType == _selectedMetric).toList();
    final weeklyData = _buildWeeklyData(metricEntries, weekStart);

    final config = FitnessMetricConfig.trackedMetrics.firstWhere(
      (c) => c.type == _selectedMetric,
      orElse: () => FitnessMetricConfig.move,
    );
    final accent = _accentFor(_selectedMetric);

    final recent = entries
        .where((e) =>
            e.timestamp.isAfter(today.subtract(Duration(days: _periodDays))))
        .toList();
    final overall = _computeOverall(metricEntries);
    final trend = _computeTrend(weeklyData.values.toList());

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(workoutEntriesProvider),
      color: accent,
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
                  Text('Trends', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Last $_periodDays days',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 18),

                  _MetricSelector(
                    selected: _selectedMetric,
                    onSelected: (m) => setState(() => _selectedMetric = m),
                  ),
                  const SizedBox(height: 18),

                  _SummaryCard(
                    config: config,
                    accent: accent,
                    latest: overall.latest,
                    average: overall.average,
                    best: overall.best,
                    trend: trend,
                  ).animate().fadeIn(duration: 400.ms).scale(
                        begin: const Offset(0.96, 0.96),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 18),

                  _ChartCard(
                    days: _weekDays,
                    data: weeklyData.values.toList(),
                    config: config,
                    accent: accent,
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 400.ms,
                      ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      for (final days in const [7, 30, 90])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _PeriodChip(
                            label: days == 7 ? 'Week' : days == 30 ? 'Month' : '3 Months',
                            selected: _periodDays == days,
                            onTap: () => setState(() => _periodDays = days),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _share(config, recent),
                        icon: const Icon(Icons.share_outlined, size: 20),
                        tooltip: 'Share progress',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _Highlights(
                    entries: recent,
                    config: config,
                    accent: accent,
                  ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
                ],
              ),
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

  Map<int, double> _buildWeeklyData(
      List<WorkoutEntry> entries, DateTime weekStart) {
    final map = {for (var i = 0; i < 7; i++) i: 0.0};
    for (final entry in entries) {
      final daysDiff = entry.timestamp.difference(weekStart).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        map[daysDiff] = (map[daysDiff] ?? 0) + entry.value;
      }
    }
    return map;
  }

  ({double latest, double average, double best}) _computeOverall(
      List<WorkoutEntry> entries) {
    if (entries.isEmpty) return (latest: 0, average: 0, best: 0);
    final values = entries.map((e) => e.value).toList();
    final sorted = List<double>.from(values)..sort((a, b) => b.compareTo(a));
    return (
      latest: entries.first.value,
      average: values.reduce((a, b) => a + b) / values.length,
      best: sorted.first,
    );
  }

  double _computeTrend(List<double> weeklyValues) {
    if (weeklyValues.length < 2) return 0;
    final half = weeklyValues.length ~/ 2;
    final firstHalf = weeklyValues.sublist(0, half);
    final secondHalf = weeklyValues.sublist(half);
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    if (firstAvg == 0) return 0;
    return ((secondAvg - firstAvg) / firstAvg) * 100;
  }

  Color _accentFor(FitnessMetricType type) => switch (type) {
        FitnessMetricType.move => AppTheme.move,
        FitnessMetricType.exercise => AppTheme.exercise,
        FitnessMetricType.stand => AppTheme.stand,
        FitnessMetricType.weight => AppTheme.purple,
        FitnessMetricType.steps => AppTheme.accent,
        FitnessMetricType.heartRate => AppTheme.red,
        FitnessMetricType.activeMinutes => AppTheme.accent,
        _ => AppTheme.accent,
      };

  void _share(FitnessMetricConfig config, List<WorkoutEntry> entries) {
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    final text =
        'My ${config.displayName}: ${total.toStringAsFixed(config.suggestedDecimals)} ${config.unit} '
        'over the last $_periodDays days 💪';
    Share.share(text, subject: 'Fitness progress');
  }
}

class _MetricSelector extends StatelessWidget {
  final FitnessMetricType selected;
  final ValueChanged<FitnessMetricType> onSelected;

  const _MetricSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FitnessMetricConfig.trackedMetrics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final config = FitnessMetricConfig.trackedMetrics[index];
          final isSelected = config.type == selected;
          return GestureDetector(
            onTap: () => onSelected(config.type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 40,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accent.withValues(alpha: 0.18)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accent
                      : Colors.white.withValues(alpha: 0.07),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                config.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? AppTheme.accent : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final FitnessMetricConfig config;
  final Color accent;
  final double latest;
  final double average;
  final double best;
  final double trend;

  const _SummaryCard({
    required this.config,
    required this.accent,
    required this.latest,
    required this.average,
    required this.best,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUp = trend >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.05),
            AppTheme.surface,
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                config.displayName.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (trend != 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isUp ? AppTheme.exercise : AppTheme.red)
                        .withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: (isUp ? AppTheme.exercise : AppTheme.red)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 13,
                        color: isUp ? AppTheme.exercise : AppTheme.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isUp ? '+' : ''}${trend.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isUp ? AppTheme.exercise : AppTheme.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                latest.toStringAsFixed(config.suggestedDecimals),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -1.4,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  config.unit,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Average',
                  value:
                      average.toStringAsFixed(config.suggestedDecimals),
                ),
              ),
              Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.08)),
              Expanded(
                child: _Stat(
                  label: 'Best',
                  value: best.toStringAsFixed(config.suggestedDecimals),
                  highlight: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? highlight;

  const _Stat({required this.label, required this.value, this.highlight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: highlight ?? AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<String> days;
  final List<double> data;
  final FitnessMetricConfig config;
  final Color accent;

  const _ChartCard({
    required this.days,
    required this.data,
    required this.config,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue =
        data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) : 1.0;
    final topY = maxValue <= 0 ? 1.0 : maxValue * 1.25;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        gradient: AppTheme.glassSheen,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: theme.textTheme.titleLarge?.copyWith(
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${config.displayName} per day',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: topY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => accent.withValues(alpha: 0.95),
                    tooltipRoundedRadius: 12,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(config.suggestedDecimals)} '
                        '${config.unit}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[index],
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 26,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: topY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: data.asMap().entries.map((entry) {
                  final isToday = entry.key == DateTime.now().weekday - 1;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        width: 16,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            accent.withValues(alpha: isToday ? 1.0 : 0.55),
                            accent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: topY,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.18)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected ? AppTheme.accent : Colors.white.withValues(alpha: 0.07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTheme.accent : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Highlights extends StatelessWidget {
  final List<WorkoutEntry> entries;
  final FitnessMetricConfig config;
  final Color accent;

  const _Highlights({
    required this.entries,
    required this.config,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workouts =
        entries.where((e) => e.metricType == config.type).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        gradient: AppTheme.glassSheen,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Highlights',
            style: theme.textTheme.titleLarge?.copyWith(letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),
          if (workouts.isEmpty)
            Text(
              'No ${config.displayName.toLowerCase()} data yet — log a workout to see trends.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in workouts.take(6))
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('MMM d').format(entry.timestamp),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.displayValue} ${entry.displayUnit}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
