import 'dart:io';

import 'package:chatappui/data/models/user_model.dart';
import 'package:chatappui/data/services/media_picker_service.dart';
import 'package:chatappui/data/services/user_service.dart';
import 'package:chatappui/presentation/screens/home/bottom_nav_screen.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final UserService _userService = UserService();
  final MediaPickerService _mediaPickerService = MediaPickerService();

  File? _selectedImageFile;
  String _currentPhotoUrl = '';
  bool _isLoading = false;
  bool _isFetching = true;
  double _uploadProgress = 0;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    final currentUser = await _userService.getCurrentUser();
    if (!mounted) return;

    if (currentUser != null) {
      _applyUserData(currentUser);
    }

    setState(() => _isFetching = false);
  }

  void _applyUserData(UserModel user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _bioController.text = user.bio;
    _currentPhotoUrl = user.photoUrl;
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final file = await _mediaPickerService.pickImageFromCamera();
                  if (!mounted || file == null) return;
                  setState(() => _selectedImageFile = file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final file = await _mediaPickerService.pickImageFromGallery();
                  if (!mounted || file == null) return;
                  setState(() => _selectedImageFile = file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty) {
      setState(() => _errorMsg = 'First name is required.');
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
      _errorMsg = null;
    });

    try {
      await _userService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        bio: _bioController.text.trim(),
        photoFile: _selectedImageFile,
        onPhotoUploadProgress: (progress) {
          if (!mounted) return;
          setState(() => _uploadProgress = progress);
        },
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMsg = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAvatarPreview() {
    if (_selectedImageFile != null) {
      return CircleAvatar(
        radius: 56,
        backgroundImage: FileImage(_selectedImageFile!),
      );
    }

    if (_currentPhotoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 56,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: Image.network(
            _currentPhotoUrl,
            width: 112,
            height: 112,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return UiHelper.loadingPlaceholder(
                height: 112,
                width: 112,
                borderRadius: BorderRadius.circular(999),
              );
            },
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.person_outline, size: 56),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 56,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Icon(
        Icons.person_outline,
        size: 60,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: UiHelper.customText(
          text: 'Your Profile',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          context: context,
        ),
        actions: [UiHelper.darkModeToggle(context)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _buildAvatarPreview(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _showPhotoOptions,
              child: UiHelper.customText(
                text: _currentPhotoUrl.isEmpty && _selectedImageFile == null
                    ? 'Upload Photo'
                    : 'Change Photo',
                fontSize: 13,
                context: context,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (_isLoading && _selectedImageFile != null) ...[
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 6),
              UiHelper.customText(
                text: 'Uploading photo... ${(_uploadProgress * 100).round()}%',
                fontSize: 12,
                context: context,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ],
            const SizedBox(height: 20),
            UiHelper.customTextField(
              controller: _firstNameController,
              hintText: 'First Name (Required)',
              prefixIcon: Icons.person_outline,
              context: context,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 14),
            UiHelper.customTextField(
              controller: _lastNameController,
              hintText: 'Last Name (Optional)',
              prefixIcon: CupertinoIcons.person_2,
              context: context,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 14),
            UiHelper.customTextField(
              controller: _bioController,
              hintText: 'Bio (Optional)',
              prefixIcon: Icons.info_outline,
              context: context,
              textInputAction: TextInputAction.done,
              maxLines: 3,
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: UiHelper.customButton(
        label: 'Save Profile',
        onPressed: _saveProfile,
        isLoading: _isLoading,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
