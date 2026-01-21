import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../utils/post.api.dart';
import '../model/post_model.dart';
import 'profile/profile_screen.dart';
import 'comments/comments_screen.dart';
import 'post_screen_details.dart';
class GetScreen extends StatefulWidget {
  final Function(List<PostModel>)? onPostsLoaded;
  
  GetScreen({this.onPostsLoaded});
  
  @override
  _GetScreenState createState() => _GetScreenState();
}

class _GetScreenState extends State<GetScreen> {
  List<PostModel> posts = [];
  bool isLoading = true;
  final GetStorage _storage = GetStorage();
  
  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      // Get API posts
      final apiPosts = await PostApi().getPosts();
      
      // Get local user posts
      final localPosts = _getLocalPosts();
      
      // Combine both lists - local posts first, then API posts
      final allPosts = [...localPosts, ...apiPosts];
      
      setState(() {
        posts = allPosts;
        isLoading = false;
      });
      
      // Notify parent about loaded posts
      if (widget.onPostsLoaded != null) {
        widget.onPostsLoaded!(posts);
      }
    } catch (e) {
      print('Error: $e');
      
      final localPosts = _getLocalPosts();
      setState(() {
        posts = localPosts;
        isLoading = false;
      });
      
      if (widget.onPostsLoaded != null) {
        widget.onPostsLoaded!(localPosts);
      }
    }
  }

  List<PostModel> _getLocalPosts() {
    try {
      final posts = _storage.read('my_posts') ?? [];
      
      return posts.map((postData) {
        final userName = postData['user']['name'] ?? 'You';
        final userBio = postData['user']['bio'] ?? '';
        final profilePicture = postData['user']['localProfilePicture'];
        
        final user = UserModel(
          id: 'current_user',
          name: userName,
          bio: userBio,
          localProfilePicture: profilePicture,
        );
        
        return PostModel(
          id: postData['id'] ?? '',
          user: user,
          content: postData['content'] ?? '',
          hashtags: List<String>.from(postData['hashtags'] ?? []),
          imageUrl: postData['hasImage'] == true && postData['imageData'] != null 
              ? 'data:image/jpeg;base64,${postData['imageData']}' 
              : null,
          likes: postData['likes'] ?? 0,
          isLiked: postData['isLiked'] ?? false,
          comments: (postData['comments'] as List?)
              ?.map((comment) => CommentModel.fromJson(comment))
              .toList() ?? [],
        );
      }).toList();
    } catch (e) {
      print('Error getting local posts: $e');
      return [];
    }
  }

  void _toggleLike(int index) {
    setState(() {
      posts[index].isLiked = !posts[index].isLiked;
      if (posts[index].isLiked) {
        posts[index].likes++;
      } else {
        posts[index].likes--;
      }
    });
  }

  void _showProfile(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(user: user)),
    );
  }

  void _showComments(List<CommentModel> comments, String postId, bool isLocalPost) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          comments: comments,
          postId: postId,
          isLocalPost: isLocalPost,
          onCommentAdded: (newCount) {
            setState(() {
              for (var post in posts) {
                if (post.id == postId) {
                  post.comments = comments;
                }
              }
            });
          },
        ),
      ),
    ).then((newCommentCount) {
      if (newCommentCount != null) {
        setState(() {});
      }
    });
  }

  Widget _buildProfileIcon(String name, {double size = 40, Uint8List? profilePicture}) {
    final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.red];
    final colorIndex = name.hashCode % colors.length;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        image: profilePicture != null
            ? DecorationImage(
                image: MemoryImage(profilePicture),
                fit: BoxFit.cover,
              )
            : null,
        color: profilePicture == null ? colors[colorIndex] : null,
      ),
      child: profilePicture == null
          ? Icon(
              Icons.person,
              color: Colors.white,
              size: size * 0.5,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(height: 1, width: double.infinity, color: Colors.grey[300]),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchPosts,
                    child: ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailScreen(
                                  post: post,
                                  isLocalPost: post.user.id == 'current_user',
                                  onPostUpdated: fetchPosts,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: GestureDetector(
                                    onTap: () => _showProfile(post.user),
                                    child: Row(
                                      children: [
                                        _buildProfileIcon(post.user.name, size: 40),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(post.user.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              if (post.user.bio != null && post.user.bio!.isNotEmpty)
                                                Padding(
                                                  padding: EdgeInsets.only(top: 2),
                                                  child: Text(
                                                    post.user.bio!,
                                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(post.content, style: TextStyle(fontSize: 15)),
                                      SizedBox(height: 8),
                                      if (post.hashtags.isNotEmpty)
                                        Text(post.hashtags.join(' '), style: TextStyle(fontSize: 15, color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12),
                                if (post.imageUrl != null)
                                  Container(
                                    height: 300,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      image: DecorationImage(image: NetworkImage(post.imageUrl!), fit: BoxFit.cover),
                                    ),
                                  ),
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _toggleLike(index),
                                        child: Row(
                                          children: [
                                            Icon(post.isLiked ? Icons.favorite : Icons.favorite_border, 
                                                 color: post.isLiked ? Colors.red : Colors.grey[600], size: 24),
                                            SizedBox(width: 8),
                                            Text('${post.likes}', style: TextStyle(fontWeight: FontWeight.w500, color: post.isLiked ? Colors.red : Colors.black)),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 24),
                                      GestureDetector(
                                        onTap: () => _showComments(post.comments, post.id, post.user.id == 'current_user'),
                                        child: Row(
                                          children: [
                                            Icon(Icons.comment_outlined, color: Colors.grey[600], size: 24),
                                            SizedBox(width: 8),
                                            Text('${post.comments.length}', style: TextStyle(fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
