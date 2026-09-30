// Hand-written in place of a `flutterfire configure`-generated file (no
// Node/Firebase CLI available in this dev environment — see the Windows
// block's comment for why it reuses the console's Web app config).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return windows;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform — '
          'only Android and Windows are set up for Kanji Athletes.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAC_JQS05SVfXn02LKk8Pz0i0q5v7RdenE',
    appId: '1:275785368511:android:dce497e2bc8af5b15f970a',
    messagingSenderId: '275785368511',
    projectId: 'kanji-athletes',
    storageBucket: 'kanji-athletes.firebasestorage.app',
  );

  // FlutterFire's Windows (and Linux) desktop support runs on the same
  // REST-based SDK as Web, so it reuses the console's Web app config
  // rather than needing its own native app registration — see
  // https://invertase.io/blog/announcing-flutterfire-desktop-auth-stable.
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBPsqLHIl7R87qFtaBcplvgwFHCOp-zWFc',
    appId: '1:275785368511:web:4c3cf1b06bbfe2425f970a',
    messagingSenderId: '275785368511',
    projectId: 'kanji-athletes',
    authDomain: 'kanji-athletes.firebaseapp.com',
    storageBucket: 'kanji-athletes.firebasestorage.app',
  );
}
