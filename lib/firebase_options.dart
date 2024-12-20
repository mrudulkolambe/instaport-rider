// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyDRgkAAZ2SIvYC-EPHw7DDDEFUsJDbScKA',
    appId: '1:209395485323:web:56f1a35285e09bdbf1a28e',
    messagingSenderId: '209395485323',
    projectId: 'instaport-main',
    authDomain: 'instaport-main.firebaseapp.com',
    databaseURL: 'https://instaport-main-default-rtdb.firebaseio.com',
    storageBucket: 'instaport-main.firebasestorage.app',
    measurementId: 'G-JYW2EG9MPB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcyS-03eWA8hCJ6ZMBm-Q_jbW7ymVKrR0',
    appId: '1:209395485323:android:89e8a330b7d3ede4f1a28e',
    messagingSenderId: '209395485323',
    projectId: 'instaport-main',
    databaseURL: 'https://instaport-main-default-rtdb.firebaseio.com',
    storageBucket: 'instaport-main.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB-NjrNn9b_MRQYXVq6eKHqgoS6wK2JIW0',
    appId: '1:209395485323:ios:1b67a255b0fffb85f1a28e',
    messagingSenderId: '209395485323',
    projectId: 'instaport-main',
    databaseURL: 'https://instaport-main-default-rtdb.firebaseio.com',
    storageBucket: 'instaport-main.firebasestorage.app',
    iosBundleId: 'com.instaport.rider',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB-NjrNn9b_MRQYXVq6eKHqgoS6wK2JIW0',
    appId: '1:209395485323:ios:a2e547c2db64dcb9f1a28e',
    messagingSenderId: '209395485323',
    projectId: 'instaport-main',
    storageBucket: 'instaport-main.appspot.com',
    iosBundleId: 'com.instaport.rider',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDRgkAAZ2SIvYC-EPHw7DDDEFUsJDbScKA',
    appId: '1:209395485323:web:aebe56da0da5a5cef1a28e',
    messagingSenderId: '209395485323',
    projectId: 'instaport-main',
    authDomain: 'instaport-main.firebaseapp.com',
    storageBucket: 'instaport-main.appspot.com',
  );

}