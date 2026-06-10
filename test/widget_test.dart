import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_chat/app.dart';
import 'package:lumo_chat/services/app_controller.dart';
import 'package:lumo_chat/services/messenger_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows auth screen for a fresh session', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});

    final store = await MessengerStore.memory();
    final controller = AppController(store);
    await controller.restoreSession();

    await tester.pumpWidget(LumoChatRoot(controller: controller));
    await tester.pump();

    expect(find.text('LumoChat'), findsOneWidget);
    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Регистрация'), findsOneWidget);
  });
}
