import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:postly/services/auth_service.dart';
import 'get_screen.dart';
import 'post_screen.dart';
import 'search/search_screen.dart';
import 'profile/my_profile_screen.dart';
import '../model/post_model.dart';

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final GetStorage _storage = GetStorage();
  Uint8List? _profilePicture;
  List<PostModel> _allPosts = []; // Store posts here
  
  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  void _loadProfilePicture() {
    final profileData = _storage.read('my_profile_picture');
    if (profileData != null && profileData is String) {
      try {
        setState(() {
          _profilePicture = base64Decode(profileData);
        });
      } catch (e) {
        print('Error loading profile picture: $e');
      }
    }
  }

  // Function to update posts from GetScreen
  void _updatePosts(List<PostModel> posts) {
    setState(() {
      _allPosts = posts;
    });
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _openUploadScreen();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _openUploadScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(),
        fullscreenDialog: true,
      ),
    );
    
    if (result == true) {
      // If post was created successfully
    }
  }

  void _openMyProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyProfileScreen()),
    );
    _loadProfilePicture();
  }

  // CHANGED: Added logout function
  void _logout() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final authService = AuthService();
      await authService.logout();
      
      // Navigate back to login screen
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildProfileIcon(String name, {double size = 40, Uint8List? profilePicture}) {
    final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.red];
    final colorIndex = name.hashCode % colors.length;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
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
      appBar: _selectedIndex == 0 
          ? AppBar(
              leading: Padding(
                padding: EdgeInsets.only(left: 16),
                child: GestureDetector(
                  onTap: _openMyProfile,
                  child: _buildProfileIcon(
                    _storage.read('user_name') ?? 'You',
                    size: 36,
                    profilePicture: _profilePicture,
                  ),
                ),
              ),
              title: Text('POSTLY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              centerTitle: true,
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      _logout();
                    } else if (value == 'settings') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Settings coming soon!'))
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 20),
                          SizedBox(width: 8),
                          Text('Settings'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Logout', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.menu),
                  ),
                ),
              ],
            )
          : AppBar(
              title: Text(_getAppBarTitle()),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          GetScreen(onPostsLoaded: _updatePosts), // Pass callback
          Container(),
          SearchScreen(allPosts: _allPosts), // Pass actual posts
          Container(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
          color: Colors.white,
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home_outlined, 0, 'Home'),
              _buildNavItem(Icons.add_box_outlined, 1, 'Upload'),
              _buildNavItem(Icons.search, 2, 'Search'),
              _buildNavItem(Icons.notifications_none, 3, 'Notifications'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? Colors.blue : Colors.grey[600],
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return 'POSTLY';
      case 1: return 'Create Post';
      case 2: return 'Search';
      case 3: return 'Notifications';
      default: return 'POSTLY';
    }
  }
}