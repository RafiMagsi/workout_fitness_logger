// App-level fitness metric types and their display configuration.

enum FitnessMetricType {
  move,
  exercise,
  stand,
  weight,
  bodyFat,
  sleep,
  activeMinutes,
  steps,
  heartRate,
  other,
}

/// How a metric is visualized and labeled in the UI.
class FitnessMetricConfig {
  final FitnessMetricType type;
  final String displayName;
  final String unit;
  final bool isRingsMetric;
  final bool supportsProgressTracking;
  final bool isPrimaryProgressMetric;
  final int suggestedDecimals;
  final bool isHigherBetter;
  final bool isLowerBetter;
  final double? targetValue;

  const FitnessMetricConfig({
    required this.type,
    required this.displayName,
    required this.unit,
    required this.isRingsMetric,
    required this.supportsProgressTracking,
    required this.isPrimaryProgressMetric,
    required this.suggestedDecimals,
    required this.isHigherBetter,
    required this.isLowerBetter,
    this.targetValue,
  });

  static const move = FitnessMetricConfig(
    type: FitnessMetricType.move,
    displayName: 'Move',
    unit: 'kcal',
    isRingsMetric: true,
    supportsProgressTracking: true,
    isPrimaryProgressMetric: true,
    suggestedDecimals: 0,
    isHigherBetter: true,
    isLowerBetter: false,
    targetValue: 600,
  );

  static const exercise = FitnessMetricConfig(
    type: FitnessMetricType.exercise,
    displayName: 'Exercise',
    unit: 'min',
    isRingsMetric: true,
    supportsProgressTracking: true,
    isPrimaryProgressMetric: true,
    suggestedDecimals: 0,
    isHigherBetter: true,
    isLowerBetter: false,
    targetValue: 30,
  );

  static const stand = FitnessMetricConfig(
    type: FitnessMetricType.stand,
    displayName: 'Stand',
    unit: 'hrs',
    isRingsMetric: true,
    supportsProgressTracking: true,
    isPrimaryProgressMetric: false,
    suggestedDecimals: 1,
    isHigherBetter: true,
    isLowerBetter: false,
    targetValue: 12,
  );

  static const weight = FitnessMetricConfig(
    type: FitnessMetricType.weight,
    displayName: 'Weight',
    unit: 'kg',
    isRingsMetric: false,
    supportsProgressTracking: true,
    isPrimaryProgressMetric: false,
    suggestedDecimals: 1,
    isHigherBetter: false,
    isLowerBetter: true,
    targetValue: null,
  );

  static const activeMinutes = FitnessMetricConfig(
    type: FitnessMetricType.activeMinutes,
    displayName: 'Active minutes',
    unit: 'min',
    isRingsMetric: false,
    supportsProgressTracking: true,
    isPrimaryProgressMetric: false,
    suggestedDecimals: 0,
    isHigherBetter: true,
    isLowerBetter: false,
    targetValue: 30,
  );

  static const steps = FitnessMetricConfig(
    type: FitnessMetricType.steps,
    displayName: 'Steps',
    unit: 'steps',
    isRingsMetric: false,
    supportsProgressTracking: true,
    isPrimaryProgressMetric: false,
    suggestedDecimals: 0,
    isHigherBetter: true,
    isLowerBetter: false,
    targetValue: 6000,
  );

  static List<FitnessMetricConfig> primaryMetrics = [
    move,
    exercise,
    stand,
  ];

  static List<FitnessMetricConfig> trackedMetrics = [
    move,
    exercise,
    stand,
    weight,
    activeMinutes,
    steps,
  ];
}
