import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/profile_repository.dart';
import '../data/demo_profile.dart';
import '../data/supabase_profile_repository.dart';

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
  final List<String> initialSkills;
  final String? initialCreatorCategory;
  final String? initialOtherLink;

  const EditProfilePage({
    super.key,
    required this.repository,
    required this.initialName,
    required this.initialUsername,
    required this.initialBio,
    this.initialAvatarUrl,
    this.initialCountryCode,
    this.initialGender,
    this.initialProfession,
    this.initialDateOfBirth,
    this.initialSkills = const [],
    this.initialCreatorCategory,
    this.initialOtherLink,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  late final TextEditingController _country;
  late final TextEditingController _profession;
  late final TextEditingController _otherLink;
  late final TextEditingController _skill;
  final _picker = ImagePicker();
  bool _saving = false;
  XFile? _avatar;
  late String _gender;
  late String _creatorCategory;
  DateTime? _dateOfBirth;
  late List<String> _skills;

  static const _categories = [
    'Dance', 'Music', 'Singing', 'Comedy', 'Education', 'Art', 'Fitness',
    'Sports', 'Fashion', 'Cooking', 'Technology', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _username = TextEditingController(text: widget.initialUsername.replaceFirst('@', ''));
    _bio = TextEditingController(text: widget.initialBio);
    _country = TextEditingController(text: widget.initialCountryCode ?? 'IN');
    _profession = TextEditingController(text: widget.initialProfession ?? '');
    _otherLink = TextEditingController(text: widget.initialOtherLink ?? '');
    _skill = TextEditingController();
    _gender = widget.initialGender ?? 'prefer_not_to_say';
    _creatorCategory = widget.initialCreatorCategory ?? 'Other';
    _dateOfBirth = widget.initialDateOfBirth;
    _skills = [...widget.initialSkills];
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    _country.dispose();
    _profession.dispose();
    _otherLink.dispose();
    _skill.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1024,
    );
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

  String _formatDate(DateTime? date) => date == null
      ? 'Not set'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _addSkill() {
    final skill = _skill.text.trim();
    if (skill.isEmpty || _skills.contains(skill) || _skills.length >= 12) return;
    setState(() {
      _skills.add(skill);
      _skill.clear();
    });
  }

  String? _cleanOtherLink() {
    final value = _otherLink.text.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      _show('Enter a valid link starting with https://');
      return null;
    }
    return uri.toString();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty || _username.text.trim().isEmpty) {
      _show('Name and username are required.');
      return;
    }
    final country = _country.text.trim().toUpperCase();
    if (country.length != 2) {
      _show('Country must be a 2-letter code, for example IN.');
      return;
    }
    final otherLink = _cleanOtherLink();
    if (_otherLink.text.trim().isNotEmpty && otherLink == null) return;

    setState(() => _saving = true);
    try {
      String? avatarPath;
      if (_avatar != null) {
        final bytes = await _avatar!.readAsBytes();
        avatarPath = await widget.repository.uploadAvatar(bytes, 'jpg', 'image/jpeg');
      }

      late ProfileData updated;
      if (widget.repository is SupabaseProfileRepository) {
        updated = await (widget.repository as SupabaseProfileRepository).updateProfileExtended(
          displayName: _name.text.trim(),
          username: _username.text.trim(),
          bio: _bio.text.trim(),
          avatarPath: avatarPath,
          countryCode: country,
          gender: _gender,
          profession: _profession.text.trim(),
          dateOfBirth: _dateOfBirth,
          skills: _skills,
          creatorCategory: _creatorCategory,
          otherLink: otherLink,
        );
      } else {
        updated = await widget.repository.updateProfile(
          displayName: _name.text.trim(),
          username: _username.text.trim(),
          bio: _bio.text.trim(),
          avatarPath: avatarPath,
          countryCode: country,
          gender: _gender,
          profession: _profession.text.trim(),
          dateOfBirth: _dateOfBirth,
        );
        updated = updated.copyWith(otherLink: otherLink);
      }

      if (mounted) Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _show('Could not save profile. Please check your connection and try again.');
    }
  }

  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

  Widget _sectionHeader(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 24, 2, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: child,
      );

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
      appBar: AppBar(
        title: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _saving ? null : _pickAvatar,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundImage: image,
                            child: image == null ? const Icon(Icons.person_outline_rounded, size: 42) : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt_outlined, color: theme.colorScheme.onPrimary, size: 17),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your identity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text('Use a clear photo and name so people recognize you.', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 9),
                          TextButton.icon(onPressed: _saving ? null : _pickAvatar, icon: const Icon(Icons.photo_camera_outlined, size: 18), label: const Text('Change photo')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _sectionHeader('Identity', 'How people see you on MANOX', Icons.badge_outlined),
            _field(TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Display name', prefixIcon: Icon(Icons.person_outline_rounded)))),
            _field(TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email)))),
            _field(TextField(controller: _bio, maxLines: 4, maxLength: 160, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Bio', hintText: 'Tell people what you create…', alignLabelWithHint: true, prefixIcon: Icon(Icons.edit_note_outlined)))),

            _sectionHeader('Creator profile', 'Improve discovery without making the page crowded', Icons.auto_awesome_outlined),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _creatorCategory,
                      decoration: const InputDecoration(labelText: 'Primary category', prefixIcon: Icon(Icons.category_outlined)),
                      items: _categories.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: _saving ? null : (value) => setState(() => _creatorCategory = value ?? 'Other'),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _profession, decoration: const InputDecoration(labelText: 'Profession', hintText: 'e.g. Designer, Teacher, Athlete', prefixIcon: Icon(Icons.work_outline_rounded))),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: Text('Skills', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700))),
                    const SizedBox(height: 8),
                    if (_skills.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _skills.map((skill) => InputChip(label: Text(skill), onDeleted: _saving ? null : () => setState(() => _skills.remove(skill)))).toList(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _skill, onSubmitted: (_) => _addSkill(), decoration: const InputDecoration(hintText: 'Add a skill'))),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(tooltip: 'Add skill', onPressed: _saving ? null : _addSkill, icon: const Icon(Icons.add_rounded)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerLeft, child: Text('${_skills.length}/12 skills', style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
            ),

            _sectionHeader('Links', 'Connect your public profile', Icons.link_outlined),
            _field(TextField(controller: _otherLink, keyboardType: TextInputType.url, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'Website or other link', hintText: 'https://example.com', prefixIcon: Icon(Icons.language_outlined)))),

            _sectionHeader('About you', 'Optional details with privacy in mind', Icons.public_outlined),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(controller: _country, maxLength: 2, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Country code', hintText: 'IN', counterText: '', prefixIcon: Icon(Icons.flag_outlined))),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 4),
                    Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        leading: const Icon(Icons.cake_outlined),
                        title: const Text('Date of birth'),
                        subtitle: Text(_formatDate(_dateOfBirth)),
                        trailing: const Icon(Icons.calendar_month_outlined),
                        onTap: _saving ? null : _pickDateOfBirth,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Private KYC, payout and full date-of-birth information are not shown publicly. Creator category and skills can help people discover your profile.')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
