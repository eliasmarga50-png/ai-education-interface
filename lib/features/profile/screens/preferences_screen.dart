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
  }}