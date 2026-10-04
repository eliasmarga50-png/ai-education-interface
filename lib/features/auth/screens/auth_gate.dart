import 'package:flutter/material.dart';

import '../../home/screens/main_shell.dart';
import '../services/auth_controller.dart';

class AuthGate extends StatefulWidget {
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
_initializeAuthentication();
}

Future<void> _initializeAuthentication() async {
await _authController.initialize();


if (!mounted) {
  return;
}

setState(() {
  _isInitializing = false;
});


}

@override
Widget build(BuildContext context) {
if (_isInitializing) {
return const Scaffold(
body: Center(
child: CircularProgressIndicator(),
),
);
}


if (_authController.isLoggedIn) {
  return const MainShell();
}

return const Scaffold(
  body: Center(
    child: Text(
      'Authentication screens coming next',
    ),
  ),
);


}
}
