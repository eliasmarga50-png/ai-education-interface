import 'package:flutter/material.dart';

import '../services/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
final AuthController authController;

const ForgotPasswordScreen({
super.key,
required this.authController,
});

@override
State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController();

bool _isSubmitting = false;

AuthController get _authController => widget.authController;

@override
void dispose() {
_emailController.dispose();
super.dispose();
}

Future<void> _submit() async {
FocusScope.of(context).unfocus();


if (!_formKey.currentState!.validate()) {
  return;
}

setState(() {
  _isSubmitting = true;
});

try {
  final success = await _authController.resetPassword(
    email: _emailController.text,
  );

  if (!mounted) {
    return;
  }

  if (success) {
    _showSuccessMessage(
      'If an account exists for this email, '
      'password reset instructions have been sent.',
    );
  } else {
    _showMessage(
      'We could not process your request. Please try again.',
    );
  }
} finally {
  if (mounted) {
    setState(() {
      _isSubmitting = false;
    });
  }
}


}

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);


return Scaffold(
  appBar: AppBar(
    title: const Text('Forgot Password'),
  ),
  body: SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                Icon(
                  Icons.lock_reset_rounded,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),

                const SizedBox(height: 24),

                Text(
                  'Reset your password',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Enter the email address associated with your '
                  'account and we will help you reset your password.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [
                    AutofillHints.email,
                  ],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Please enter your email.';
                    }

                    if (!_isValidEmail(email)) {
                      return 'Please enter a valid email.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Send Reset Instructions'),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Back to Log In'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);


}

bool _isValidEmail(String email) {
return RegExp(
r'^[^@\s]+@[^@\s]+.[^@\s]+$',
).hasMatch(email);
}

void _showSuccessMessage(String message) {
ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(message),
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
