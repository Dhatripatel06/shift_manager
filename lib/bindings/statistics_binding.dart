import 'package:get/get.dart';
import '../controllers/statistics_controller.dart';

/// Binding for Statistics screen
class StatisticsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StatisticsController>()) {
      Get.lazyPut(() => StatisticsController(), fenix: true);
    }
  }
}
