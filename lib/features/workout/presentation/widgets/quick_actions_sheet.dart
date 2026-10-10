import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/workout_entry.dart';

class QuickActionsSheet extends StatelessWidget {
  const QuickActionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder: (_) => const QuickActionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF4A4A6A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'What did you do?',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _actions.map((action) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/log?exercise=${action.type.name}');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        action.icon,
                        size: 20,
                        color: const Color(0xFF6C5CE7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        action.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFFE2E8F0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static const _actions = [
    _ActionData(Icons.directions_run_rounded, 'Run', ExerciseType.running),
    _ActionData(Icons.directions_bike_rounded, 'Cycle', ExerciseType.cycling),
    _ActionData(Icons.self_improvement_rounded, 'Yoga', ExerciseType.yoga),
    _ActionData(Icons.fitness_center_rounded, 'Weights', ExerciseType.strength),
    _ActionData(Icons.nordic_walking_rounded, 'Walk', ExerciseType.walking),
    _ActionData(Icons.pool_rounded, 'Swim', ExerciseType.swimming),
    _ActionData(Icons.motorcycle_rounded, 'Other', ExerciseType.other),
  ];
}

class _ActionData {
  final IconData icon;
  final String label;
  final ExerciseType type;

  const _ActionData(this.icon, this.label, this.type);
}
