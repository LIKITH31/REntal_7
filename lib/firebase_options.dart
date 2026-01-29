// File generated manually for Firebase configuration
// This file contains Firebase configuration for Android
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDwLR8YZ9z659soqNniOpRcUIXlnDolKOs',
    appId: '1:775134713875:web:63190d4f8cb97a66a947e6',
    messagingSenderId: '775134713875',
    projectId: 'rental-b3324',
    authDomain: 'rental-b3324.firebaseapp.com',
    storageBucket: 'rental-b3324.firebasestorage.app',
    measurementId: 'G-NC0VWBDYBH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQtpQFqWLbE4aGRZi1S--NrpLYHBs13wc',
    appId: '1:775134713875:android:5d1801b5b7e9db37a947e6',
    messagingSenderId: '775134713875',
    projectId: 'rental-b3324',
    storageBucket: 'rental-b3324.firebasestorage.app',
  );
}
