import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/validation/validators.dart';
import '../services/profile_controller.dart';
import '../widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _imagePicker = ImagePicker();

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
  bool _isPickingAvatar = false;

  Future<void> _pickAvatar() async {
    if (_isPickingAvatar) {
      return;
    }
    _isPickingAvatar = true;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) {
        return;
      }

      // The controller copies the photo to permanent storage (on phones the
      // picked file is only a temporary cache file).
      final saved = await _profileController.updateAvatar(image.path);

      if (!mounted) {
        return;
      }

      if (!saved) {
        _showMessage('We could not save your photo. Please try again.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'We could not open your photos. Check the permission and try again.',
        );
      }
    } finally {
      _isPickingAvatar = false;
    }
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
      _showMessage('Your profile could not be saved. Please log in again.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Profile updated successfully.',
        ),
      ),
    );

    Navigator.pop(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

                  return Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ProfileAvatar(
                        imagePath: profile.avatarUrl,
                        radius: 58,
                        fallbackText: profile.name,
                      ),
                      Material(
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _pickAvatar,
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
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: TextButton.icon(
                onPressed: _pickAvatar,
                icon: const Icon(
                  Icons.photo_library_outlined,
                ),
                label: const Text(
                  'Change profile photo',
                ),
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
              onPressed: _isSaving ? null : _saveProfile,
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