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
  late Future<Map<String, dynamic>?> _userProfile;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.authService.isLoggedIn();
    _userProfile = widget.authService.getUserProfile();
  }

  void _refresh() {
    setState(() {
      _isLoggedIn = widget.authService.isLoggedIn();
      _userProfile = widget.authService.getUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<bool>(
        future: _isLoggedIn,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == true) {
            return _buildProfilePage();
          } else {
            return _buildAuthUI();
          }
        },
      ),
    );
  }

  Widget _buildProfilePage() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          flexibleSpace: FlexibleSpaceBar(
            background: FutureBuilder<Map<String, dynamic>?>(
              future: _userProfile,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final user = snapshot.data;
                if (user == null) {
                  return const Center(child: Text('Ошибка загрузки профиля'));
                }

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Container(color: Colors.black), // Можно заменить на фоновое изображение
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(user['avatarUrl']),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _userProfile,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final user = snapshot.data;
                if (user == null) {
                  return const Center(child: Text('Ошибка загрузки профиля'));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${user['userName']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (user['bio'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(user['bio']),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(user['followingCount'].toString(), 'Подписки'),
                        _buildStatItem(user['followersCount'].toString(), 'Подписчики'),
                        _buildStatItem(user['likeCount'].toString(), 'Лайки'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () async {
                          await widget.authService.logout();
                          _refresh();
                        },
                        child: const Text('Редактировать профиль'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // Заглушка для будущего списка видео
        SliverToBoxAdapter(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            alignment: Alignment.center,
            child: const Text('Здесь будет список видео',
                style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Войдите, чтобы увидеть профиль',
            style: TextStyle(fontSize: 18),
          ),
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