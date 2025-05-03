import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  final List<String> _videoUrls = [
      //'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8', 
      //'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
      'http://10.0.2.2:9000/videos/65e49fd0-8e1a-47e1-981f-f259b470337c/master.m3u8',
      'http://localhost:9000/videos/e6e6e408-0b44-4bdb-8251-96f92cadeb93/master.m3u8',
      'http://localhost:9000/videos/89aff2d0-646a-41e2-a35a-a3097c8fde76/master.m3u8',
  ];
  
  List<VideoPlayerController> _videoControllers = [];
  List<ChewieController> _chewieControllers = [];
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayers();
  }

  Future<void> _initializePlayers() async {
    try {
      _videoControllers = _videoUrls.map((url) {
        return VideoPlayerController.networkUrl(
          Uri.parse(url
            .replaceAll('localhost', '10.0.2.2')
            .replaceAll('127.0.0.1', '10.0.2.2'),
          ),
          formatHint: VideoFormat.hls,
        );
      }).toList();

      // 2. Быстрая проверка доступности видео
      final firstVideo = _videoControllers.first;
      await firstVideo.initialize().timeout(const Duration(seconds: 10));

      // 3. Инициализация остальных (параллельно)
      await Future.wait(
        _videoControllers.map((c) => c.initialize()),
      );

      // 4. Настройка Chewie
      _chewieControllers = _videoControllers.map((vc) {
        return ChewieController(
          videoPlayerController: vc,
          autoPlay: true,
          looping: true,
          showControls: false,
          errorBuilder: (context, errorMsg) {
            return Center(child: Text('Ошибка видео: $errorMsg'));
          },
        );
      }).toList();

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Ошибка инициализации: $e');
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var c in _videoControllers) c.dispose();
    for (var c in _chewieControllers) c.dispose();
    super.dispose();
  }

  Widget _buildLoader() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загружаем видео...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Не удалось загрузить видео'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initializePlayers,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return Scaffold(body: _buildError());
    if (!_isInitialized) return Scaffold(body: _buildLoader());

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videoUrls.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Chewie(controller: _chewieControllers[index]),
              _buildVideoInfo(index),
              _buildActionBar(index),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoInfo(int index) {
    return Positioned(
      bottom: 80,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@user_$index',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Тестовое видео #${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(int index) {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white, size: 32),
            onPressed: () {},
          ),
          const Text('123', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 20),
          IconButton(
            icon: const Icon(Icons.comment, color: Colors.white, size: 32),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
