import 'package:equatable/equatable.dart';
import 'metrics.dart';

/// A single logged workout or body measurement entry.
class WorkoutEntry extends Equatable {
  final String id;
  final DateTime timestamp;
  final ExerciseType exerciseType;
  final double durationMinutes;
  final double value;
  final FitnessMetricType metricType;
  final String? note;

  const WorkoutEntry({
    required this.id,
    required this.timestamp,
    required this.exerciseType,
    required this.durationMinutes,
    required this.value,
    required this.metricType,
    this.note,
  });

  @override
  List<Object?> get props => [
        id,
        timestamp,
        exerciseType,
        durationMinutes,
        value,
        metricType,
        note,
      ];

  /// Returns a rounded display value based on the metric's suggested decimals.
  String get displayValue {
    final decimals = FitnessMetricConfig.trackedMetrics
        .firstWhere(
          (c) => c.type == metricType,
          orElse: () => FitnessMetricConfig.activeMinutes,
        )
        .suggestedDecimals;
    return value.toStringAsFixed(decimals);
  }

  /// Returns a display unit for the metric.
  String get displayUnit {
    return FitnessMetricConfig.trackedMetrics
        .firstWhere(
          (c) => c.type == metricType,
          orElse: () => FitnessMetricConfig.activeMinutes,
        )
        .unit;
  }

  /// Returns a concise description for history list display.
  String get shortLabel {
    final base = '${durationMinutes.toStringAsFixed(0)}m · $displayValue$displayUnit';
    return exerciseType == ExerciseType.strength
        ? '${durationMinutes.toStringAsFixed(0)}m · strength'
        : base;
  }

  /// Returns true if this entry qualifies as a "body measurement" entry.
  bool get isMeasurement =>
      metricType == FitnessMetricType.weight ||
      metricType == FitnessMetricType.bodyFat;

  /// Returns a human-friendly exercise label.
  String get exerciseLabel {
    return switch (exerciseType) {
      ExerciseType.running => 'Run',
      ExerciseType.cycling => 'Cycle',
      ExerciseType.yoga => 'Yoga',
      ExerciseType.strength => 'Strength',
      ExerciseType.walking => 'Walk',
      ExerciseType.swimming => 'Swim',
      ExerciseType.other => 'Other',
    };
  }
}

enum ExerciseType {
  running,
  cycling,
  yoga,
  strength,
  walking,
  swimming,
  other,
}
