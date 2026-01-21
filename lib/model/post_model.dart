class UserModel {
  final String id;
  String name;
  final String? avatar;
  String? bio;
  final int followers;
  final int following;
  final String? profilePicture;
  String? localProfilePicture;

  UserModel({
    required this.id,
    required this.name,
    this.avatar,
    this.bio,
    this.followers = 0,
    this.following = 0,
    this.profilePicture,
    this.localProfilePicture,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userId = json['id'].toString();
    final userName = json['name'] ?? 'Unknown';
    
    return UserModel(
      id: userId,
      name: userName,
      avatar: (json['avatar'] != null && json['avatar'].toString().isNotEmpty)
          ? json['avatar'].toString()
          : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=0D8ABC&color=fff&size=150',
      bio: json['bio'],
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      profilePicture: json['profilePicture'],
      localProfilePicture: json['localProfilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'followers': followers,
      'following': following,
      'profilePicture': profilePicture,
      'localProfilePicture': localProfilePicture,
    };
  }
}

class CommentModel {
  final String id;
  final UserModel user;
  final String text;

  CommentModel({
    required this.id,
    required this.user,
    required this.text,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'].toString(),
      user: UserModel.fromJson(json['user']),
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'text': text,
    };
  }
}

class PostModel {
  final String id;
  final UserModel user;
  final String content;
  final String? imageUrl;
  int likes;
  List<CommentModel> comments;
  final List<String> hashtags;
  bool isLiked;

  PostModel({
    required this.id,
    required this.user,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.hashtags,
    this.isLiked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'].toString(),
      user: UserModel.fromJson(json['user']),
      content: json['content'],
      imageUrl: json['image'],
      likes: json['likes'] ?? 0,
      comments: (json['comments'] as List?)
          ?.map((comment) => CommentModel.fromJson(comment))
          .toList() ?? [],
      hashtags: List<String>.from(json['hashtags'] ?? []),
      isLiked: json['isLiked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'content': content,
      'image': imageUrl,
      'likes': likes,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'hashtags': hashtags,
      'isLiked': isLiked,
    };
  }
}