



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
    
  }
}



