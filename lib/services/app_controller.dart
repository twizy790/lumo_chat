import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

import '../models/app_user.dart';
import '../models/chat_dialog.dart';
import '../models/chat_message.dart';
import 'messenger_store.dart';

class AppController extends ChangeNotifier {
  AppController(this._store);

  final MessengerStore _store;
  final Random _random = Random();

  AppUser? get currentUser =>
      _store.users.where((user) => user.id == _store.currentUserId).firstOrNull;

  ThemeMode get themeMode => switch (_store.themeMode) {
        ThemeModeValue.light => ThemeMode.light,
        ThemeModeValue.dark => ThemeMode.dark,
        ThemeModeValue.system => ThemeMode.system,
      };

  bool get isLoggedIn => currentUser != null;

  List<AppUser> get users => List.unmodifiable(_store.users);

  List<ChatDialog> get dialogs {
    final me = currentUser;
    if (me == null) return const [];
    final relevant = _store.dialogs.where((dialog) => dialog.participantIds.contains(me.id)).toList();
    relevant.sort((a, b) {
      final at = a.lastMessageAt ?? a.createdAt;
      final bt = b.lastMessageAt ?? b.createdAt;
      return bt.compareTo(at);
    });
    return relevant;
  }

  List<ChatMessage> messagesForDialog(String dialogId) {
    final list = _store.messages.where((message) => message.dialogId == dialogId).toList();
    list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return list;
  }

  List<AppUser> searchableUsers(String query) {
    final me = currentUser;
    final lower = query.trim().toLowerCase();
    return _store.users.where((user) {
      if (me != null && user.id == me.id) return false;
      if (lower.isEmpty) return true;
      return user.name.toLowerCase().contains(lower) || user.email.toLowerCase().contains(lower);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  int unreadCountForDialog(String dialogId) {
    final me = currentUser;
    if (me == null) return 0;
    return messagesForDialog(dialogId)
        .where((message) => message.authorId != me.id && !message.isReadBy(me.id))
        .length;
  }

  int get totalUnreadCount {
    final me = currentUser;
    if (me == null) return 0;
    return dialogs.fold<int>(0, (sum, dialog) => sum + unreadCountForDialog(dialog.id));
  }

  Future<void> restoreSession() async {
    final sessionId = _store.currentUserId;
    if (sessionId != null) {
      final user = _store.users.where((user) => user.id == sessionId).firstOrNull;
      if (user != null) {
        await _touchUser(user.id);
      } else {
        await _store.saveSession(null);
      }
    }
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty || name.trim().isEmpty) {
      throw MessengerException('Заполните имя, email и пароль.');
    }
    if (_store.users.any((user) => user.email.toLowerCase() == normalizedEmail)) {
      throw MessengerException('Пользователь с таким email уже существует.');
    }

    final user = AppUser(
      id: _generateId('user'),
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: _hashPassword(password),
      bio: 'Расскажите о себе в профиле',
    );
    _store.users = [..._store.users, user];
    await _store.saveUsers(_store.users);
    await _store.saveSession(user.id);
    await _touchUser(user.id);
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = _store.users.where((item) => item.email.toLowerCase() == normalizedEmail).firstOrNull;
    if (user == null) {
      throw MessengerException('Аккаунт не найден.');
    }
    if (user.passwordHash != _hashPassword(password)) {
      throw MessengerException('Неверный пароль.');
    }
    await _store.saveSession(user.id);
    await _touchUser(user.id);
    notifyListeners();
  }

  Future<void> logout() async {
    await _store.saveSession(null);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    String? avatarData,
  }) async {
    final me = currentUser;
    if (me == null) return;
    final updated = me.copyWith(
      name: name.trim().isEmpty ? me.name : name.trim(),
      bio: bio.trim(),
      avatarData: avatarData ?? me.avatarData,
      lastSeenAt: DateTime.now(),
    );
    _replaceUser(updated);
    await _store.saveUsers(_store.users);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => ThemeModeValue.light,
      ThemeMode.dark => ThemeModeValue.dark,
      ThemeMode.system => ThemeModeValue.system,
    };
    await _store.saveThemeMode(value);
    notifyListeners();
  }

