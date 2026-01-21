import 'package:flutter/material.dart';
import '../../model/post_model.dart';
import '../post_screen_details.dart';
import '../profile/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<PostModel> allPosts;
  
  SearchScreen({required this.allPosts});
  
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PostModel> _filteredPosts = [];
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _filteredPosts = widget.allPosts;
  }
  
  void _searchPosts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPosts = widget.allPosts;
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      
      
      final searchQuery = query.toLowerCase().trim();
      
      
      _filteredPosts = widget.allPosts.where((post) {
        
        final hasHashtagMatch = post.hashtags.any((hashtag) => 
          hashtag.toLowerCase().contains(searchQuery)
        );
        
        
        final hasContentMatch = post.content.toLowerCase().contains(searchQuery);
        
        
        final hasUserMatch = post.user.name.toLowerCase().contains(searchQuery);
        
        
        final hasBioMatch = post.user.bio != null && 
            post.user.bio!.toLowerCase().contains(searchQuery);
        
       
        return hasHashtagMatch || hasContentMatch || hasUserMatch || hasBioMatch;
      }).toList();
    });
  }
  
  
  Widget _buildPostItem(BuildContext context, PostModel post) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(user: post.user),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text(
                    post.user.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      post: post,
                      isLocalPost: false,
                      onPostUpdated: () {},
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.content.length > 100 
                      ? '${post.content.substring(0, 100)}...' 
                      : post.content,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  
                  
                  if (post.hashtags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: post.hashtags.map((hashtag) => Chip(
                        label: Text(
                          hashtag,
                          style: TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.blue[50],
                        labelStyle: TextStyle(color: Colors.blue[700]),
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                ],
              ),
            ),
            
            // Stats
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.favorite_border, size: 18, color: Colors.grey),
                SizedBox(width: 4),
                Text('${post.likes}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(width: 16),
                Icon(Icons.comment_outlined, size: 18, color: Colors.grey),
                SizedBox(width: 4),
                Text('${post.comments.length}', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search hashtags, content, users...',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _filteredPosts = widget.allPosts;
                          _isSearching = false;
                        });
                      },
                    )
                  : null,
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              
              _searchPosts(value);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search by hashtags, post content, or user names',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: _isSearching
                ? _filteredPosts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'No posts found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try searching for different keywords',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = _filteredPosts[index];
                          return _buildPostItem(context, post);
                        },
                      )
                : ListView(
                    children: [
                      
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Popular Hashtags',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                '#flutter',
                                '#travel',
                                '#photography',
                                '#coding',
                                '#nature',
                                '#food',
                                '#weekend',
                                '#sunset',
                              ].map((hashtag) => GestureDetector(
                                onTap: () {
                                  _searchController.text = hashtag;
                                  _searchPosts(hashtag);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    hashtag,
                                    style: TextStyle(color: Colors.blue[700]),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      
                      
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Posts',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12),
                          ],
                        ),
                      ),
                      
                      
                      ...widget.allPosts.take(3).map((post) => _buildPostItem(context, post)).toList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}