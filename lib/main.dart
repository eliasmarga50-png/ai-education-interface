import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/ai_tutor/services/tutor_controller.dart';
import 'features/auth/screens/auth_gate.dart';
import 'features/dashboard/services/learning_activity_service.dart';
import 'features/lessons/services/learning_progress_service.dart';
import 'features/profile/services/profile_controller.dart';
import 'features/quizzes/services/quiz_progress_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved profile (name, email, bio) so greeting shows the real name.
  await ProfileController.instance.initialize();

  // Load saved lesson progress and study activity (streak, learning time).
  await LearningProgressService.instance.initialize();
  await LearningActivityService.instance.initialize();

  // Load saved quiz scores before the first screen is built.
  await QuizProgressService.instance.initialize();

  // Load saved AI Tutor conversations.
  await TutorController.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AI Education Platform',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}