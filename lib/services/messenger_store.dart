import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/chat_dialog.dart';
import '../models/chat_message.dart';

class MessengerStore {
  MessengerStore._(this._prefs);

  static const _usersKey = 'lumo.users';
  static const _dialogsKey = 'lumo.dialogs';
  static const _messagesKey = 'lumo.messages';
  static const _sessionKey = 'lumo.session.userId';
  static const _themeKey = 'lumo.theme.mode';

  final SharedPreferences _prefs;

  List<AppUser> users = [];
  List<ChatDialog> dialogs = [];
  List<ChatMessage> messages = [];
  String? currentUserId;
  ThemeModeValue themeMode = ThemeModeValue.light;

  static Future<MessengerStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = MessengerStore._(prefs);
    store.users = _readList(
      prefs.getString(_usersKey),
      (json) => AppUser.fromJson(json as Map<String, dynamic>),
    );
    store.dialogs = _readList(
      prefs.getString(_dialogsKey),
      (json) => ChatDialog.fromJson(json as Map<String, dynamic>),
    );
    store.messages = _readList(
      prefs.getString(_messagesKey),
      (json) => ChatMessage.fromJson(json as Map<String, dynamic>),
    );
    store.currentUserId = prefs.getString(_sessionKey);
    store.themeMode = themeModeFromName(prefs.getString(_themeKey));
    return store;
  }

  static List<T> _readList<T>(
    String? raw,
    T Function(dynamic json) fromJson,
  ) {
    if (raw == null || raw.isEmpty) return <T>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map(fromJson).toList(growable: true);
  }

  Future<void> saveUsers(List<AppUser> value) async {
    users = value;
    await _prefs.setString(_usersKey, jsonEncode(value.map((e) => e.toJson()).toList()));
  }

  Future<void> saveDialogs(List<ChatDialog> value) async {
    dialogs = value;
    await _prefs.setString(_dialogsKey, jsonEncode(value.map((e) => e.toJson()).toList()));
  }

  Future<void> saveMessages(List<ChatMessage> value) async {
    messages = value;
    await _prefs.setString(_messagesKey, jsonEncode(value.map((e) => e.toJson()).toList()));
  }

  Future<void> saveSession(String? userId) async {
    currentUserId = userId;
    if (userId == null) {
      await _prefs.remove(_sessionKey);
    } else {
      await _prefs.setString(_sessionKey, userId);
    }
  }

  Future<void> saveThemeMode(ThemeModeValue mode) async {
    themeMode = mode;
    await _prefs.setString(_themeKey, mode.name);
  }
}

enum ThemeModeValue { light, dark, system }

ThemeModeValue themeModeFromName(String? value) {
  return ThemeModeValue.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => ThemeModeValue.light,
  );
}
