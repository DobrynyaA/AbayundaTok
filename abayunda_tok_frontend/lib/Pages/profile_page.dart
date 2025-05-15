import 'package:flutter/material.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final AuthService authService;
  final String? userId; // null - текущий пользователь

  const ProfilePage({
    super.key,
    required this.authService,
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
        ? widget.authService.getUserProfile()
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
    padding: const EdgeInsets.all(16.0),
    sliver: FutureBuilder<Map<String, dynamic>?>(
      future: _userProfile,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(child: CircularProgressIndicator());
        }
        
        final videos = snapshot.data!['videos'] as List<dynamic>? ?? [];
        
        return videos.isEmpty
            ? SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    widget.userId == null
                        ? 'У вас пока нет видео'
                        : 'У пользователя нет видео',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            : SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
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

Widget _buildVideoItem(Map<String, dynamic> video) {
  return GestureDetector(
    //onTap: () => _openVideoPlayer(video['id']),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              video['thumbnailUrl'] ?? 'https://via.placeholder.com/300',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          video['title'] ?? 'Без названия',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${video['views']} просмотров',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}
}