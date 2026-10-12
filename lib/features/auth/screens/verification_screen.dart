import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_controller.dart';

/// Asks for the 6-digit code that the server emailed. On success
/// AuthController becomes authenticated and AuthGate swaps this screen for
/// the app, so nothing here navigates.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.authController,
    required this.email,
  });

  final AuthController authController;
  final String email;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();

  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;
  String? _notice;
  int _secondsLeft = 0;
  Timer? _ticker;

  AuthController get _authController => widget.authController;

  @override
  void initState() {
    super.initState();
    _notice = _authController.verificationNotice;
    _updateCountdown();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _updateCountdown() {
    final availableAt = _authController.resendAvailableAt;
    final left = availableAt == null
        ? 0
        : availableAt.difference(DateTime.now()).inSeconds + 1;
    final clamped = left < 0 ? 0 : left;

    if (clamped != _secondsLeft && mounted) {
      setState(() {
        _secondsLeft = clamped;
      });
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(() {
        _error = 'Enter the 6-digit code.';
      });
      return;
    }
    if (_isVerifying) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final user = await _authController.verifyEmail(code: code);

    if (!mounted) {
      return;
    }

    // On success AuthGate replaces this screen; only failures stay here.
    if (user == null) {
      setState(() {
        _isVerifying = false;
        _error = _authController.lastError ??
            'We could not verify your email. Please try again.';
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _error = null;
      _notice = null;
    });

    final ok = await _authController.resendVerificationCode();

    if (!mounted) {
      return;
    }

    setState(() {
      _isResending = false;
      _codeController.clear();
    });
    _updateCountdown();

    _showMessage(
      ok
          ? 'A new code has been sent to ${widget.email}.'
          : _authController.lastError ?? 'Could not send a new code.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _isVerifying || _isResending;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
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
                    'We sent a 6-digit code to:',
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
                  if (_notice != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _notice!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  TextField(
                    controller: _codeController,
                    enabled: !busy,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: theme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••••',
                      errorText: _error,
                      errorMaxLines: 2,
                    ),
                    onChanged: (value) {
                      if (_error != null) {
                        setState(() {
                          _error = null;
                        });
                      }
                      if (value.length == 6) {
                        _verify();
                      }
                    },
                    onSubmitted: (_) => _verify(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: busy ? null : _verify,
                      child: _isVerifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Verify'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: busy || _secondsLeft > 0 ? null : _resend,
                    child: _isResending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _secondsLeft > 0
                                ? 'Resend code in ${_secondsLeft}s'
                                : 'Resend code',
                          ),
                  ),
                  const SizedBox(height: 8),
                  // Escape hatch for a mistyped email: AuthGate returns to the
                  // welcome flow so the user can register again.
                  TextButton(
                    onPressed:
                        busy ? null : _authController.discardUnverifiedAccount,
                    child: const Text('Use a different email'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The code expires in 10 minutes. Check your spam or '
                    'junk folder if you do not see the email.',
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
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}