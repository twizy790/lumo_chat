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

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_index)),
        actions: [
          if (unread > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text('Новых: $unread'),
              ),
            ),
          IconButton(
            tooltip: 'Тема',
            onPressed: () async {
              await controller.setThemeMode(
                Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
              );
            },
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark ? Icons.dark_mode : Icons.light_mode,
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
}
