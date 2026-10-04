import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
const SplashScreen({
super.key,
});

@override
Widget build(BuildContext context) {
return Scaffold(
body: SafeArea(
child: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.school_rounded,
size: 72,
),
const SizedBox(height: 24),
Text(
'AI Education',
style: Theme.of(context).textTheme.headlineMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 12),
Text(
'Learn smarter. Learn with AI.',
style: Theme.of(context).textTheme.bodyLarge,
textAlign: TextAlign.center,
),
const SizedBox(height: 32),
const SizedBox(
width: 28,
height: 28,
child: CircularProgressIndicator(
strokeWidth: 3,
),
),
],
),
),
),
);
}
}
