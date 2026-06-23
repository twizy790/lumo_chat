import 'package:flutter/material.dart';

import '../services/app_controller.dart';
import '../widgets/app_scope.dart';
import '../widgets/content_frame.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/section_card.dart';
import '../widgets/user_avatar.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _title = TextEditingController();
  final _query = TextEditingController();
  final Set<String> _selected = <String>{};
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final users = controller.searchableUsers(_query.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Новая группа')),
      body: ContentFrame(
        child: ListView(
          children: [
            const DashboardHeader(
              eyebrow: 'Group chat',
              title: 'Соберите команду',
              subtitle: 'Добавьте минимум двух собеседников, чтобы создать групповой чат и протестировать совместную переписку.',
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Название группы'),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: TextField(
                controller: _query,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Найти участников',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            Text('Выбрано: ${_selected.length}', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            ...users.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: CheckboxListTile(
                    value: _selected.contains(user.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(user.id);
                        } else {
                          _selected.remove(user.id);
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    title: Text(user.name),
                    subtitle: Text(user.bio.isEmpty ? user.email : user.bio),
                    secondary: UserAvatar(name: user.name, avatarData: user.avatarData),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _busy = true);
                      try {
                        final dialog = await controller.createGroupChat(
                          title: _title.text,
                          participantIds: _selected.toList(),
                        );
                        if (!context.mounted) return;
                        navigator.pop(dialog.id);
                      } on MessengerException catch (error) {
                        if (!context.mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text(error.message)));
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Создать группу'),
            ),
          ],
        ),
      ),
    );
  }
}
