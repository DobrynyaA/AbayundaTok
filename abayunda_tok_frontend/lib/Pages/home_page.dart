import 'package:abayunda_tok_frontend/Models/VideoData.dart';
import 'package:abayunda_tok_frontend/Screens/CommentScreens.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';
import 'package:abayunda_tok_frontend/Services/comment_service.dart';
import 'package:abayunda_tok_frontend/Services/folower_service.dart';
import 'package:abayunda_tok_frontend/pages/profile_page.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:abayunda_tok_frontend/Services/video_service.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  final VideoService videoService;
  final AuthService authService;
  final CommentService commentService;
  final FolowerService folowerService;
  const HomePage({super.key, required this.videoService, required this.authService, required this.commentService, required this.folowerService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  final List<String> _videoUrls = [];
  final List<String> _videoDescriptions = [
    "dfgdfgdfgdf",
    "dfgdfgdfgdfgdfgdfgdf",
    "sdfffffffffffffffffffffffffffffffffff"
  ];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);

    try {
      final newUrls = await widget.videoService.fetchVideosUrls(_currentPage, 3);
      
      setState(() {
        _videoUrls.addAll(newUrls);
        _currentPage++;
        _hasMore = newUrls.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar(e.toString());
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videoUrls.length + (_hasMore ? 1 : 0),
        onPageChanged: (index) {
          if (index >= _videoUrls.length - 3 && _hasMore) {
            _loadVideos();
          }
        },
        itemBuilder: (context, index) {
          if (index >= _videoUrls.length) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          return _VideoPlayerWithOverlay(
            videoUrl: _videoUrls[index],
            description: _videoDescriptions[index % _videoDescriptions.length],
            authService: widget.authService,
            videoService: widget.videoService,
            commentService: widget.commentService,
            folowerService: widget.folowerService,
          );
        },
      ),
    );
  }
}

class _VideoPlayerWithOverlay extends StatefulWidget {
  final String videoUrl;
  final String description;
  final AuthService authService;
  final VideoService videoService;
  final CommentService commentService;
  final FolowerService folowerService;

  const _VideoPlayerWithOverlay({
    required this.videoUrl,
    required this.description,
    required this.authService,
    required this.videoService,
    required this.commentService,
    required this.folowerService
  });

  @override
  State<_VideoPlayerWithOverlay> createState() => _VideoPlayerWithOverlayState();
}

class _VideoPlayerWithOverlayState extends State<_VideoPlayerWithOverlay> {
  
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  VideoData? _videoData;
  bool _isLoadingDetails = true;
  bool _isLikeLoading = false;

  @override
void initState() {
  super.initState();
  _loadVideoDetails().then((_) {
    _initializeVideo();
  });
}

  Future<void> _loadVideoDetails() async {
    try {
      final details = await widget.videoService.fetchVideoDetails(widget.videoUrl);
      if (!mounted) return;
      
      setState(() {
        _videoData = details;
        _isLoadingDetails = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDetails = false);
      debugPrint('Ошибка загрузки деталей видео: $e');
    }
  }
  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.network(widget.videoUrl);
      await _videoController!.initialize();
      
      if (!mounted) {
        _disposeControllers();
        return;
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        showControls: false,
        aspectRatio: _videoController!.value.aspectRatio,
      );

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint("Ошибка загрузки видео: $e");
      _disposeControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки видео")),
      );
    }
  }

  void _disposeControllers() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  @override
  void dispose() {
    _isLoadingDetails = false;
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        Container(color: Colors.black),
        Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 10,
          child: _VideoDescription(description: _videoData?.description ?? widget.description,username: _videoData?.username ?? "vova",),
        ),
        Positioned(
          right: 10,
          bottom: 250,
          child: _RightIcons(authService: widget.authService,videoData: _videoData,videoService: widget.videoService,commentService: widget.commentService,folowerService: widget.folowerService, ),
        ),
      ],
    );
  }
}

class _RightIcons extends StatefulWidget {
  final AuthService authService; 
  final VideoData? videoData;
  final VideoService videoService;
  final FolowerService folowerService;
  final CommentService commentService;
  
  const _RightIcons({
    required this.authService,
    required this.videoData,
    required this.videoService,
    required this.commentService,
    required this.folowerService
  });

  @override
  State<_RightIcons> createState() => _RightIconsState();
}

class _RightIconsState extends State<_RightIcons> {
  bool _isLiked = false;
  bool _isLikeLoading = false;
  int _likeCount = -1;
  int _commentCount = -1;
  String _avatarUrl = "";

  @override
  void initState() {
    super.initState();
    _isLiked = widget.videoData?.isLiked ?? false;
    _likeCount = widget.videoData?.likeCount ?? -1;
    _commentCount = widget.videoData?.commentCount ?? -1;
    _avatarUrl = widget.videoData?.avtorAvatarUrl ?? "";
  }

  Future<void> _toggleLike() async {
    if (_isLikeLoading) return;
    
    setState(() => _isLikeLoading = true);
    
    try {
      final userId = await widget.authService.getToken();
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Требуется авторизация')),
        );
        return;
      }

      if (_isLiked) {
        final result = await widget.videoService.removeLike(widget.videoData!.id);
        if (!mounted) return;
        setState(() {
          _isLiked = false;
          _likeCount = int.tryParse(result) ?? _likeCount - 1;
        });
      } else {
        final result = await widget.videoService.putLike(widget.videoData!.id);
        if (!mounted) return;
        setState(() {
          _isLiked = true;
          _likeCount = int.tryParse(result) ?? _likeCount + 1;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLikeLoading = false);
      }
    }
  }
  void _openComments() async {
    if (widget.videoData == null) return;
    
    if (!await widget.authService.isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Войдите, чтобы оставлять комментарии')),
      );
      return;
    }

    final updatedCount = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          videoId: widget.videoData!.id,
          commentService: widget.commentService,
          authService: widget.authService,
        ),
      ),
    );

    if (updatedCount != null && mounted) {
      setState(() => _commentCount = updatedCount);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (widget.videoData == null) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    return Column(
      children: [
        _LikeButton(
          isLiked: _isLiked,
          likeCount: _likeCount,
          isLoading: _isLikeLoading,
          onPressed: _toggleLike,
        ),
        const SizedBox(height: 15),
        _CommentButton(
          commentCount: _commentCount,
          onPressed: _openComments,
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(
                  authService: widget.authService,
                  videoService: widget.videoService,
                  commentService: widget.commentService,
                  userId: widget.videoData?.avtorId,
                  folowerService: widget.folowerService,
                ),
              ),
            );
          },
          child: CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(_avatarUrl),
          ),
        )
      ],
    );
  }
}

class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final bool isLoading;
  final VoidCallback onPressed;

  const _LikeButton({
    required this.isLiked,
    required this.likeCount,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: isLoading 
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Icon(
                  Icons.favorite,
                  size: 35,
                  color: isLiked ? Colors.red : Colors.white,
                ),
          onPressed: onPressed,
        ),
        Text(
          likeCount.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

class _CommentButton extends StatelessWidget {
  final int commentCount;
  final VoidCallback onPressed;

  const _CommentButton({
    required this.commentCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.comment, size: 35, color: Colors.white),
          onPressed: onPressed,
        ),
        Text(
          commentCount.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

class _VideoDescription extends StatelessWidget {
  final String description;
  final String username;
  const _VideoDescription({required this.description,required this.username});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            username,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}