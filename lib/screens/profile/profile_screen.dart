
import 'package:flutter/material.dart';
import '../../model/post_model.dart';
import '../post_screen_details.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;
  ProfileScreen({required this.user});

  Widget _buildProfileIcon(String name, {double size = 100}) {
    final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.red];
    final colorIndex = name.hashCode % colors.length;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors[colorIndex],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }

  List<Map<String, dynamic>> _getUserPosts() {
    if (user.id == '101') {
      return [
        {
          'id': '1',
          'content': 'Just launched my new Flutter app! 🚀',
          'hasImage': true,
          'imageUrl': 'https://picsum.photos/id/1/500/500',
          'likes': 245,
          'comments': [],
          'timestamp': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
          'user': {
            'id': '101',
            'name': 'John Doe',
            'bio': 'Flutter Developer',
            'avatar': 'https://i.pravatar.cc/150?img=1',
          },
          'hashtags': ['#flutter', '#coding', '#appdev'],
        },
        {
          'id': '4',
          'content': 'Working on some amazing UI designs today!',
          'hasImage': true,
          'imageUrl': 'https://picsum.photos/id/20/500/500',
          'likes': 89,
          'comments': [],
          'timestamp': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
          'user': {
            'id': '101',
            'name': 'John Doe',
            'bio': 'Flutter Developer',
            'avatar': 'https://i.pravatar.cc/150?img=1',
          },
          'hashtags': ['#ui', '#design', '#flutter'],
        },
      ];
    } else if (user.id == '102') {
      return [
        {
          'id': '2',
          'content': 'Beautiful sunset at the beach! 🌅 Perfect end to the weekend.',
          'hasImage': true,
          'imageUrl': 'https://picsum.photos/id/2/500/500',
          'likes': 189,
          'comments': [],
          'timestamp': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
          'user': {
            'id': '102',
            'name': 'Sarah Johnson',
            'bio': 'UX Designer',
            'avatar': 'https://i.pravatar.cc/150?img=2',
          },
          'hashtags': ['#weekend', '#beach', '#sunset'],
        },
        {
          'id': '5',
          'content': 'New design project coming soon!',
          'hasImage': true,
          'imageUrl': 'https://picsum.photos/id/30/500/500',
          'likes': 120,
          'comments': [],
          'timestamp': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
          'user': {
            'id': '102',
            'name': 'Sarah Johnson',
            'bio': 'UX Designer',
            'avatar': 'https://i.pravatar.cc/150?img=2',
          },
          'hashtags': ['#design', '#ux', '#project'],
        },
      ];
    } else if (user.id == '103') {
      return [
        {
          'id': '3',
          'content': 'Working on my new photography project. Nature has so much beauty to offer.',
          'hasImage': true,
          'imageUrl': 'https://picsum.photos/id/3/500/500',
          'likes': 423,
          'comments': [],
          'timestamp': DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
          'user': {
            'id': '103',
            'name': 'Mike Wilson',
            'bio': 'Travel Photographer',
            'avatar': 'https://i.pravatar.cc/150?img=3',
          },
          'hashtags': ['#photography', '#nature', '#art'],
        },
        {
          'id': '6',
          'content': 'Captured this amazing landscape during my trip.',
          'hasImage': true,
          'imageUrl': 'https://picsum.photos/id/40/500/500',
          'likes': 256,
          'comments': [],
          'timestamp': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
          'user': {
            'id': '103',
            'name': 'Mike Wilson',
            'bio': 'Travel Photographer',
            'avatar': 'https://i.pravatar.cc/150?img=3',
          },
          'hashtags': ['#travel', '#photography', '#landscape'],
        },
      ];
    }
    
    return [
      {
        'id': 'default_1',
        'content': 'Check out my latest post!',
        'hasImage': true,
        'imageUrl': 'https://picsum.photos/id/50/500/500',
        'likes': 50,
        'comments': [],
        'timestamp': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
        'user': user.toJson(),
        'hashtags': ['#post', '#update'],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final userPosts = _getUserPosts();
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  _buildProfileIcon(user.name, size: 100),
                  SizedBox(height: 16),
                  Text(user.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(user.bio!, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
                  ],
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Posts', '${userPosts.length}'),
                      _buildStatColumn('Followers', '${user.followers}'),
                      _buildStatColumn('Following', '${user.following}'),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          child: Text('Follow'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(child: OutlinedButton(onPressed: () {}, child: Text('Message'))),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Posts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 1,
                    ),
                    itemCount: userPosts.length,
                    itemBuilder: (context, index) {
                      final post = userPosts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(
                                post: post,
                                isLocalPost: false,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.grey[200],
                          child: post['imageUrl'] != null
                              ? Image.network(
                                  post['imageUrl']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: Icon(Icons.image, color: Colors.grey[500]),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Icon(Icons.text_fields, color: Colors.grey[500]),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}