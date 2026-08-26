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
  final String? initialCountryCode;
  final String? initialGender;
  final String? initialProfession;
  final DateTime? initialDateOfBirth;

  const EditProfilePage({super.key, required this.repository, required this.initialName, required this.initialUsername, required this.initialBio, this.initialAvatarUrl, this.initialCountryCode, this.initialGender, this.initialProfession, this.initialDateOfBirth});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  late final TextEditingController _country;
  late final TextEditingController _profession;
  final _picker = ImagePicker();
  bool _saving = false;
  XFile? _avatar;
  late String _gender;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _username = TextEditingController(text: widget.initialUsername.replaceFirst('@', ''));
    _bio = TextEditingController(text: widget.initialBio);
    _country = TextEditingController(text: widget.initialCountryCode ?? 'IN');
    _profession = TextEditingController(text: widget.initialProfession ?? '');
    _gender = widget.initialGender ?? 'prefer_not_to_say';
    _dateOfBirth = widget.initialDateOfBirth;
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    _country.dispose();
    _profession.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 1024);
    if (picked != null && mounted) setState(() => _avatar = picked);
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'SELECT DATE OF BIRTH',
    );
    if (selected != null && mounted) setState(() => _dateOfBirth = selected);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty || _username.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and username are required.')));
      return;
    }
    final country = _country.text.trim().toUpperCase();
    if (country.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Country must be a 2-letter country code, for example IN.')));
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
        countryCode: country,
        gender: _gender,
        profession: _profession.text,
        dateOfBirth: _dateOfBirth,
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
    if (_avatar != null) image = FileImage(File(_avatar!.path));
    else if (widget.initialAvatarUrl != null) image = NetworkImage(widget.initialAvatarUrl!);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), actions: [TextButton(onPressed: _saving ? null : _save, child: const Text('SAVE'))]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Center(child: GestureDetector(onTap: _pickAvatar, child: Stack(alignment: Alignment.bottomRight, children: [
              CircleAvatar(radius: 52, backgroundImage: image, child: image == null ? const Icon(Icons.person_outline, size: 52) : null),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18)),
            ]))),
            const SizedBox(height: 28),
            TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Display name', prefixIcon: Icon(Icons.badge_outlined))),
            const SizedBox(height: 16),
            TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email))),
            const SizedBox(height: 16),
            TextField(controller: _bio, maxLines: 4, maxLength: 160, decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true, prefixIcon: Icon(Icons.edit_note_outlined))),
            const SizedBox(height: 16),
            TextField(controller: _country, textCapitalization: TextCapitalization.characters, maxLength: 2, decoration: const InputDecoration(labelText: 'Country code', hintText: 'IN', counterText: '', prefixIcon: Icon(Icons.public_outlined))),
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
            const SizedBox(height: 16),
            TextField(controller: _profession, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Profession', hintText: 'Creator, Farmer, Doctor, Lawyer, Police…', prefixIcon: Icon(Icons.work_outline))),
            const SizedBox(height: 8),
            Card(child: ListTile(
              leading: const Icon(Icons.cake_outlined),
              title: const Text('Date of birth'),
              subtitle: Text(_formatDate(_dateOfBirth)),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _saving ? null : _pickDateOfBirth,
            )),
            const SizedBox(height: 8),
            Text('Country, gender and profession can be shown as profile information. Date of birth is stored for account/profile use and should not be exposed as a full date on public profiles.', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Text('Your profile name, username and bio are public. Never add private payout or KYC information here.', style: theme.textTheme.bodySmall),
            if (_saving) ...const [SizedBox(height: 24), Center(child: CircularProgressIndicator())],
          ],
        ),
      ),
    );
  }
}
