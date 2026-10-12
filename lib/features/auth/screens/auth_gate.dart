import 'package:flutter/material.dart';

import '../../home/screens/main_shell.dart';
import '../services/auth_controller.dart';
import 'splash_screen.dart';
import 'verification_screen.dart';

/// Root of the app. Rebuilds whenever [AuthController] changes and shows the
/// screen that matches the current [AuthStatus], so no auth screen ever has
/// to navigate into (or out of) the app by hand.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthController _authController = AuthController.instance;

  AuthStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _authController.addListener(_closePushedScreensWhenSignedOut);
    _authController.initialize();
  }

  @override
  void dispose() {
    _authController.removeListener(_closePushedScreensWhenSignedOut);
    super.dispose();
  }

  /// Screens opened with Navigator.push (edit profile, lessons, dialogs...) live
  /// above this widget. When the session ends (logout, expired session) they
  /// would stay on screen on top of the sign-in flow, so close them all.
  void _closePushedScreensWhenSignedOut() {
    final status = _authController.status;
    final wasAuthenticated = _lastStatus == AuthStatus.authenticated;
    _lastStatus = status;

    if (wasAuthenticated && status != AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _authController,
      builder: (context, _) {
        debugPrint('AUTH GATE → status: ${_authController.status}');

        switch (_authController.status) {
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );

          case AuthStatus.authenticated:
            return const MainShell();

          case AuthStatus.needsVerification:
            return VerificationScreen(
              authController: _authController,
              email: _authController.currentUser?.email ?? '',
            );

          case AuthStatus.unauthenticated:
            // A nested Navigator keeps Splash -> Welcome -> Login/Register
            // inside the gate. When the status changes, the gate replaces
            // this whole Navigator, so no old screens stay on the stack.
            return Navigator(
              key: const ValueKey('signed-out-navigator'),
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => const SplashScreen(),
              ),
            );
        }
      },
    );
  }
}