import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCFifuQZFNuR9Hjh2khXfXC3LCz2y4wy5o',
    appId: '1:191430390917:web:ed6c75d8424efacebce5ec',
    messagingSenderId: '191430390917',
    projectId: 'lumo-chat-46987',
    authDomain: 'lumo-chat-46987.firebaseapp.com',
    storageBucket: 'lumo-chat-46987.firebasestorage.app',
    measurementId: 'G-93KK2L7Y3B',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLVPlwAZRaBga8ELTvaboNttugIEguUO8',
    appId: '1:191430390917:android:5a1ad2f19e6bff9abce5ec',
    messagingSenderId: '191430390917',
    projectId: 'lumo-chat-46987',
    storageBucket: 'lumo-chat-46987.firebasestorage.app',
  );
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCFifuQZFNuR9Hjh2khXfXC3LCz2y4wy5o',
    appId: '1:191430390917:web:034b91ecb84287efbce5ec',
    messagingSenderId: '191430390917',
    projectId: 'lumo-chat-46987',
    authDomain: 'lumo-chat-46987.firebaseapp.com',
    storageBucket: 'lumo-chat-46987.firebasestorage.app',
    measurementId: 'G-T6QPP217CL',
  );
}
