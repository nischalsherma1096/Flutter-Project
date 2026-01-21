// main_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:postly/main.dart';

void main() {
  // Setup before all tests
  setUpAll(() async {
    await GetStorage.init();
  });

  // Cleanup after each test
  tearDown(() async {
    await GetStorage.init(); // Reinitialize to clear any state
  });

  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(MyApp());

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Verify that POSTLY text appears somewhere (in AppBar)
    expect(find.text('POSTLY'), findsOneWidget);
    
    // Let any pending timers complete
    await tester.pumpAndSettle();
  });

  testWidgets('App structure is correct', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    
    // Check for MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Check that app has a scaffold
    expect(find.byType(Scaffold), findsOneWidget);
    
    // Check for AppBar
    expect(find.byType(AppBar), findsOneWidget);
    
    // Let any pending timers complete
    await tester.pumpAndSettle();
  });

  // Additional tests for the new functionality
  testWidgets('App has main feed with posts', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    
    // Check if posts are loading (CircularProgressIndicator should appear briefly)
    await tester.pump(Duration(milliseconds: 500));
    
    // Posts should load after initial delay
    await tester.pumpAndSettle(Duration(seconds: 2));
    
    // Should find post content or indicators
    expect(find.text('Just launched my new Flutter app!'), findsOneWidget);
  });

  // Test to verify GetStorage is working
  testWidgets('Storage can store and retrieve data', (WidgetTester tester) async {
    final storage = GetStorage();
    
    // Write test data
    storage.write('test_key', 'test_value');
    
    // Read test data
    final value = storage.read('test_key');
    expect(value, equals('test_value'));
    
    // Clean up
    storage.remove('test_key');
  });
}