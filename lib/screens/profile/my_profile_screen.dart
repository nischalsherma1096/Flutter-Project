import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../post_screen.dart';
import '../post_screen_details.dart';

class MyProfileScreen extends StatefulWidget {
  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final GetStorage _storage = GetStorage();
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _myPosts = [];
  bool _isLoading = true;
  Uint8List? _profilePicture;
  bool _isUploadingProfile = false;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  bool _isEditingName = false;
  bool _isEditingBio = false;

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
    _loadProfilePicture();
    _loadUserInfo(); 
  }

  
  void _loadUserInfo() {
    final userName = _storage.read('user_name') ?? 'You';
    final userBio = _storage.read('user_bio') ?? 'Bio'; 
    
    setState(() {
      _nameController.text = userName;
      _bioController.text = userBio;
    });
  }

  void _loadProfilePicture() {
    final profileData = _storage.read('my_profile_picture');
    if (profileData != null && profileData is String) {
      try {
        setState(() {
          _profilePicture = base64Decode(profileData);
        });
      } catch (e) {
        print('Error decoding profile picture: $e');
      }
    }
  }

  void _updatePostsWithNewUserInfo() {
    final posts = _storage.read('my_posts') ?? [];
    final updatedPosts = List.from(posts);
    final newName = _nameController.text.trim();
    final newBio = _bioController.text.trim();
    final profilePicture = _storage.read('my_profile_picture');
    
    for (int i = 0; i < updatedPosts.length; i++) {
      // Update post author info
      updatedPosts[i]['user']['name'] = newName;
      if (newBio.isNotEmpty) {
        updatedPosts[i]['user']['bio'] = newBio;
      }
      if (profilePicture != null) {
        updatedPosts[i]['user']['localProfilePicture'] = profilePicture;
      }
      
      // Update comments by current user
      if (updatedPosts[i]['comments'] != null) {
        final comments = List.from(updatedPosts[i]['comments']);
        for (int j = 0; j < comments.length; j++) {
          if (comments[j]['user']['id'] == 'current_user') {
            comments[j]['user']['name'] = newName;
            if (newBio.isNotEmpty) {
              comments[j]['user']['bio'] = newBio;
            }
            if (profilePicture != null) {
              comments[j]['user']['localProfilePicture'] = profilePicture;
            }
          }
        }
        updatedPosts[i]['comments'] = comments;
      }
    }
    
    _storage.write('my_posts', updatedPosts);
    _loadMyPosts();
  }

  Future<void> _pickProfilePicture() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _isUploadingProfile = true;
        });

        final bytes = await pickedFile.readAsBytes();
        
        Uint8List compressedBytes = bytes;
        if (bytes.lengthInBytes > 1 * 1024 * 1024) {
          compressedBytes = await _compressImage(bytes);
        }
        
        await _storage.write('my_profile_picture', base64Encode(compressedBytes));
        
        setState(() {
          _profilePicture = compressedBytes;
          _isUploadingProfile = false;
        });
        
        _updatePostsWithNewUserInfo();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error picking profile picture: $e');
      setState(() {
        _isUploadingProfile = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 400,
        minWidth: 400,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      print('Compression error: $e');
      return bytes;
    }
  }

  void _loadMyPosts() {
    try {
      final posts = _storage.read('my_posts') ?? [];
      setState(() {
        _myPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createNewPost() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => PostScreen()));
    if (result == true) _loadMyPosts();
  }

  Widget _buildProfilePicture({double size = 120}) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: _isUploadingProfile
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : _profilePicture != null
                  ? ClipOval(
                      child: Image.memory(
                        _profilePicture!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultProfileIcon(size: size);
                        },
                      ),
                    )
                  : _buildDefaultProfileIcon(size: size),
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue[700],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: IconButton(
            icon: Icon(Icons.camera_alt, size: 20, color: Colors.white),
            onPressed: _isUploadingProfile ? null : _pickProfilePicture,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultProfileIcon({double size = 120}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildNameField() {
    if (_isEditingName) {
      return TextField(
        controller: _nameController,
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: 'Enter your name',
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: () {
              // Save only name
              final newName = _nameController.text.trim();
              if (newName.isNotEmpty) {
                _storage.write('user_name', newName);
                setState(() {
                  _isEditingName = false;
                });
                _updatePostsWithNewUserInfo();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Name updated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            _storage.write('user_name', value.trim());
            setState(() {
              _isEditingName = false;
            });
            _updatePostsWithNewUserInfo();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Name updated!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    } else {
      return GestureDetector(
        onTap: () {
          setState(() {
            _isEditingName = true;
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _nameController.text,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.edit, size: 20, color: Colors.grey),
          ],
        ),
      );
    }
  }

  Widget _buildBioField() {
    if (_isEditingBio) {
      return TextField(
        controller: _bioController,
        style: TextStyle(color: Colors.grey[600], fontSize: 16),
        textAlign: TextAlign.center,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'Enter your bio',
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: () {
              // Save only bio
              final newBio = _bioController.text.trim();
              _storage.write('user_bio', newBio);
              setState(() {
                _isEditingBio = false;
              });
              _updatePostsWithNewUserInfo();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bio updated!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ),
        onSubmitted: (value) {
          _storage.write('user_bio', value.trim());
          setState(() {
            _isEditingBio = false;
          });
          _updatePostsWithNewUserInfo();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bio updated!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    } else {
      return GestureDetector(
        onTap: () {
          setState(() {
            _isEditingBio = true;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: IntrinsicWidth(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _bioController.text,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 4),
                Transform.translate(
                  offset: Offset(0, 0),
                  child: Icon(Icons.edit, size: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Settings coming soon!'))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  _buildProfilePicture(size: 120),
                  SizedBox(height: 16),
                  _buildNameField(),
                  SizedBox(height: 8),
                  _buildBioField(),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Posts', '${_myPosts.length}'),
                      _buildStatColumn('Followers', '150'),
                      _buildStatColumn('Following', '200'),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createNewPost,
                      child: Text(
                        'New Post',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
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
                  Text('My Posts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  if (_isLoading) Center(child: CircularProgressIndicator())
                  else if (_myPosts.isEmpty) Container(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Column(
                      children: [
                        Icon(Icons.post_add, size: 60, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text('No posts yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        SizedBox(height: 8),
                        Text('Share your first post!', style: TextStyle(color: Colors.grey[500])),
                        SizedBox(height: 20),
                        ElevatedButton(onPressed: _createNewPost, child: Text('Create First Post')),
                      ],
                    ),
                  )
                  else GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2, childAspectRatio: 1,
                    ),
                    itemCount: _myPosts.length,
                    itemBuilder: (context, index) {
                      final post = _myPosts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(
                                post: post,
                                isLocalPost: true,
                                onPostUpdated: _loadMyPosts,
                                onPostDeleted: _loadMyPosts,
                              ),
                            ),
                          ).then((value) {
                            if (value == true) {
                              _loadMyPosts();
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[100]!, width: 0.5)),
                          child: post['hasImage'] && post['imageData'] != null
                              ? Image.memory(
                                  base64Decode(post['imageData']),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[100],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.text_fields, color: Colors.grey[400], size: 30),
                                        SizedBox(height: 5),
                                        Text('Text Post', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                      ],
                                    ),
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
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }
}
