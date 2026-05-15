import 'package:get/get.dart';
import '../controllers/shift_controller.dart';

/// Binding for Shift screens (Add, Edit, List)
class ShiftBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ShiftController());
  }
}
