import 'dart:async';

import 'package:bookmunity/features/social/data/photo_processing.dart';
import 'package:bookmunity/features/social/presentation/cute_avatar.dart';
import 'package:bookmunity/features/social/presentation/username_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('AvatarLook', () {
    test('is stable for the same seed', () {
      final a = AvatarLook.fromSeed('uid-123');
      final b = AvatarLook.fromSeed('uid-123');
      expect(a.animal, b.animal);
      expect(a.background, b.background);
      expect(a.fur, b.fur);
    });

    test('spreads users across animals', () {
      final animals = {
        for (var i = 0; i < 200; i++) AvatarLook.fromSeed('user-$i').animal,
      };
      expect(animals.length, AvatarAnimal.values.length);
    });

    testWidgets('paints every animal without errors', (tester) async {
      // Find a seed for each animal, then render them all.
      final seeds = <AvatarAnimal, String>{};
      for (var i = 0; seeds.length < AvatarAnimal.values.length; i++) {
        seeds.putIfAbsent(AvatarLook.fromSeed('s$i').animal, () => 's$i');
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Wrap(
            children: [
              for (final seed in seeds.values) CuteAvatar(seed: seed, size: 64),
            ],
          ),
        ),
      );
      expect(find.byType(CuteAvatar), findsNWidgets(seeds.length));
      expect(tester.takeException(), isNull);
    });
  });

  group('squareProfileJpeg', () {
    test('centre-crops and shrinks to a small square JPEG', () {
      final source = img.Image(width: 1200, height: 800);
      img.fill(source, color: img.ColorRgb8(200, 120, 90));
      final jpeg = squareProfileJpeg(img.encodePng(source))!;
      final decoded = img.decodeJpg(jpeg)!;
      expect(decoded.width, profilePhotoSize);
      expect(decoded.height, profilePhotoSize);
      // Fits the Firestore rule limit once base64-encoded.
      expect((jpeg.length * 4 / 3).ceil(), lessThan(150000));
    });

    test('returns null for non-images', () {
      expect(squareProfileJpeg(Uint8ListHelper.text('hello')), isNull);
    });
  });

  group('UsernameChecker', () {
    test('ignores invalid names and reports availability', () async {
      final taken = {'ayesha_reads'};
      final checker = UsernameChecker(
        check: (name) async => !taken.contains(name.toLowerCase()),
        debounce: Duration.zero,
      );
      checker.onChanged('ab');
      expect(checker.state, UsernameAvailability.idle);

      checker.onChanged('Ayesha_Reads');
      expect(checker.state, UsernameAvailability.checking);
      await pumpEventQueue();
      expect(checker.state, UsernameAvailability.taken);

      expect(await checker.checkNow('new_reader'), isTrue);
      expect(checker.state, UsernameAvailability.available);
      checker.dispose();
    });

    test('reports unknown when the check fails', () async {
      final checker = UsernameChecker(
        check: (_) => Future.error(TimeoutException('offline')),
        debounce: Duration.zero,
      );
      expect(await checker.checkNow('someone'), isNull);
      expect(checker.state, UsernameAvailability.unknown);
      checker.dispose();
    });
  });
}

abstract final class Uint8ListHelper {
  static Uint8List text(String value) => Uint8List.fromList(value.codeUnits);
}
