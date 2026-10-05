



import 'package:flutter/material.dart';
import '../services/auth_controller.dart';


class ForgotPasswordScreen extends StatefulWidget{
  final AuthController authController;

  const ForgotPasswordScreen({
    super.key,
    required this.authController,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();

  class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
    final _formKey = GlobalKey<FormState>();
    final _emailController = TextEditingController();

    bool _isSubmitting = false;

    AuthController get_authController => widget.authController;

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
        _isSubmitting = false;
      });

      try {
        final success = await _authController.resetPassword(
          email: _emailController.text,
        );

        if(!mounted) {
          return;
        }

        if (success) {
          _showSuccessMessage(
            'If an account exists for this email, '
            'password reset instructions have been sent'
          );
        } else {
          _ShowMessage(
            'We could not process your request. Please try again.',
          );
        }
      }  finally {
        if (mounted) {
          setState((){
            _isSubmitting = false;
          });
        }
      }
    }

    
  }
}



