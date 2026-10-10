// Smoke tests for the Fitness (Apple Fitness-style) app shell and summary.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:workout_fitness_logger/main.dart';
import 'package:workout_fitness_logger/core/shell/app_shell.dart';
import 'package:workout_fitness_logger/features/workout/domain/workout_entry.dart';
import 'package:workout_fitness_logger/features/workout/domain/metrics.dart';
import 'package:workout_fitness_logger/features/workout/presentation/providers/workout_provider.dart';

List<WorkoutEntry> _seedEntries() {
  final now = DateTime.now();
  return [
    WorkoutEntry(
      id: 'today-run',
      timestamp: DateTime(now.year, now.month, now.day, 8, 30),
      exerciseType: ExerciseType.running,
      durationMinutes: 32,
      value: 320,
      metricType: FitnessMetricType.move,
      note: 'Morning pace',
    ),
    WorkoutEntry(
      id: 'yesterday-lift',
      timestamp: DateTime(now.year, now.month, now.day - 1, 18, 0),
      exerciseType: ExerciseType.strength,
      durationMinutes: 45,
      value: 0,
      metricType: FitnessMetricType.activeMinutes,
    ),
  ];
}

/// Pumps the app with demo entries pre-seeded so widget tests never touch the
/// platform file system.
Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutEntriesProvider.overrideWith((ref) async => _seedEntries()),
      ],
      child: const FitnessApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  testWidgets('Summary screen shows title, rings and metric cards',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    expect(find.text('Summary'), findsWidgets);
    expect(find.text('Move'), findsWidgets);
    expect(find.text('Exercise'), findsWidgets);
    expect(find.text('Stand'), findsWidgets);
    expect(find.text('Latest Workouts'), findsOneWidget);
  });

  testWidgets('Tab bar navigates to Trends and History',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.trending_up_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Trends'), findsWidgets);

    await tester.tap(find.byIcon(Icons.emoji_events_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Awards'), findsWidgets);

    await tester.tap(find.byIcon(Icons.event_note_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('History'), findsWidgets);
  });

  testWidgets('Log button opens the Log Workout modal',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byType(LogButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Log Workout'), findsWidgets);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('Save Workout'), findsOneWidget);
  });
}
