import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAtP37cujyIjvDYWXCClnjFMK9LmlbmqdU',
    appId: '1:637423664987:android:c7e9053b3dff21c8c5647e',
    messagingSenderId: '637423664987',
    projectId: 'cfts-da53b',
    storageBucket: 'cfts-da53b.firebasestorage.app',
  );

  // NOTE: Web and other-platform options are placeholders. To run on web/iOS,
  // register the app in the Firebase console and fill in the real values, or
  // add the platform config files (GoogleService-Info.plist / firebase.json).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAtP37cujyIjvDYWXCClnjFMK9LmlbmqdU',
    appId: '1:637423664987:ios:PLACEHOLDER',
    messagingSenderId: '637423664987',
    projectId: 'cfts-da53b',
    storageBucket: 'cfts-da53b.firebasestorage.app',
    iosBundleId: 'com.KQG.courtCaseTracker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'PLACEHOLDER',
    appId: 'PLACEHOLDER',
    messagingSenderId: '637423664987',
    projectId: 'cfts-da53b',
    storageBucket: 'cfts-da53b.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'PLACEHOLDER',
    appId: 'PLACEHOLDER',
    messagingSenderId: '637423664987',
    projectId: 'cfts-da53b',
    storageBucket: 'cfts-da53b.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'PLACEHOLDER',
    appId: 'PLACEHOLDER',
    messagingSenderId: '637423664987',
    projectId: 'cfts-da53b',
    storageBucket: 'cfts-da53b.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PLACEHOLDER',
    appId: 'PLACEHOLDER',
    messagingSenderId: '637423664987',
    projectId: 'cfts-da53b',
    storageBucket: 'cfts-da53b.firebasestorage.app',
  );
}
