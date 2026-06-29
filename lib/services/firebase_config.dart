/// Firebase configuration for DRIFT expense sharing.
///
/// To set up:
/// 1. Go to https://console.firebase.google.com
/// 2. Create project "drift-expenses"
/// 3. Enable Authentication → Anonymous sign-in
/// 4. Create Firestore Database (start in test mode)
/// 5. Add Web app (⚙️ → Project settings → Your apps → Add app)
/// 6. Copy the firebaseConfig values below
///
/// Security: These are public client-side credentials.
/// Actual security comes from Firestore Security Rules.

class FirebaseConfig {
  // 🔑 PASTE YOUR VALUES HERE
  static const String apiKey = 'YOUR_API_KEY';
  static const String authDomain = 'YOUR_PROJECT.firebaseapp.com';
  static const String projectId = 'YOUR_PROJECT_ID';
  static const String storageBucket = 'YOUR_PROJECT.appspot.com';
  static const String messagingSenderId = 'YOUR_SENDER_ID';
  static const String appId = 'YOUR_APP_ID';

  // Set this to true once you've pasted real values
  static bool get isConfigured =>
      apiKey != 'YOUR_API_KEY' && projectId != 'YOUR_PROJECT_ID';
}
