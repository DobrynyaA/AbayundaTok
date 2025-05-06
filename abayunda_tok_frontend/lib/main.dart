import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Services/auth_service.dart';
import 'Services/video_service.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'package:flutter/services.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService(await SharedPreferences.getInstance());
  final videoService = VideoService(baseUrl: 'https://10.0.2.2:7000');
  HttpOverrides.global = _MyHttpOverrides();
  runApp(MyApp(authService: authService,videoService: videoService,));
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final VideoService videoService;
  const MyApp({super.key, required this.authService,required this.videoService});

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
            return MainNavigation(authService: authService, videoService: videoService,);
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final AuthService authService;
  final VideoService videoService;
  const MainNavigation({super.key, required this.authService,required this.videoService});

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
          HomePage(videoService: widget.videoService),
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