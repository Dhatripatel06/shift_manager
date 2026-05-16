import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/providers/hive_provider.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'bindings/initial_binding.dart';
import 'controllers/theme_controller.dart';

/// Entry point for Shiftly application.
/// Initializes Firebase, Hive, and sets up GetX navigation.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style - clean light style for Shiftly
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
    // App should still work offline without Firebase
  }

  // Initialize Hive local database
  final hiveProvider = HiveProvider();
  await hiveProvider.init();
  Get.put(hiveProvider, permanent: true);

  // Initialize Theme Controller
  final themeController = ThemeController();
  Get.put(themeController, permanent: true);

  runApp(const ShiftlyApp());
}

/// Root application widget
class ShiftlyApp extends StatelessWidget {
  const ShiftlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme - light mode is primary for Shiftly's clean design
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Navigation
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,

      // Dependency injection
      initialBinding: InitialBinding(),

      // Default transitions
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),

      // Locale
      locale: const Locale('en', 'GB'),
      fallbackLocale: const Locale('en', 'US'),

      // Builder for global settings
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}
