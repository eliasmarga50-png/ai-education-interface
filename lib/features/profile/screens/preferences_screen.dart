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
          Textbutton(
            onPressed: _savePreferences,
            child: const Text('save'),
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

          const sizedBox(height: 28),

          Text(
            'Learning Goal',
            style: Theme.of(context)
               .textTheme
               .titleMedium,
          ),

          const SizedBox(height:10),

          DropdownButtonFormField<String>(initialValue: _learningGoal,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.flag_outlined,
            ),
            labelText: 'what do you want to achieve?',
          ),
          items: const[
            DropdownMenuItem(
              value: 'Improve my skill',
              child: Text('Improve my Skills'),
              ),
              DropdownMenuItem(
                value: 'prepare for a career',
                child: Text('prepare for a career',),
                ),
              DropdownMenuItem(
                value: 'prepare for exams',
                child: Text('prepare for exams',
                
                ),
              ),
          ],
          onChanged: (value) {
            if (value==null) {
              return;
            }

            setState(() {
              _learningGoal= value;
            });
          },
        ),

        const SizedBox(height: 24),
          ],
      ),
      );
  }
  
  }