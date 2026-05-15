import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

/// Middleware to protect routes requiring authentication
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 9;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn) {
      print(
        '[AuthMiddleware] Redirecting unauthenticated user from $route to login',
      );
      return const RouteSettings(name: '/login');
    }
    return null;
  }
}
