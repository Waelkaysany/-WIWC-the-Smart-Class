// File generated based on Firebase project configuration
// Project: wiwc-smartclass

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web platform is not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS platform is not configured.');
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS platform is not configured.');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows platform is not configured.');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux platform is not configured.');
      default:
        throw UnsupportedError('Unknown platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBg251F3-QeIfsvxd2GM0Wg_xarexEdYIA',
    appId: '1:1090749757095:android:f4255c4399c00e0fdacd82',
    messagingSenderId: '1090749757095',
    projectId: 'wiwc-smartclass',
    storageBucket: 'wiwc-smartclass.firebasestorage.app',
    databaseURL: 'https://wiwc-smartclass-default-rtdb.firebaseio.com',
  );
}
