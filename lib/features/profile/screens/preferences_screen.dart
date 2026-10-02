import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/profile_controller.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() =>
      _PreferencesScreenState();
}

class _PreferencesScreenState
    extends State<PreferencesScreen> {
  final _controller =
      ProfileController.instance;

  late String _learningGoal;
  late String _difficulty;
  late bool _aiAssistance;
  late bool _dailyReminders;

  @override
  void initState() {
    super.initState();

    final preferences = _controller.preferences;

    _learningGoal = preferences.learningGoal;
    _difficulty = preferences.preferredDifficulty;
    _aiAssistance = preferences.aiAssistance;
    _dailyReminders = preferences.dailyReminders;
  }

  void _savePreferences() {
    _controller.updatePreferences(
      learningGoal: _learningGoal,
      preferredDifficulty: _difficulty,
      aiAssistance: _aiAssistance,
      dailyReminders: _dailyReminders,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Preferences updated successfully.',
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        actions: [
          TextButton(
            onPressed: _savePreferences,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          30,
        ),
        children: [
          const _PreferenceHeader(),

          const SizedBox(height: 28),

          Text(
            'Learning Goal',
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            initialValue: _learningGoal,
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.flag_outlined,
              ),
              labelText: 'What do you want to achieve?',
            ),
            items: const [
              DropdownMenuItem(
                value: 'Improve my skills',
                child: Text('Improve my skills'),
              ),
              DropdownMenuItem(
                value: 'Learn a new skill',
                child: Text('Learn a new skill'),
              ),
              DropdownMenuItem(
                value: 'Prepare for a career',
                child: Text(
                  'Prepare for a career',
                ),
              ),
              DropdownMenuItem(
                value: 'Prepare for exams',
                child: Text(
                  'Prepare for exams',
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _learningGoal = value;
              });
            },
          ),

          const SizedBox(height: 24),

          Text(
            'Preferred Difficulty',
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            initialValue: _difficulty,
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.bar_chart_outlined,
              ),
              labelText: 'Choose your level',
            ),
            items: const [
              DropdownMenuItem(
                value: 'Beginner',
                child: Text('Beginner'),
              ),
              DropdownMenuItem(
                value: 'Intermediate',
                child: Text('Intermediate'),
              ),
              DropdownMenuItem(
                value: 'Advanced',
                child: Text('Advanced'),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _difficulty = value;
              });
            },
          ),

          const SizedBox(height: 28),

          const _PreferenceSectionTitle(
            title: 'Learning Assistance',
          ),

          const SizedBox(height: 10),

          Card(
            child: SwitchListTile(
              value: _aiAssistance,
              onChanged: (value) {
                setState(() {
                  _aiAssistance = value;
                });
              },
              secondary: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      AppTheme.primaryColor.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: const Text(
                'AI learning assistance',
              ),
              subtitle: const Text(
                'Allow AI Tutor features to help with learning.',
              ),
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: SwitchListTile(
              value: _dailyReminders,
              onChanged: (value) {
                setState(() {
                  _dailyReminders = value;
                });
              },
              secondary: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      AppTheme.primaryColor.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: const Text(
                'Daily learning reminders',
              ),
              subtitle: const Text(
                'Receive reminders to continue learning.',
              ),
            ),
          ),

          const SizedBox(height: 30),

          FilledButton.icon(
            onPressed: _savePreferences,
            icon: const Icon(
              Icons.save_outlined,
            ),
            label: const Text(
              'Save Preferences',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(
                double.infinity,
                52,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceHeader extends StatelessWidget {
  const _PreferenceHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.tune,
            color: AppTheme.primaryColor,
            size: 30,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Customize your learning experience so the platform can better match your goals.',
              style: TextStyle(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSectionTitle
    extends StatelessWidget {
  final String title;

  const _PreferenceSectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}