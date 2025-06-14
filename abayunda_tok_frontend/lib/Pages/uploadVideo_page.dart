import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:abayunda_tok_frontend/Models/Comment.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';
import 'package:abayunda_tok_frontend/Services/comment_service.dart';
import 'package:abayunda_tok_frontend/Services/folower_service.dart';
import 'package:abayunda_tok_frontend/Services/video_service.dart';
import 'package:abayunda_tok_frontend/main.dart';

class UploadVideoPage extends StatefulWidget {
  final VideoService videoService;
  final AuthService authService;
  final CommentService commentService;
  final FolowerService folowerService;

  const UploadVideoPage({
    super.key,
    required this.videoService,
    required this.authService,
    required this.commentService,
    required this.folowerService,
  });

  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  final TextEditingController _descriptionController = TextEditingController();
  File? _videoFile;
  bool _isUploading = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await widget.authService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (!_isLoggedIn) return;
    
    final pickedFile = await ImagePicker().pickVideo(source: source);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (!_isLoggedIn || _videoFile == null) return;

    setState(() => _isUploading = true);

    try {
      final success = await widget.videoService.uploadVideo(
        videoFile: _videoFile!,
        description: _descriptionController.text,
      );

      if (success) {
        if (!mounted) return;
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
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить видео')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildAuthMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 50, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Авторизуйтесь, чтобы загрузить видео',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
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
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadInterface() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Видео превью
          if (_videoFile != null)
            AspectRatio(
              aspectRatio: 9/16,
              child: VideoPlayerWidget(videoFile: _videoFile!),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam, size: 50, color: Colors.white30),
                    SizedBox(height: 10),
                    Text(
                      'Выберите видео',
                      style: TextStyle(color: Colors.white30),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Кнопки выбора видео
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.video_library),
                label: const Text('Галерея'),
                onPressed: () => _pickVideo(ImageSource.gallery),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Камера'),
                onPressed: () => _pickVideo(ImageSource.camera),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Поле описания
          TextField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.black), // Черный цвет текста
            decoration: InputDecoration(
              labelText: 'Описание видео',
              labelStyle: const TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 20),

          // Кнопка загрузки
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _videoFile != null && !_isUploading ? _uploadVideo : null,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Загрузить видео',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Загрузить видео'),
        actions: [
          if (_isLoggedIn && _videoFile != null)
            IconButton(
              icon: const Icon(Icons.upload),
              onPressed: _isUploading ? null : _uploadVideo,
            ),
        ],
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : _isLoggedIn ? _buildUploadInterface() : _buildAuthMessage(),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final File videoFile;

  const VideoPlayerWidget({super.key, required this.videoFile});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_controller.value.isInitialized)
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        Center(
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 50,
              color: Colors.white.withOpacity(0.7),
            ),
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
                _isPlaying ? _controller.play() : _controller.pause();
              });
            },
          ),
        ),
      ],
    );
  }
}