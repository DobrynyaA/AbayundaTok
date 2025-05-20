import 'package:abayunda_tok_frontend/Services/comment_service.dart';
import 'package:abayunda_tok_frontend/Services/folower_service.dart';
import 'package:abayunda_tok_frontend/Services/video_service.dart';
import 'package:abayunda_tok_frontend/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';

class AuthPage extends StatefulWidget {
  final AuthService authService;
  final VideoService videoService;
  final CommentService commentService;
  final FolowerService folowerService;
  const AuthPage({super.key, required this.authService,required this.videoService,required this.commentService, required this.folowerService});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late Future<bool> _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.authService.isLoggedIn();
  }

  void _refresh() {
    setState(() {
      _isLoggedIn = widget.authService.isLoggedIn();
    });
  }

  @override
Widget build(BuildContext context) {
  return FutureBuilder<bool>(
    future: _isLoggedIn,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (snapshot.data != true) {
        return _buildAuthUI();
      }

      // Добавляем вложенный FutureBuilder для userId
      return FutureBuilder<String?>(
        future: widget.authService.getUserIdFromToken(),
        builder: (context, userIdSnapshot) {
          if (userIdSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return ProfilePage(
            userId: userIdSnapshot.data, // Может быть null
            authService: widget.authService,
            videoService: widget.videoService,
            commentService: widget.commentService,
            folowerService: widget.folowerService,
          );
        },
      );
    },
  );
}

  Widget _buildAuthUI() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Войдите, чтобы увидеть профиль', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showLoginDialog(),
              child: const Text('Войти'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _showRegisterDialog(),
              child: const Text('Зарегистрироваться'),
            ),
          ],
        ),
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