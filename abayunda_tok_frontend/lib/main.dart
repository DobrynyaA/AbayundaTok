import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Services/auth_service.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService(await SharedPreferences.getInstance());
  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JWT Auth Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<bool>(
        future: authService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return MainNavigation(authService: authService);
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final AuthService authService;

  const MainNavigation({super.key, required this.authService});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomePage(),
          ProfilePage(authService: widget.authService),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}