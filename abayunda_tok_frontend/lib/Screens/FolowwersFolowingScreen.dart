import 'package:abayunda_tok_frontend/Services/comment_service.dart';
import 'package:abayunda_tok_frontend/Services/folower_service.dart';
import 'package:abayunda_tok_frontend/Services/video_service.dart';
import 'package:flutter/material.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';
import 'package:abayunda_tok_frontend/Pages/profile_page.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final AuthService authService;
  final FolowerService folowerService;
  CommentService commentService;
  VideoService videoService;
  final String userId;
  final bool showFollowers;

  FollowersFollowingScreen({
    super.key,
    required this.authService,
    required this.userId,
    required this.showFollowers,
    required this.folowerService,
    required this.commentService,
    required this.videoService,
  });

  @override
  State<FollowersFollowingScreen> createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> {
  late Future<List<dynamic>> _followData;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.showFollowers ? 0 : 1;
    _loadData();
  }

  void _loadData() {
    setState(() {
      _followData = _selectedTab == 0
          ? widget.folowerService.getFollowers(widget.userId)
          : widget.folowerService.getFollowing(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сообщество'),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedTab == 0 ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _selectedTab = 0;
                    _loadData();
                  });
                },
                child: const Text('Подписчики'))
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTab == 1 ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _selectedTab = 1;
                  _loadData();
                });
              },
              child: const Text('Подписки'))
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return FutureBuilder<List<dynamic>>(
      future: _followData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Нет данных'));
        }

        final users = snapshot.data!;

        if (users.isEmpty) {
          return Center(
            child: Text(
              _selectedTab == 0 
                ? 'У вас пока нет подписчиков' 
                : 'Вы ни на кого не подписаны',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserItem(user);
          },
        );
      },
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(user['avatarUrl'] ?? 'https://via.placeholder.com/150'),
      ),
      title: Text(user['userName'] ?? 'Без имени'),
      subtitle: Text(user['bio'] ?? ''),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              authService: widget.authService,
              videoService: widget.videoService,
              commentService: widget.commentService,
              folowerService: widget.folowerService,
              userId: user['id'],
            ),
          ),
        );
      },
    );
  }
}