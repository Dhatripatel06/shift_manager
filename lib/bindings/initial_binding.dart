import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/firestore_service.dart';
import '../services/sync_service.dart';
import '../services/export_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../data/repositories/shift_repository.dart';
import '../domain/repositories/shift_repository_contract.dart';

/// Initial binding that registers core services on app startup
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services (permanent - survive navigation)
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService(), permanent: true);
    }
    if (!Get.isRegistered<ConnectivityService>()) {
      Get.put(ConnectivityService(), permanent: true);
    }
    if (!Get.isRegistered<FirestoreService>()) {
      Get.put(FirestoreService(), permanent: true);
    }
    if (!Get.isRegistered<SyncService>()) {
      Get.put(SyncService(), permanent: true);
    }
    if (!Get.isRegistered<ExportService>()) {
      Get.put(ExportService(), permanent: true);
    }

    // Domain contracts
    if (!Get.isRegistered<IShiftRepository>()) {
      Get.put<IShiftRepository>(LocalShiftRepository(), permanent: true);
    }

    // Core controllers
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController(), permanent: true);
    }
  }
}
