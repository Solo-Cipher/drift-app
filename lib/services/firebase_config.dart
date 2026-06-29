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
  static const String apiKey = 'AIzaSyAiKaxa6UVKqoQCirMU5beBFBSfautuyTI';
  static const String authDomain = 'drift-expenses.firebaseapp.com';
  static const String projectId = 'drift-expenses';
  static const String storageBucket = 'drift-expenses.firebasestorage.app';
  static const String messagingSenderId = '373750180502';
  static const String appId = '1:373750180502:web:5b56b9f478fdf3acfcb0b7';

  static bool get isConfigured => true;
}
