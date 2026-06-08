import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_controller.dart';
import '../utils/formatters.dart';
import '../widgets/app_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  String? _avatarData;
  bool _loaded = false;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final me = AppScope.of(context).currentUser;
    if (me != null) {
      _name.text = me.name;
      _bio.text = me.bio;
      _avatarData = me.avatarData;
    }
    _loaded = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final me = controller.currentUser;
    if (me == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          child: Column(
            children: [
              UserAvatar(name: _name.text.isEmpty ? me.name : _name.text, avatarData: _avatarData, size: 92),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _pickAvatar,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Изменить аватар'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Имя'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bio,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Краткая информация'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить профиль'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${me.email}'),
              const SizedBox(height: 8),
              Text('Последний вход: ${formatDateTimeCompact(me.lastSeenAt)}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () async {
            await controller.logout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Выйти из аккаунта'),
        ),
      ],
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (result == null) return;
    final bytes = await result.readAsBytes();
    setState(() => _avatarData = base64Encode(bytes));
  }

  Future<void> _save() async {
    final controller = AppScope.of(context);
    setState(() => _busy = true);
    try {
      await controller.updateProfile(
        name: _name.text,
        bio: _bio.text,
        avatarData: _avatarData,
      );
    } on MessengerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
