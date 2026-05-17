import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/services/app_error_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/providers/hive_provider.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'bindings/initial_binding.dart';
import 'controllers/theme_controller.dart';

/// Entry point for Shiftly application.
/// Initializes Firebase, Hive, and sets up GetX navigation.
void main() async {
  AppErrorHandler.register();
  AppErrorHandler.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set preferred orientations.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Initialize Firebase.
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase init error: $e');
      // App should still work offline without Firebase.
    }

    // Initialize Hive local database before controllers read preferences.
    final hiveProvider = HiveProvider();
    await hiveProvider.init();
    Get.put(hiveProvider, permanent: true);

    final themeController = ThemeController();
    Get.put(themeController, permanent: true);

    runApp(const ShiftlyApp());
  });
}

/// Root application widget
class ShiftlyApp extends StatelessWidget {
  const ShiftlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,

        // Theme - reactive dark/light mode support
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeCtrl.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,

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
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: mediaQuery.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.25,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
