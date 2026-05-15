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
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncAll(),
    );
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
      return;
    }

    try {
      syncStatus.value = SyncStatus.syncing;

      // 1. Push local unsynced changes to Firestore
      await _pushLocalChanges();

      // 2. Pull remote changes
      await _pullRemoteChanges();

      syncStatus.value = SyncStatus.synced;
      lastSyncTime.value = DateTime.now();
      pendingSyncCount.value = 0;
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      // Don't throw - sync failures shouldn't crash the app
      // Data is safe in Hive
    }
  }

  /// Push all unsynced local shifts to Firestore
  Future<void> _pushLocalChanges() async {
    final unsyncedShifts = _hiveProvider.getUnsyncedShifts();

    if (unsyncedShifts.isEmpty) return;

    final batch = _firestore.batch();

    for (final shift in unsyncedShifts) {
      final docRef = _shiftsRef().doc(shift.id);

      if (shift.isDeleted) {
        batch.delete(docRef);
      } else {
        batch.set(docRef, shift.toFirestoreMap(), SetOptions(merge: true));
      }
    }

    await batch.commit();

    // Mark all as synced locally
    for (final shift in unsyncedShifts) {
      if (shift.isDeleted) {
        await _hiveProvider.permanentlyDeleteShift(shift.id);
      } else {
        await _hiveProvider.markAsSynced(shift.id);
      }
    }
  }

  /// Pull remote changes from Firestore
  Future<void> _pullRemoteChanges() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot;

      if (lastSyncTime.value != null) {
        snapshot = await _shiftsRef()
            .where('updatedAt',
                isGreaterThan: lastSyncTime.value!.toIso8601String())
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

  /// Sync a single shift immediately
  Future<void> syncShift(ShiftModel shift) async {
    if (!_connectivity.isConnected.value || !_auth.isLoggedIn) {
      pendingSyncCount.value++;
      return;
    }

    try {
      if (shift.isDeleted) {
        await _shiftsRef().doc(shift.id).delete();
        await _hiveProvider.permanentlyDeleteShift(shift.id);
      } else {
        await _shiftsRef()
            .doc(shift.id)
            .set(shift.toFirestoreMap(), SetOptions(merge: true));
        await _hiveProvider.markAsSynced(shift.id);
      }
    } catch (e) {
      pendingSyncCount.value++;
      // Data is safe locally - will sync later
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
