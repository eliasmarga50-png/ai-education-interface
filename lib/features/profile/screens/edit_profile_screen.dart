


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

  @override 
  void initState() {
    super.initState();

    final profile = _profileController.profile;

    _nameController = TextEditingController(text: profile.name);

    _emailController = TextEditingController(text: profile.email);

    _bioController = TextEditingController(text: profile.bio);

    @override 
    void dispose() {
      _nameController.dispose();
      _emailController.dispose();
      _bioController.dispose();
      super.dispose();
    }

    @override
    void _saveProfile() {
      if (!_formKey.currentState!.validate()){
        return;
      }

      _profileController.updateProfile( 
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        bio: _bioController.text.trim(),
      );

      ScaffoldMessenger.of(context).ShowSnackBar(const SnackBar(content: Text('Profile updated successfully.'),));

      Navigator.pop(context);
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(

      );
    }
  }
}



