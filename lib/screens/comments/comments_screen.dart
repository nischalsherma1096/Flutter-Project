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
  final TextEditingController _editCommentController = TextEditingController();
  List<CommentModel> _comments = [];
  final GetStorage _storage = GetStorage();
  String? _editingCommentId;

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
    _updateCommentNames(); // Update names on init
  }

  void _updateCommentNames() {
    // Update all current user comments with current name
    final currentUserName = _storage.read('user_name') ?? 'You';
    final currentUserBio = _storage.read('user_bio') ?? '';
    final currentProfilePicture = _storage.read('my_profile_picture');
    
    for (var comment in _comments) {
      if (comment.user.id == 'current_user') {
        comment.user.name = currentUserName;
        comment.user.bio = currentUserBio;
        comment.user.localProfilePicture = currentProfilePicture;
      }
    }
  }

  void _addComment() async {
    if (_commentController.text.isNotEmpty) {
      final currentUserName = _storage.read('user_name') ?? 'You';
      final currentUserBio = _storage.read('user_bio') ?? '';
      final currentProfilePicture = _storage.read('my_profile_picture');
      
      final newComment = CommentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        user: UserModel(
          id: 'current_user', 
          name: currentUserName,
          bio: currentUserBio,
          localProfilePicture: currentProfilePicture,
        ),
        text: _commentController.text,
      );
      
      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
      });

      if (widget.isLocalPost) {
        await _updateLocalPostComment(newComment, isNew: true);
      }

      if (widget.onCommentAdded != null) {
        widget.onCommentAdded!(_comments.length);
      }
    }
  }

  Future<void> _updateLocalPostComment(CommentModel comment, {bool isNew = false, bool isDelete = false}) async {
    try {
      final posts = _storage.read('my_posts') ?? [];
      final updatedPosts = List.from(posts);
      
      for (int i = 0; i < updatedPosts.length; i++) {
        if (updatedPosts[i]['id'] == widget.postId) {
          final commentJson = comment.toJson();
          
          if (isDelete) {
            // Delete comment
            final comments = List.from(updatedPosts[i]['comments'] ?? []);
            updatedPosts[i]['comments'] = comments.where((c) => c['id'] != comment.id).toList();
          } else if (isNew) {
            // Add new comment
            if (updatedPosts[i]['comments'] == null) {
              updatedPosts[i]['comments'] = [commentJson];
            } else {
              updatedPosts[i]['comments'].insert(0, commentJson);
            }
          } else {
            // Update existing comment
            final comments = List.from(updatedPosts[i]['comments'] ?? []);
            for (int j = 0; j < comments.length; j++) {
              if (comments[j]['id'] == comment.id) {
                comments[j] = commentJson;
                break;
              }
            }
            updatedPosts[i]['comments'] = comments;
          }
          break;
        }
      }
      
      await _storage.write('my_posts', updatedPosts);
      
      if (!isDelete) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNew ? 'Comment added!' : 'Comment updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating local post comment: $e');
    }
  }

  void _startEditingComment(CommentModel comment) {
    setState(() {
      _editingCommentId = comment.id;
      _editCommentController.text = comment.text;
    });
  }

  void _saveEditedComment(String commentId) async {
    if (_editCommentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment cannot be empty!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final commentIndex = _comments.indexWhere((c) => c.id == commentId);
    if (commentIndex != -1) {
      final currentUserName = _storage.read('user_name') ?? 'You';
      final currentUserBio = _storage.read('user_bio') ?? '';
      final currentProfilePicture = _storage.read('my_profile_picture');
      
      final updatedComment = CommentModel(
        id: _comments[commentIndex].id,
        user: UserModel(
          id: 'current_user',
          name: currentUserName,
          bio: currentUserBio,
          localProfilePicture: currentProfilePicture,
        ),
        text: _editCommentController.text,
      );
      
      setState(() {
        _comments[commentIndex] = updatedComment;
        _editingCommentId = null;
        _editCommentController.clear();
      });

      if (widget.isLocalPost) {
        await _updateLocalPostComment(updatedComment, isNew: false);
      }
    }
  }

  void _deleteComment(String commentId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Comment'),
        content: Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final commentIndex = _comments.indexWhere((c) => c.id == commentId);
              if (commentIndex != -1) {
                final commentToDelete = _comments[commentIndex];
                
                setState(() {
                  _comments.removeAt(commentIndex);
                });

                if (widget.isLocalPost) {
                  await _updateLocalPostComment(commentToDelete, isDelete: true);
                }

                if (widget.onCommentAdded != null) {
                  widget.onCommentAdded!(_comments.length);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Comment deleted!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _cancelEditing() {
    setState(() {
      _editingCommentId = null;
      _editCommentController.clear();
    });
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

  // Helper method to get display name for a user
  String _getDisplayName(UserModel user) {
    if (user.id == 'current_user') {
      return _storage.read('user_name') ?? 'You';
    }
    return user.name;
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
                final isCurrentUser = comment.user.id == 'current_user';
                final isEditing = _editingCommentId == comment.id;
                final displayName = _getDisplayName(comment.user);
                
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileIcon(displayName, size: 40, profilePicture: profilePicture),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100], 
                                borderRadius: BorderRadius.circular(12),
                                border: isEditing ? Border.all(color: Colors.blue, width: 1) : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      if (isCurrentUser && !isEditing)
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit, size: 16, color: Colors.blue),
                                              onPressed: () => _startEditingComment(comment),
                                              padding: EdgeInsets.zero,
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, size: 16, color: Colors.red),
                                              onPressed: () => _deleteComment(comment.id),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  if (isEditing)
                                    Column(
                                      children: [
                                        TextField(
                                          controller: _editCommentController,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            hintText: 'Edit comment...',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: _cancelEditing,
                                              child: Text('Cancel', style: TextStyle(color: Colors.red)),
                                            ),
                                            SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () => _saveEditedComment(comment.id),
                                              child: Text('Save'),
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(horizontal: 16),
                                                backgroundColor: Colors.transparent,
                                                elevation: 0, 
                                                foregroundColor: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  else
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