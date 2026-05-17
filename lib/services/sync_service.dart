import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/shift_model.dart';
import '../core/services/app_logger.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import 'firestore_service.dart';
import '../data/providers/hive_provider.dart';

/// Sync status enum
enum SyncStatus { synced, syncing, offline, error }

/// Service that handles bidirectional sync between Hive (local) and
/// Cloud Firestore (cloud).
/// Implements offline-first architecture: always save locally first, then sync.
class SyncService extends GetxService {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  /// Observable sync status
  final Rx<SyncStatus> syncStatus = SyncStatus.offline.obs;

  /// Last sync timestamp
  final Rx<DateTime?> lastSyncTime = Rx<DateTime?>(null);

  /// Pending sync count
  final RxInt pendingSyncCount = 0.obs;

  Timer? _syncTimer;

  /// Reference to connectivity service
  ConnectivityService get _connectivity => Get.find<ConnectivityService>();

  /// Reference to auth service
  AuthService get _auth => Get.find<AuthService>();

  /// Reference to Hive provider
  HiveProvider get _hiveProvider => Get.find<HiveProvider>();

  @override
  void onInit() {
    super.onInit();
    // Listen for connectivity changes and auto-sync
    ever(_connectivity.isConnected, (bool connected) {
      if (connected && _auth.isLoggedIn) {
        syncAll();
      } else if (!connected) {
        syncStatus.value = SyncStatus.offline;
      }
    });

    // Periodic sync every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) => syncAll());
  }

  /// Sync all unsynced shifts to Firebase RTDB
  Future<void> syncAll() async {
    if (!_connectivity.isConnected.value || !_auth.isLoggedIn) {
      syncStatus.value = SyncStatus.offline;
      debugPrint(
        '[SyncService] syncAll: Offline or not logged in. '
        'Connected: ${_connectivity.isConnected.value}, '
        'LoggedIn: ${_auth.isLoggedIn}',
      );
      return;
    }

    try {
      syncStatus.value = SyncStatus.syncing;
      AppLogger.debug('[SyncService] Starting sync...');

      // 1. Push local changes
      await _pushLocalChanges();

      // 2. Pull remote changes
      await _pullRemoteChanges();

      syncStatus.value = SyncStatus.synced;
      lastSyncTime.value = DateTime.now();
      _refreshPendingCount();
      AppLogger.debug('[SyncService] Sync completed successfully');
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      _refreshPendingCount();
      AppLogger.debug('[SyncService] ERROR during syncAll: $e');
    }
  }

  /// Push all unsynced local shifts to Cloud Firestore
  Future<void> _pushLocalChanges() async {
    final unsyncedShifts = _hiveProvider.getUnsyncedShifts();

    if (unsyncedShifts.isEmpty) {
      debugPrint('[SyncService] No unsynced shifts to push');
      return;
    }

    debugPrint(
      '[SyncService] Pushing ${unsyncedShifts.length} unsynced shifts...',
    );

    try {
      // Batch write all unsynced shifts to Firestore
      await _firestoreService.batchWriteShifts(unsyncedShifts);
      debugPrint('[SyncService] Batch update successful');

      // Mark all as synced locally
      for (final shift in unsyncedShifts) {
        if (shift.isDeleted) {
          await _hiveProvider.permanentlyDeleteShift(shift.id);
        } else {
          await _hiveProvider.markAsSynced(shift.id);
        }
      }
      debugPrint(
        '[SyncService] Marked ${unsyncedShifts.length} shifts as synced',
      );
    } catch (e) {
      debugPrint('[SyncService] ERROR in batch update: $e');
      rethrow;
    }
  }

  /// Pull remote changes from Cloud Firestore (current user only)
  Future<void> _pullRemoteChanges() async {
    try {
      // Get real-time stream and take first snapshot
      final remoteShifts = await _firestoreService.watchAllShifts().first;

      for (final remoteShift in remoteShifts) {
        try {
          final localShift = _hiveProvider.getShift(remoteShift.id);

          if (localShift == null) {
            // New shift from cloud
            await _hiveProvider.saveShift(remoteShift.copyWith(isSynced: true));
          } else if (remoteShift.updatedAt.isAfter(localShift.updatedAt) &&
              localShift.isSynced) {
            // Remote is newer and local hasn't been modified
            await _hiveProvider.saveShift(remoteShift.copyWith(isSynced: true));
          }
          // If local is newer (unsynced), keep local version
        } catch (e) {
          debugPrint('[SyncService] Error parsing remote shift: $e');
        }
      }
    } catch (e) {
      // Silently handle pull errors - local data is still valid
      debugPrint('[SyncService] Pull error (non-fatal): $e');
    }
  }

  /// Sync a single shift immediately with retry logic
  Future<void> syncShift(ShiftModel shift) async {
    if (!_connectivity.isConnected.value) {
      _refreshPendingCount();
      debugPrint('[SyncService] No connectivity for shift ${shift.id}');
      return;
    }

    if (!_auth.isLoggedIn) {
      _refreshPendingCount();
      debugPrint('[SyncService] User not authenticated for shift ${shift.id}');
      return;
    }

    final userId = _auth.userId;
    if (userId == null) {
      _refreshPendingCount();
      debugPrint('[SyncService] User UID is null for shift ${shift.id}');
      return;
    }

    // Retry logic with exponential backoff
    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        if (shift.isDeleted) {
          await _firestoreService.deleteShift(shift.id);
          await _hiveProvider.permanentlyDeleteShift(shift.id);
          debugPrint('[SyncService] Successfully deleted shift ${shift.id}');
        } else {
          await _firestoreService.createShift(shift);
          await _hiveProvider.markAsSynced(shift.id);
          debugPrint(
            '[SyncService] Successfully synced shift ${shift.id} for user $userId',
          );
        }
        _refreshPendingCount();
        return; // Success - exit retry loop
      } catch (e) {
        retries++;
        debugPrint(
          '[SyncService] Sync attempt $retries/$maxRetries failed for '
          'shift ${shift.id}: $e',
        );

        if (retries < maxRetries) {
          // Exponential backoff: 500ms, 1s, 2s
          final delay = Duration(milliseconds: 500 * (1 << (retries - 1)));
          debugPrint('[SyncService] Retrying in ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
        }
      }
    }

    // All retries exhausted
    _refreshPendingCount();
    debugPrint(
      '[SyncService] FAILED to sync shift ${shift.id} after $maxRetries attempts',
    );
  }

  void _refreshPendingCount() {
    try {
      pendingSyncCount.value = _hiveProvider.getUnsyncedShifts().length;
    } catch (_) {
      pendingSyncCount.value = 0;
    }
  }

  /// Full restore from Cloud Firestore (for reinstall scenarios)
  Future<int> fullRestore() async {
    if (!_connectivity.isConnected.value || !_auth.isLoggedIn) {
      throw Exception('Cannot restore: No internet or not logged in');
    }

    try {
      syncStatus.value = SyncStatus.syncing;

      // Get all shifts from Firestore
      final remoteShifts = await _firestoreService.watchAllShifts().first;
      int restoredCount = 0;

      for (final shift in remoteShifts) {
        try {
          if (!shift.isDeleted) {
            await _hiveProvider.saveShift(shift.copyWith(isSynced: true));
            restoredCount++;
          }
        } catch (e) {
          debugPrint('[SyncService] Error restoring shift: $e');
        }
      }

      syncStatus.value = SyncStatus.synced;
      lastSyncTime.value = DateTime.now();
      return restoredCount;
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      throw Exception('Restore failed: $e');
    }
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    super.onClose();
  }
}
