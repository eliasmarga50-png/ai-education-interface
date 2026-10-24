import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/profile_feedback.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<(String, String)> _faq = [
    (
      'How do I change my name, bio or photo?',
      'Open Profile and tap Edit Profile. Your changes are saved to your '
          'account, so they are the same on every device you log in on. '
          'Your email address cannot be changed.',
    ),
    (
      'I forgot my password',
      'On the login screen tap Forgot password. We email you a 6-digit code; '
          'check your spam folder if it does not arrive. If you are logged in, '
          'use Profile > Privacy > Change password.',
    ),
    (
      'How does the AI Tutor work?',
      'Your question, the recent messages of that chat and the lesson and '
          'course titles are sent through our server to Google Gemini, which '
          'writes the answer. Answers can be wrong, so check anything '
          'important.',
    ),
    (
      'Where is my progress saved?',
      'Lesson progress, study time, streak and AI Tutor chats are saved on '
          'this device. Quiz results are saved on your account.',
    ),
    (
      'Why do I not get reminders?',
      'Reminder settings are saved to your account, but this version of the '
          'app does not send reminders to your device yet.',
    ),
    (
      'How do I delete my account?',
      'Go to Profile > Privacy > Delete account. You will be asked for your '
          'password. This cannot be undone.',
    ),
  ];

  Future<void> _emailSupport(BuildContext context) async {
    final email = ApiConfig.supportEmail;
    final subject = Uri.encodeComponent('AI Education Platform support');
    final uri = Uri.parse('mailto:$email?subject=$subject');

    var opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {
      opened = false;
    }

    if (opened || !context.mounted) {
      return;
    }

    // No mail app on this device: give the address so it can be used elsewhere.
    await Clipboard.setData(ClipboardData(text: email));
    if (!context.mounted) {
      return;
    }
    showProfileSnack(
      context,
      'No mail app found. The address $email was copied.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ApiConfig.supportEmail;
    final configured = email.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Text(
            'Frequently asked questions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (question, answer) in _faq)
                  ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: Text(
                      question,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(answer, style: const TextStyle(height: 1.5))],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Contact us',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
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
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: const Text(
                'Email support',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                configured
                    ? email
                    : 'Support email is not set up in this build.',
              ),
              trailing: configured ? const Icon(Icons.chevron_right) : null,
              enabled: configured,
              onTap: configured ? () => _emailSupport(context) : null,
            ),
          ),
        ],
      ),
    );
  }
}