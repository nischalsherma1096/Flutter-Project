import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../model/post_model.dart';
import './comments/comments_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final dynamic post;
  final bool isLocalPost;
  final Function()? onPostUpdated;
  final Function()? onPostDeleted;

  PostDetailScreen({
    required this.post,
    this.isLocalPost = false,
    this.onPostUpdated,
    this.onPostDeleted,
  });

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late bool _isLiked;
  int _likeCount = 0;
  final GetStorage _storage = GetStorage();
  bool _isEditing = false;
  final TextEditingController _editController = TextEditingController();
  List<CommentModel> _comments = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.isLocalPost) {
      _isLiked = widget.post['isLiked'] ?? false;
      _likeCount = widget.post['likes'] ?? 0;
      _editController.text = widget.post['content'] ?? '';
      
      if (widget.post['comments'] != null) {
        _comments = (widget.post['comments'] as List)
            .map((comment) => CommentModel.fromJson(comment))
            .toList();
        _updateCommentNames(); // Update names on init
      }
    } else {
      _isLiked = widget.post.isLiked ?? false;
      _likeCount = widget.post.likes ?? 0;
      _editController.text = widget.post.content ?? '';
      _comments = widget.post.comments ?? [];
      _updateCommentNames(); // Update names on init
    }
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

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

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

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
    });

    if (widget.isLocalPost) {
      _updateLocalPostLikes();
    }
  }

  void _updateLocalPostLikes() {
    final posts = _storage.read('my_posts') ?? [];
    final updatedPosts = List.from(posts);
    
    for (int i = 0; i < updatedPosts.length; i++) {
      if (updatedPosts[i]['id'] == widget.post['id']) {
        updatedPosts[i]['likes'] = _likeCount;
        updatedPosts[i]['isLiked'] = _isLiked;
        break;
      }
    }
    
    _storage.write('my_posts', updatedPosts);
  }

  void _deletePost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final posts = _storage.read('my_posts') ?? [];
              final updatedPosts = posts.where((p) => p['id'] != widget.post['id']).toList();
              _storage.write('my_posts', updatedPosts);
              
              Navigator.pop(context);
              if (widget.onPostDeleted != null) {
                widget.onPostDeleted!();
              }
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveEdit() {
    if (_editController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post cannot be empty!'), backgroundColor: Colors.red),
      );
      return;
    }

    final posts = _storage.read('my_posts') ?? [];
    final updatedPosts = List.from(posts);
    
    for (int i = 0; i < updatedPosts.length; i++) {
      if (updatedPosts[i]['id'] == widget.post['id']) {
        updatedPosts[i]['content'] = _editController.text.trim();
        updatedPosts[i]['hashtags'] = _extractHashtags(_editController.text);
        updatedPosts[i]['timestamp'] = DateTime.now().toIso8601String();
        break;
      }
    }
    
    _storage.write('my_posts', updatedPosts);
    
    setState(() {
      _isEditing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post updated successfully!'), backgroundColor: Colors.green),
    );
    
    if (widget.onPostUpdated != null) {
      widget.onPostUpdated!();
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editController.text = widget.isLocalPost 
        ? widget.post['content'] ?? ''
        : widget.post.content ?? '';
    });
  }

  List<String> _extractHashtags(String text) {
    final hashtagRegex = RegExp(r'\B#\w\w+');
    return hashtagRegex
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
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

  String _getUserName() {
    if (widget.isLocalPost) {
      final postUser = widget.post['user'];
      if (postUser != null && postUser['id'] == 'current_user') {
        return _storage.read('user_name') ?? 'You';
      }
      return widget.post['user']?['name'] ?? 'You';
    } else {
      if (widget.post.user?.id == 'current_user') {
        return _storage.read('user_name') ?? 'You';
      }
      return widget.post.user?.name ?? 'Unknown';
    }
  }

  String _getUserBio() {
    if (widget.isLocalPost) {
      final postUser = widget.post['user'];
      if (postUser != null && postUser['id'] == 'current_user') {
        return _storage.read('user_bio') ?? '';
      }
      return widget.post['user']?['bio'] ?? '';
    } else {
      if (widget.post.user?.id == 'current_user') {
        return _storage.read('user_bio') ?? '';
      }
      return widget.post.user?.bio ?? '';
    }
  }

  String _getPostContent() {
    if (widget.isLocalPost) {
      return widget.post['content'] ?? '';
    } else {
      return widget.post.content ?? '';
    }
  }

  List<String> _getHashtags() {
    if (widget.isLocalPost) {
      return List<String>.from(widget.post['hashtags'] ?? []);
    } else {
      return widget.post.hashtags ?? [];
    }
  }

  bool _hasImage() {
    if (widget.isLocalPost) {
      return widget.post['hasImage'] == true && widget.post['imageData'] != null;
    } else {
      return widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty;
    }
  }

  Widget? _getImageWidget() {
    if (widget.isLocalPost) {
      if (widget.post['hasImage'] == true && widget.post['imageData'] != null) {
        try {
          final imageData = widget.post['imageData'];
          final Uint8List imageBytes = imageData is String ? base64Decode(imageData) : imageData;
          return Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey[400]));
            },
          );
        } catch (e) {
          return null;
        }
      }
      return null;
    } else {
      if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty) {
        return Image.network(
          widget.post.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey[400]));
          },
        );
      }
      return null;
    }
  }

  void _showComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          comments: _comments,
          postId: widget.isLocalPost ? widget.post['id'] : widget.post.id,
          isLocalPost: widget.isLocalPost,
          onCommentAdded: (newCount) {
            setState(() {
              if (!widget.isLocalPost) {
                final currentUserName = _storage.read('user_name') ?? 'You';
                final currentUserBio = _storage.read('user_bio') ?? '';
                final currentProfilePicture = _storage.read('my_profile_picture');
                
                _comments = [
                  CommentModel(
                    id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                    user: UserModel(
                      id: 'current_user',
                      name: currentUserName,
                      bio: currentUserBio,
                      localProfilePicture: currentProfilePicture,
                    ),
                    text: 'New comment',
                  ),
                  ..._comments,
                ];
              }
            });
          },
        ),
      ),
    ).then((newCommentCount) {
      if (newCommentCount != null && widget.isLocalPost) {
        _loadLocalPostComments();
      }
    });
  }

  void _loadLocalPostComments() {
    if (!widget.isLocalPost) return;
    
    final posts = _storage.read('my_posts') ?? [];
    for (var post in posts) {
      if (post['id'] == widget.post['id']) {
        setState(() {
          _comments = (post['comments'] ?? [])
              .map((comment) => CommentModel.fromJson(comment))
              .toList();
          _updateCommentNames(); // Update names when loading
        });
        break;
      }
    }
  }

  String _getPostTimestamp() {
    if (widget.isLocalPost && widget.post['timestamp'] != null) {
      final postDate = DateTime.parse(widget.post['timestamp']);
      final difference = DateTime.now().difference(postDate);
      
      if (difference.inDays < 1) {
        return 'today';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else {
        return '${difference.inDays} days ago';
      }
    }
    return '';
  }

  bool _isCurrentUser() {
    final postUserName = _getUserName();
    final currentUserName = _storage.read('user_name') ?? 'You';
    return postUserName == currentUserName || postUserName == 'You';
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName();
    final userBio = _getUserBio();
    final postContent = _getPostContent();
    final hashtags = _getHashtags();
    final imageWidget = _getImageWidget();
    final postTimestamp = _getPostTimestamp();
    final isCurrentUser = _isCurrentUser();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: Text('Post Details'),
        actions: widget.isLocalPost ? [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.check, color: Colors.green),
              onPressed: _saveEdit,
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: _cancelEdit,
            ),
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: _startEditing,
            ),
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _deletePost,
            ),
        ] : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildProfileIcon(
                    userName,
                    size: 50,
                    profilePicture: isCurrentUser 
                      ? _getProfilePictureForUser(UserModel(id: 'current_user', name: 'You'))
                      : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        if (userBio.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              userBio,
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (postTimestamp.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Posted $postTimestamp',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1),
            
            // Post Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _editController,
                          maxLines: 6,
                          maxLength: 280,
                          decoration: InputDecoration(
                            hintText: 'Edit your post...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tip: Use #hashtags to reach more people',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postContent,
                          style: TextStyle(fontSize: 16, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        
                        if (hashtags.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            children: hashtags
                                .map<Widget>((tag) => Chip(
                                      label: Text(tag),
                                      backgroundColor: Colors.blue[50],
                                      labelStyle: TextStyle(color: Colors.blue[700]),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            
            // Post Image (if exists)
            if (imageWidget != null && _hasImage())
              Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: imageWidget,
              ),
            
            // Post Stats (NON-CLICKABLE - just for display)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Just icon, no button
                  Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.grey[600],
                    size: 24,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '$_likeCount likes',
                    style: TextStyle(
                      color: _isLiked ? Colors.red : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 20),
                  Icon(Icons.comment_outlined, color: Colors.grey[600], size: 24),
                  SizedBox(width: 6),
                  Text(
                    '${_comments.length} comments',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1),
            
            // Action Buttons (CLICKABLE - for functionality)
            if (!_isEditing)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: _toggleLike,
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.grey[600],
                      ),
                      label: Text(
                        _isLiked ? 'Liked' : 'Like',
                        style: TextStyle(color: _isLiked ? Colors.red : Colors.grey[600]),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showComments,
                      icon: Icon(Icons.comment_outlined, color: Colors.grey[600]),
                      label: Text('Comment', style: TextStyle(color: Colors.grey[600])),
                    ),
                  ],
                ),
              ),
            
            if (!_isEditing) Divider(height: 1),
            
            // Comments Preview
            if (!_isEditing)
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comments',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    if (_comments.isEmpty)
                      _buildNoCommentsView()
                    else
                      ..._comments.take(2).map((comment) => _buildCommentPreview(comment)),
                    if (_comments.length > 2)
                      _buildViewAllCommentsButton(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCommentsView() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.comment_outlined, size: 40, color: Colors.grey[400]),
            SizedBox(height: 10),
            Text(
              'No comments yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 5),
            Text(
              'Be the first to comment!',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAllCommentsButton() {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: TextButton(
        onPressed: _showComments,
        child: Text(
          'View all ${_comments.length} comments',
          style: TextStyle(color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildCommentPreview(CommentModel comment) {
    final profilePicture = _getProfilePictureForUser(comment.user);
    final isCurrentUserComment = comment.user.id == 'current_user';
    final displayName = _getDisplayName(comment.user);
    
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileIcon(displayName, size: 30, profilePicture: profilePicture),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (isCurrentUserComment)
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          '• You',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  comment.text,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}