import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/shift_model.dart';
import '../core/constants/app_constants.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import '../data/providers/hive_provider.dart';

/// Sync status enum
enum SyncStatus { synced, syncing, offline, error }

/// Service that handles bidirectional sync between Hive (local) and Firestore (cloud).
/// Implements offline-first architecture: always save locally first, then sync to cloud.
class SyncService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  /// Get Firestore path for user's shifts
  CollectionReference<Map<String, dynamic>> _shiftsRef() {
    final uid = _auth.userId;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.shiftsCollection);
  }

  /// Sync all unsynced shifts to Firestore
  Future<void> syncAll() async {
    if (!_connectivity.isConnected.value || !_auth.isLoggedIn) {
      syncStatus.value = SyncStatus.offline;
      print(
        '[SyncService] syncAll: Offline or not logged in. Connected: ${_connectivity.isConnected.value}, LoggedIn: ${_auth.isLoggedIn}',
      );
      return;
    }

    try {
      syncStatus.value = SyncStatus.syncing;
      print('[SyncService] Starting sync...');

      // Ensure Firebase auth token is ready for Firestore

      await _pushLocalChanges();

      // 2. Pull remote changes
      await _pullRemoteChanges();

      syncStatus.value = SyncStatus.synced;
      lastSyncTime.value = DateTime.now();
      pendingSyncCount.value = 0;
      print('[SyncService] Sync completed successfully');
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      print('[SyncService] ERROR during syncAll: $e');
      rethrow;
    }
  }

  /// Push all unsynced local shifts to Firestore
  Future<void> _pushLocalChanges() async {
    final unsyncedShifts = _hiveProvider.getUnsyncedShifts();

    if (unsyncedShifts.isEmpty) {
      print('[SyncService] No unsynced shifts to push');
      return;
    }

    print('[SyncService] Pushing ${unsyncedShifts.length} unsynced shifts...');

    final batch = _firestore.batch();

    for (final shift in unsyncedShifts) {
      final docRef = _shiftsRef().doc(shift.id);

      if (shift.isDeleted) {
        batch.delete(docRef);
        print('[SyncService] Queued delete for shift ${shift.id}');
      } else {
        batch.set(docRef, shift.toFirestoreMap(), SetOptions(merge: true));
        print('[SyncService] Queued write for shift ${shift.id}');
      }
    }

    try {
      await batch.commit();
      print('[SyncService] Batch commit successful');

      // Mark all as synced locally
      for (final shift in unsyncedShifts) {
        if (shift.isDeleted) {
          await _hiveProvider.permanentlyDeleteShift(shift.id);
        } else {
          await _hiveProvider.markAsSynced(shift.id);
        }
      }
      print('[SyncService] Marked ${unsyncedShifts.length} shifts as synced');
    } catch (e) {
      print('[SyncService] ERROR in batch commit: $e');
      rethrow;
    }
  }

  /// Pull remote changes from Firestore
  Future<void> _pullRemoteChanges() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot;

      if (lastSyncTime.value != null) {
        snapshot = await _shiftsRef()
            .where(
              'updatedAt',
              isGreaterThan: lastSyncTime.value!.toIso8601String(),
            )
            .get();
      } else {
        snapshot = await _shiftsRef().get();
      }

      for (final doc in snapshot.docs) {
        final remoteShift = ShiftModel.fromFirestoreMap(doc.data());
        final localShift = _hiveProvider.getShift(remoteShift.id);

        if (localShift == null) {
          // New shift from cloud
          await _hiveProvider.saveShift(remoteShift.copyWith(isSynced: true));
        } else if (remoteShift.updatedAt.isAfter(localShift.updatedAt) &&
            localShift.isSynced) {
          // Remote is newer and local hasn't been modified
          await _hiveProvider.saveShift(remoteShift.copyWith(isSynced: true));
        }
        // If local is newer (unsynced), keep local version - it will be pushed on next sync
      }
    } catch (e) {
      // Silently handle pull errors - local data is still valid
    }
  }

  /// Sync a single shift immediately with retry logic
  Future<void> syncShift(ShiftModel shift) async {
    if (!_connectivity.isConnected.value) {
      pendingSyncCount.value++;
      print('[SyncService] No connectivity for shift ${shift.id}');
      return;
    }

    if (!_auth.isLoggedIn) {
      pendingSyncCount.value++;
      print('[SyncService] User not authenticated for shift ${shift.id}');
      return;
    }

    final userId = _auth.userId;
    if (userId == null) {
      pendingSyncCount.value++;
      print('[SyncService] User UID is null for shift ${shift.id}');
      return;
    }

    // Retry logic with exponential backoff
    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        // Ensure user document exists first
        await _ensureUserDocumentExists(userId);

        if (shift.isDeleted) {
          await _shiftsRef().doc(shift.id).delete();
          await _hiveProvider.permanentlyDeleteShift(shift.id);
          print('[SyncService] Successfully deleted shift ${shift.id}');
        } else {
          final firestoreData = shift.toFirestoreMap();
          print('[SyncService] Writing shift data: $firestoreData');
          await _shiftsRef()
              .doc(shift.id)
              .set(firestoreData, SetOptions(merge: true));
          await _hiveProvider.markAsSynced(shift.id);
          print(
            '[SyncService] Successfully synced shift ${shift.id} for user $userId to path: users/$userId/shifts/${shift.id}',
          );
        }
        return; // Success - exit retry loop
      } catch (e) {
        retries++;
        print(
          '[SyncService] Sync attempt $retries/$maxRetries failed for shift ${shift.id}: $e',
        );

        if (retries < maxRetries) {
          // Exponential backoff: 500ms, 1s, 2s
          final delay = Duration(milliseconds: 500 * (1 << (retries - 1)));
          print('[SyncService] Retrying in ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
        }
      }
    }

    // All retries exhausted
    pendingSyncCount.value++;
    print(
      '[SyncService] FAILED to sync shift ${shift.id} after $maxRetries attempts',
    );
  }

  /// Ensure user document exists in Firestore
  Future<void> _ensureUserDocumentExists(String userId) async {
    try {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        // Create minimal user document
        await userRef.set({
          'uid': userId,
          'createdAt': DateTime.now().toIso8601String(),
          'lastSync': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
        print('[SyncService] Created user document for $userId');
      }
    } catch (e) {
      print('[SyncService] Error ensuring user document exists: $e');
      rethrow;
    }
  }

  /// Full restore from Firestore (for reinstall scenarios)
  Future<int> fullRestore() async {
    if (!_connectivity.isConnected.value || !_auth.isLoggedIn) {
      throw Exception('Cannot restore: No internet or not logged in');
    }

    try {
      syncStatus.value = SyncStatus.syncing;

      final snapshot = await _shiftsRef().get();
      int restoredCount = 0;

      for (final doc in snapshot.docs) {
        final shift = ShiftModel.fromFirestoreMap(doc.data());
        if (!shift.isDeleted) {
          await _hiveProvider.saveShift(shift.copyWith(isSynced: true));
          restoredCount++;
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
