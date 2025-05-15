import 'dart:io';

import 'package:abayunda_tok_frontend/Pages/auth_page.dart';
import 'package:abayunda_tok_frontend/Services/comment_service.dart';
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
  final videoService = VideoService(baseUrl: 'https://10.0.2.2:7000', authService: authService);
  final commentService = CommentService(baseUrl: 'https://10.0.2.2:7000', authService: authService);
  HttpOverrides.global = _MyHttpOverrides();
  runApp(MyApp(authService: authService,videoService: videoService,commentService: commentService,));
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
  final CommentService commentService;
  const MyApp({super.key, required this.authService,required this.videoService,required this.commentService});

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
            return MainNavigation(authService: authService, videoService: videoService, commentService:commentService,);
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
  final CommentService commentService;
  const MainNavigation({super.key, required this.authService,required this.videoService,required this.commentService});

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
          HomePage(videoService: widget.videoService, authService: widget.authService, commentService: widget.commentService),
          AuthPage(authService: widget.authService),
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