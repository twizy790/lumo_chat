import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/app_scope.dart';
import 'dialogs_screen.dart';
import 'profile_screen.dart';
import 'users_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final unread = controller.totalUnreadCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titleForIndex(_index)),
            Text(
              _subtitleForIndex(_index),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          if (unread > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF241138) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark ? const Color(0xFF35204F) : const Color(0xFFE9D5FF),
                  ),
                ),
                alignment: Alignment.center,
                child: Text('Новых: $unread'),
              ),
            ),
          IconButton(
            tooltip: 'Сменить тему',
            onPressed: () async {
              await controller.setThemeMode(
                Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
              );
            },
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                unawaited(controller.logout());
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('Выйти')),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          DialogsScreen(),
          UsersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Диалоги'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Пользователи'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Профиль'),
        ],
      ),
    );
  }

  String _titleForIndex(int index) {
    return switch (index) {
      0 => 'Диалоги',
      1 => 'Поиск',
      _ => 'Профиль',
    };
  }

  String _subtitleForIndex(int index) {
    return switch (index) {
      0 => 'Ваши чаты и последние сообщения',
      1 => 'Поиск собеседников по имени и email',
      _ => 'Настройки аккаунта и внешний вид',
    };
  }
}
