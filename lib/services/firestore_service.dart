import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/rating_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // --------------------------------------------------
  // USER OPERATIONS
  // --------------------------------------------------

  Future<void> createUser(UserModel user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap());
  }

  Future<void> markOnboardingDone(String uid) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'onboardingDone': true});
  }

  Future<bool> userExists(String uid) async {
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();
    return doc.exists;
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc =
          await _db.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists) return UserModel.fromMap(doc.data()!);
      return null;
    } catch (e) {
      debugPrint('[FirestoreService] getUser error: $e');
      return null;
    }
  }

  Future<void> updateLastActive(String uid) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'lastActiveAt': FieldValue.serverTimestamp()});
  }

  // --------------------------------------------------
  // SEARCH HISTORY
  // --------------------------------------------------

  Future<void> saveSearchHistory({
    required String uid,
    required String query,
    required String detectedType,
    required int resultCount,
  }) async {
    await _db
        .collection(AppConstants.searchHistoryCollection)
        .doc(uid)
        .collection('searches')
        .add({
      'query': query,
      'detectedType': detectedType,
      'resultCount': resultCount,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getSearchHistory(String uid) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.searchHistoryCollection)
          .doc(uid)
          .collection('searches')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('[FirestoreService] getSearchHistory error: $e');
      return [];
    }
  }

  // --------------------------------------------------
  // RATINGS
  // --------------------------------------------------

  Future<void> saveRating({
    required String uid,
    required RatingModel rating,
  }) async {
    await _db
        .collection(AppConstants.ratingsCollection)
        .doc(uid)
        .collection('rated')
        .doc(rating.id)
        .set(rating.toMap());
  }

  Future<List<RatingModel>> getUserRatings(String uid) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.ratingsCollection)
          .doc(uid)
          .collection('rated')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      return snapshot.docs.map((d) => RatingModel.fromMap(d.data())).toList();
    } catch (e) {
      debugPrint('[FirestoreService] getUserRatings error: $e');
      return [];
    }
  }

  // --------------------------------------------------
  // WATCHLIST
  // --------------------------------------------------

  Future<void> addToWatchlist({
    required String uid,
    required String title,
    required String contentType,
  }) async {
    final docId = _safeDocId(title);
    await _db
        .collection(AppConstants.watchlistCollection)
        .doc(uid)
        .collection('items')
        .doc(docId)
        .set({
      'title': title,
      'contentType': contentType,
      'addedAt': FieldValue.serverTimestamp(),
      'watched': false,
    });
  }

  Future<void> toggleWatched({
    required String uid,
    required String title,
    required bool watched,
  }) async {
    final docId = _safeDocId(title);
    await _db
        .collection(AppConstants.watchlistCollection)
        .doc(uid)
        .collection('items')
        .doc(docId)
        .update({'watched': watched});
  }

  Future<void> removeFromWatchlist({
    required String uid,
    required String title,
  }) async {
    final docId = _safeDocId(title);
    await _db
        .collection(AppConstants.watchlistCollection)
        .doc(uid)
        .collection('items')
        .doc(docId)
        .delete();
  }

  Stream<List<Map<String, dynamic>>> watchlistStream(String uid) {
    return _db
        .collection(AppConstants.watchlistCollection)
        .doc(uid)
        .collection('items')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // --------------------------------------------------
  // USER PREFERENCES
  // --------------------------------------------------

  /// WHY do we save both current + history?
  ///
  /// OLD problem: every save OVERWRITES the previous preferences array.
  /// User picks [anime, kdrama] → then changes to [bollywood] → old choice gone!
  ///
  /// NEW approach:
  /// - `favoriteTypes` / `favoriteGenres` = CURRENT preferences (latest)
  /// - `preferenceHistory` = array of ALL past snapshots with timestamps
  ///
  /// This means:
  /// ✅ App always reads the latest from top-level fields (fast, simple)
  /// ✅ Firestore keeps the full history for future ML/RL training
  /// ✅ merge: true ensures we never delete other fields in the document
  Future<void> savePreferences({
    required String uid,
    required List<String> favoriteGenres,
    required List<String> favoriteTypes,
  }) async {
    final docRef = _db.collection(AppConstants.preferencesCollection).doc(uid);

    /// WHY FieldValue.arrayUnion for history?
    /// arrayUnion appends to the array without reading it first.
    /// We push a new snapshot object each time preferences change.
    /// Firestore handles this atomically — no race conditions.
    await docRef.set({
      // Current preferences — always reflects latest choice
      'favoriteTypes': favoriteTypes,
      'favoriteGenres': favoriteGenres,
      'updatedAt': FieldValue.serverTimestamp(),

      // Full history — every past set of preferences with timestamp
      // Future ML can use this to understand how tastes evolve over time!
      'preferenceHistory': FieldValue.arrayUnion([
        {
          'favoriteTypes': favoriteTypes,
          'favoriteGenres': favoriteGenres,
          'savedAt': DateTime.now().toIso8601String(),
        }
      ]),
    }, SetOptions(merge: true));
  }

  /// Fetches current preferences — used to pre-fill the edit sheet
  Future<Map<String, dynamic>> getPreferences(String uid) async {
    try {
      final doc = await _db
          .collection(AppConstants.preferencesCollection)
          .doc(uid)
          .get();
      return doc.exists ? doc.data()! : {};
    } catch (e) {
      debugPrint('[FirestoreService] getPreferences error: $e');
      return {};
    }
  }

  // --------------------------------------------------
  // HELPER
  // --------------------------------------------------

  String generateId() => _uuid.v4();
}

/// WHY a top-level function?
/// Titles with special chars like "Spider-Man: No Way Home"
/// produce invalid Firestore document IDs. We convert to a safe slug.
String _safeDocId(String title) {
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
