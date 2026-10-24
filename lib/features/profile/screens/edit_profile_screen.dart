import 'package:flutter/material.dart';

import '../../../core/validation/validators.dart';
import '../services/profile_controller.dart';
import '../services/profile_photo_picker.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_feedback.dart';

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

    _nameController =
        TextEditingController(text: profile.name);

    _emailController =
        TextEditingController(text: profile.email);

    _bioController =
        TextEditingController(text: profile.bio);
  }

  bool _isSaving = false;

  Future<void> _pickAvatar() async {
    if (_profileController.isUpdatingAvatar) {
      return;
    }

    // Resizes the photo, uploads it to the account and keeps a copy here.
    final message = await ProfilePhotoPicker.pickAndUpload();

    if (!mounted || message == null) {
      return;
    }

    showProfileSnack(
      context,
      message,
      isError: true,
      onRetry: _pickAvatar,
    );
  }

  Future<void> _removeAvatar() async {
    if (_profileController.isUpdatingAvatar) {
      return;
    }

    final removed = await _profileController.removeAvatar();

    if (!mounted) {
      return;
    }

    if (removed) {
      showProfileSnack(context, 'Profile photo removed.');
      return;
    }

    showProfileSnack(
      context,
      _profileController.lastError ??
          'We could not remove your photo. Please try again.',
      isError: true,
      onRetry: _removeAvatar,
    );
  }

  Future<void> _saveProfile() async {
    // The AppBar button and the bottom button both call this.
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });

    final saved = await _profileController.updateProfile(
      name: _nameController.text,
      bio: _bioController.text,
    );

    if (!mounted) {
      return;
    }

    if (!saved) {
      setState(() {
        _isSaving = false;
      });
      showProfileSnack(
        context,
        _profileController.lastError ??
            'Your profile could not be saved. Please try again.',
        isError: true,
        onRetry: _saveProfile,
      );
      return;
    }

    showProfileSnack(context, 'Profile updated successfully.');

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
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
              child: AnimatedBuilder(
                animation: _profileController,
                builder: (context, _) {
                  final profile =
                      _profileController.profile;
                  final isUploading =
                      _profileController.isUpdatingAvatar;

                  return Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ProfileAvatar(
                            imagePath: profile.avatarUrl,
                            radius: 58,
                            fallbackText: profile.name,
                          ),
                          if (isUploading)
                            const Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Material(
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: isUploading
                                  ? null
                                  : _pickAvatar,
                              customBorder:
                                  const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      TextButton.icon(
                        onPressed:
                            isUploading ? null : _pickAvatar,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                        ),
                        label: const Text(
                          'Change profile photo',
                        ),
                      ),

                      if (profile.avatarUrl.isNotEmpty)
                        TextButton.icon(
                          onPressed: isUploading
                              ? null
                              : _removeAvatar,
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                          label: const Text(
                            'Remove photo',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Personal Information',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction:
                  TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(
                  Icons.person_outline,
                ),
              ),
              validator: Validators.name,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              readOnly: true,
              keyboardType:
                  TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email address',
                helperText: 'Your email is tied to your account.',
                prefixIcon: Icon(
                  Icons.email_outlined,
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _bioController,
              maxLines: 4,
              maxLength: ProfileController.maxBioLength,
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
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.save_outlined,
                    ),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Changes',
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