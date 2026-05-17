import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/firestore_service.dart';
import '../services/sync_service.dart';
import '../services/export_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';

/// Initial binding that registers core services on app startup
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services (permanent - survive navigation)
    Get.put(AuthService(), permanent: true);
    Get.put(ConnectivityService(), permanent: true);
    Get.put(FirestoreService(), permanent: true);
    Get.put(SyncService(), permanent: true);
    Get.put(ExportService(), permanent: true);

    // Core controllers
    Get.put(AuthController(), permanent: true);
    Get.put(ThemeController(), permanent: true);
  }
}
