import '../domain/workout_entry.dart';
import '../domain/metrics.dart';

/// JSON (de)serialization for [WorkoutEntry].
///
/// Kept in the data layer (extensions cannot declare constructors) so the
/// domain model stays free of persistence concerns.
class WorkoutEntryCodec {
  const WorkoutEntryCodec._();

  static Map<String, dynamic> toJson(WorkoutEntry entry) => {
        'id': entry.id,
        'timestamp': entry.timestamp.toIso8601String(),
        'exerciseType': entry.exerciseType.name,
        'durationMinutes': entry.durationMinutes,
        'value': entry.value,
        'metricType': entry.metricType.name,
        'note': entry.note,
      };

  static WorkoutEntry fromJson(Map<String, dynamic> json) {
    final exerciseName = json['exerciseType'] as String;
    final metricName = json['metricType'] as String? ?? 'activeMinutes';
    return WorkoutEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      exerciseType: ExerciseType.values.firstWhere(
        (e) => e.name == exerciseName,
        orElse: () => ExerciseType.other,
      ),
      durationMinutes: (json['durationMinutes'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
      metricType: FitnessMetricType.values.firstWhere(
        (e) => e.name == metricName,
        orElse: () => FitnessMetricType.activeMinutes,
      ),
      note: json['note'] as String?,
    );
  }
}
