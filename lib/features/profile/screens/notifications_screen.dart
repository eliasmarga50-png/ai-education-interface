import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/profile_controller.dart';
import '../widgets/profile_feedback.dart';

/// Notification settings. They are saved on the account; the same switch is
/// shown in Preferences.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _controller = ProfileController.instance;

  late bool _dailyReminders;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dailyReminders = _controller.preferences.dailyReminders;
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final saved = await _controller.updatePreferences(
      dailyReminders: _dailyReminders,
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
        _controller.lastError ??
            'Your notification settings could not be saved.',
        isError: true,
        onRetry: _save,
      );
      return;
    }

    showProfileSnack(context, 'Notification settings saved.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.notifications_none,
                  color: AppTheme.primaryColor,
                  size: 30,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Choose which learning notifications you want.',
                    style: TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Card(
            child: SwitchListTile(
              value: _dailyReminders,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _dailyReminders = value;
                      });
                    },
              secondary: const Icon(
                Icons.alarm_outlined,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Daily learning reminders'),
              subtitle: const Text(
                'A nudge to keep your streak going.',
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Your choice is saved to your account. This version of the app '
            'does not send reminders to your device yet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),

          const SizedBox(height: 28),

          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
      ),
    );
  }
}