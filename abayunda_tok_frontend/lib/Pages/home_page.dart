import 'package:abayunda_tok_frontend/Services/auth_service.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:abayunda_tok_frontend/Services/video_service.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  final VideoService videoService;
  final AuthService authService;
  
  const HomePage({super.key, required this.videoService, required this.authService});

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
      final newUrls = await widget.videoService.fetchVideos(_currentPage, 3);
      
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
  const _VideoPlayerWithOverlay({
    required this.videoUrl,
    required this.description,
    required this.authService
  });

  @override
  State<_VideoPlayerWithOverlay> createState() => _VideoPlayerWithOverlayState();
}

class _VideoPlayerWithOverlayState extends State<_VideoPlayerWithOverlay> {
  
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.network(widget.videoUrl);
      await _videoController!.initialize();
      
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
          child: _VideoDescription(description: widget.description),
        ),
        Positioned(
          right: 10,
          bottom: 250,
          child: _RightIcons(authService: widget.authService,),
        ),
      ],
    );
  }
}

class _RightIcons extends StatelessWidget {
  final AuthService authService; 

  const _RightIcons({required this.authService});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _IconButton(icon: Icons.favorite, count: '245K',authService: authService),
        const SizedBox(height: 15),
        _IconButton(icon: Icons.comment, count: '1.2K',authService: authService),
        const SizedBox(height: 15),
        const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.amber,
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String count;
  final AuthService authService;
  const _IconButton({required this.icon, required this.count, required this.authService});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()async {
        if (!await authService.isLoggedIn()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Войдите или зарегистрируйтесь, чтобы пользоваться данным функционалом'),
            ),
          );
        }else{
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Вы успешно зарегистрированы'),
            ),
          );
        }
      },
      child: Column(
        children: [
          Icon(icon, size: 35, color: Colors.white),
          if (count.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(count, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _VideoDescription extends StatelessWidget {
  final String description;

  const _VideoDescription({required this.description});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '@username',
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