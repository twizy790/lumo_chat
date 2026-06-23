import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/app_controller.dart';
import '../utils/formatters.dart';
import '../utils/iterable_x.dart';
import '../widgets/app_scope.dart';
import '../widgets/content_frame.dart';
import '../widgets/dashboard_header.dart';
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
      body: ContentFrame(
        child: ListView(
          children: [
            DashboardHeader(
              eyebrow: 'Lumo space',
              title: 'Все диалоги под рукой',
              subtitle: controller.totalUnreadCount > 0
                  ? 'У вас ${controller.totalUnreadCount} непрочитанных сообщений. Откройте чат, чтобы ответить и отметить их как прочитанные.'
                  : 'Здесь собраны личные переписки и групповые чаты. Последние сообщения всегда наверху.',
              trailing: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.mark_chat_unread_rounded, color: Colors.white, size: 30),
              ),
            ),
            if (controller.totalUnreadCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
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
            const SizedBox(height: 16),
            if (dialogs.isEmpty)
              const SectionCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 26),
                  child: Column(
                    children: [
                      Icon(Icons.forum_outlined, size: 42),
                      SizedBox(height: 12),
                      Text(
                        'Диалогов пока нет',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Найдите пользователя во вкладке поиска или создайте групповой чат.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
                              content: const Text('Сообщения и переписка будут удалены из Firebase.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Отмена'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Удалить'),
                                ),
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
      ),
    );
  }
}
