import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/shift_controller.dart';

/// Binding for the Home/Dashboard screen
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DashboardController());
    Get.lazyPut(() => ShiftController());
  }
}
