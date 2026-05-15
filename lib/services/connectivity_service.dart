import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Service that monitors network connectivity status.
/// Provides reactive connectivity state for offline-first architecture.
class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();

  /// Observable connectivity status
  final RxBool isConnected = false.obs;

  /// Stream subscription for connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  /// Initialize connectivity check
  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      isConnected.value = false;
    }
  }

  /// Update connectivity status based on results
  void _updateStatus(List<ConnectivityResult> results) {
    isConnected.value = results.any(
      (r) => r != ConnectivityResult.none,
    );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
