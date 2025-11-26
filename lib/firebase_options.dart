import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "YOUR-KEY",
      authDomain: "YOUR-PROJECT.firebaseapp.com",
      projectId: "YOUR-PROJECT",
      storageBucket: "YOUR-PROJECT.appspot.com",
      messagingSenderId: "123",
      appId: "1:123:web:abc",
    );
  }
}