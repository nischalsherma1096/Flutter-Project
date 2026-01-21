import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../screens/main_navigation_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Gmail validation regex
  bool _isValidGmail(String email) {
    final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    return gmailRegex.hasMatch(email);
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final success = await _authService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
      fullName: _fullNameController.text.trim(),
    );

    if (success) {
      // Navigate to main screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainNavigationScreen()),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create Account'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              // Welcome Text
              Text(
                'Join Postly Today',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create an account to connect with friends and share your moments.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    
                    TextFormField(
                      controller: _fullNameController,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Full Name (Optional)',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Username
                    TextFormField(
                      controller: _usernameController,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Username *',
                        prefixIcon: Icon(Icons.alternate_email),
                        hintText: 'e.g., johndoe, john_doe, john.doe',
                        helperText: '2-24 chars, lowercase letters, numbers, ., _',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please choose a username';
                        }
                        
                        final trimmedValue = value.trim();
                        
                        // Username rules: lowercase only, no spaces
                        if (trimmedValue.length < 2) {
                          return 'Username must be at least 2 characters';
                        }
                        if (trimmedValue.length > 24) {
                          return 'Username cannot exceed 24 characters';
                        }
                        
                        // Check for uppercase letters
                        if (trimmedValue.contains(RegExp(r'[A-Z]'))) {
                          return 'Username must be in lowercase only';
                        }
                        
                        // Username regex: lowercase letters, numbers, underscores, dots
                        final usernameRegex = RegExp(r'^[a-z0-9._]+$');
                        if (!usernameRegex.hasMatch(trimmedValue)) {
                          return 'Username can only contain lowercase letters, numbers, dots and underscores';
                        }
                        
                        // Cannot start or end with dot or underscore
                        if (trimmedValue.startsWith('.') || trimmedValue.startsWith('_')) {
                          return 'Username cannot start with . or _';
                        }
                        if (trimmedValue.endsWith('.') || trimmedValue.endsWith('_')) {
                          return 'Username cannot end with . or _';
                        }
                        
                        // No consecutive dots or underscores
                        if (trimmedValue.contains('..') || trimmedValue.contains('__') || 
                            trimmedValue.contains('._') || trimmedValue.contains('_.')) {
                          return 'Username cannot have consecutive . or _';
                        }
                        
                        if (_authService.checkUsernameExists(trimmedValue)) {
                          return 'Username already taken';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    // Gmail Field
                    TextFormField(
                      controller: _emailController,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Gmail Address *',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'example@gmail.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your Gmail';
                        }
                        
                        // Check for Gmail format
                        if (!_isValidGmail(value.trim())) {
                          return 'Please enter a valid Gmail (example@gmail.com)';
                        }
                        
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signup,
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Sign Up',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Already have an account
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? '),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Log In',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              // Terms and Conditions
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'By signing up, you agree to our:',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text('Terms of Service'),
                      ),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text('Privacy Policy'),
                      ),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text('Cookie Policy'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}