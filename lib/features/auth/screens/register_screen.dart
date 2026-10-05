


import 'package:flutter/material.dart';
import '../services/auth_controller.dart';

class RegisterScreen extends StatefulWidget{
  final AuthController authController;

  const RegisterScreen({
    super.key,
    required this.authController,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSubmitting = false;
  AuthController get _authController => widget.authController;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()){
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await _authController.register(
        name: _nameController.text, 
        email: _emailController.text, 
        password: _passwordController.text,
        );

        if (!mounted) {
          return;
        }

        if (user==null) {
          _showMessage('Unable to create your account');
          return;
        }

        Navigator.of(context).pop(user);
    } finally {}
  }
  

}






