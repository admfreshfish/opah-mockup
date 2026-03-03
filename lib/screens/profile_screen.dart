import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/profile_repository.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.required = false});

  /// When true, user must complete profile before continuing (e.g. after first login).
  final bool required;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = ProfileRepository.instance;
  final _nicknameController = TextEditingController();

  String? _profileImagePath;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
    _nicknameController.addListener(_onNicknameChanged);
  }

  void _onNicknameChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_onNicknameChanged);
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final nickname = await _repo.getNickname();
    final imagePath = await _repo.getProfileImagePath();
    if (mounted) {
      setState(() {
        _nicknameController.text = nickname ?? '';
        _profileImagePath = imagePath;
        _loading = false;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted || xFile == null) return;
    setState(() => _saving = true);
    await _repo.saveProfileImageFromPath(xFile.path);
    if (!mounted) return;
    final path = await _repo.getProfileImagePath();
    if (!mounted) return;
    setState(() {
      _profileImagePath = path;
      _saving = false;
    });
  }

  Future<void> _removePhoto() async {
    setState(() => _saving = true);
    await _repo.clearProfileImage();
    if (!mounted) return;
    setState(() {
      _profileImagePath = null;
      _saving = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _repo.setNickname(_nicknameController.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }

  bool get _isProfileComplete {
    final hasNickname = _nicknameController.text.trim().isNotEmpty;
    return hasNickname || _profileImagePath != null;
  }

  Future<void> _continue() async {
    await _repo.setNickname(_nicknameController.text.trim());
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.required ? 'Create your profile' : 'My profile'),
        automaticallyImplyLeading: !widget.required,
        actions: widget.required
            ? null
            : [
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
              ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _saving ? null : _pickPhoto,
                  child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    backgroundImage: _profileImagePath != null
                        ? FileImage(File(_profileImagePath!))
                        : null,
                    child: _profileImagePath == null
                        ? Icon(
                            Icons.person,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        onPressed: _saving ? null : _pickPhoto,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
                const SizedBox(height: 6),
                Text(
                  'Profile picture (optional)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (_profileImagePath != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton.icon(
                  onPressed: _saving ? null : _removePhoto,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove photo'),
                ),
              ),
            ),
          const SizedBox(height: 32),
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              labelText: 'Nickname',
              hintText: 'How you want to be called',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 24),
          Text(
            widget.required
                ? 'Add a nickname to get started. You can add a profile picture later.'
                : 'Your nickname will appear when you post photos in events.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (widget.required) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isProfileComplete && !_saving ? _continue : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
