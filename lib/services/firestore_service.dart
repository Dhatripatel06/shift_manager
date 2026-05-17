import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../core/config/app_environment.dart';
import '../models/shift_model.dart';
import '../models/user_profile_model.dart';
import 'auth_service.dart';

/// Exception types for Firestore operations
class FirestoreException implements Exception {
  final String message;
  final String? code;

  FirestoreException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Production-grade Firestore service for multi-user shift management
/// Implements offline-first architecture with real-time sync
class FirestoreService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = Get.find<AuthService>();
  static const Duration _requestTimeout = AppEnvironment.networkTimeout;

  /// Firestore connection state
  final RxBool isConnected = true.obs;
  final RxBool isSyncing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeOfflineSettings();
    _listenToConnectionState();
  }

  /// Initialize Firestore offline persistence
  void _initializeOfflineSettings() {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('[Firestore] Offline settings error: $e');
    }
  }

  /// Listen to connectivity state
  void _listenToConnectionState() {
    _firestore.snapshotsInSync().listen(
      (_) => isConnected.value = true,
      onError: (_) => isConnected.value = false,
    );
  }

  /// Get current user ID
  String get _userId => _auth.userId ?? '';

  /// Get user profile reference
  DocumentReference<Map<String, dynamic>> _getUserRef() {
    if (_userId.isEmpty) throw FirestoreException('User not authenticated');
    return _firestore.collection('users').doc(_userId);
  }

  /// Get shifts collection reference
  CollectionReference<Map<String, dynamic>> _getShiftsRef() {
    return _getUserRef().collection('shifts');
  }

  // ─────────────────────────────────────────────────────────────
  // USER PROFILE OPERATIONS
  // ─────────────────────────────────────────────────────────────

  /// Create or update user profile
  Future<void> createOrUpdateUserProfile({
    required String uid,
    String? name,
    String? email,
    String? photoUrl,
  }) async {
    try {
      isSyncing.value = true;
      final profile = UserProfile(
        uid: uid,
        name: name,
        email: email,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .set(profile.toFirestore(), SetOptions(merge: true));

      debugPrint('[Firestore] User profile created/updated: $uid');
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to create user profile', code: e.code);
    } finally {
      isSyncing.value = false;
    }
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc.data() as Map<String, dynamic>);
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to fetch user profile', code: e.code);
    }
  }

  /// Listen to user profile changes (real-time)
  Stream<UserProfile?> watchUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return UserProfile.fromFirestore(
            snapshot.data() as Map<String, dynamic>,
          );
        })
        .handleError((error) {
          debugPrint('[Firestore] Error watching user profile: $error');
          throw FirestoreException('Real-time profile sync failed');
        });
  }

  // ─────────────────────────────────────────────────────────────
  // SHIFT OPERATIONS (CREATE, READ, UPDATE, DELETE)
  // ─────────────────────────────────────────────────────────────

  /// Create a new shift
  Future<ShiftModel> createShift(ShiftModel shift) async {
    try {
      isSyncing.value = true;

      final firestoreData = shift.toFirebaseMap();
      firestoreData['userId'] = _userId;

      await _getShiftsRef()
          .doc(shift.id)
          .set(firestoreData)
          .timeout(_requestTimeout);

      debugPrint('[Firestore] Shift created: ${shift.id}');
      return shift;
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to create shift', code: e.code);
    } finally {
      isSyncing.value = false;
    }
  }

  /// Get single shift
  Future<ShiftModel?> getShift(String shiftId) async {
    try {
      final doc = await _getShiftsRef().doc(shiftId).get().timeout(
            _requestTimeout,
          );
      if (!doc.exists) return null;
      return ShiftModel.fromFirebaseMap(doc.data() as Map<String, dynamic>);
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to fetch shift', code: e.code);
    }
  }

  /// Update shift
  Future<ShiftModel> updateShift(ShiftModel shift) async {
    try {
      isSyncing.value = true;

      final firestoreData = shift.toFirebaseMap();
      firestoreData['userId'] = _userId;

      await _getShiftsRef()
          .doc(shift.id)
          .update(firestoreData)
          .timeout(_requestTimeout);

      debugPrint('[Firestore] Shift updated: ${shift.id}');
      return shift;
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to update shift', code: e.code);
    } finally {
      isSyncing.value = false;
    }
  }

  /// Delete shift (soft delete - marks as deleted)
  Future<void> deleteShift(String shiftId) async {
    try {
      isSyncing.value = true;

      await _getShiftsRef().doc(shiftId).update({
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }).timeout(_requestTimeout);

      debugPrint('[Firestore] Shift deleted: $shiftId');
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to delete shift', code: e.code);
    } finally {
      isSyncing.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REAL-TIME LISTENERS
  // ─────────────────────────────────────────────────────────────

  /// Listen to all shifts (real-time)
  Stream<List<ShiftModel>> watchAllShifts() {
    return _getShiftsRef()
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ShiftModel.fromFirebaseMap(doc.data()))
              .toList();
        })
        .handleError((error) {
          debugPrint('[Firestore] Error watching shifts: $error');
          throw FirestoreException('Real-time shifts sync failed');
        });
  }

  /// Listen to recent shifts
  Stream<List<ShiftModel>> watchRecentShifts({int limit = 10}) {
    return _getShiftsRef()
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ShiftModel.fromFirebaseMap(doc.data()))
              .toList();
        });
  }

  // ─────────────────────────────────────────────────────────────
  // QUERIES & FILTERING
  // ─────────────────────────────────────────────────────────────

  /// Get shifts by date range
  Future<List<ShiftModel>> getShiftsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _getShiftsRef()
          .where('isDeleted', isEqualTo: false)
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('date', descending: true)
          .get()
          .timeout(_requestTimeout);

      return snapshot.docs
          .map((doc) => ShiftModel.fromFirebaseMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to fetch shifts by date', code: e.code);
    }
  }

  /// Get shifts by event name (search)
  Future<List<ShiftModel>> searchByEventName(String query) async {
    try {
      final snapshot = await _getShiftsRef()
          .where('isDeleted', isEqualTo: false)
          .where('eventName', isGreaterThanOrEqualTo: query)
          .where('eventName', isLessThan: '${query}z')
          .orderBy('eventName')
          .orderBy('date', descending: true)
          .get()
          .timeout(_requestTimeout);

      return snapshot.docs
          .map((doc) => ShiftModel.fromFirebaseMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreException('Search failed', code: e.code);
    }
  }

  /// Get shifts with pagination
  Future<List<ShiftModel>> getPaginatedShifts({
    int pageSize = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _getShiftsRef()
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .limit(pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get().timeout(_requestTimeout);
      return snapshot.docs
          .map((doc) => ShiftModel.fromFirebaseMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreException('Pagination failed', code: e.code);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // STATISTICS & AGGREGATIONS
  // ─────────────────────────────────────────────────────────────

  /// Get total earnings
  Future<double> getTotalEarnings() async {
    try {
      final snapshot = await _getShiftsRef()
          .where('isDeleted', isEqualTo: false)
          .get()
          .timeout(_requestTimeout);

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['totalPay'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to calculate earnings', code: e.code);
    }
  }

  /// Get earnings by date range
  Future<double> getEarningsByDateRange(DateTime start, DateTime end) async {
    try {
      final snapshot = await _getShiftsRef()
          .where('isDeleted', isEqualTo: false)
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThanOrEqualTo: end.toIso8601String())
          .get()
          .timeout(_requestTimeout);

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['totalPay'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to fetch earnings', code: e.code);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BATCH OPERATIONS
  // ─────────────────────────────────────────────────────────────

  /// Batch create/update shifts
  Future<void> batchWriteShifts(List<ShiftModel> shifts) async {
    try {
      isSyncing.value = true;
      final batch = _firestore.batch();

      for (var shift in shifts) {
        final firestoreData = shift.toFirebaseMap();
        firestoreData['userId'] = _userId;
        batch.set(
          _getShiftsRef().doc(shift.id),
          firestoreData,
          SetOptions(merge: true),
        );
      }

      await batch.commit().timeout(_requestTimeout);
      debugPrint('[Firestore] Batch write completed: ${shifts.length} shifts');
    } on FirebaseException catch (e) {
      throw FirestoreException('Batch write failed', code: e.code);
    } finally {
      isSyncing.value = false;
    }
  }

  /// Batch delete shifts
  Future<void> batchDeleteShifts(List<String> shiftIds) async {
    try {
      isSyncing.value = true;
      final batch = _firestore.batch();

      for (var id in shiftIds) {
        batch.update(_getShiftsRef().doc(id), {'isDeleted': true});
      }

      await batch.commit().timeout(_requestTimeout);
      debugPrint(
        '[Firestore] Batch delete completed: ${shiftIds.length} shifts',
      );
    } on FirebaseException catch (e) {
      throw FirestoreException('Batch delete failed', code: e.code);
    } finally {
      isSyncing.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TRANSACTION OPERATIONS
  // ─────────────────────────────────────────────────────────────

  /// Transactional shift update with conflict prevention
  Future<void> transactionalUpdateShift(ShiftModel shift) async {
    try {
      isSyncing.value = true;

      await _firestore.runTransaction((transaction) async {
        final docRef = _getShiftsRef().doc(shift.id);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw FirestoreException('Shift not found');
        }

        final firestoreData = shift.toFirebaseMap();
        firestoreData['userId'] = _userId;

        transaction.update(docRef, firestoreData);
      }).timeout(_requestTimeout);

      debugPrint('[Firestore] Transactional update completed: ${shift.id}');
    } on FirebaseException catch (e) {
      throw FirestoreException('Transaction failed', code: e.code);
    } finally {
      isSyncing.value = false;
    }
  }
}
