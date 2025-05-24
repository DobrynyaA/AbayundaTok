import 'package:flutter/material.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';
import 'package:abayunda_tok_frontend/Services/comment_service.dart';
import 'package:abayunda_tok_frontend/Services/folower_service.dart';
import 'package:abayunda_tok_frontend/Services/video_service.dart';
import 'package:abayunda_tok_frontend/Pages/profile_page.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final AuthService authService;
  final FolowerService folowerService;
  final CommentService commentService;
  final VideoService videoService;
  final String userId;
  final bool showFollowers;

  const FollowersFollowingScreen({
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

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _followData;
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showFollowers ? 0 : 1,
    );
    _tabController.addListener(_handleTabSelection);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _followData = _tabController.index == 0
          ? widget.folowerService.getFollowers(widget.userId)
          : widget.folowerService.getFollowing(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'Сообщество',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Поисковая строка
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Поиск...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              // Табы
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFBB86FC), Color(0xFF6200EE)],
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Подписчики'),
                    Tab(text: 'Подписки'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(),
          _buildUserList(),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return FutureBuilder<List<dynamic>>(
      future: _followData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBB86FC)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Ошибка: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text(
              'Нет данных',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final users = snapshot.data!
            .where((user) => user['userName']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _tabController.index == 0 ? Icons.people : Icons.person_search,
                  size: 48,
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                Text(
                  _tabController.index == 0
                      ? 'Подписчиков пока нет'
                      : 'Подписок пока нет',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (context, index) => Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
          ),
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserItem(user);
          },
        );
      },
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1E1E1E),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Hero(
          tag: 'avatar_${user['id']}',
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFBB86FC),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                user['avatarUrl'] ?? 'https://via.placeholder.com/150',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          user['userName'] ?? 'Без имени',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: user['bio'] != null && user['bio'].isNotEmpty
            ? Text(
                user['bio'],
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withOpacity(0.6),
        ),
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
      ),
    );
  }
}