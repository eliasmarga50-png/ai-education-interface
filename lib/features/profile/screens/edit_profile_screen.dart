


import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/profile_controller.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => 
    _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> { 
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;

  final _profileController = ProfileController.instance;

  
}



