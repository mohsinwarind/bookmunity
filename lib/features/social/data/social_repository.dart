import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'social_models.dart';

class UsernameTakenException implements Exception {
  const UsernameTakenException(this.username);
  final String username;

  @override
  String toString() => '“$username” is already taken.';
}

/// Whether [username] is free. Works before sign-in (the rules allow a
/// public `get` on `usernames/{name}`), so signup can check it up front.
Future<bool> isUsernameAvailable(FirebaseFirestore db, String username) async {
  final lower = username.trim().toLowerCase();
  final doc = await db
      .collection('usernames')
      .doc(lower)
      .get(const GetOptions(source: Source.server));
  return !doc.exists;
}

/// All social reads and writes. Every write mirrors a rule in
/// firestore.rules; change both together.
class SocialRepository {
  SocialRepository(this._db, this.uid);

  final FirebaseFirestore _db;

  /// The signed-in user.
  final String uid;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _db.collection('profiles');
  CollectionReference<Map<String, dynamic>> get _usernames =>
      _db.collection('usernames');
  CollectionReference<Map<String, dynamic>> get _avatars =>
      _db.collection('avatars');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('friendRequests');
  CollectionReference<Map<String, dynamic>> _friendsOf(String owner) =>
      _db.collection('users').doc(owner).collection('friends');
  CollectionReference<Map<String, dynamic>> _activityOf(String owner) =>
      _db.collection('users').doc(owner).collection('activity');
  CollectionReference<Map<String, dynamic>> _reviewsOf(String bookKey) =>
      _db.collection('books').doc(reviewDocKey(bookKey)).collection('reviews');

  // ------------------------------------------------------------ profile

