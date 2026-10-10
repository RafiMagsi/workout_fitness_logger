import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/workout_entry.dart';
import '../../domain/metrics.dart';
import '../providers/workout_provider.dart';
import '../../data/workout_storage.dart';
import '../../../../core/theme/app.dart';

/// Log workout — presented like an iOS modal sheet: grabber, Cancel/Save
/// header, Apple-style workout type grid, big numeric fields.
class LogPage extends ConsumerStatefulWidget {
  final String exerciseType;

  const LogPage({super.key, this.exerciseType = ''});

  @override
  ConsumerState<LogPage> createState() => _LogPageState();
}

class _LogPageState extends ConsumerState<LogPage> {
  late final TextEditingController _durationCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _noteCtrl;
  ExerciseType _selectedType = ExerciseType.running;
  FitnessMetricType _selectedMetric = FitnessMetricType.move;
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _durationCtrl = TextEditingController(text: '30');
    _valueCtrl = TextEditingController(text: '0');
    _noteCtrl = TextEditingController();
    if (widget.exerciseType.isNotEmpty) {
      _selectedType = ExerciseType.values.firstWhere(
        (e) => e.name == widget.exerciseType,
        orElse: () => ExerciseType.running,
      );
    }
    _applyTypeDefaults();
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    _valueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _applyTypeDefaults() {
    if (_initialized) return;
    _initialized = true;
    switch (_selectedType) {
      case ExerciseType.strength:
        _selectedMetric = FitnessMetricType.activeMinutes;
        _durationCtrl.text = '40';
      case ExerciseType.yoga:
        _selectedMetric = FitnessMetricType.activeMinutes;
        _durationCtrl.text = '25';
      case ExerciseType.running:
      case ExerciseType.cycling:
      case ExerciseType.swimming:
      case ExerciseType.walking:
        _selectedMetric = FitnessMetricType.move;
        _durationCtrl.text = '30';
      case ExerciseType.other:
        _selectedMetric = FitnessMetricType.activeMinutes;
        _durationCtrl.text = '20';
    }
    _valueCtrl.text = '0';
  }

