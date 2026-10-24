import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/services/auth_controller.dart';
import '../widgets/profile_feedback.dart';
import 'change_password_screen.dart';

/// Account security and what the app does with your data.
///
/// Signing out everywhere and deleting the account end the session, and
/// AuthGate then replaces the app with the sign-in flow.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _isBusy = false;

  Future<void> _signOutEverywhere() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out of all devices?'),
          content: const Text(
            'Every device where you are logged in, including this one, will '
            'be signed out. You can log in again at any time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign Out Everywhere'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    final auth = AuthController.instance;
    final done = await auth.logOutEverywhere();

    // On success the session is over and AuthGate takes the app away.
    if (!mounted || done) {
      return;
    }

    setState(() {
      _isBusy = false;
    });
    showProfileSnack(
      context,
      auth.lastError ?? 'We could not sign you out of your other devices.',
      isError: true,
      onRetry: _signOutEverywhere,
    );
  }

  Future<void> _deleteAccount() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteAccountDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              Text(
                'Security',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _PrivacyTile(
                icon: Icons.password_outlined,
                title: 'Change password',
                subtitle: 'Choose a new password for your account',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),

              _PrivacyTile(
                icon: Icons.devices_outlined,
                title: 'Sign out of all devices',
                subtitle: 'End every session, including this one',
                onTap: _isBusy ? null : _signOutEverywhere,
              ),

              const SizedBox(height: 24),

              Text(
                'Your data',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DataLine(
                        icon: Icons.cloud_outlined,
                        text: 'On our server: your name, email, bio, photo, '
                            'learning preferences and quiz results.',
                      ),
                      const SizedBox(height: 12),
                      _DataLine(
                        icon: Icons.phone_android_outlined,
                        text: 'On this device: lesson progress, study time, '
                            'streak and AI Tutor chats.',
                      ),
                      const SizedBox(height: 12),
                      _DataLine(
                        icon: Icons.smart_toy_outlined,
                        text: 'AI Tutor: your question, the recent messages '
                            'of that chat and the lesson and course titles '
                            'are sent through our server to Google Gemini to '
                            'write the answer.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Danger zone',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),

              const SizedBox(height: 12),

              _PrivacyTile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete account',
                subtitle: 'Permanently remove your account and its data',
                destructive: true,
                onTap: _isBusy ? null : _deleteAccount,
              ),
            ],
          ),

          if (_isBusy)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrivacyTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  const _PrivacyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : AppTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: destructive ? color : null,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(subtitle),
          ),
          trailing: const Icon(Icons.chevron_right),
          enabled: onTap != null,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _DataLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DataLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
      ],
    );
  }
}

/// Asks for the password again, then deletes the account. On success the
/// session ends and AuthGate closes this dialog together with every screen.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _isDeleting = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_isDeleting) {
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _error = 'Please enter your password.';
      });
      return;
    }

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    final auth = AuthController.instance;
    final deleted = await auth.deleteAccount(
      password: _passwordController.text,
    );

    if (!mounted || deleted) {
      return;
    }

    setState(() {
      _isDeleting = false;
      _error = auth.lastError ?? 'Your account could not be deleted.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: const Text('Delete account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently deletes your account, profile and quiz results. '
            'It cannot be undone. Enter your password to confirm.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            enabled: !_isDeleting,
            autofocus: true,
            onSubmitted: (_) => _delete(),
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isDeleting ? null : _delete,
          style: FilledButton.styleFrom(backgroundColor: error),
          child: _isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete Account'),
        ),
      ],
    );
  }
}