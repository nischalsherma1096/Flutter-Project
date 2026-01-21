import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'screens/auth/login_screen.dart'; // Make sure this path is correct
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Postly',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
      ),
      home: LoginWrapper(), // Change this line
      debugShowCheckedModeBanner: false,
    );
  }
}

// Add this LoginWrapper widget
class LoginWrapper extends StatelessWidget {
  final GetStorage _storage = GetStorage();
  
  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    final isAuthenticated = _storage.read('isAuthenticated') ?? false;
    
    // Show login screen if not authenticated, otherwise show main screen
    if (isAuthenticated) {
      return MainNavigationScreen();
    } else {
      return LoginScreen();
    }
  }
}