  Future<ChatDialog> openDirectChat(String otherUserId) async {
    final me = currentUser;
    if (me == null) throw MessengerException('Сначала войдите в аккаунт.');
    final existing = _store.dialogs.where((dialog) {
      return !dialog.isGroup &&
          dialog.participantIds.length == 2 &&
          dialog.participantIds.contains(me.id) &&
          dialog.participantIds.contains(otherUserId);
    }).firstOrNull;
    if (existing != null) return existing;

    final other = _userById(otherUserId);
    if (other == null) throw MessengerException('Пользователь не найден.');
    final dialog = ChatDialog(
      id: _generateId('dialog'),
      participantIds: [me.id, other.id],
      isGroup: false,
      title: other.name,
      createdAt: DateTime.now(),
    );
    _store.dialogs = [..._store.dialogs, dialog];
    await _store.saveDialogs(_store.dialogs);
    notifyListeners();
    return dialog;
  }

  Future<ChatDialog> createGroupChat({
    required String title,
    required List<String> participantIds,
  }) async {
    final me = currentUser;
    if (me == null) throw MessengerException('Сначала войдите в аккаунт.');
    final participants = <String>{me.id, ...participantIds}.toList();
    if (participants.length < 3) {
      throw MessengerException('Для группового чата нужно минимум 3 участника.');
    }
    final cleanTitle = title.trim().isEmpty ? 'Групповой чат' : title.trim();
    final dialog = ChatDialog(
      id: _generateId('dialog'),
      participantIds: participants,
      isGroup: true,
      title: cleanTitle,
      createdAt: DateTime.now(),
    );
    _store.dialogs = [..._store.dialogs, dialog];
    await _store.saveDialogs(_store.dialogs);
    notifyListeners();
    return dialog;
  }

  Future<void> sendTextMessage(
    String dialogId,
    String text, {
    String? imageData,
  }) async {
    final me = currentUser;
    if (me == null) throw MessengerException('Сначала войдите в аккаунт.');
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageData == null) {
      throw MessengerException('Введите сообщение или добавьте изображение.');
    }
    final dialog = _dialogById(dialogId);
    if (dialog == null) throw MessengerException('Диалог не найден.');
    final message = ChatMessage(
      id: _generateId('msg'),
      dialogId: dialog.id,
      authorId: me.id,
      text: trimmed,
      imageData: imageData,
      sentAt: DateTime.now(),
      readBy: [me.id],
    );
    _store.messages = [..._store.messages, message];
    await _store.saveMessages(_store.messages);
    _updateDialogLastMessage(dialog.id, text: trimmed, senderId: me.id);
    await _store.saveDialogs(_store.dialogs);
    notifyListeners();
  }

  Future<void> markDialogRead(String dialogId) async {
    final me = currentUser;
    if (me == null) return;
    var changed = false;
    final updatedMessages = <ChatMessage>[];
    for (final message in _store.messages) {
      if (message.dialogId == dialogId &&
          message.authorId != me.id &&
          !message.readBy.contains(me.id)) {
        updatedMessages.add(
          message.copyWith(readBy: [...message.readBy, me.id]),
        );
        changed = true;
      } else {
        updatedMessages.add(message);
      }
    }
    if (changed) {
      _store.messages = updatedMessages;
      await _store.saveMessages(_store.messages);
      notifyListeners();
    }
  }

  Future<void> deleteDialog(String dialogId) async {
    final dialog = _dialogById(dialogId);
    if (dialog == null) return;
    _store.dialogs = _store.dialogs.where((item) => item.id != dialogId).toList();
    _store.messages = _store.messages.where((message) => message.dialogId != dialogId).toList();
    await _store.saveDialogs(_store.dialogs);
    await _store.saveMessages(_store.messages);
    notifyListeners();
  }

  Future<void> _touchUser(String userId) async {
    final user = _userById(userId);
    if (user == null) return;
    _replaceUser(user.copyWith(lastSeenAt: DateTime.now()));
    await _store.saveUsers(_store.users);
  }

  void _replaceUser(AppUser user) {
    final index = _store.users.indexWhere((item) => item.id == user.id);
    if (index >= 0) {
      _store.users[index] = user;
    }
  }

  AppUser? _userById(String id) {
    return _store.users.where((user) => user.id == id).firstOrNull;
  }

  ChatDialog? _dialogById(String id) {
    return _store.dialogs.where((dialog) => dialog.id == id).firstOrNull;
  }

  void _updateDialogLastMessage(
    String dialogId, {
    required String text,
    required String senderId,
  }) {
    final index = _store.dialogs.indexWhere((dialog) => dialog.id == dialogId);
    if (index < 0) return;
    final current = _store.dialogs[index];
    _store.dialogs[index] = current.copyWith(
      lastMessagePreview: text.isEmpty ? 'Изображение' : text,
      lastMessageAt: DateTime.now(),
      lastMessageSenderId: senderId,
    );
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  String _generateId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
  }
}

class MessengerException implements Exception {
  MessengerException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension StringAvatarX on String {
  String get safeInitials {
    final trimmed = trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
