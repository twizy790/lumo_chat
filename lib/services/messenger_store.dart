import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/chat_dialog.dart';
import '../models/chat_message.dart';
import '../utils/iterable_x.dart';

class MessengerStore extends ChangeNotifier {
  MessengerStore._({
    required SharedPreferences prefs,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  })  : _prefs = prefs,
        _auth = auth,
        _firestore = firestore,
        _messaging = messaging;

  static const _themeKey = 'lumo.theme.mode';

  final SharedPreferences _prefs;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final FirebaseMessaging? _messaging;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _dialogsSubscription;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _messageSubscriptions = [];
  final Map<String, ChatMessage> _messageById = {};

  List<AppUser> users = [];
  List<ChatDialog> dialogs = [];
  List<ChatMessage> messages = [];
  String? currentUserId;
  ThemeModeValue themeMode = ThemeModeValue.dark;

  bool get isFirebaseEnabled => _auth != null && _firestore != null;

  CollectionReference<Map<String, dynamic>> get _usersRef => _firestore!.collection('users');
  CollectionReference<Map<String, dynamic>> get _dialogsRef => _firestore!.collection('dialogs');
  CollectionReference<Map<String, dynamic>> get _messagesRef => _firestore!.collection('messages');

  static Future<MessengerStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = MessengerStore._(
      prefs: prefs,
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      messaging: FirebaseMessaging.instance,
    );
    store.themeMode = themeModeFromName(prefs.getString(_themeKey));
    store.currentUserId = store._auth!.currentUser?.uid;
    await store.refresh();
    await store.registerPushToken();
    return store;
  }

  static Future<MessengerStore> memory() async {
    final prefs = await SharedPreferences.getInstance();
    return MessengerStore._(prefs: prefs);
  }

  Future<void> refresh() async {
    if (!isFirebaseEnabled) return;
    currentUserId = _auth!.currentUser?.uid;
    await _loadUsers();
    await _loadDialogs();
    await _loadMessages();
    await _bindRealtime();
    notifyListeners();
  }

  Future<AppUser> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final credentials = await _auth!.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = credentials.user;
    if (firebaseUser == null) {
      throw const FirebaseStoreException('Не удалось создать аккаунт.');
    }

    await firebaseUser.updateDisplayName(name);
    final user = AppUser(
      id: firebaseUser.uid,
      name: name,
      email: email,
      passwordHash: '',
      bio: 'Расскажите о себе в профиле',
    );
    await _usersRef.doc(user.id).set(_userToFirestore(user));
    currentUserId = user.id;
    await refresh();
    await registerPushToken();
    return user;
  }

  Future<AppUser> loginUser({
    required String email,
    required String password,
  }) async {
    final credentials = await _auth!.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = credentials.user;
    if (firebaseUser == null) {
      throw const FirebaseStoreException('Не удалось войти в аккаунт.');
    }

    currentUserId = firebaseUser.uid;
    await refresh();
    await registerPushToken();

    final existing = users.where((user) => user.id == firebaseUser.uid).firstOrNull;
    if (existing != null) return existing;

    final created = AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? firebaseUser.email ?? 'Пользователь',
      email: firebaseUser.email ?? email,
      passwordHash: '',
      bio: '',
    );
    await _usersRef.doc(created.id).set(_userToFirestore(created));
    await refresh();
    return created;
  }

  Future<void> registerPushToken() async {
    if (_messaging == null || currentUserId == null) return;
    try {
      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token == null) return;
      await _usersRef.doc(currentUserId).set(
        {
          'pushTokens': FieldValue.arrayUnion([token]),
          'lastSeenAt': Timestamp.fromDate(DateTime.now()),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // На десктопе и web токен или разрешения могут быть недоступны.
    }
  }

  Future<void> saveUsers(List<AppUser> value) async {
    users = value;
    if (!isFirebaseEnabled) return;
    final batch = _firestore!.batch();
    for (final user in value) {
      batch.set(_usersRef.doc(user.id), _userToFirestore(user), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> saveDialogs(List<ChatDialog> value) async {
    dialogs = value;
    if (!isFirebaseEnabled) return;
    final batch = _firestore!.batch();
    for (final dialog in value) {
      batch.set(_dialogsRef.doc(dialog.id), _dialogToFirestore(dialog), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> saveMessages(List<ChatMessage> value) async {
    messages = value;
    if (!isFirebaseEnabled) return;
    final batch = _firestore!.batch();
    for (final message in value) {
      batch.set(_messagesRef.doc(message.id), _messageToFirestore(message), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> saveSession(String? userId) async {
    currentUserId = userId;
    if (userId == null) {
      dialogs = [];
      messages = [];
      _messageById.clear();
      await _cancelDialogAndMessageSubscriptions();
      if (_auth != null) {
        await _auth.signOut();
      }
      notifyListeners();
      return;
    }
    await _bindRealtime();
  }

  Future<void> saveThemeMode(ThemeModeValue mode) async {
    themeMode = mode;
    await _prefs.setString(_themeKey, mode.name);
  }

  Future<void> deleteDialog(String dialogId) async {
    dialogs = dialogs.where((dialog) => dialog.id != dialogId).toList();
    messages = messages.where((message) => message.dialogId != dialogId).toList();
    _messageById.removeWhere((_, message) => message.dialogId == dialogId);
    notifyListeners();
    if (!isFirebaseEnabled) return;

    final batch = _firestore!.batch();
    batch.delete(_dialogsRef.doc(dialogId));
    final snapshots = await _messagesRef.where('dialogId', isEqualTo: dialogId).get();
    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _bindRealtime() async {
    if (!isFirebaseEnabled) return;
    _usersSubscription ??= _usersRef.snapshots().listen((snapshot) {
      users = snapshot.docs.map((doc) {
        final data = _withId(doc.id, doc.data());
        return AppUser.fromJson(_normalizeFirestoreData(data));
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    });

    await _cancelDialogAndMessageSubscriptions();

    final uid = currentUserId;
    if (uid == null) {
      dialogs = [];
      messages = [];
      _messageById.clear();
      notifyListeners();
      return;
    }

    _dialogsSubscription =
        _dialogsRef.where('participantIds', arrayContains: uid).snapshots().listen((snapshot) {
      dialogs = snapshot.docs.map((doc) {
        final data = _withId(doc.id, doc.data());
        return ChatDialog.fromJson(_normalizeFirestoreData(data));
      }).toList()
        ..sort((a, b) {
          final at = a.lastMessageAt ?? a.createdAt;
          final bt = b.lastMessageAt ?? b.createdAt;
          return bt.compareTo(at);
        });

      unawaited(_bindMessageSubscriptions());
      notifyListeners();
    });
  }

  Future<void> _bindMessageSubscriptions() async {
    for (final subscription in _messageSubscriptions) {
      await subscription.cancel();
    }
    _messageSubscriptions.clear();
    _messageById.clear();

    final ids = dialogs.map((dialog) => dialog.id).toList();
    if (ids.isEmpty) {
      messages = [];
      notifyListeners();
      return;
    }

    for (var start = 0; start < ids.length; start += 10) {
      final chunk = ids.skip(start).take(10).toList();
      final chunkSet = chunk.toSet();
      final subscription = _messagesRef.where('dialogId', whereIn: chunk).snapshots().listen(
        (snapshot) {
          _messageById.removeWhere((_, message) => chunkSet.contains(message.dialogId));
          for (final doc in snapshot.docs) {
            final data = _withId(doc.id, doc.data());
            final message = ChatMessage.fromJson(_normalizeFirestoreData(data));
            _messageById[message.id] = message;
          }
          messages = _messageById.values.toList()..sort((a, b) => a.sentAt.compareTo(b.sentAt));
          notifyListeners();
        },
      );
      _messageSubscriptions.add(subscription);
    }
  }

  Future<void> _cancelDialogAndMessageSubscriptions() async {
    await _dialogsSubscription?.cancel();
    _dialogsSubscription = null;
    for (final subscription in _messageSubscriptions) {
      await subscription.cancel();
    }
    _messageSubscriptions.clear();
  }

  Future<void> _loadUsers() async {
    final snapshot = await _usersRef.get();
    users = snapshot.docs.map((doc) {
      final data = _withId(doc.id, doc.data());
      return AppUser.fromJson(_normalizeFirestoreData(data));
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _loadDialogs() async {
    final currentId = _auth!.currentUser?.uid;
    if (currentId == null) {
      dialogs = [];
      return;
    }
    final snapshot = await _dialogsRef.where('participantIds', arrayContains: currentId).get();
    dialogs = snapshot.docs.map((doc) {
      final data = _withId(doc.id, doc.data());
      return ChatDialog.fromJson(_normalizeFirestoreData(data));
    }).toList()
      ..sort((a, b) {
        final at = a.lastMessageAt ?? a.createdAt;
        final bt = b.lastMessageAt ?? b.createdAt;
        return bt.compareTo(at);
      });
  }

  Future<void> _loadMessages() async {
    final dialogIds = dialogs.map((dialog) => dialog.id).toSet();
    if (dialogIds.isEmpty) {
      messages = [];
      return;
    }
    final allMessages = <ChatMessage>[];
    final ids = dialogIds.toList();
    for (var start = 0; start < ids.length; start += 10) {
      final chunk = ids.skip(start).take(10).toList();
      final snapshot = await _messagesRef.where('dialogId', whereIn: chunk).get();
      allMessages.addAll(
        snapshot.docs.map((doc) {
          final data = _withId(doc.id, doc.data());
          return ChatMessage.fromJson(_normalizeFirestoreData(data));
        }),
      );
    }
    messages = allMessages..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  Map<String, dynamic> _userToFirestore(AppUser user) {
    return {
      'name': user.name,
      'email': user.email,
      'avatarData': user.avatarData,
      'bio': user.bio,
      'createdAt': Timestamp.fromDate(user.createdAt),
      'lastSeenAt': Timestamp.fromDate(user.lastSeenAt),
    };
  }

  Map<String, dynamic> _dialogToFirestore(ChatDialog dialog) {
    return {
      'participantIds': dialog.participantIds,
      'isGroup': dialog.isGroup,
      'title': dialog.title,
      'createdAt': Timestamp.fromDate(dialog.createdAt),
      'lastMessagePreview': dialog.lastMessagePreview,
      'lastMessageAt': dialog.lastMessageAt == null ? null : Timestamp.fromDate(dialog.lastMessageAt!),
      'lastMessageSenderId': dialog.lastMessageSenderId,
    };
  }

  Map<String, dynamic> _messageToFirestore(ChatMessage message) {
    return {
      'dialogId': message.dialogId,
      'authorId': message.authorId,
      'text': message.text,
      'imageData': message.imageData,
      'sentAt': Timestamp.fromDate(message.sentAt),
      'readBy': message.readBy,
    };
  }

  Map<String, dynamic> _withId(String id, Map<String, dynamic> data) {
    return {'id': id, ...data};
  }

  Map<String, dynamic> _normalizeFirestoreData(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      return MapEntry(key, value);
    });
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _dialogsSubscription?.cancel();
    for (final subscription in _messageSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

class FirebaseStoreException implements Exception {
  const FirebaseStoreException(this.message);

  final String message;
}

enum ThemeModeValue { light, dark, system }

ThemeModeValue themeModeFromName(String? value) {
  return ThemeModeValue.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => ThemeModeValue.dark,
  );
}
