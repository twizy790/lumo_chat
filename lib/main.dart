import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/app_controller.dart';
import 'services/messenger_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final store = await MessengerStore.load();
  final controller = AppController(store);
  await controller.restoreSession();
  runApp(LumoChatRoot(controller: controller));
}
