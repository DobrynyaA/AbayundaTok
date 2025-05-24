import 'package:abayunda_tok_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:abayunda_tok_frontend/Models/VideoData.dart';
import 'package:abayunda_tok_frontend/Screens/EditProfileScreen.dart';
import 'package:abayunda_tok_frontend/Screens/FolowwersFolowingScreen.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';
import 'package:abayunda_tok_frontend/Services/comment_service.dart';
import 'package:abayunda_tok_frontend/Services/folower_service.dart';
import 'package:abayunda_tok_frontend/Services/video_service.dart';
import 'package:abayunda_tok_frontend/pages/singleVideo_page.dart';

class ProfilePage extends StatefulWidget {
  final AuthService authService;
  final CommentService commentService;
  final VideoService videoService;
  final FolowerService folowerService;
  final String? userId;

  const ProfilePage({
    super.key,
    required this.authService,
    required this.videoService,
    required this.commentService,
    required this.folowerService,
    this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>?> _userProfile;
  late Future<String?> _currentUserId;
  final _scrollController = ScrollController();
  double _appBarOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.authService.getUserIdFromToken();
    _loadProfile();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
  final offset = _scrollController.offset;
  double newOpacity;
  
  if (offset <= 0) {
    newOpacity = 1.0;
  } else if (offset >= 100) {
    newOpacity = 0.0;
  } else {
    newOpacity = 1.0 - offset / 100;
  }
  
  if (mounted) {
    setState(() {
      _appBarOpacity = newOpacity;
    });
  }
}

  void _loadProfile() {
    _userProfile = _isMyProfile()
        ? widget.authService.getMyProfile()
        : widget.authService.getUserProfileById(widget.userId);
  }

  bool _isMyProfile() {
    return _currentUserId == widget.userId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildProfileHeader(),
          _buildProfileStats(),
          _buildProfileActions(),
          _buildVideosSection(),
        ],
      ),
    );
  }

  SliverAppBar _buildProfileHeader() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: FutureBuilder<Map<String, dynamic>?>(
              future: _userProfile,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBB86FC)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Ошибка загрузки профиля',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final user = snapshot.data!;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF2A2A2A).withOpacity(0.8),
                            const Color(0xFF121212).withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFBB86FC),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF2A2A2A),
                              backgroundImage: NetworkImage(
                                user['avatarUrl'] ?? 'https://via.placeholder.com/150',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            user['userName'] ?? 'Без имени',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (user['bio'] != null && user['bio'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                user['bio'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),

                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      right: 16,
                      child: Opacity(
                        opacity: _appBarOpacity.clamp(0.0, 1.0), // Дополнительная защита
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          onPressed: () async {
                            await widget.authService.logout();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyApp(
                                  authService: widget.authService,
                                  videoService: widget.videoService,
                                  commentService: widget.commentService,
                                  folowerService: widget.folowerService,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildProfileStats() {
    return SliverToBoxAdapter(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final user = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                // Разделитель
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFBB86FC).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Статистика
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      user['followersCount']?.toString() ?? '0',
                      'Подписчики',
                      context,
                      user,
                    ),
                    _buildStatItem(
                      user['followingCount']?.toString() ?? '0',
                      'Подписки',
                      context,
                      user,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String value, String label, BuildContext context, Map<String, dynamic> userData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowersFollowingScreen(
              authService: widget.authService,
              commentService: widget.commentService,
              videoService: widget.videoService,
              folowerService: widget.folowerService,
              userId: widget.userId.toString(),
              showFollowers: label == 'Подписчики',
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildProfileActions() {
    return SliverToBoxAdapter(
      child: FutureBuilder(
        future: Future.wait([
          _userProfile,
          _currentUserId,
          widget.folowerService.isFollowing(widget.userId!),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final user = snapshot.data![0] as Map<String, dynamic>;
          final currentUserId = snapshot.data![1] as String?;
          final isFollowing = snapshot.data![2] as bool;
          final isMyProfile = currentUserId == widget.userId;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
            child: Column(
              children: [
                if (isMyProfile)
                  _buildActionButton(
                    text: 'Редактировать профиль',
                    icon: Icons.edit,
                    onPressed: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            authService: widget.authService,
                            userData: user,
                          ),
                        ),
                      );
                      if (updated == true) {
                        setState(() {
                          _loadProfile();
                        });
                      }
                    },
                  )
                else
                  _buildFollowButton(
                    isFollowing: isFollowing,
                    onPressed: () async {
                      try {
                        if (isFollowing) {
                          await widget.folowerService.unfollow(widget.userId!);
                        } else {
                          await widget.folowerService.follow(widget.userId!);
                        }
                        setState(() {
                          _loadProfile();
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ошибка: ${e.toString()}'),
                            backgroundColor: Colors.red[800],
                          ),
                        );
                      }
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFollowButton({
    required bool isFollowing,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: isFollowing
            ? null
            : const LinearGradient(
                colors: [Color(0xFFBB86FC), Color(0xFF6200EE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isFollowing
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFBB86FC).withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? const Color(0xFF2A2A2A) : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          isFollowing ? 'Отписаться' : 'Подписаться',
          style: TextStyle(
            color: isFollowing ? Colors.white : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 20, color: const Color(0xFFBB86FC)),
        label: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFBB86FC),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFBB86FC), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  // Оригинальные методы _buildVideosSection и _buildVideoItem остаются без изменений
  SliverPadding _buildVideosSection() {
    return SliverPadding(
      padding: const EdgeInsets.all(2.0),
      sliver: FutureBuilder<Map<String, dynamic>?>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SliverToBoxAdapter(child: CircularProgressIndicator());
          }
          
          final videos = (snapshot.data!['videos'] as List<dynamic>? ?? [])
              .map((v) => VideoData.fromJson(v))
              .toList();
          
          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 0.6, 
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildVideoItem(videos[index]),
              childCount: videos.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoItem(VideoData video) {
    return GestureDetector(
      onTap: () => _openVideoPlayer(context, video),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Обложка видео
          Image.network(
            video.thumbnailUrl ?? 'https://via.placeholder.com/300',
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          
          // Затемнение нижней части для текста
          Positioned.fill(
            bottom: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 8,
            left: 8,
            child: Row(
              children: [
                const Icon(Icons.favorite, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _formatLikeCount(video.likeCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openVideoPlayer(BuildContext context, VideoData video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SingleVideoPage(
          authService: widget.authService,
          videoService: widget.videoService,
          commentService: widget.commentService,
          videoUrl: video.hlsUrl,
          folowerService: widget.folowerService,
        ),
      ),
    );
  }

  String _formatLikeCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}