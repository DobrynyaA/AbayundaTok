import 'package:flutter/material.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final AuthService authService;

  const ProfilePage({super.key, required this.authService});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<bool> _isLoggedIn;
  late Future<String?> _userName;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.authService.isLoggedIn();
    _userName = widget.authService.getUserName();
  }

  void _refresh() {
    setState(() {
      _isLoggedIn = widget.authService.isLoggedIn();
      _userName = widget.authService.getUserName();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: FutureBuilder<bool>(
        future: _isLoggedIn,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == true) {
            return _buildLoggedInUI();
          } else {
            return _buildAuthUI();
          }
        },
      ),
    );
  }

  Widget _buildLoggedInUI() {
    return Column(
      children: [
        FutureBuilder<String?>(
          future: _userName,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            return Text(
              'Привет, ${snapshot.data ?? 'пользователь'}!',
              style: Theme.of(context).textTheme.headlineMedium,
            );
          },
        ),
        ElevatedButton(
          onPressed: () async {
            await widget.authService.logout();
            _refresh();
          },
          child: const Text('Выйти'),
        ),
      ],
    );
  }

  Widget _buildAuthUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => _showLoginDialog(),
            child: const Text('Войти'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showRegisterDialog(),
            child: const Text('Зарегистрироваться'),
          ),
        ],
      ),
    );
  }

  void _showLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вход'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Пароль'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await widget.authService.login(
                emailController.text,
                passwordController.text,
              );
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  _refresh();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ошибка входа')),
                  );
                }
              }
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  void _showRegisterDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Регистрация'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Пароль'),
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Имя пользователя'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await widget.authService.register(
                emailController.text,
                passwordController.text,
                usernameController.text,
              );
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Регистрация успешна!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ошибка регистрации')),
                  );
                }
              }
            },
            child: const Text('Зарегистрироваться'),
          ),
        ],
      ),
    );
  }
}