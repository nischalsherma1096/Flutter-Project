import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/post_model.dart';

class PostApi {
  static const String baseUrl = 'https://socialmedia-rest-api.vercel.app/api';

  Future<List<PostModel>> getPosts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PostModel.fromJson(json)).toList();
      } else {
        print('API Error ${response.statusCode}: Using mock data');
        return _getMockPosts();
      }
    } catch (e) {
      print('API Error: $e - Using mock data');
      return _getMockPosts();
    }
  }

  List<PostModel> _getMockPosts() {
    return [
      PostModel(
        id: '1',
        user: UserModel(
          id: '101',
          name: 'John Doe',
          avatar: 'https://i.pravatar.cc/150?img=1',
          bio: 'Flutter Developer',
          followers: 1200,
          following: 450,
        ),
        content: 'Just launched my new Flutter app! 🚀',
        imageUrl: 'https://picsum.photos/id/1/500/500',
        likes: 245,
        comments: [
          CommentModel(
            id: 'c1',
            user: UserModel(
              id: '102', 
              name: 'Alice Smith',
              avatar: 'https://i.pravatar.cc/150?img=4',
              bio: 'Mobile App Designer',
            ),
            text: 'Amazing work! 👏',
          ),
          CommentModel(
            id: 'c2',
            user: UserModel(
              id: '103', 
              name: 'Mike Wilson',
              avatar: 'https://i.pravatar.cc/150?img=5',
              bio: 'Travel Blogger',
            ),
            text: 'Where can I download it?',
          ),
        ],
        hashtags: ['#flutter', '#coding', '#appdev'],
      ),
      PostModel(
        id: '2',
        user: UserModel(
          id: '102',
          name: 'Sarah Johnson',
          avatar: 'https://i.pravatar.cc/150?img=2',
          bio: 'UX Designer',
          followers: 890,
          following: 320,
        ),
        content: 'Beautiful sunset at the beach! 🌅 Perfect end to the weekend.',
        imageUrl: 'https://picsum.photos/id/2/500/500',
        likes: 189,
        comments: [
          CommentModel(
            id: 'c3',
            user: UserModel(
              id: '103', 
              name: 'Mike Wilson',
              avatar: 'https://i.pravatar.cc/150?img=5',
              bio: 'Travel Blogger',
            ),
            text: 'Wish I was there!',
          ),
        ],
        hashtags: ['#weekend', '#beach', '#sunset', '#vacation'],
      ),
      PostModel(
        id: '3',
        user: UserModel(
          id: '103',
          name: 'Mike Wilson',
          avatar: 'https://i.pravatar.cc/150?img=3',
          bio: 'Travel Photographer',
          followers: 2500,
          following: 800,
        ),
        content: 'Working on my new photography project. Nature has so much beauty to offer.',
        imageUrl: 'https://picsum.photos/id/3/500/500',
        likes: 423,
        comments: [
          CommentModel(
            id: 'c4',
            user: UserModel(
              id: '101', 
              name: 'John Doe',
              avatar: 'https://i.pravatar.cc/150?img=1',
              bio: 'Flutter Developer',
            ),
            text: 'Stunning shot!',
          ),
          CommentModel(
            id: 'c5',
            user: UserModel(
              id: '102', 
              name: 'Sarah Johnson',
              avatar: 'https://i.pravatar.cc/150?img=2',
              bio: 'UX Designer',
            ),
            text: 'Love the composition!',
          ),
        ],
        hashtags: ['#photography', '#nature', '#art'],
      ),
    ];
  }
}