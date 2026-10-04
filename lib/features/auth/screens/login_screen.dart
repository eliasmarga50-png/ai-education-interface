


import 'package:flutter/material.dart';

import '../services/auth_controller.dart';

class LoginScreen extends StatefulWidget {
final AuthController authController;

const LoginScreen({
super.key,
required this.authController,
});

@override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final _formKey = GlobalKey<FormState>();

final _emailController = TextEditingController();
final _passwordController = TextEditingController();

bool _isPasswordVisible = false;
bool _isSubmitting = false;

AuthController get _authController => widget.authController;

@override
void dispose() {
_emailController.dispose();
_passwordController.dispose();
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
  final user = await _authController.login(
    email: _emailController.text,
    password: _passwordController.text,
  );

  if (!mounted) {
    return;
  }

  if (user == null) {
    _showMessage('Please check your email and password.');
    return;
  }

  Navigator.of(context).pop(user);
} finally {
  if (mounted) {
    setState(() {
      _isSubmitting = false;
    });
  }
}


}

void _openForgotPassword() {
// Forgot password screen will be connected next.
}

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);


return Scaffold(
  appBar: AppBar(
    title: const Text('Log In'),
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

                Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Log in to continue your learning journey.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
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

                    if (!email.contains('@')) {
                      return 'Please enter a valid email.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [
                    AutofillHints.password,
                  ],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _isPasswordVisible
                          ? 'Hide password'
                          : 'Show password',
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : _openForgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),

                const SizedBox(height: 16),

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
                        : const Text('Log In'),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Your account is securely stored on this device '
                  'for now. Backend authentication will be connected later.',
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



