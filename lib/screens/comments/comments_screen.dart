import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../../model/post_model.dart';

class CommentsScreen extends StatefulWidget {
  final List<CommentModel> comments;
  final String postId;
  final bool isLocalPost;
  final Function(int)? onCommentAdded;
  CommentsScreen({
    required this.comments,
    required this.postId,
    this.isLocalPost = false,
    this.onCommentAdded,
  });

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  final GetStorage _storage = GetStorage();

  Widget _buildProfileIcon(String name, {double size = 40, Uint8List? profilePicture}) {
    if (profilePicture != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipOval(
          child: Image.memory(
            profilePicture,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultProfileIcon(name, size: size);
            },
          ),
        ),
      );
    }
    
    final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.red];
    final colorIndex = name.hashCode % colors.length;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors[colorIndex],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildDefaultProfileIcon(String name, {double size = 40}) {
    final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.red];
    final colorIndex = name.hashCode % colors.length;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors[colorIndex],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _comments = widget.comments;
  }

  void _addComment() async {
    if (_commentController.text.isNotEmpty) {
      final userName = _storage.read('user_name') ?? 'You';
      final userBio = _storage.read('user_bio') ?? 'Flutter Developer & Social Media Enthusiast';
      final profilePicture = _storage.read('my_profile_picture');
      
      final newComment = CommentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        user: UserModel(
          id: 'current_user', 
          name: userName,
          bio: userBio,
          localProfilePicture: profilePicture,
        ),
        text: _commentController.text,
      );
      
      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
      });

      if (widget.isLocalPost) {
        await _updateLocalPostComment(newComment);
      }

      if (widget.onCommentAdded != null) {
        widget.onCommentAdded!(_comments.length);
      }
    }
  }

  Future<void> _updateLocalPostComment(CommentModel newComment) async {
    try {
      final posts = _storage.read('my_posts') ?? [];
      final updatedPosts = List.from(posts);
      
      for (int i = 0; i < updatedPosts.length; i++) {
        if (updatedPosts[i]['id'] == widget.postId) {
          final commentJson = newComment.toJson();
          
          if (updatedPosts[i]['comments'] == null) {
            updatedPosts[i]['comments'] = [commentJson];
          } else {
            updatedPosts[i]['comments'].insert(0, commentJson);
          }
          break;
        }
      }
      
      await _storage.write('my_posts', updatedPosts);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment added!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating local post comment: $e');
    }
  }

  Uint8List? _getProfilePictureForUser(UserModel user) {
    if (user.id == 'current_user') {
      final profileData = _storage.read('my_profile_picture');
      if (profileData != null && profileData is String) {
        try {
          return base64Decode(profileData);
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () {
          Navigator.pop(context, _comments.length);
        }),
        title: Text('Comments (${_comments.length})'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              reverse: false,
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                final profilePicture = _getProfilePictureForUser(comment.user);
                
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileIcon(comment.user.name, size: 40, profilePicture: profilePicture),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(comment.user.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  SizedBox(height: 4),
                                  Text(comment.text),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[300]!)), color: Colors.white),
            child: Row(
              children: [
                _buildProfileIcon(
                  _storage.read('user_name') ?? 'You',
                  size: 40,
                  profilePicture: _getProfilePictureForUser(UserModel(id: 'current_user', name: 'You')),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                SizedBox(width: 12),
                IconButton(icon: Icon(Icons.send, color: Colors.blue), onPressed: _addComment),
              ],
            ),
          ),
        ],
      ),
    );
  }
}