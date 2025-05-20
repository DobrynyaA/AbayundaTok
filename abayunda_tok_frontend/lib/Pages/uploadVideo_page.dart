import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:abayunda_tok_frontend/Services/video_service.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';
import 'package:video_player/video_player.dart';

class UploadVideoPage extends StatefulWidget {
  final VideoService videoService;
  final AuthService authService;

  const UploadVideoPage({
    super.key,
    required this.videoService,
    required this.authService,
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
        Navigator.pop(context, true);
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 50, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Авторизуйтесь, чтобы загрузить видео',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
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
          if (_videoFile != null)
            AspectRatio(
              aspectRatio: 9/16,
              child: VideoPlayerWidget(videoFile: _videoFile!),
            )
          else
            Container(
              height: 300,
              color: Colors.black12,
              child: const Center(
                child: Icon(Icons.videocam, size: 100, color: Colors.white30),
              ),
            ),
          const SizedBox(height: 20),
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
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Описание видео',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
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
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.upload),
              onPressed: _videoFile != null && !_isUploading ? _uploadVideo : null,
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
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}