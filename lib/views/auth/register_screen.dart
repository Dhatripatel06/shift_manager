import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';

/// Registration screen for new user accounts.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimaryLight),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            const SizedBox(height: 16),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.person_add_rounded, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text('Create Account', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight)),
            const SizedBox(height: 8),
            Text('Join ${AppConstants.appName}', style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 32),
            _label('Full Name'),
            const SizedBox(height: 8),
            TextField(controller: c.nameController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'Enter your name', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 16),
            _label('Email'),
            const SizedBox(height: 8),
            TextField(controller: c.emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Enter your email', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 16),
            _label('Password'),
            const SizedBox(height: 8),
            Obx(() => TextField(controller: c.passwordController, obscureText: !c.isPasswordVisible.value, decoration: InputDecoration(hintText: 'At least 6 characters', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(c.isPasswordVisible.value ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: c.togglePasswordVisibility)))),
            const SizedBox(height: 16),
            _label('Confirm Password'),
            const SizedBox(height: 8),
            Obx(() => TextField(controller: c.confirmPasswordController, obscureText: !c.isConfirmPasswordVisible.value, decoration: InputDecoration(hintText: 'Re-enter password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(c.isConfirmPasswordVisible.value ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: c.toggleConfirmPasswordVisibility)))),
            const SizedBox(height: 28),
            Obx(() => SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: c.isLoading.value ? null : c.registerWithEmail,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: c.isLoading.value ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text('Create Account', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Already have an account? ', style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondaryLight)),
              GestureDetector(onTap: () => Get.back(), child: Text('Sign In', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
            ]),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  static Widget _label(String t) => Align(alignment: Alignment.centerLeft, child: Text(t, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)));
}
