import 'package:flutter/material.dart';

import '../services/app_controller.dart';
import '../widgets/app_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/user_avatar.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0C0614), Color(0xFF24103D), Color(0xFF4B1D71)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 18),
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.25),
                                      Colors.white.withValues(alpha: 0.08),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                              const UserAvatar(name: 'Lumo Chat', size: 70),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'LumoChat',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Учебный мобильный мессенджер с профилем, чатами и группами',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFE9D5FF).withValues(alpha: 0.9),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SectionCard(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(
                              tabs: [
                                Tab(text: 'Вход'),
                                Tab(text: 'Регистрация'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 420,
                              child: TabBarView(
                                children: [
                                  _LoginForm(controller: controller),
                                  _RegisterForm(controller: controller),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.controller});

  final AppController controller;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _email,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          decoration: const InputDecoration(labelText: 'Пароль'),
          obscureText: true,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Войти'),
        ),
        const SizedBox(height: 10),
        Text(
          'После входа вы увидите свои диалоги и непрочитанные сообщения.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await widget.controller.login(
        email: _email.text,
        password: _password.text,
      );
    } on MessengerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({required this.controller});

  final AppController controller;

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Имя'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          decoration: const InputDecoration(labelText: 'Пароль'),
          obscureText: true,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Создать аккаунт'),
        ),
        const SizedBox(height: 10),
        Text(
          'Сначала создайте два аккаунта, затем проверьте поиск и чат.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await widget.controller.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
    } on MessengerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
