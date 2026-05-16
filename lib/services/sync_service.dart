import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/shift_model.dart';
import '../core/constants/app_constants.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import '../data/providers/hive_provider.dart';

/// Sync status enum
enum SyncStatus { synced, syncing, offline, error }

/// Service that handles bidirectional sync between Hive (local) and
/// Firebase Realtime Database (cloud).
/// Implements offline-first architecture: always save locally first, then sync.
class SyncService extends GetxService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

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

  /// Get Firebase RTDB reference for user's shifts
  DatabaseReference _shiftsRef() {
    final uid = _auth.userId;
    if (uid == null) throw Exception('User not authenticated');
    return _database.ref(
        '${AppConstants.usersPath}/$uid/${AppConstants.shiftsPath}');
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
      debugPrint('[SyncService] Starting sync...');

      // 1. Push local changes
      await _pushLocalChanges();

      // 2. Pull remote changes
      await _pullRemoteChanges();

      syncStatus.value = SyncStatus.synced;
      lastSyncTime.value = DateTime.now();
      pendingSyncCount.value = 0;
      debugPrint('[SyncService] Sync completed successfully');
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      debugPrint('[SyncService] ERROR during syncAll: $e');
    }
  }

  /// Push all unsynced local shifts to Firebase RTDB
  Future<void> _pushLocalChanges() async {
    final unsyncedShifts = _hiveProvider.getUnsyncedShifts();

    if (unsyncedShifts.isEmpty) {
      debugPrint('[SyncService] No unsynced shifts to push');
      return;
    }

    debugPrint(
        '[SyncService] Pushing ${unsyncedShifts.length} unsynced shifts...');

    final updates = <String, dynamic>{};

    for (final shift in unsyncedShifts) {
      if (shift.isDeleted) {
        // Will remove after batch
        updates[shift.id] = null;
        debugPrint('[SyncService] Queued delete for shift ${shift.id}');
      } else {
        updates[shift.id] = shift.toFirebaseMap();
        debugPrint('[SyncService] Queued write for shift ${shift.id}');
      }
    }

    try {
      await _shiftsRef().update(updates);
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
          '[SyncService] Marked ${unsyncedShifts.length} shifts as synced');
    } catch (e) {
      debugPrint('[SyncService] ERROR in batch update: $e');
      rethrow;
    }
  }

  /// Pull remote changes from Firebase RTDB
  Future<void> _pullRemoteChanges() async {
    try {
      final snapshot = await _shiftsRef().get();

      if (!snapshot.exists || snapshot.value == null) return;

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      for (final entry in data.entries) {
        try {
          final remoteShift = ShiftModel.fromFirebaseMap(
              Map<String, dynamic>.from(entry.value as Map));
          final localShift = _hiveProvider.getShift(remoteShift.id);

          if (localShift == null) {
            // New shift from cloud
            await _hiveProvider
                .saveShift(remoteShift.copyWith(isSynced: true));
          } else if (remoteShift.updatedAt.isAfter(localShift.updatedAt) &&
              localShift.isSynced) {
            // Remote is newer and local hasn't been modified
            await _hiveProvider
                .saveShift(remoteShift.copyWith(isSynced: true));
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
      pendingSyncCount.value++;
      debugPrint('[SyncService] No connectivity for shift ${shift.id}');
      return;
    }

    if (!_auth.isLoggedIn) {
      pendingSyncCount.value++;
      debugPrint(
          '[SyncService] User not authenticated for shift ${shift.id}');
      return;
    }

    final userId = _auth.userId;
    if (userId == null) {
      pendingSyncCount.value++;
      debugPrint('[SyncService] User UID is null for shift ${shift.id}');
      return;
    }

    // Retry logic with exponential backoff
    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        if (shift.isDeleted) {
          await _shiftsRef().child(shift.id).remove();
          await _hiveProvider.permanentlyDeleteShift(shift.id);
          debugPrint(
              '[SyncService] Successfully deleted shift ${shift.id}');
        } else {
          await _shiftsRef().child(shift.id).set(shift.toFirebaseMap());
          await _hiveProvider.markAsSynced(shift.id);
          debugPrint(
            '[SyncService] Successfully synced shift ${shift.id} for user $userId',
          );
        }
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
          debugPrint(
              '[SyncService] Retrying in ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
        }
      }
    }

    // All retries exhausted
    pendingSyncCount.value++;
    debugPrint(
      '[SyncService] FAILED to sync shift ${shift.id} after $maxRetries attempts',
    );
  }

  /// Full restore from Firebase RTDB (for reinstall scenarios)
  Future<int> fullRestore() async {
    if (!_connectivity.isConnected.value || !_auth.isLoggedIn) {
      throw Exception('Cannot restore: No internet or not logged in');
    }

    try {
      syncStatus.value = SyncStatus.syncing;

      final snapshot = await _shiftsRef().get();
      int restoredCount = 0;

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        for (final entry in data.entries) {
          try {
            final shift = ShiftModel.fromFirebaseMap(
                Map<String, dynamic>.from(entry.value as Map));
            if (!shift.isDeleted) {
              await _hiveProvider
                  .saveShift(shift.copyWith(isSynced: true));
              restoredCount++;
            }
          } catch (e) {
            debugPrint('[SyncService] Error restoring shift: $e');
          }
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
