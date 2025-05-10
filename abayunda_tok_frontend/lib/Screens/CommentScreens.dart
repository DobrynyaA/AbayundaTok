import 'package:abayunda_tok_frontend/Models/Comment.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';
import 'package:abayunda_tok_frontend/Services/comment_service.dart';
import 'package:abayunda_tok_frontend/Widgets/CommentItem.dart';
import 'package:flutter/material.dart';

class CommentsScreen extends StatefulWidget {
  final int videoId;
  final CommentService commentService;
  final AuthService authService;

  const CommentsScreen({
    required this.videoId,
    required this.commentService,
    required this.authService,
  });

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  late Future<List<Comment>> _commentsFuture;
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _commentsFuture = widget.commentService.getComments(widget.videoId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Комментарии'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Comment>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Нет комментариев'));
                } else {
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final comment = snapshot.data![index];
                      return CommentItem(comment: comment);
                    },
                  );
                }
              },
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Написать комментарий...',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _addComment,
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    try {
      await widget.commentService.addComment(
        widget.videoId,
        _commentController.text,
      );
      
      _commentController.clear();
      setState(() {
        _commentsFuture = widget.commentService.getComments(widget.videoId);
      });
      
      // Прокрутка вниз после добавления
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}