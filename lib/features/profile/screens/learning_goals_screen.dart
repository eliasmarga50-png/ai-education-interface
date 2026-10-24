import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../dashboard/services/learning_activity_service.dart';
import '../services/profile_controller.dart';
import '../widgets/profile_feedback.dart';

/// Sets the learning goal and the daily study target, and shows how today is
/// going. Both settings are saved on the account; the daily target also drives
/// the goal ring on Home.
class LearningGoalsScreen extends StatefulWidget {
  const LearningGoalsScreen({super.key});

  @override
  State<LearningGoalsScreen> createState() => _LearningGoalsScreenState();
}

class _LearningGoalsScreenState extends State<LearningGoalsScreen> {
  static const List<int> _targets = [10, 15, 30, 45, 60, 90];

  final _controller = ProfileController.instance;

  late String _goal;
  late int _dailyMinutes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final preferences = _controller.preferences;
    _goal = preferences.learningGoal;
    _dailyMinutes = preferences.dailyGoalMinutes;
  }

  List<int> get _options {
    final options = {..._targets, _dailyMinutes}.toList()..sort();
    return options;
  }

  String _label(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final saved = await _controller.updatePreferences(
      learningGoal: _goal,
      dailyGoalMinutes: _dailyMinutes,
    );

    if (!mounted) {
      return;
    }

    if (!saved) {
      setState(() {
        _isSaving = false;
      });
      showProfileSnack(
        context,
        _controller.lastError ?? 'Your goals could not be saved.',
        isError: true,
        onRetry: _save,
      );
      return;
    }

    showProfileSnack(context, 'Learning goals saved.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Goals'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          AnimatedBuilder(
            animation: LearningActivityService.instance,
            builder: (context, _) {
              final activity = LearningActivityService.instance;
              final todayMinutes = activity.secondsOn(DateTime.now()) ~/ 60;
              final progress =
                  (todayMinutes / _dailyMinutes).clamp(0.0, 1.0).toDouble();
              final reached = todayMinutes >= _dailyMinutes;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            reached
                                ? Icons.check_circle
                                : Icons.track_changes_outlined,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Today',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        reached
                            ? 'Goal reached: $todayMinutes of '
                                '${_label(_dailyMinutes)} studied.'
                            : '$todayMinutes of ${_label(_dailyMinutes)} '
                                'studied today.',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Streak: ${activity.currentStreak} '
                        '${activity.currentStreak == 1 ? 'day' : 'days'}'
                        ' · Longest: ${activity.longestStreak}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          Text('Learning goal', style: theme.textTheme.titleMedium),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            initialValue: _goal,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.flag_outlined),
              labelText: 'What do you want to achieve?',
            ),
            items: [
              for (final goal in LearningPreferences.goals)
                DropdownMenuItem(value: goal, child: Text(goal)),
            ],
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _goal = value;
                    });
                  },
          ),

          const SizedBox(height: 28),

          Text('Daily study target', style: theme.textTheme.titleMedium),

          const SizedBox(height: 4),

          Text(
            'How long you want to study each day.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in _options)
                ChoiceChip(
                  label: Text(_label(minutes)),
                  selected: minutes == _dailyMinutes,
                  onSelected: _isSaving
                      ? null
                      : (_) {
                          setState(() {
                            _dailyMinutes = minutes;
                          });
                        },
                ),
            ],
          ),

          const SizedBox(height: 30),

          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Saving...' : 'Save Goals'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
      ),
    );
  }
}