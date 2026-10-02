import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;

  final _profileController =
      ProfileController.instance;

  @override
  void initState() {
    super.initState();

    final profile = _profileController.profile;

    _nameController = TextEditingController(
      text: profile.name,
    );

    _emailController = TextEditingController(
      text: profile.email,
    );

    _bioController = TextEditingController(
      text: profile.bio,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _profileController.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      bio: _bioController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully.'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            30,
          ),
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 52,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Personal Information',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(
                  Icons.person_outline,
                ),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter your name.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              keyboardType:
                  TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(
                  Icons.email_outlined,
                ),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'Please enter your email.';
                }

                if (!email.contains('@') ||
                    !email.contains('.')) {
                  return 'Please enter a valid email.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText:
                    'Tell us a little about yourself...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(
                    bottom: 70,
                  ),
                  child: Icon(
                    Icons.edit_note_outlined,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(
                Icons.save_outlined,
              ),
              label: const Text(
                'Save Changes',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  52,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}