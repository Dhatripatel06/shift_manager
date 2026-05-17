import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/shift_controller.dart';

/// Binding for the Home/Dashboard screen
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DashboardController>()) {
      Get.lazyPut(() => DashboardController(), fenix: true);
    }
    if (!Get.isRegistered<ShiftController>()) {
      Get.lazyPut(() => ShiftController(), fenix: true);
    }
  }
}
