


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






