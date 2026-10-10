import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/workout_storage.dart';
import '../../domain/workout_entry.dart';
import '../../domain/metrics.dart';

final workoutStorageProvider = Provider<WorkoutStorage>((ref) {
  return WorkoutStorage.instance;
});

final workoutEntriesProvider = FutureProvider<List<WorkoutEntry>>((ref) async {
  final storage = ref.watch(workoutStorageProvider);
  await storage.seedDemoIfNeeded();
  return storage.entries;
});

final latestEntryProvider = FutureProvider<WorkoutEntry?>((ref) async {
  final entries = await ref.watch(workoutEntriesProvider.future);
  return entries.isNotEmpty ? entries.first : null;
});

final todayProgressProvider = Provider<TodayProgress>((ref) {
  final entriesAsync = ref.watch(workoutEntriesProvider);
  return entriesAsync.when(
    data: TodayProgress._computeTodayProgress,
    loading: () => TodayProgress.empty,
    error: (_, _) => TodayProgress.empty,
  );
});

/// Rolling workout streak (consecutive days ending today or yesterday).
final streakDaysProvider = Provider<int>((ref) {
  final entriesAsync = ref.watch(workoutEntriesProvider);
  return entriesAsync.when(
    data: _computeStreak,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

class TodayProgress {
  final double movePercent;
  final double exercisePercent;
  final double standPercent;
  final double totalMove;
  final double totalExerciseMinutes;
  final int totalStandHours;
  final int workoutsCount;

  const TodayProgress({
    required this.movePercent,
    required this.exercisePercent,
    required this.standPercent,
    required this.totalMove,
    required this.totalExerciseMinutes,
    required this.totalStandHours,
    required this.workoutsCount,
  });

  static const empty = TodayProgress(
    movePercent: 0,
    exercisePercent: 0,
    standPercent: 0,
    totalMove: 0,
    totalExerciseMinutes: 0,
    totalStandHours: 0,
    workoutsCount: 0,
  );

  static TodayProgress _computeTodayProgress(List<WorkoutEntry> entries) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final todayEntries =
        entries.where((e) => e.timestamp.isAfter(startOfDay)).toList();

    double totalMove = 0;
    double exerciseMinutes = 0;
    final activeHours = <int>{};

    for (final entry in todayEntries) {
      // Every logged workout contributes active (exercise) minutes.
      exerciseMinutes += entry.durationMinutes;
      if (entry.metricType == FitnessMetricType.move) {
        totalMove += entry.value;
      } else if (entry.metricType == FitnessMetricType.activeMinutes) {
        // Active-minute logs still burn calories; estimate for the Move ring.
        totalMove += entry.durationMinutes * 6;
      }
      activeHours.add(entry.timestamp.hour);
    }

    const targetMove = 600.0;
    const targetExerciseMinutes = 30.0;
    const targetStandHours = 12.0;

    return TodayProgress(
      movePercent: (totalMove / targetMove).clamp(0, 1).toDouble(),
      exercisePercent:
          (exerciseMinutes / targetExerciseMinutes).clamp(0, 1).toDouble(),
      standPercent:
          (activeHours.length / targetStandHours).clamp(0, 1).toDouble(),
      totalMove: totalMove,
      totalExerciseMinutes: exerciseMinutes,
      totalStandHours: activeHours.length,
      workoutsCount: todayEntries.length,
    );
  }
}

int _computeStreak(List<WorkoutEntry> entries) {
  if (entries.isEmpty) return 0;

  final days = entries
      .map((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  // Streak must touch today or yesterday to count.
  if (!days.contains(today) && !days.contains(yesterday)) return 0;

  var streak = 0;
  var cursor = days.contains(today) ? today : yesterday;
  for (final day in days) {
    if (day == cursor) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return streak;
}
