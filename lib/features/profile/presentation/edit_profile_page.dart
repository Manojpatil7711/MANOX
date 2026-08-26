import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/profile_repository.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileRepository repository;
  final String initialName;
  final String initialUsername;
  final String initialBio;
  final String? initialAvatarUrl;

  const EditProfilePage({super.key, required this.repository, required this.initialName, required this.initialUsername, required this.initialBio, this.initialAvatarUrl});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  final _picker = ImagePicker();
  bool _saving = false;
  XFile? _avatar;
  String _gender = 'prefer_not_to_say';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _username = TextEditingController(text: widget.initialUsername.replaceFirst('@', ''));
    _bio = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 1024);
    if (picked != null && mounted) setState(() => _avatar = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty || _username.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and username are required.')));
      return;
    }
    setState(() => _saving = true);
    try {
      String? avatarPath;
      if (_avatar != null) {
        final bytes = await _avatar!.readAsBytes();
        avatarPath = await widget.repository.uploadAvatar(bytes, 'jpg', 'image/jpeg');
      }
      final updated = await widget.repository.updateProfile(
        displayName: _name.text,
        username: _username.text,
        bio: _bio.text,
        avatarPath: avatarPath,
        gender: _gender,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save profile: $e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ImageProvider<Object>? image;
    if (_avatar != null) {
      image = FileImage(File(_avatar!.path));
    } else if (widget.initialAvatarUrl != null) {
      image = NetworkImage(widget.initialAvatarUrl!);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), actions: [TextButton(onPressed: _saving ? null : _save, child: const Text('SAVE'))]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(alignment: Alignment.bottomRight, children: [
                  CircleAvatar(radius: 52, backgroundImage: image, child: image == null ? const Icon(Icons.person_outline, size: 52) : null),
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18)),
                ]),
              ),
            ),
            const SizedBox(height: 28),
            TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Display name', prefixIcon: Icon(Icons.badge_outlined))),
            const SizedBox(height: 16),
            TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email))),
            const SizedBox(height: 16),
            TextField(controller: _bio, maxLines: 4, maxLength: 160, decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true, prefixIcon: Icon(Icons.edit_note_outlined))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.person_outline)),
              items: const [
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
                DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
              ],
              onChanged: _saving ? null : (value) => setState(() => _gender = value ?? 'prefer_not_to_say'),
            ),
            const SizedBox(height: 8),
            Text('Selecting Female enables MANOX Safety Alert Mode. Your gender is not displayed publicly by this control.', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Text('Your profile name, username and bio are public. Never add private payout or KYC information here.', style: theme.textTheme.bodySmall),
            if (_saving) ...const [SizedBox(height: 24), Center(child: CircularProgressIndicator())],
          ],
        ),
      ),
    );
  }
}
