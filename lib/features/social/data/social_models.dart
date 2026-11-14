import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _time(Object? value) => value is Timestamp ? value.toDate() : null;

String _str(Object? value) => value is String ? value : '';

int _int(Object? value) => value is num ? value.toInt() : 0;

/// Username rules shared by the UI and mirrored in firestore.rules.
abstract final class Usernames {
  static final pattern = RegExp(r'^[A-Za-z0-9_]{3,20}$');

  static String? validate(String? value) {
    final name = value?.trim() ?? '';
    if (name.length < 3) return 'Use at least 3 characters.';
    if (name.length > 20) return 'Use at most 20 characters.';
    if (!pattern.hasMatch(name)) {
      return 'Letters, numbers and underscores only.';
    }
    return null;
  }
}

class Profile {
  const Profile({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.booksFinished,
    required this.currentStreak,
    required this.longestStreak,
    required this.badgeCount,
    this.bio = '',
    this.hasPhoto = false,
    this.createdAt,
  });

  factory Profile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Profile(
      uid: doc.id,
      username: _str(data['username']),
      displayName: _str(data['displayName']),
      booksFinished: _int(data['booksFinished']),
      currentStreak: _int(data['currentStreak']),
      longestStreak: _int(data['longestStreak']),
      badgeCount: _int(data['badgeCount']),
      bio: _str(data['bio']),
      hasPhoto: data['hasPhoto'] == true,
      createdAt: _time(data['createdAt']),
    );
  }

  final String uid;
  final String username;
  final String displayName;
  final int booksFinished;
  final int currentStreak;
  final int longestStreak;
  final int badgeCount;

  /// Short public "about me", at most [maxBioLength] characters.
  final String bio;

  /// Whether the user uploaded a photo (stored in `avatars/{uid}`). When
  /// false the generated cute avatar is shown instead.
  final bool hasPhoto;
  final DateTime? createdAt;

  static const maxBioLength = 160;
}

/// Where the signed-in user's profile stands, as far as the server knows.
enum ProfileStatus {
  /// Still waiting for the server.
  loading,

  /// The profile exists.
  ready,

  /// The server confirmed there is no profile: ask for a username.
  missing,

  /// Firestore cannot be reached or is not set up; let the user in anyway.
  unavailable,
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.fromUsername,
    required this.fromDisplayName,
    required this.toUsername,
    required this.toDisplayName,
    this.createdAt,
  });

  factory FriendRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return FriendRequest(
      id: doc.id,
      fromUid: _str(data['fromUid']),
      toUid: _str(data['toUid']),
      fromUsername: _str(data['fromUsername']),
      fromDisplayName: _str(data['fromDisplayName']),
      toUsername: _str(data['toUsername']),
      toDisplayName: _str(data['toDisplayName']),
      createdAt: _time(data['createdAt']),
    );
  }

  final String id;
  final String fromUid;
  final String toUid;
  final String fromUsername;
  final String fromDisplayName;
  final String toUsername;
  final String toDisplayName;
  final DateTime? createdAt;
}

class Friend {
  const Friend({
    required this.uid,
    required this.username,
    required this.displayName,
    this.since,
  });

  factory Friend.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Friend(
      uid: doc.id,
      username: _str(data['username']),
      displayName: _str(data['displayName']),
      since: _time(data['since']),
    );
  }

  final String uid;
  final String username;
  final String displayName;
  final DateTime? since;
}

enum ActivityType { started, finished, badge, review }

class Activity {
  const Activity({
    required this.id,
    required this.ownerUid,
    required this.type,
    required this.title,
    required this.author,
    required this.bookKey,
    required this.badgeId,
    required this.badgeTitle,
    required this.rating,
    this.createdAt,
  });

  factory Activity.fromDoc(
    String ownerUid,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return Activity(
      id: doc.id,
      ownerUid: ownerUid,
      type: ActivityType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => ActivityType.started,
      ),
      title: _str(data['title']),
      author: _str(data['author']),
      bookKey: _str(data['bookKey']),
      badgeId: _str(data['badgeId']),
      badgeTitle: _str(data['badgeTitle']),
      rating: _int(data['rating']),
      createdAt: _time(data['createdAt']),
    );
  }

  final String id;
  final String ownerUid;
  final ActivityType type;
  final String title;
  final String author;
  final String bookKey;
  final String badgeId;
  final String badgeTitle;
  final int rating;
  final DateTime? createdAt;
}

class Review {
  const Review({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.rating,
    required this.text,
    this.updatedAt,
  });

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Review(
      uid: doc.id,
      username: _str(data['username']),
      displayName: _str(data['displayName']),
      rating: _int(data['rating']).clamp(1, 5),
      text: _str(data['text']),
      updatedAt: _time(data['updatedAt']),
    );
  }

  final String uid;
  final String username;
  final String displayName;
  final int rating;
  final String text;
  final DateTime? updatedAt;
}

/// Firestore document IDs cannot contain '/', and the rules cap length.
String reviewDocKey(String bookKey) {
  final cleaned = bookKey.replaceAll('/', '-').trim();
  if (cleaned.isEmpty) return 'unknown';
  return cleaned.length > 200 ? cleaned.substring(0, 200) : cleaned;
}

String _clip(String value, int max) =>
    value.length > max ? value.substring(0, max) : value;

/// Truncates free text to the limits enforced by firestore.rules.
String clipTitle(String value) => _clip(value, 200);
String clipDisplayName(String value) => _clip(value.trim(), 50);
String clipBio(String value) => _clip(value.trim(), Profile.maxBioLength);
