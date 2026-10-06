import 'package:flutter/material.dart';

import '../services/auth_controller.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
  });

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (loginContext) => LoginScreen(
          // "Sign up" on the login screen swaps itself for the register
          // screen, so Back returns to Welcome instead of stacking screens.
          onCreateAccountTap: () {
            Navigator.of(loginContext).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RegisterScreen(
                  authController: AuthController.instance,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          authController: AuthController.instance,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    final horizontalPadding = size.width < 600 ? 24.0 : 48.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 32,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // App identity.
                  Icon(
                    Icons.school_rounded,
                    size: 88,
                    color: theme.colorScheme.primary,
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Welcome to AI Education',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Learn at your own pace, practice with AI, '
                    'and build skills that move you forward.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Primary action.
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _openLogin(context),
                      child: const Text('Log In'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary action.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _openRegister(context),
                      child: const Text('Create Account'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Your learning journey starts here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}