enum AppEnvironmentName { development, staging, production }

class AppEnvironment {
  AppEnvironment._();

  static const AppEnvironmentName current = AppEnvironmentName.production;

  static const Duration networkTimeout = Duration(seconds: 15);

  static bool get isProduction => current == AppEnvironmentName.production;
}
