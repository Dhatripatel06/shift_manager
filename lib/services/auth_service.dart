import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

/// Service handling Firebase Authentication with Google Sign In and Email/Password.
/// Manages user authentication state, profile syncing, and provides sign in/out.
class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Observable current user
  final Rx<User?> currentUser = Rx<User?>(null);

  /// Observable user profile
  final Rx<UserModel?> userProfile = Rx<UserModel?>(null);

  /// Check if user is logged in
  bool get isLoggedIn => currentUser.value != null;

  /// Get user ID
  String? get userId => currentUser.value?.uid;

  /// Get user display name
  String get displayName =>
      userProfile.value?.name ??
      currentUser.value?.displayName ??
      'User';

  /// Get user email
  String? get email => currentUser.value?.email;

  /// Get user photo URL
  String? get photoUrl =>
      userProfile.value?.photoUrl ?? currentUser.value?.photoURL;

  @override
  void onInit() {
    super.onInit();
    // Bind to auth state changes
    currentUser.bindStream(_auth.authStateChanges());
    // When auth state changes, sync profile
    ever(currentUser, (User? user) {
      if (user != null) {
        _syncUserProfile(user);
      } else {
        userProfile.value = null;
      }
    });
  }

  /// Sync user profile to Firebase RTDB
  Future<void> _syncUserProfile(User user) async {
    try {
      final ref = _database.ref(
          '${AppConstants.usersPath}/${user.uid}/${AppConstants.profilePath}');
      final snapshot = await ref.get();

      final now = DateTime.now();
      if (snapshot.exists) {
        // Update last login
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final profile = UserModel.fromMap(data).copyWith(lastLogin: now);
        await ref.update({'lastLogin': now.toIso8601String()});
        userProfile.value = profile;
      } else {
        // Create new profile
        final profile = UserModel(
          uid: user.uid,
          name: user.displayName ?? user.email?.split('@').first ?? 'User',
          email: user.email ?? '',
          photoUrl: user.photoURL,
          createdAt: now,
          lastLogin: now,
        );
        await ref.set(profile.toMap());
        userProfile.value = profile;
      }
    } catch (e) {
      // Offline - create local profile from auth data
      userProfile.value = UserModel(
        uid: user.uid,
        name: user.displayName ?? user.email?.split('@').first ?? 'User',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
      debugPrint('Profile sync failed (offline): $e');
    }
  }

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Initialize if needed
      try {
        await googleSignIn.initialize();
      } catch (_) {
        // May already be initialized
      }

      // Trigger the Google Sign In flow
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // Create a Firebase credential
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
      throw Exception('Google sign in failed: $e');
    }
  }

  /// Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'wrong-password':
          throw Exception('Incorrect password. Please try again.');
        case 'invalid-email':
          throw Exception('Please enter a valid email address.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'too-many-requests':
          throw Exception('Too many attempts. Please try again later.');
        default:
          throw Exception(e.message ?? 'Sign in failed.');
      }
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Register with email and password
  Future<User?> registerWithEmail(
      String name, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name.trim());
      await userCredential.user?.reload();

      // Re-fetch user to get updated profile
      currentUser.value = _auth.currentUser;

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('An account already exists with this email.');
        case 'weak-password':
          throw Exception('Password is too weak. Use at least 6 characters.');
        case 'invalid-email':
          throw Exception('Please enter a valid email address.');
        default:
          throw Exception(e.message ?? 'Registration failed.');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'invalid-email':
          throw Exception('Please enter a valid email address.');
        default:
          throw Exception(e.message ?? 'Password reset failed.');
      }
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Google sign-in may not have been used
      }
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Check if user is already signed in (for auto-login)
  Future<bool> isAlreadySignedIn() async {
    return _auth.currentUser != null;
  }
}