  void _onTypeSelected(ExerciseType type) {
    _selectedType = type;
    _initialized = false;
    _applyTypeDefaults();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const _Grabber(),
            _Header(onCancel: () => context.pop(), onSave: _saveEntry),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Workout', style: _sectionStyle(theme))
                          .animate()
                          .fadeIn(duration: 280.ms, delay: 40.ms),
                      const SizedBox(height: 12),
                      _WorkoutTypeGrid(
                        selected: _selectedType,
                        onSelected: _onTypeSelected,
                      ).animate().fadeIn(duration: 320.ms, delay: 80.ms),
                      const SizedBox(height: 26),

                      Text('Details', style: _sectionStyle(theme))
                          .animate()
                          .fadeIn(duration: 280.ms, delay: 120.ms),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _BigNumberField(
                              label: 'Duration',
                              controller: _durationCtrl,
                              suffix: 'min',
                              icon: Icons.timer_outlined,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BigNumberField(
                              label: _metricLabel(),
                              controller: _valueCtrl,
                              suffix: _metricUnit(),
                              icon: _metricIcon(),
                              color: _metricColor(),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 320.ms, delay: 160.ms),
                      const SizedBox(height: 24),

                      Text('Tracking', style: _sectionStyle(theme))
                          .animate()
                          .fadeIn(duration: 280.ms, delay: 200.ms),
                      const SizedBox(height: 12),
                      _MetricSelector(
                        selected: _selectedMetric,
                        onSelected: (m) => setState(() => _selectedMetric = m),
                      ).animate().fadeIn(duration: 320.ms, delay: 240.ms),
                      const SizedBox(height: 24),

                      Text('Note', style: _sectionStyle(theme))
                          .animate()
                          .fadeIn(duration: 280.ms, delay: 280.ms),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteCtrl,
                        decoration: const InputDecoration(
                          hintText: 'How did it feel?',
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ).animate().fadeIn(duration: 320.ms, delay: 320.ms),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: _saving ? null : _saveEntry,
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Text('Save Workout'),
                        ),
                      ).animate().fadeIn(duration: 320.ms, delay: 360.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _sectionStyle(ThemeData theme) => theme.textTheme.titleSmall!.copyWith(
        color: AppTheme.textTertiary,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
      );

  String _metricLabel() => FitnessMetricConfig.trackedMetrics
      .firstWhere((c) => c.type == _selectedMetric)
      .displayName;

  String _metricUnit() => FitnessMetricConfig.trackedMetrics
      .firstWhere((c) => c.type == _selectedMetric)
      .unit;

  IconData _metricIcon() => switch (_selectedMetric) {
        FitnessMetricType.move => Icons.local_fire_department_rounded,
        FitnessMetricType.exercise => Icons.fitness_center_rounded,
        FitnessMetricType.stand => Icons.accessibility_new_rounded,
        FitnessMetricType.weight => Icons.monitor_heart_rounded,
        FitnessMetricType.steps => Icons.directions_walk_rounded,
        FitnessMetricType.activeMinutes => Icons.timer_outlined,
        FitnessMetricType.heartRate => Icons.favorite_rounded,
        _ => Icons.show_chart_rounded,
      };

  Color _metricColor() => switch (_selectedMetric) {
        FitnessMetricType.move => AppTheme.move,
        FitnessMetricType.exercise => AppTheme.exercise,
        FitnessMetricType.stand => AppTheme.stand,
        FitnessMetricType.weight => AppTheme.purple,
        FitnessMetricType.steps => AppTheme.accent,
        FitnessMetricType.heartRate => AppTheme.red,
        _ => AppTheme.accent,
      };

  Future<void> _saveEntry() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final duration = double.tryParse(_durationCtrl.text) ?? 0;
    final value = double.tryParse(_valueCtrl.text) ?? 0;

    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration must be greater than 0')),
      );
      return;
    }

    setState(() => _saving = true);

    final entry = WorkoutEntry(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      exerciseType: _selectedType,
      durationMinutes: duration,
      value: value,
      metricType: _selectedMetric,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
    );

    await WorkoutStorage.instance.addEntry(entry);
    ref.invalidate(workoutEntriesProvider);
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Workout Saved'),
        content: Text(
          '${entry.exerciseLabel} · ${entry.durationMinutes.toStringAsFixed(0)} min',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: AppTheme.textTertiary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _Header({required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
      child: Row(
        children: [
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
          Expanded(
            child: Text(
              'Log Workout',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          TextButton(onPressed: onSave, child: const Text('Save')),
        ],
      ),
    );
  }
}

class _WorkoutTypeGrid extends StatelessWidget {
  final ExerciseType selected;
  final ValueChanged<ExerciseType> onSelected;

  const _WorkoutTypeGrid({
    required this.selected,
    required this.onSelected,
  });

  static final _types = [
    (ExerciseType.running, Icons.directions_run_rounded, 'Run', AppTheme.move),
    (ExerciseType.cycling, Icons.directions_bike_rounded, 'Cycle', AppTheme.blue),
    (ExerciseType.strength, Icons.fitness_center_rounded, 'Weights', AppTheme.exercise),
    (ExerciseType.walking, Icons.directions_walk_rounded, 'Walk', AppTheme.stand),
    (ExerciseType.swimming, Icons.pool_rounded, 'Swim', AppTheme.accent),
    (ExerciseType.yoga, Icons.self_improvement_rounded, 'Yoga', AppTheme.purple),
    (ExerciseType.other, Icons.more_horiz_rounded, 'Other', AppTheme.textSecondary),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.82,
      children: [
        for (final (type, icon, label, color) in _types)
          _TypeTile(
            icon: icon,
            label: label,
            color: color,
            selected: type == selected,
            onTap: () => onSelected(type),
            textStyle: theme.textTheme.labelMedium,
          ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? textStyle;

  const _TypeTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.06),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: selected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: textStyle?.copyWith(
                color: selected ? color : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  final IconData icon;
  final Color color;

  const _BigNumberField({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        gradient: AppTheme.glassSheen,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.left,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  suffix,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricSelector extends StatelessWidget {
  final FitnessMetricType selected;
  final ValueChanged<FitnessMetricType> onSelected;

  const _MetricSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final config in FitnessMetricConfig.trackedMetrics)
          _MetricChip(
            label: config.displayName,
            selected: config.type == selected,
            onTap: () => onSelected(config.type),
          ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MetricChip({
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
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.18)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.accent : Colors.white.withValues(alpha: 0.07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTheme.accent : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
