import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_controller.dart';
import 'services/messenger_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await MessengerStore.load();
  final controller = AppController(store);
  await controller.restoreSession();
  runApp(LumoChatRoot(controller: controller));
}
