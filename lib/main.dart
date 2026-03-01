import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';

bool firebaseInitialized = false;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize notifications (non-blocking if it fails)
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint('🔔 Notification init failed: $e');
    }

    // Try to initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseInitialized = true;
      debugPrint('✅ Firebase initialized successfully');
      // Reset studentsPresent to 0 (real count comes from ESP32 RFID)
      FirebaseDatabase.instance.ref('classroom/sensors/studentsPresent').set(0);
    } catch (e) {
      debugPrint('⚠️ Firebase init error: $e');
      firebaseInitialized = false;
    }

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    runApp(const ProviderScope(child: WIWCApp()));
  } catch (e, stack) {
    debugPrint('FATAL STARTUP ERROR: $e');
    debugPrint(stack.toString());
    // Still try to run the app to show an error screen if possible
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Fatal Error: $e')))));
  }
}
