import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

/// Controller for authentication flow.
/// Manages Google Sign In, Email/Password auth, and navigation.
class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  /// Loading state
  final RxBool isLoading = false.obs;

  /// Error message
  final RxString errorMessage = ''.obs;

  /// Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  /// Password visibility
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  /// Check if user is logged in
  bool get isLoggedIn => _authService.isLoggedIn;

  /// Get display name
  String get displayName => _authService.displayName;

  /// Get photo URL
  String? get photoUrl => _authService.photoUrl;

  /// Get email
  String? get email => _authService.email;

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await _authService.signInWithGoogle();

      if (user != null) {
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      errorMessage.value = 'Sign in failed. Please try again.';
      Get.snackbar(
        'Sign In Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await _authService.signInWithEmail(email, password);

      if (user != null) {
        _clearFields();
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _showError(message);
    } finally {
      isLoading.value = false;
    }
  }

  /// Register with email and password
  Future<void> registerWithEmail() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user =
          await _authService.registerWithEmail(name, email, password);

      if (user != null) {
        _clearFields();
        Get.offAllNamed(AppRoutes.home);
        Get.snackbar(
          'Welcome to Shiftly! 🎉',
          'Your account has been created successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _showError(message);
    } finally {
      isLoading.value = false;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }

    try {
      isLoading.value = true;
      await _authService.sendPasswordReset(email);
      Get.snackbar(
        'Email Sent ✉️',
        'Check your inbox for password reset instructions.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
      Get.back(); // Return to login
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _showError(message);
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _clearFields();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign out',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Show error snackbar
  void _showError(String message) {
    errorMessage.value = message;
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.8),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  /// Clear form fields
  void _clearFields() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    errorMessage.value = '';
    isPasswordVisible.value = false;
    isConfirmPasswordVisible.value = false;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