  Stream<Profile?> watchMyProfile() => _profiles
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? Profile.fromDoc(doc) : null);

  /// Profile state for the startup gate. A cached "no such document" is not
  /// trusted (a fresh install has an empty cache); only the server can say
  /// the profile is missing. Errors, or no answer in time, mean Firestore
  /// is unavailable and the user is let in without social features.
  Stream<ProfileStatus> watchMyProfileStatus({
    Duration timeout = const Duration(seconds: 10),
  }) {
    final controller = StreamController<ProfileStatus>();
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? subscription;
    Timer? timer;
    var last = ProfileStatus.loading;

    void emit(ProfileStatus status) {
      if (status == last && status != ProfileStatus.loading) return;
      last = status;
      controller.add(status);
    }

    controller.onListen = () {
      emit(ProfileStatus.loading);
      timer = Timer(timeout, () {
        if (last == ProfileStatus.loading) emit(ProfileStatus.unavailable);
      });
      subscription = _profiles
          .doc(uid)
          .snapshots(includeMetadataChanges: true)
          .listen((doc) {
            if (doc.exists) {
              emit(ProfileStatus.ready);
            } else if (!doc.metadata.isFromCache) {
              emit(ProfileStatus.missing);
            }
          }, onError: (Object _) => emit(ProfileStatus.unavailable));
    };
    controller.onCancel = () async {
      timer?.cancel();
      await subscription?.cancel();
    };
    return controller.stream;
  }

  Future<Profile?> profile(String userId) async {
    final doc = await _profiles.doc(userId).get();
    return doc.exists ? Profile.fromDoc(doc) : null;
  }

  Stream<Profile?> watchProfile(String userId) => _profiles
      .doc(userId)
      .snapshots()
      .map((doc) => doc.exists ? Profile.fromDoc(doc) : null);

  /// Claims [username] and creates the profile atomically.
  Future<void> createProfile({
    required String username,
    required String displayName,
    required ProfileStats stats,
  }) async {
    final name = username.trim();
    final lower = name.toLowerCase();
    await _db.runTransaction((transaction) async {
      final claimed = await transaction.get(_usernames.doc(lower));
      if (claimed.exists) throw UsernameTakenException(name);
      transaction
        ..set(_usernames.doc(lower), {'uid': uid})
        ..set(_profiles.doc(uid), {
          'uid': uid,
          'username': name,
          'usernameLower': lower,
          'displayName': clipDisplayName(
            displayName.trim().isEmpty ? name : displayName,
          ),
          ...stats.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
    });
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    ProfileStats? stats,
  }) => _profiles.doc(uid).update({
    if (displayName != null) 'displayName': clipDisplayName(displayName),
    if (bio != null) 'bio': clipBio(bio),
    ...?stats?.toJson(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  // ------------------------------------------------------------- photos
  //
  // Photos live in their own collection so profile reads (search results,
  // friend lists) stay small; the profile only carries `hasPhoto`.

  /// The uploaded photo of [userId], or null when they use the cute avatar.
  Stream<Uint8List?> watchPhoto(String userId) =>
      _avatars.doc(userId).snapshots().map((doc) {
        final photo = doc.data()?['photo'];
        if (photo is! String || photo.isEmpty) return null;
        try {
          return base64Decode(photo);
        } on FormatException {
          return null;
        }
      });

  /// Stores [jpeg] (already resized, see `photo_processing.dart`).
  Future<void> setPhoto(Uint8List jpeg) {
    final encoded = base64Encode(jpeg);
    if (encoded.length > maxPhotoChars) {
      throw ArgumentError('Photo is too large after resizing.');
    }
    final batch = _db.batch()
      ..set(_avatars.doc(uid), {
        'uid': uid,
        'photo': encoded,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..update(_profiles.doc(uid), {
        'hasPhoto': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    return batch.commit();
  }

  Future<void> removePhoto() {
    final batch = _db.batch()
      ..delete(_avatars.doc(uid))
      ..update(_profiles.doc(uid), {
        'hasPhoto': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    return batch.commit();
  }

  /// Mirrors the size limit in firestore.rules (base64 characters).
  static const maxPhotoChars = 150000;

  /// Prefix search on usernames (case-insensitive).
  Future<List<Profile>> searchUsers(String query) async {
    final prefix = query.trim().toLowerCase().replaceAll('@', '');
    if (prefix.isEmpty) return const [];
    final result = await _profiles
        .orderBy('usernameLower')
        .startAt([prefix])
        .endAt(['$prefix'])
        .limit(20)
        .get();
    return result.docs
        .map(Profile.fromDoc)
        .where((profile) => profile.uid != uid)
        .toList();
  }

  // ------------------------------------------------------------ friends

  Stream<List<Friend>> watchFriends() => _friendsOf(uid).snapshots().map(
    (snapshot) => snapshot.docs.map(Friend.fromDoc).toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      ),
  );

  Stream<List<FriendRequest>> watchIncomingRequests() =>
      _requests.where('toUid', isEqualTo: uid).snapshots().map(_sortedRequests);

  Stream<List<FriendRequest>> watchOutgoingRequests() => _requests
      .where('fromUid', isEqualTo: uid)
      .snapshots()
      .map(_sortedRequests);

  List<FriendRequest> _sortedRequests(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => snapshot.docs.map(FriendRequest.fromDoc).toList()
    ..sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );

  Future<void> sendRequest({required Profile me, required Profile to}) =>
      _requests.doc('${uid}_${to.uid}').set({
        'fromUid': uid,
        'toUid': to.uid,
        'fromUsername': me.username,
        'fromDisplayName': me.displayName,
        'toUsername': to.username,
        'toDisplayName': to.displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// Creates both sides of the friendship and removes the request in one
  /// batch, so a half-accepted friendship can never exist.
  Future<void> acceptRequest(FriendRequest request, {required Profile me}) {
    final batch = _db.batch()
      ..set(_friendsOf(uid).doc(request.fromUid), {
        'uid': request.fromUid,
        'username': request.fromUsername,
        'displayName': request.fromDisplayName,
        'since': FieldValue.serverTimestamp(),
      })
      ..set(_friendsOf(request.fromUid).doc(uid), {
        'uid': uid,
        'username': me.username,
        'displayName': me.displayName,
        'since': FieldValue.serverTimestamp(),
      })
      ..delete(_requests.doc(request.id));
    return batch.commit();
  }

  /// Declines an incoming request or cancels an outgoing one.
  Future<void> deleteRequest(FriendRequest request) =>
      _requests.doc(request.id).delete();

  Future<void> removeFriend(String friendUid) {
    final batch = _db.batch()
      ..delete(_friendsOf(uid).doc(friendUid))
      ..delete(_friendsOf(friendUid).doc(uid));
    return batch.commit();
  }

  // ----------------------------------------------------------- activity

  Future<void> postActivity({
    required ActivityType type,
    String title = '',
    String author = '',
    String bookKey = '',
    String badgeId = '',
    String badgeTitle = '',
    int rating = 0,
  }) => _activityOf(uid).add({
    'type': type.name,
    'title': clipTitle(title),
    'author': clipTitle(author),
    'bookKey': clipTitle(bookKey),
    'badgeId': badgeId.length > 60 ? badgeId.substring(0, 60) : badgeId,
    'badgeTitle': badgeTitle.length > 60
        ? badgeTitle.substring(0, 60)
        : badgeTitle,
    'rating': rating.clamp(0, 5),
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<List<Activity>> activityOf(String owner, {int limit = 20}) async {
    final result = await _activityOf(
      owner,
    ).orderBy('createdAt', descending: true).limit(limit).get();
    return result.docs.map((doc) => Activity.fromDoc(owner, doc)).toList();
  }

  /// Recent activity across friends, newest first.
  Future<List<Activity>> feed(List<Friend> friends) async {
    final lists = await Future.wait(
      friends.map(
        (friend) => activityOf(friend.uid, limit: 10).catchError(
          // A friend who removed us mid-load is no longer readable.
          (_) => <Activity>[],
        ),
      ),
    );
    return lists.expand((items) => items).toList()..sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
  }

  // ------------------------------------------------------------ reviews

  Stream<List<Review>> watchReviews(String bookKey) => _reviewsOf(bookKey)
      .orderBy('updatedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Review.fromDoc).toList());

  Future<void> saveReview({
    required Profile me,
    required String bookKey,
    required String title,
    required String author,
    required int rating,
    required String text,
  }) async {
    final ref = _reviewsOf(bookKey).doc(uid);
    final existing = await ref.get();
    final body = text.trim();
    await ref.set({
      'uid': uid,
      'username': me.username,
      'displayName': me.displayName,
      'rating': rating.clamp(1, 5),
      'text': body.length > 2000 ? body.substring(0, 2000) : body,
      'title': clipTitle(title.isEmpty ? 'Untitled' : title),
      'author': clipTitle(author),
      'createdAt': existing.exists
          ? existing.data()!['createdAt']
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReview(String bookKey) =>
      _reviewsOf(bookKey).doc(uid).delete();
}

/// Self-reported reading stats published on the public profile.
class ProfileStats {
  const ProfileStats({
    required this.booksFinished,
    required this.currentStreak,
    required this.longestStreak,
    required this.badgeCount,
  });

  static const zero = ProfileStats(
    booksFinished: 0,
    currentStreak: 0,
    longestStreak: 0,
    badgeCount: 0,
  );

  final int booksFinished;
  final int currentStreak;
  final int longestStreak;
  final int badgeCount;

  Map<String, Object> toJson() => {
    'booksFinished': booksFinished.clamp(0, 100000),
    'currentStreak': currentStreak.clamp(0, 100000),
    'longestStreak': longestStreak.clamp(0, 100000),
    'badgeCount': badgeCount.clamp(0, 100),
  };
}
