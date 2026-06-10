import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'services/app_controller.dart';
import 'widgets/app_scope.dart';

class LumoChatRoot extends StatelessWidget {
  const LumoChatRoot({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'LumoChat',
            themeMode: controller.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: controller.currentUser == null
                ? const AuthScreen()
                : const HomeShell(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6D38D8),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF7F3FF),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFFF7F3FF),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6D38D8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF6D38D8),
        foregroundColor: Colors.white,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFC77DFF),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF10071B),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFF10071B),
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF160D24),
        indicatorColor: const Color(0xFF3F225F),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1029),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF231536),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC77DFF), width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
      ),
    );
  }
}
