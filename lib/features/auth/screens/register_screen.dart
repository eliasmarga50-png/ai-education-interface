


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
}






