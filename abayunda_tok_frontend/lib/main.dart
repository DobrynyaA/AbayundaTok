import 'dart:io';

import 'package:abayunda_tok_frontend/Constants/Url.dart';
import 'package:abayunda_tok_frontend/Pages/auth_page.dart';
import 'package:abayunda_tok_frontend/Pages/uploadVideo_page.dart';
import 'package:abayunda_tok_frontend/Services/comment_service.dart';
import 'package:abayunda_tok_frontend/Services/folower_service.dart';
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
  final videoService = VideoService(baseUrl: Url.serverAdress, authService: authService);
  final commentService = CommentService(baseUrl: Url.serverAdress, authService: authService);
  final folowerService = FolowerService(baseUrl: Url.serverAdress, authService: authService);
  HttpOverrides.global = _MyHttpOverrides();
  runApp(MyApp(authService: authService,videoService: videoService,commentService: commentService,folowerService: folowerService,));
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
  final FolowerService folowerService;
  const MyApp({super.key, required this.authService,required this.videoService,required this.commentService,required this.folowerService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JWT Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF1E1E1E),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: authService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return MainNavigation(authService: authService, videoService: videoService, commentService:commentService,folowerService: folowerService,);
          }
          return Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
            )),
          );
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final AuthService authService;
  final VideoService videoService;
  final CommentService commentService;
  final FolowerService folowerService;
  const MainNavigation({super.key, required this.authService,required this.videoService,required this.commentService,required this.folowerService});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  double _iconSize = 24.0;
  Color _activeColor = Color(0xFFBB86FC);
  Color _inactiveColor = Color(0xFF757575);
  Color _backgroundColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(videoService: widget.videoService, authService: widget.authService, commentService: widget.commentService,folowerService: widget.folowerService,),
          UploadVideoPage(videoService: widget.videoService, authService: widget.authService,commentService: widget.commentService,folowerService: widget.folowerService,),
          AuthPage(authService: widget.authService, videoService: widget.videoService, commentService: widget.commentService,folowerService: widget.folowerService,),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            elevation: 10,
            type: BottomNavigationBarType.fixed,
            backgroundColor: _backgroundColor,
            selectedItemColor: _activeColor,
            unselectedItemColor: _inactiveColor,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
              letterSpacing: 0.5,
            ),
            items: [
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 0 ? _activeColor.withOpacity(0.15) : Colors.transparent,
                  ),
                  child: Icon(Icons.home_filled, size: _iconSize),
                ),
                label: 'Главная',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 1 ? _activeColor.withOpacity(0.15) : Colors.transparent,
                  ),
                  child: Icon(Icons.add_circle_outline, size: _iconSize),
                ),
                label: 'Загрузить',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 2 ? _activeColor.withOpacity(0.15) : Colors.transparent,
                  ),
                  child: Icon(Icons.person_outline, size: _iconSize),
                ),
                label: 'Профиль',
              ),
            ],
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}