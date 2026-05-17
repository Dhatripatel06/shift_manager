import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/providers/hive_provider.dart';
import '../core/theme/app_theme.dart';

/// Controller for theme management (dark/light mode)
class ThemeController extends GetxController {
  final HiveProvider _hiveProvider = Get.find<HiveProvider>();

  /// Observable dark mode state - defaults to light theme
  final RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _hiveProvider.isDarkMode;
  }

  /// Toggle theme mode
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _hiveProvider.setDarkMode(isDarkMode.value);
    Get.changeTheme(
      isDarkMode.value ? AppTheme.darkTheme : AppTheme.lightTheme,
    );
  }

  /// Get current theme data
  ThemeData get currentTheme =>
      isDarkMode.value ? AppTheme.darkTheme : AppTheme.lightTheme;
}
