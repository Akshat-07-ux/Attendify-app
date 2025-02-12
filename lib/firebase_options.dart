// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCgdU61CeJ1jUluVXogvv2RM0bTeNYX0Uc',
    appId: '1:334583314906:web:3f57272612696214a6a8e3',
    messagingSenderId: '334583314906',
    projectId: 'attendance-f365b',
    authDomain: 'attendance-f365b.firebaseapp.com',
    storageBucket: 'attendance-f365b.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCalS9F7ZU6GHpDytqA0k_K_zGjt5k8X3I',
    appId: '1:334583314906:android:84d3fb7d92abff24a6a8e3',
    messagingSenderId: '334583314906',
    projectId: 'attendance-f365b',
    storageBucket: 'attendance-f365b.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBITaiKDJDmwzhZg-bo8KnPFuNPTCZRnms',
    appId: '1:334583314906:ios:88d24d66e195ce32a6a8e3',
    messagingSenderId: '334583314906',
    projectId: 'attendance-f365b',
    storageBucket: 'attendance-f365b.appspot.com',
    iosBundleId: 'com.example.attendance',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCgdU61CeJ1jUluVXogvv2RM0bTeNYX0Uc',
    appId: '1:334583314906:web:899ca8de76d1d5daa6a8e3',
    messagingSenderId: '334583314906',
    projectId: 'attendance-f365b',
    authDomain: 'attendance-f365b.firebaseapp.com',
    storageBucket: 'attendance-f365b.appspot.com',
  );
}

