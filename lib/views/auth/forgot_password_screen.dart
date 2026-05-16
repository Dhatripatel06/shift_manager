import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/auth_controller.dart';

/// Forgot password screen - sends password reset email.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimaryLight), onPressed: () => Get.back()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            Center(child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.lock_reset_rounded, size: 32, color: AppColors.primary),
            )),
            const SizedBox(height: 24),
            Center(child: Text('Reset Password', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight))),
            const SizedBox(height: 8),
            Center(child: Text('We\'ll send you a reset link', style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textSecondaryLight), textAlign: TextAlign.center)),
            const SizedBox(height: 32),
            Text('Email', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 8),
            TextField(controller: c.emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Enter your email', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 28),
            Obx(() => SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: c.isLoading.value ? null : c.sendPasswordReset,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: c.isLoading.value ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text('Send Reset Link', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )),
            const SizedBox(height: 20),
            Center(child: GestureDetector(onTap: () => Get.back(), child: Text('Back to Sign In', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)))),
          ]),
        ),
      ),
    );
  }
}
