import 'package:flutter/material.dart';

import '../services/app_controller.dart';
import '../widgets/app_scope.dart';
import '../widgets/content_frame.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/section_card.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final users = controller.searchableUsers(_query.text);

    return ContentFrame(
      child: ListView(
        children: [
          DashboardHeader(
            eyebrow: 'People search',
            title: 'Найдите собеседника',
            subtitle: 'Поиск работает по имени и email. Откройте карточку пользователя, чтобы сразу перейти в личный чат.',
            trailing: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.travel_explore_rounded, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: TextField(
              controller: _query,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Поиск по имени или email',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Найдено пользователей: ${users.length}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          if (users.isEmpty)
            const SectionCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Пока никого не найдено')),
              ),
            )
          else
            ...users.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: UserAvatar(name: user.name, avatarData: user.avatarData),
                    title: Text(user.name),
                    subtitle: Text(user.bio.isEmpty ? user.email : user.bio),
                    trailing: const Icon(Icons.chat_bubble_outline),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final dialog = await controller.openDirectChat(user.id);
                        if (!context.mounted) return;
                        await navigator.push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(dialogId: dialog.id),
                          ),
                        );
                      } on MessengerException catch (error) {
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(error.message)),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
