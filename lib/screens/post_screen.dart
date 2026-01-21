import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _postController = TextEditingController();
  final GetStorage _storage = GetStorage();
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _profilePicture;

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

  Widget _buildProfileIcon() {
    final userName = _storage.read('user_name') ?? 'You';
    final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.red];
    final colorIndex = userName.hashCode % colors.length;
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        image: _profilePicture != null
            ? DecorationImage(
                image: MemoryImage(_profilePicture!),
                fit: BoxFit.cover,
              )
            : null,
        color: _profilePicture == null ? colors[colorIndex] : null,
      ),
      child: _profilePicture == null
          ? Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            )
          : null,
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        
        Uint8List compressedBytes = bytes;
        if (bytes.lengthInBytes > 2 * 1024 * 1024) {
          compressedBytes = await _compressImage(bytes);
        }
        
        setState(() {
          _selectedImageBytes = compressedBytes;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected (${(compressedBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image. Please try another image.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 800,
        minWidth: 800,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      print('Image compressed from ${bytes.lengthInBytes ~/ 1024}KB to ${result.lengthInBytes ~/ 1024}KB');
      return result;
    } catch (e) {
      print('Compression error: $e');
      return bytes;
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please write something or add an image!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final userName = _storage.read('user_name') ?? 'You';
      final userBio = _storage.read('user_bio') ?? 'Flutter Developer & Social Media Enthusiast';
      final profilePicture = _storage.read('my_profile_picture');
      
      final newPost = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': _postController.text.trim(),
        'hasImage': _selectedImageBytes != null,
        'imageData': _selectedImageBytes != null ? base64Encode(_selectedImageBytes!) : null,
        'likes': 0,
        'isLiked': false,
        'comments': [],
        'timestamp': DateTime.now().toIso8601String(),
        'user': {
          'id': 'current_user',
          'name': userName,
          'bio': userBio,
          'localProfilePicture': profilePicture,
          'avatar': 'https://i.pravatar.cc/150?img=5',
        },
        'hashtags': _extractHashtags(_postController.text),
      };

      final List existingPosts = _storage.read('my_posts') ?? [];
      existingPosts.insert(0, newPost);
      await _storage.write('my_posts', existingPosts);

      _postController.clear();
      setState(() {
        _selectedImageBytes = null;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {
      print('Error creating post: $e');
      setState(() {
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create post. Image might be too large.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<String> _extractHashtags(String text) {
    final hashtagRegex = RegExp(r'\B#\w\w+');
    return hashtagRegex
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  Widget _buildImagePreview() {
    if (_selectedImageBytes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 50,
              color: Colors.grey[400],
            ),
            SizedBox(height: 10),
            Text(
              'No image selected',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 5),
            Text(
              'Supported: JPG, PNG, GIF, WebP',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _selectedImageBytes!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 40),
                        SizedBox(height: 10),
                        Text('Unsupported image format'),
                        SizedBox(height: 5),
                        Text('Please try JPG or PNG', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.7),
            ),
            child: IconButton(
              icon: Icon(Icons.close, size: 20, color: Colors.white),
              onPressed: _removeImage,
              padding: EdgeInsets.all(4),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 16),
          child: _buildProfileIcon(),
        ),
        title: Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.close),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.grey[300],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _postController,
                      maxLines: 8,
                      maxLength: 280,
                      decoration: InputDecoration(
                        hintText: "Type Your Text Here...",
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedImageBytes != null 
                          ? Colors.blue 
                          : Colors.grey[300]!,
                        width: _selectedImageBytes != null ? 2 : 1,
                      ),
                    ),
                    child: _buildImagePreview(),
                  ),
                  
                  SizedBox(height: 10),
                  Text(
                    'Max image size: 5MB • Supported: JPG, PNG, WebP, GIF',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  
                  if (_selectedImageBytes != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Image size: ${(_selectedImageBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(color: Colors.green[700], fontSize: 12),
                      ),
                    ),
                  
                  if (_isUploading)
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text(
                            'Creating post...',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  Spacer(),
                  
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _pickImage,
                            icon: Icon(
                              _selectedImageBytes != null 
                                ? Icons.photo_camera 
                                : Icons.photo_library_outlined,
                            ),
                            label: Text(
                              _selectedImageBytes != null 
                                ? 'Change Photo' 
                                : 'Upload Photo',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedImageBytes != null 
                                ? Colors.green[100] 
                                : Colors.grey[100],
                              foregroundColor: _selectedImageBytes != null 
                                ? Colors.green[800] 
                                : Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              disabledBackgroundColor: Colors.grey[200],
                              disabledForegroundColor: Colors.grey[400],
                            ),
                          ),
                        ),
                        
                        SizedBox(width: 16),
                        
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isUploading ? null : _createPost,
                            child: _isUploading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'POST',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isUploading 
                                ? Colors.blue[300] 
                                : Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              disabledBackgroundColor: Colors.blue[200],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  Text(
                    'Note: Posts are saved locally on your device',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}