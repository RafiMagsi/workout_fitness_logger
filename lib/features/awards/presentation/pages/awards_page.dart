import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../workout/domain/workout_entry.dart';
import '../../../workout/domain/metrics.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../../../../core/theme/app.dart';

/// Awards screen — Apple Fitness style achievements grid, computed live from
/// the user's workout history (streaks, totals, goal closes, records).
class AwardsPage extends ConsumerWidget {
  const AwardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final stats = _computeStats(entries);
    final awards = _buildAwards(stats);
    final unlocked = awards.where((a) => a.unlocked).length;

    return RefreshIndicator(
      onRefresh: () async {},
      color: AppTheme.orange,
      backgroundColor: AppTheme.surfaceRaised,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Awards',
                      style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 4),
                  Text(
                    '$unlocked of ${awards.length} unlocked',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 18),

                  // Hero award — the streak, with a big gold treatment.
                  _HeroAward(stats: stats)
                      .animate()
                      .fadeIn(duration: 420.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                        duration: 420.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final award = awards[index];
                  return _AwardCard(award: award)
                      .animate()
                      .fadeIn(
                        delay: (80 + (index % 6) * 70).ms,
                        duration: 360.ms,
                      )
                      .slideY(begin: 0.06, end: 0, duration: 360.ms);
                },
                childCount: awards.length,
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

  _Stats _computeStats(List<WorkoutEntry> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var totalKcal = 0.0;
    var totalMinutes = 0.0;
    var goalDays = 0;
    var earlyWorkouts = 0;
    var longest = 0.0;
    final kcalByDay = <DateTime, double>{};

    for (final e in entries) {
      if (e.metricType == FitnessMetricType.move) {
        totalKcal += e.value;
        final day = DateTime(
            e.timestamp.year, e.timestamp.month, e.timestamp.day);
        kcalByDay[day] = (kcalByDay[day] ?? 0) + e.value;
      }
      totalMinutes += e.durationMinutes;
      if (e.durationMinutes > longest) longest = e.durationMinutes;
      if (e.timestamp.hour < 9) earlyWorkouts++;
    }
    goalDays = kcalByDay.values.where((v) => v >= 600).length;

    return _Stats(
      workouts: entries.length,
      totalKcal: totalKcal,
      totalMinutes: totalMinutes,
      goalDays: goalDays,
      earlyWorkouts: earlyWorkouts,
      longest: longest,
      daysTracked: kcalByDay.length,
      today: today,
    );
  }

  List<_Award> _buildAwards(_Stats s) {
    return [
      _Award(
        title: 'Goal Closers',
        subtitle: '${s.goalDays} days over 600 kcal',
        icon: Icons.local_fire_department_rounded,
        colors: const [Color(0xFFFF6B4A), Color(0xFFFA114F)],
        unlocked: s.goalDays > 0,
        progress: (s.goalDays / 10).clamp(0, 1),
        goalLabel: '10 days',
      ),
      _Award(
        title: 'Early Riser',
        subtitle: '${s.earlyWorkouts} workouts before 9 AM',
        icon: Icons.wb_sunny_rounded,
        colors: const [Color(0xFFFFD60A), Color(0xFFFF9F0A)],
        unlocked: s.earlyWorkouts > 0,
        progress: (s.earlyWorkouts / 10).clamp(0, 1),
        goalLabel: '10 workouts',
      ),
      _Award(
        title: 'Endurance',
        subtitle: 'Longest session ${s.longest.toStringAsFixed(0)} min',
        icon: Icons.military_tech_rounded,
        colors: const [Color(0xFF5AC8FA), Color(0xFF0A84FF)],
        unlocked: s.longest >= 30,
        progress: (s.longest / 60).clamp(0, 1),
        goalLabel: '60 min',
      ),
      _Award(
        title: 'Calorie King',
        subtitle: '${s.totalKcal.toStringAsFixed(0)} kcal burned',
        icon: Icons.whatshot_rounded,
        colors: const [Color(0xFFFF9F0A), Color(0xFFFA114F)],
        unlocked: s.totalKcal >= 1000,
        progress: (s.totalKcal / 5000).clamp(0, 1),
        goalLabel: '5,000 kcal',
      ),
      _Award(
        title: 'Time Trainer',
        subtitle: '${(s.totalMinutes / 60).toStringAsFixed(1)} hours training',
        icon: Icons.timer_rounded,
        colors: const [Color(0xFFBF5AF2), Color(0xFF6E5BFF)],
        unlocked: s.totalMinutes >= 300,
        progress: (s.totalMinutes / 600).clamp(0, 1),
        goalLabel: '10 hours',
      ),
      _Award(
        title: 'Century Club',
        subtitle: '${s.workouts} of 100 workouts',
        icon: Icons.emoji_events_rounded,
        colors: const [Color(0xFFFFD60A), Color(0xFFFF9F0A)],
        unlocked: s.workouts >= 100,
        progress: (s.workouts / 100).clamp(0, 1),
        goalLabel: '100 workouts',
      ),
    ];
  }
}

class _Stats {
  final int workouts;
  final double totalKcal;
  final double totalMinutes;
  final int goalDays;
  final int earlyWorkouts;
  final double longest;
  final int daysTracked;
  final DateTime today;

  const _Stats({
    required this.workouts,
    required this.totalKcal,
    required this.totalMinutes,
    required this.goalDays,
    required this.earlyWorkouts,
    required this.longest,
    required this.daysTracked,
    required this.today,
  });
}

class _Award {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final bool unlocked;
  final double progress;
  final String goalLabel;

  const _Award({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.unlocked,
    required this.progress,
    required this.goalLabel,
  });
}

class _HeroAward extends StatelessWidget {
  final _Stats stats;

  const _HeroAward({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x33FFD60A), Color(0x1AFF9F0A), Color(0xFF121218)],
        ),
        border: Border.all(color: const Color(0xFFFFD60A).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F0A).withValues(alpha: 0.15),
            blurRadius: 34,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE066), Color(0xFFFFB300), Color(0xFFFF8A00)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9F0A).withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFF5C3A00),
              size: 40,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALL-TIME TOTAL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFFFD60A),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.workouts} workouts logged',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.totalKcal.toStringAsFixed(0)} kcal · '
                  '${(stats.totalMinutes / 60).toStringAsFixed(1)} hrs trained',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
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

class _AwardCard extends StatelessWidget {
  final _Award award;

  const _AwardCard({required this.award});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = award.unlocked;
    final medalColor = unlocked ? award.colors.last : AppTheme.border;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        gradient: unlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  award.colors.first.withValues(alpha: 0.14),
                  AppTheme.surface,
                ],
              )
            : AppTheme.glassSheen,
        border: Border.all(
          color: unlocked
              ? award.colors.last.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: award.colors,
                    )
                  : null,
              color: unlocked ? null : AppTheme.surfaceRaised,
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: award.colors.last.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              award.icon,
              size: 24,
              color: unlocked ? Colors.white : AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            award.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: unlocked ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            unlocked ? award.subtitle : 'Locked · ${award.goalLabel}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: unlocked ? medalColor : AppTheme.textTertiary,
              fontWeight: unlocked ? FontWeight.w600 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.06)),
                  FractionallySizedBox(
                    widthFactor: award.progress.clamp(0.005, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: unlocked
                              ? award.colors
                              : [
                                  AppTheme.textTertiary,
                                  AppTheme.textTertiary,
                                ],
                        ),
                        boxShadow: unlocked
                            ? [
                                BoxShadow(
                                  color: award.colors.last
                                      .withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
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
