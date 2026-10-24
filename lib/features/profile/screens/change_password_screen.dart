import 'package:flutter/material.dart';

import '../../../core/validation/validators.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../auth/services/auth_controller.dart';
import '../widgets/profile_feedback.dart';

/// Changes the password of the signed-in account. The server asks for the
/// current password again, signs every other device out, and keeps this one
/// signed in.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final auth = AuthController.instance;
    final changed = await auth.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );

    if (!mounted) {
      return;
    }

    if (!changed) {
      setState(() {
        _isSaving = false;
        _error = auth.lastError ?? 'Your password could not be changed.';
      });
      return;
    }

    showProfileSnack(
      context,
      'Password changed. Your other devices were signed out.',
    );
    Navigator.pop(context);
  }

  InputDecoration _decoration({
    required String label,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: visible ? 'Hide password' : 'Show password',
        onPressed: onToggle,
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          children: [
            if (_error != null)
              AppErrorBanner(
                message: _error!,
                onDismiss: () {
                  setState(() {
                    _error = null;
                  });
                },
              ),

            TextFormField(
              controller: _currentController,
              obscureText: !_showCurrent,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.password],
              decoration: _decoration(
                label: 'Current password',
                visible: _showCurrent,
                onToggle: () {
                  setState(() {
                    _showCurrent = !_showCurrent;
                  });
                },
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter your current password.'
                  : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _newController,
              obscureText: !_showNew,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: _decoration(
                label: 'New password',
                visible: _showNew,
                onToggle: () {
                  setState(() {
                    _showNew = !_showNew;
                  });
                },
              ),
              validator: (value) {
                final problem = Validators.newPassword(value);
                if (problem != null) {
                  return problem;
                }
                if (value == _currentController.text) {
                  return 'Choose a password different from your current one.';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _confirmController,
              obscureText: !_showNew,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) =>
                  Validators.confirmPassword(value, _newController.text),
            ),

            const SizedBox(height: 10),

            Text(
              'Use at least 8 characters, with a letter and a number. '
              'Your other devices will be signed out.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Changing...' : 'Change Password'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}