import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../model/post_model.dart'; // ADD THIS IMPORT

class AuthService {
  final GetStorage _storage = GetStorage();
  
  // Keys for storage
  static const String _authKey = 'isAuthenticated';
  static const String _userKey = 'currentUser';
  static const String _usersKey = 'registeredUsers';
  
  // Username validation - no uppercase, no spaces
  bool _isValidUsername(String username) {
    final usernameRegex = RegExp(r'^[a-z0-9._]+$');
    return usernameRegex.hasMatch(username);
  }
  
  // Gmail validation regex - accepts only @gmail.com addresses
  bool _isValidGmail(String email) {
    final normalizedEmail = email.toLowerCase();
    final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    return gmailRegex.hasMatch(normalizedEmail);
  }
  
  // Check if user is logged in
  bool isLoggedIn() {
    return _storage.read(_authKey) ?? false;
  }
  
  // Get current user
  Map<String, dynamic>? getCurrentUser() {
    return _storage.read(_userKey);
  }
  
  // Get current user ID
  String? getCurrentUserId() {
    return getCurrentUser()?['id'];
  }
  
  // Get user-specific posts key
  String _getUserPostsKey(String userId) {
    return 'my_posts_$userId';
  }
  
  // Login with username OR gmail and password
  Future<bool> login(String usernameOrGmail, String password) async {
    try {
      // Get all registered users
      final users = _storage.read(_usersKey) ?? [];
      
      // Convert input to lowercase for Gmail comparison
      final normalizedInput = usernameOrGmail.toLowerCase().trim();
      
      // Find user with matching username OR gmail and password
      final user = users.firstWhere(
        (user) {
          // Check username (case-sensitive)
          if (user['username'] == usernameOrGmail && 
              user['password'] == password) {
            return true;
          }
          
          // Check Gmail (case-insensitive)
          final userEmail = user['email'].toString().toLowerCase();
          if (userEmail == normalizedInput && 
              user['password'] == password) {
            return true;
          }
          
          return false;
        },
        orElse: () => null,
      );
      
      if (user != null) {
        // Save auth state and current user
        await _storage.write(_authKey, true);
        await _storage.write(_userKey, user);
        
        // Save user info for profile
        await _storage.write('user_name', user['fullName'] ?? user['username']);
        await _storage.write('user_bio', user['bio'] ?? '');
        await _storage.write('user_username', user['username']);
        
        // Initialize empty posts for user if not exists
        final userId = user['id'];
        final userPostsKey = _getUserPostsKey(userId);
        if (_storage.read(userPostsKey) == null) {
          await _storage.write(userPostsKey, []);
        }
        
        // Show success message
        Fluttertoast.showToast(
          msg: "Login successful!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        
        return true;
      } else {
        Fluttertoast.showToast(
          msg: "Invalid username/Gmail or password",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      Fluttertoast.showToast(
        msg: "An error occurred. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }
  
  // Register new user - ONLY ACCEPTS GMAIL ADDRESSES
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? fullName,
  }) async {
    try {
      // Validation
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        Fluttertoast.showToast(
          msg: "Please fill all required fields",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      // Convert Gmail to lowercase for case-insensitive handling
      final normalizedEmail = email.toLowerCase().trim();
      
      // USERNAME VALIDATION - lowercase only, no spaces
      final trimmedUsername = username.trim();
      if (!_isValidUsername(trimmedUsername)) {
        Fluttertoast.showToast(
          msg: "Username can only contain lowercase letters, numbers, dots and underscores",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      if (trimmedUsername.length < 2) {
        Fluttertoast.showToast(
          msg: "Username must be at least 2 characters",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      if (trimmedUsername.length > 24) {
        Fluttertoast.showToast(
          msg: "Username cannot exceed 24 characters",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      if (trimmedUsername.startsWith('.') || trimmedUsername.startsWith('_')) {
        Fluttertoast.showToast(
          msg: "Username cannot start with . or _",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      if (trimmedUsername.endsWith('.') || trimmedUsername.endsWith('_')) {
        Fluttertoast.showToast(
          msg: "Username cannot end with . or _",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      if (trimmedUsername.contains('..') || trimmedUsername.contains('__') || 
          trimmedUsername.contains('._') || trimmedUsername.contains('_.')) {
        Fluttertoast.showToast(
          msg: "Username cannot have consecutive . or _",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      // GMAIL VALIDATION - ONLY ACCEPTS @gmail.com
      if (!_isValidGmail(normalizedEmail)) {
        Fluttertoast.showToast(
          msg: "Please enter a valid Gmail address (example@gmail.com)",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      if (password != confirmPassword) {
        Fluttertoast.showToast(
          msg: "Passwords do not match",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      if (password.length < 6) {
        Fluttertoast.showToast(
          msg: "Password must be at least 6 characters",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      // Check if username already exists
      final users = _storage.read(_usersKey) ?? [];
      final usernameExists = users.any((user) => user['username'] == trimmedUsername);
      
      // Check if Gmail already exists (case-insensitive)
      final emailExists = users.any((user) => 
          user['email'].toString().toLowerCase() == normalizedEmail);
      
      if (usernameExists) {
        Fluttertoast.showToast(
          msg: "Username already taken",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      if (emailExists) {
        Fluttertoast.showToast(
          msg: "This Gmail is already registered",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      // Create new user with lowercase Gmail
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final newUser = {
        'id': userId,
        'username': trimmedUsername, // Save trimmed username
        'email': normalizedEmail, // Save as lowercase
        'password': password, // In real app, hash this password!
        'fullName': fullName ?? trimmedUsername,
        'createdAt': DateTime.now().toIso8601String(),
        'bio': 'New user',
        'followers': 0,
        'following': 0,
        'profilePicture': null,
      };
      
      // Add to users list
      users.add(newUser);
      await _storage.write(_usersKey, users);
      
      // Auto login after registration
      await _storage.write(_authKey, true);
      await _storage.write(_userKey, newUser);
      
      // Save user info for profile
      await _storage.write('user_name', newUser['fullName']);
      await _storage.write('user_bio', newUser['bio']);
      await _storage.write('user_username', newUser['username']);
      
      // Initialize empty posts for new user
      await _storage.write(_getUserPostsKey(userId), []);
      
      Fluttertoast.showToast(
        msg: "Registration successful!",
        backgroundColor: Colors.green,
      );
      
      return true;
    } catch (e) {
      print('Registration error: $e');
      Fluttertoast.showToast(
        msg: "Registration failed. Please try again.",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }
  
  // Logout - CLEARS ALL USER-SPECIFIC DATA
  Future<void> logout() async {
    await _storage.write(_authKey, false);
    await _storage.remove(_userKey);
    await _storage.remove('user_name');
    await _storage.remove('user_bio');
    await _storage.remove('user_username');
    await _storage.remove('remembered_username');
    await _storage.remove('remembered_password');
    // Note: Don't clear my_profile_picture here - keep it per device
    
    Fluttertoast.showToast(
      msg: "Logged out successfully",
      backgroundColor: Colors.blue,
    );
  }
  
  // Get posts for current user
  List<PostModel> getCurrentUserPosts() {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    final userPostsKey = _getUserPostsKey(userId);
    final posts = _storage.read(userPostsKey) ?? [];
    
    // Convert to PostModel objects
    return posts.map((postData) {
      final user = UserModel(
        id: 'current_user',
        name: postData['user']['name'] ?? 'You',
        bio: postData['user']['bio'] ?? '',
        localProfilePicture: postData['user']['localProfilePicture'],
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
  }
  
  // Save posts for current user
  Future<void> saveCurrentUserPosts(List<PostModel> posts) async {
    final userId = getCurrentUserId();
    if (userId == null) return;
    final userPostsKey = _getUserPostsKey(userId);
    
    // Convert PostModel back to JSON
    final postsJson = posts.map((post) {
      return {
        'id': post.id,
        'user': post.user.toJson(),
        'content': post.content,
        'hashtags': post.hashtags,
        'hasImage': post.imageUrl != null,
        'imageData': post.imageUrl != null && post.imageUrl!.startsWith('data:image')
            ? post.imageUrl!.split(',').last
            : null,
        'likes': post.likes,
        'isLiked': post.isLiked,
        'comments': post.comments.map((comment) => comment.toJson()).toList(),
      };
    }).toList();
    
    await _storage.write(userPostsKey, postsJson);
  }
  
  // Check if username exists
  bool checkUsernameExists(String username) {
    final users = _storage.read(_usersKey) ?? [];
    return users.any((user) => user['username'] == username);
  }
  
  // Check if Gmail exists (case-insensitive)
  bool checkGmailExists(String email) {
    final users = _storage.read(_usersKey) ?? [];
    final normalizedEmail = email.toLowerCase().trim();
    return users.any((user) => 
        user['email'].toString().toLowerCase() == normalizedEmail);
  }
  
  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final currentUser = getCurrentUser();
      if (currentUser == null) return false;
      
      // Update current user data
      final updatedUser = {...currentUser, ...updates};
      await _storage.write(_userKey, updatedUser);
      
      // Update in users list
      final users = _storage.read(_usersKey) ?? [];
      final updatedUsers = users.map((user) {
        if (user['id'] == currentUser['id']) {
          return {...user, ...updates};
        }
        return user;
      }).toList();
      
      await _storage.write(_usersKey, updatedUsers);
      
      // Update profile info in storage
      if (updates.containsKey('fullName')) {
        await _storage.write('user_name', updates['fullName']);
      }
      if (updates.containsKey('bio')) {
        await _storage.write('user_bio', updates['bio']);
      }
      if (updates.containsKey('username')) {
        await _storage.write('user_username', updates['username']);
      }
      
      return true;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }
}