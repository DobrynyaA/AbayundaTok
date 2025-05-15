import 'package:abayunda_tok_frontend/Models/Comment.dart';
import 'package:abayunda_tok_frontend/Models/VideoData.dart';
import 'package:abayunda_tok_frontend/Pages/singleVideo_page.dart';
import 'package:abayunda_tok_frontend/Services/comment_service.dart';
import 'package:abayunda_tok_frontend/Services/video_service.dart';
import 'package:flutter/material.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final AuthService authService;
  final CommentService commentService;
  final VideoService videoService;
  final String? userId;

  const ProfilePage({
    super.key,
    required this.authService,
    required this.videoService,
    required this.commentService,
    this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>?> _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _userProfile = widget.userId == null
        ? widget.authService.getMyProfile()
        : widget.authService.getUserProfileById(widget.userId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
    expandedHeight: 200,
    flexibleSpace: FutureBuilder<Map<String, dynamic>?>(
      future: _userProfile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final user = snapshot.data;
        if (user == null) {
          return const Center(child: Text('Профиль не найден'));
        }

        return Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.black),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user['avatarUrl'] ?? 'https://via.placeholder.com/150'),
              ),
            ),
          ],
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                user['followersCount']?.toString() ?? '0', 
                'Подписчики'
              ),
              _buildStatItem(
                user['followingCount']?.toString() ?? '0', 
                'Подписки'
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildStatItem(String value, String label) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    ],
  );
}
SliverToBoxAdapter _buildProfileActions() {
  final isCurrentUser = widget.userId == null;
  
  return SliverToBoxAdapter(
    child: FutureBuilder<Map<String, dynamic>?>(
      future: _userProfile,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              if (isCurrentUser)
                _buildActionButton(
                  text: 'Редактировать профиль',
                  icon: Icons.edit,
                  onPressed: widget.authService.logout
                ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildActionButton({
  required String text,
  required IconData icon,
  required VoidCallback onPressed,
}) {
  return OutlinedButton.icon(
    icon: Icon(icon, size: 20),
    label: Text(text),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    onPressed: onPressed,
  );
}
SliverPadding _buildVideosSection() {
  return SliverPadding(
    padding: const EdgeInsets.all(2.0), // Минимальные отступы
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
            childAspectRatio: 0.6, // Более квадратные карточки
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
        videoUrl: video.hlsUrl
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