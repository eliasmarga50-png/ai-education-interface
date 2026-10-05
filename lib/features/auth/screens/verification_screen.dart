


import 'package:ai_education_interface/features/home/screens/main_shell.dart';
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

  AuthController get_authController => widget.authController;

  Future<void> _verifyEmail() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final user = await get_authController.verifyEmail();

      if (!mounted) {
        return;
      }

      if (user==null) {
        _showMessage(
          'We could not verify your email. Please try again',
        );
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainShell(),
          ),
          (route) => false,
        );
    } finally {}
  }
}




