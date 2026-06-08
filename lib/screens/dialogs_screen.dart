import 'package:flutter/material.dart';

import '../services/app_controller.dart';
import '../utils/formatters.dart';
import '../models/app_user.dart';
import '../widgets/app_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';
import 'group_create_screen.dart';

class DialogsScreen extends StatelessWidget {
  const DialogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final dialogs = controller.dialogs;
    final me = controller.currentUser;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final navigator = Navigator.of(context);
          final dialogId = await navigator.push<String>(
            MaterialPageRoute(builder: (_) => const GroupCreateScreen()),
          );
          if (dialogId != null) {
            await navigator.push(
              MaterialPageRoute(builder: (_) => ChatScreen(dialogId: dialogId)),
            );
          }
        },
        icon: const Icon(Icons.group_add),
        label: const Text('Группа'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (controller.totalUnreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SectionCard(
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'У вас ${controller.totalUnreadCount} новых сообщений',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (dialogs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: Text('Диалогов пока нет. Найдите пользователя или создайте группу.'),
              ),
            )
          else
            ...dialogs.map(
              (dialog) {
                final unread = controller.unreadCountForDialog(dialog.id);
                final participants = dialog.participantIds
                    .where((id) => id != me?.id)
                    .map((id) => controller.users.where((user) => user.id == id).firstOrNull)
                    .whereType<AppUser>()
                    .toList();
                final displayName = dialog.isGroup
                    ? dialog.title
                    : (participants.isEmpty ? dialog.title : participants.first.name);
                final subtitle = dialog.lastMessagePreview ?? 'Нет сообщений';
                final time = dialog.lastMessageAt == null ? '' : timeAgo(dialog.lastMessageAt!);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: UserAvatar(
                        name: displayName,
                        avatarData: dialog.isGroup
                            ? null
                            : (participants.isNotEmpty ? participants.first.avatarData : null),
                        isGroup: dialog.isGroup,
                      ),
                      title: Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(time, style: Theme.of(context).textTheme.labelSmall),
                          if (unread > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  unread.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ChatScreen(dialogId: dialog.id)),
                        );
                      },
                      onLongPress: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Удалить диалог?'),
                            content: const Text('Сообщения и переписка будут удалены только локально.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
                            ],
                          ),
                        );
                        if (result == true) {
                          await controller.deleteDialog(dialog.id);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
