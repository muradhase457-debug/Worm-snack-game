// TEMPLATE ONLY - the GitHub Actions workflow overwrites this file from
// google-services.json during the build. Do NOT put real keys here.
// If the {{ }} placeholders are still present at runtime, the app shows a
// friendly "Setup Needed" screen instead of crashing.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '{{API_KEY}}',
    appId: '{{APP_ID}}',
    messagingSenderId: '{{SENDER_ID}}',
    projectId: '{{PROJECT_ID}}',
    storageBucket: '{{STORAGE_BUCKET}}',
  );

  static bool get needsSetup => android.projectId.contains('{{');
}
