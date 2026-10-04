


import 'package:flutter/widgets.dart';

import 'package/material.dart';

import '../../home/screens/main_shell.dart';
import '../services/auth_controller.dart';

class AuthGate extends StatefulWidget{
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthController _authController = AuthController();

  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeAtheentication();
  }

  
}



