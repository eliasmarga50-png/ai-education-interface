import 'package:flutter/material.dart';

import '../services/auth_controller.dart';

class VerificationScreen extends StatefulWidget {
final AuthController authController;
final String email;

const VerificationScreen({
super.key,
required this.authController,
required this.email,
});

@override
State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
bool _isVerifying = false;
bool _isResending = false;

AuthController get _authController => widget.authController;

Future<void> _verifyEmail() async {
setState(() {
_isVerifying = true;
});


try {
  final user = await _authController.verifyEmail();

  if (!mounted) {
    return;
  }

  if (user == null) {
    _showMessage(
      'We could not verify your email. Please try again.',
    );
    return;
  }

  // No navigation here: AuthController is now authenticated and
  // AuthGate swaps this screen for MainShell.
} finally {
  if (mounted) {
    setState(() {
      _isVerifying = false;
    });
  }
}


}

Future<void> _resendVerification() async {
setState(() {
_isResending = true;
});


try {
  // The real email service will be connected later.
  await Future<void>.delayed(
    const Duration(milliseconds: 500),
  );

  if (!mounted) {
    return;
  }

  _showMessage(
    'A new verification email has been requested.',
  );
} finally {
  if (mounted) {
    setState(() {
      _isResending = false;
    });
  }
}


}

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);


return Scaffold(
  body: SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              Icon(
                Icons.mark_email_read_outlined,
                size: 88,
                color: theme.colorScheme.primary,
              ),

              const SizedBox(height: 28),

              Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'We sent a verification email to:',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Please verify your email address before '
                'continuing to your learning dashboard.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isVerifying || _isResending
                      ? null
                      : _verifyEmail,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('I Verified My Email'),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: _isVerifying || _isResending
                    ? null
                    : _resendVerification,
                child: _isResending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Resend Verification Email'),
              ),

              const SizedBox(height: 8),

              // Escape hatch for a mistyped email: deletes the unverified
              // account; AuthGate then returns to the welcome flow.
              TextButton(
                onPressed: _isVerifying || _isResending
                    ? null
                    : _authController.discardUnverifiedAccount,
                child: const Text('Use a different email'),
              ),

              const SizedBox(height: 16),

              Text(
                'Check your spam or junk folder if you do not '
                'see the email in your inbox.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
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

void _showMessage(String message) {
ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(message),
),
);
}
}