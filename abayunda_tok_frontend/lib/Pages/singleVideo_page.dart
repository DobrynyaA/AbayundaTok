import 'package:abayunda_tok_frontend/Models/VideoData.dart';
import 'package:abayunda_tok_frontend/Screens/CommentScreens.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';
import 'package:abayunda_tok_frontend/Services/comment_service.dart';
import 'package:abayunda_tok_frontend/Services/folower_service.dart';
import 'package:abayunda_tok_frontend/Services/video_service.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'profile_page.dart';

class SingleVideoPage extends StatefulWidget {
  final VideoService videoService;
  final AuthService authService;
  final CommentService commentService;
  final FolowerService folowerService;
  final String videoUrl;

  const SingleVideoPage({
    super.key,
    required this.videoService,
    required this.authService,
    required this.commentService,
    required this.folowerService,
    required this.videoUrl,
  });

  @override
  State<SingleVideoPage> createState() => _SingleVideoPageState();
}

class _SingleVideoPageState extends State<SingleVideoPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  VideoData? _videoData;
  bool _isLoadingDetails = true;
  bool _isLikeLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVideoData();
  }

  Future<void> _loadVideoData() async {
    try {
      final videoDetails = await widget.videoService.fetchVideoDetails(widget.videoUrl);
      if (!mounted) return;
      
      setState(() {
        _videoData = videoDetails;
        _isLoadingDetails = false;
      });
      
      _initializeVideo(_videoData!.hlsUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDetails = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки видео: $e')),
      );
    }
  }

  Future<void> _initializeVideo(String videoUrl) async {
    try {
      _videoController = VideoPlayerController.network(videoUrl);
      await _videoController!.initialize();
      
      if (!mounted) {
        _disposeControllers();
        return;
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        showControls: true,
        aspectRatio: _videoController!.value.aspectRatio,
      );

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint("Ошибка инициализации видео: $e");
      _disposeControllers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки видео")),
        );
      }
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
    _disposeControllers();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isLikeLoading || _videoData == null) return;
    
    setState(() => _isLikeLoading = true);
    
    try {
      if (_videoData != null) {
        if (_videoData!.isLiked == true) {
          final result = await widget.videoService.removeLike(_videoData!.id);
          if (!mounted) return;
          setState(() {
            _videoData!.isLiked = false;
            _videoData!.likeCount = int.tryParse(result) ?? _videoData!.likeCount - 1;
          });
        } else {
          final result = await widget.videoService.putLike(_videoData!.id);
          if (!mounted) return;
          setState(() {
            _videoData!.isLiked = true;
            _videoData!.likeCount = int.tryParse(result) ?? _videoData!.likeCount + 1;
          });
        }
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
    if (_videoData == null) return;
    
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
          videoId: _videoData!.id,
          commentService: widget.commentService,
          authService: widget.authService,
        ),
      ),
    );

    if (updatedCount != null && mounted) {
      setState(() => _videoData!.commentCount = updatedCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDetails || !_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            child: _VideoDescription(
              description: _videoData?.description ?? '',
              username: _videoData?.username ?? '',
            ),
          ),
          Positioned(
            right: 10,
            bottom: 250,
            child: Column(
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: _isLikeLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : Icon(
                              Icons.favorite,
                              size: 35,
                              color: _videoData?.isLiked == true ? Colors.red : Colors.white,
                            ),
                      onPressed: _toggleLike,
                    ),
                    Text(
                      _videoData?.likeCount.toString() ?? '0',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.comment, size: 35, color: Colors.white),
                      onPressed: _openComments,
                    ),
                    Text(
                      _videoData?.commentCount.toString() ?? '0',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () {
                    if (_videoData?.avtorId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(
                            authService: widget.authService,
                            videoService: widget.videoService,
                            commentService: widget.commentService,
                            folowerService: widget.folowerService,
                            userId: _videoData?.avtorId,
                          ),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(_videoData?.avtorAvatarUrl ?? ''),
                  ),
                ),
              ],
            ),
          ),

          // Кнопка назад
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoDescription extends StatelessWidget {
  final String description;
  final String username;

  const _VideoDescription({
    required this.description,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@$username',
            style: const TextStyle(
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
        ],
      ),
    );
  }
}