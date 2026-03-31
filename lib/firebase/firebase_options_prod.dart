import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptionsProd {
  static FirebaseOptions get web => const FirebaseOptions(
    apiKey: "API_KEY_ACTUAL",
    authDomain: "AUTH_DOMAIN_ACTUAL",
    projectId: "PROJECT_ID_ACTUAL",
    storageBucket: "STORAGE_BUCKET_ACTUAL",
    messagingSenderId: "MESSAGING_SENDER_ID_ACTUAL",
    appId: "APP_ID_ACTUAL",
  );
}
