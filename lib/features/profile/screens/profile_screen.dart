import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../auth/services/auth_controller.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../dashboard/services/learning_activity_service.dart';
import '../../lessons/services/learning_progress_service.dart';
import '../../quizzes/data/mock_quiz_data.dart';
import '../../quizzes/screens/quiz_list_screen.dart';
import '../../quizzes/services/quiz_progress_service.dart';
import 'appearance_screen.dart';
import 'edit_profile_screen.dart';
import 'preferences_screen.dart';
import '../models/profile.dart';
import '../services/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openScreen(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  Future<void> _confirmLogOut(BuildContext context) async {
    final shouldLogOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'You will need to log in again to continue learning.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogOut != true) {
      return;
    }

    // No navigation here: AuthController becomes unauthenticated and
    // AuthGate swaps the app for the welcome flow.
    await AuthController.instance.logOut();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ProfileController.instance,
      builder: (context, _) {
        final profile =
            ProfileController.instance.profile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                tooltip: 'Appearance',
                onPressed: () {
                  _openScreen(
                    context,
                    const AppearanceScreen(),
                  );
                },
                icon: const Icon(
                  Icons.settings_outlined,
                ),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            children: [
              _ProfileHeader(
                profile: profile,
                onEditProfile: () {
                  _openScreen(
                    context,
                    const EditProfileScreen(),
                  );
                },
              ),

              const SizedBox(height: 28),

              const _LearningOverview(),

              const SizedBox(height: 14),

              const _QuizStatsCard(),

              const SizedBox(height: 30),

              const _SectionTitle(
                title: 'Account',
              ),

              const SizedBox(height: 12),

              _ProfileMenuItem(
                icon: Icons.person_outline,
                title: 'Personal Information',
                subtitle:
                    'Manage your name, email and profile',
                onTap: () {
                  _openScreen(
                    context,
                    const EditProfileScreen(),
                  );
                },
              ),

              _ProfileMenuItem(
                icon: Icons.notifications_none,
                title: 'Notifications',
                subtitle:
                    'Manage your learning notifications',
                onTap: () {},
              ),

              _ProfileMenuItem(
                icon: Icons.tune,
                title: 'Preferences',
                subtitle:
                    'Customize your learning experience',
                onTap: () {
                  _openScreen(
                    context,
                    const PreferencesScreen(),
                  );
                },
              ),

              const SizedBox(height: 28),

              const _SectionTitle(
                title: 'Learning',
              ),

              const SizedBox(height: 12),

              _ProfileMenuItem(
                icon: Icons.menu_book_outlined,
                title: 'My Courses',
                subtitle:
                    'View your enrolled courses',
                onTap: () {},
              ),

              _ProfileMenuItem(
                icon:
                    Icons.workspace_premium_outlined,
                title: 'Certificates',
                subtitle:
                    'View your earned certificates',
                onTap: () {},
              ),

              _ProfileMenuItem(
                icon: Icons.flag_outlined,
                title: 'Learning Goals',
                subtitle:
                    'Set and track your learning goals',
                onTap: () {},
              ),

              const SizedBox(height: 28),

              const _SectionTitle(
                title: 'Settings',
              ),

              const SizedBox(height: 12),

              _ProfileMenuItem(
                icon: Icons.dark_mode_outlined,
                title: 'Appearance',
                subtitle:
                    'Light, dark and system themes',
                onTap: () {
                  _openScreen(
                    context,
                    const AppearanceScreen(),
                  );
                },
              ),

              _ProfileMenuItem(
                icon: Icons.lock_outline,
                title: 'Privacy',
                subtitle:
                    'Manage your privacy settings',
                onTap: () {},
              ),

              _ProfileMenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle:
                    'Get help with the platform',
                onTap: () {},
              ),

              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: () => _confirmLogOut(context),
                icon: const Icon(
                  Icons.logout,
                ),
                label: const Text(
                  'Log Out',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                  minimumSize: const Size(
                    double.infinity,
                    52,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'AI Education Platform',
                  style: TextStyle(
                    color:
                        AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEditProfile;

  const _ProfileHeader({
    required this.profile,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color:
                    AppTheme.primaryColor.withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 52,
                color: AppTheme.primaryColor,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Text(
          profile.name,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 4),

        Text(
          profile.email,
          style:
              Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 10),

        Text(
          profile.bio,
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
        ),

        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: onEditProfile,
          icon: const Icon(
            Icons.edit_outlined,
            size: 18,
          ),
          label: const Text(
            'Edit Profile',
          ),
        ),
      ],
    );
  }
}

class _QuizStatsCard extends StatelessWidget {
  const _QuizStatsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: QuizProgressService.instance,
      builder: (context, child) {
        final service = QuizProgressService.instance;
        final total = MockQuizData.quizzes.length;

        final subtitle = service.totalAttempts == 0
            ? '$total quizzes available'
            : '${service.quizzesPassed} of $total passed · '
                '${service.averageBestPercentage.round()}% average';

        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuizListScreen(),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.quiz_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            title: const Text(
              'Quizzes',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class _LearningOverview extends StatelessWidget {
  const _LearningOverview();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        LearningProgressService.instance,
        LearningActivityService.instance,
      ]),
      builder: (context, child) {
        final snapshot = DashboardService.snapshot();

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.menu_book_outlined,
                    value: '${snapshot.coursesStarted}',
                    label: 'Started',
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _StatItem(
                    icon: Icons.check_circle_outline,
                    value: '${snapshot.coursesCompleted}',
                    label: 'Completed',
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _StatItem(
                    icon: Icons.access_time_outlined,
                    value: DashboardService.formatDuration(
                      snapshot.totalSeconds,
                    ),
                    label: 'Learning',
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _StatItem(
                    icon: Icons.local_fire_department_outlined,
                    value: '${snapshot.streak}',
                    label: 'Day Streak',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 21,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 45,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
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

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        child: PressableScale(
          onTap: onTap,
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
                  color: AppTheme.primaryColor.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(
                  top: 3,
                ),
                child: Text(
                  subtitle,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}