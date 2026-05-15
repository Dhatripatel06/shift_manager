import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service handling Firebase Authentication with Google Sign In.
/// Manages user authentication state and provides sign in/out functionality.
///
/// Uses google_sign_in v7.x API with singleton instance pattern.
class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Observable current user
  final Rx<User?> currentUser = Rx<User?>(null);

  /// Check if user is logged in
  bool get isLoggedIn => currentUser.value != null;

  /// Get user ID
  String? get userId => currentUser.value?.uid;

  /// Get user display name
  String? get displayName => currentUser.value?.displayName;

  /// Get user email
  String? get email => currentUser.value?.email;

  /// Get user photo URL
  String? get photoUrl => currentUser.value?.photoURL;

  @override
  void onInit() {
    super.onInit();
    // Bind to auth state changes
    currentUser.bindStream(_auth.authStateChanges());
    // Initialize Google Sign In
    _initGoogleSignIn();
  }

  /// Initialize Google Sign In
  Future<void> _initGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();
    } catch (e) {
      // May fail if Firebase/Google services not configured yet
      debugPrint('Google Sign In initialization: $e');
    }
  }

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtain auth details (only idToken available in v7.x)
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // Create a Firebase credential with idToken only
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on GoogleSignInException {
      // User cancelled or other Google Sign In error
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception('Firebase Auth Error: ${e.message}');
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign out from both Google and Firebase
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Check if user is already signed in (for auto-login)
  Future<bool> isAlreadySignedIn() async {
    return _auth.currentUser != null;
  }
}

// Avoid importing foundation in non-Flutter contexts
void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
