import 'package:bookmunity/features/social/data/social_models.dart';
import 'package:bookmunity/features/social/data/social_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('username validation mirrors firestore.rules', () {
    expect(Usernames.validate('ab'), isNotNull);
    expect(Usernames.validate('abc'), isNull);
    expect(Usernames.validate('Reader_42'), isNull);
    expect(Usernames.validate('a' * 20), isNull);
    expect(Usernames.validate('a' * 21), isNotNull);
    expect(Usernames.validate('no spaces'), isNotNull);
    expect(Usernames.validate('émile'), isNotNull);
    expect(Usernames.validate(null), isNotNull);
  });

  test('review keys are valid Firestore document ids', () {
    expect(reviewDocKey('9781234567890'), '9781234567890');
    expect(reviewDocKey('a/b|c'), 'a-b|c');
    expect(reviewDocKey('  '), 'unknown');
    expect(reviewDocKey('x' * 300), hasLength(200));
  });

  test('text is clipped to rule limits', () {
    expect(clipTitle('t' * 500), hasLength(200));
    expect(clipDisplayName('  ${'n' * 80}  '), hasLength(50));
  });

  test('profile stats are clamped to rule ranges', () {
    const stats = ProfileStats(
      booksFinished: -1,
      currentStreak: 5,
      longestStreak: 999999,
      badgeCount: 500,
    );
    expect(stats.toJson(), {
      'booksFinished': 0,
      'currentStreak': 5,
      'longestStreak': 100000,
      'badgeCount': 100,
    });
  });
}
