import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The animals a generated avatar can be.
enum AvatarAnimal { bunny, cat, bear, fox, panda, frog, mouse, chick }

/// A deterministic avatar description derived from a seed (the user's uid),
/// so every user keeps the same little animal on every device.
@immutable
class AvatarLook {
  const AvatarLook({
    required this.animal,
    required this.background,
    required this.fur,
  });

  factory AvatarLook.fromSeed(String seed) {
    final hash = _fnv1a(seed);
    final animal = AvatarAnimal.values[hash % AvatarAnimal.values.length];
    final background =
        _backgrounds[(hash ~/ AvatarAnimal.values.length) %
            _backgrounds.length];
    final furs = _furs[animal]!;
    final fur = furs[(hash ~/ 97) % furs.length];
    return AvatarLook(animal: animal, background: background, fur: fur);
  }

  final AvatarAnimal animal;
  final Color background;
  final Color fur;

  static const _backgrounds = [
    Color(0xFFFBE3D6), // peach
    Color(0xFFDCEBF7), // sky
    Color(0xFFE3F1DF), // mint
    Color(0xFFF6E7B8), // butter
    Color(0xFFEBDDF4), // lilac
    Color(0xFFF8DCE4), // blush
    Color(0xFFDDEFEC), // sea glass
  ];

  static const Map<AvatarAnimal, List<Color>> _furs = {
    AvatarAnimal.bunny: [
      Color(0xFFC9CED8),
      Color(0xFFF4EFE8),
      Color(0xFFD9B99B),
    ],
    AvatarAnimal.cat: [Color(0xFFF2B36B), Color(0xFF8E9096), Color(0xFFF4EFE8)],
    AvatarAnimal.bear: [
      Color(0xFFB98563),
      Color(0xFF8C6449),
      Color(0xFFD9B99B),
    ],
    AvatarAnimal.fox: [Color(0xFFEE8A4B), Color(0xFFE47A55)],
    AvatarAnimal.panda: [Color(0xFFFBFAF7)],
    AvatarAnimal.frog: [Color(0xFF8CC984), Color(0xFF9FD3A0)],
    AvatarAnimal.mouse: [Color(0xFFB9BDC6), Color(0xFFD8CFC4)],
    AvatarAnimal.chick: [Color(0xFFF7D35C), Color(0xFFF5C84A)],
  };

  /// FNV-1a: stable across runs and platforms, unlike String.hashCode.
  static int _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}

/// A round, generated animal avatar.
class CuteAvatar extends StatelessWidget {
  const CuteAvatar({required this.seed, this.size = 40, super.key});

  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: CuteAvatarPainter(AvatarLook.fromSeed(seed))),
    );
  }
}

class CuteAvatarPainter extends CustomPainter {
  CuteAvatarPainter(this.look);

  final AvatarLook look;

  static const _ink = Color(0xFF2B2B2B);
  static const _blush = Color(0x66F28B9B);
  static const _innerEar = Color(0xFFF4B6C2);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    final clip = Path()..addOval(Rect.fromLTWH(0, 0, s, s));
    canvas.clipPath(clip);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s, s),
      Paint()..color = look.background,
    );

    Offset p(double x, double y) => Offset(x * s, y * s);
    final fur = Paint()..color = look.fur;
    final ink = Paint()..color = _ink;
    final face = Rect.fromCenter(
      center: p(0.5, 0.6),
      width: s * 0.62,
      height: s * 0.56,
    );

    // Ears and other parts behind the face.
    switch (look.animal) {
      case AvatarAnimal.bunny:
        for (final dx in [-0.13, 0.13]) {
          final ear = Rect.fromCenter(
            center: p(0.5 + dx, 0.25),
            width: s * 0.15,
            height: s * 0.42,
          );
          canvas.drawOval(ear, fur);
          canvas.drawOval(ear.deflate(s * 0.035), Paint()..color = _innerEar);
        }
      case AvatarAnimal.cat:
      case AvatarAnimal.fox:
        for (final side in [-1.0, 1.0]) {
          final ear = Path()
            ..moveTo(0.5 * s + side * 0.27 * s, 0.5 * s)
            ..lineTo(0.5 * s + side * 0.25 * s, 0.17 * s)
            ..lineTo(0.5 * s + side * 0.04 * s, 0.38 * s)
            ..close();
          canvas.drawPath(ear, fur);
          final inner = Path()
            ..moveTo(0.5 * s + side * 0.22 * s, 0.42 * s)
            ..lineTo(0.5 * s + side * 0.22 * s, 0.25 * s)
            ..lineTo(0.5 * s + side * 0.11 * s, 0.37 * s)
            ..close();
          canvas.drawPath(
            inner,
            Paint()..color = look.animal == AvatarAnimal.fox ? _ink : _innerEar,
          );
        }
      case AvatarAnimal.bear:
        for (final dx in [-0.24, 0.24]) {
          canvas.drawCircle(p(0.5 + dx, 0.36), s * 0.1, fur);
          canvas.drawCircle(
            p(0.5 + dx, 0.36),
            s * 0.05,
            Paint()..color = _shade(look.fur, -0.18),
          );
        }
      case AvatarAnimal.panda:
        for (final dx in [-0.24, 0.24]) {
          canvas.drawCircle(p(0.5 + dx, 0.36), s * 0.1, ink);
        }
      case AvatarAnimal.mouse:
        for (final dx in [-0.27, 0.27]) {
          canvas.drawCircle(p(0.5 + dx, 0.34), s * 0.15, fur);
          canvas.drawCircle(
            p(0.5 + dx, 0.34),
            s * 0.09,
            Paint()..color = _innerEar,
          );
        }
      case AvatarAnimal.frog:
        for (final dx in [-0.16, 0.16]) {
          canvas.drawCircle(p(0.5 + dx, 0.36), s * 0.12, fur);
        }
      case AvatarAnimal.chick:
        final tuft = Path()
          ..moveTo(0.47 * s, 0.34 * s)
          ..quadraticBezierTo(0.44 * s, 0.2 * s, 0.52 * s, 0.22 * s)
          ..quadraticBezierTo(0.5 * s, 0.28 * s, 0.53 * s, 0.34 * s)
          ..close();
        canvas.drawPath(tuft, fur);
    }

    // Body hint and face.
    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 1.08), width: s * 0.8, height: s * 0.5),
      Paint()..color = _shade(look.fur, -0.06),
    );
    canvas.drawOval(face, fur);

    // Face markings.
    switch (look.animal) {
      case AvatarAnimal.fox:
        for (final side in [-1.0, 1.0]) {
          final cheek = Path()
            ..moveTo(0.5 * s, 0.86 * s)
            ..quadraticBezierTo(
              0.5 * s + side * 0.3 * s,
              0.82 * s,
              0.5 * s + side * 0.3 * s,
              0.6 * s,
            )
            ..quadraticBezierTo(
              0.5 * s + side * 0.14 * s,
              0.66 * s,
              0.5 * s,
              0.68 * s,
            )
            ..close();
          canvas.drawPath(cheek, Paint()..color = const Color(0xFFFFF6EC));
        }
      case AvatarAnimal.panda:
        for (final side in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(0.5 * s + side * 0.12 * s, 0.57 * s);
          canvas.rotate(side * -0.5);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: s * 0.13,
              height: s * 0.18,
            ),
            ink,
          );
          canvas.restore();
        }
      case AvatarAnimal.bear:
        canvas.drawOval(
          Rect.fromCenter(
            center: p(0.5, 0.7),
            width: s * 0.24,
            height: s * 0.17,
          ),
          Paint()..color = _shade(look.fur, 0.28),
        );
      case AvatarAnimal.frog:
        for (final dx in [-0.16, 0.16]) {
          canvas.drawCircle(
            p(0.5 + dx, 0.36),
            s * 0.075,
            Paint()..color = Colors.white,
          );
        }
      case AvatarAnimal.bunny:
      case AvatarAnimal.cat:
      case AvatarAnimal.mouse:
      case AvatarAnimal.chick:
        break;
    }

    // Eyes (frogs keep theirs on top of the head).
    final eyeY = look.animal == AvatarAnimal.frog ? 0.37 : 0.57;
    final eyeDx = look.animal == AvatarAnimal.frog ? 0.16 : 0.12;
    final eyeColor = look.animal == AvatarAnimal.panda ? Colors.white : _ink;
    for (final dx in [-eyeDx, eyeDx]) {
      canvas.drawCircle(
        p(0.5 + dx, eyeY),
        s * 0.035,
        Paint()..color = eyeColor,
      );
      canvas.drawCircle(
        p(0.5 + dx + 0.012, eyeY - 0.012),
        s * 0.012,
        Paint()
          ..color = look.animal == AvatarAnimal.panda ? _ink : Colors.white,
      );
    }

    // Cheeks.
    for (final dx in [-0.19, 0.19]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: p(0.5 + dx, 0.67),
          width: s * 0.1,
          height: s * 0.06,
        ),
        Paint()..color = _blush,
      );
    }

    // Nose / beak and mouth.
    if (look.animal == AvatarAnimal.chick) {
      final beak = Path()
        ..moveTo(0.46 * s, 0.63 * s)
        ..lineTo(0.54 * s, 0.63 * s)
        ..lineTo(0.5 * s, 0.69 * s)
        ..close();
      canvas.drawPath(beak, Paint()..color = const Color(0xFFEE8A4B));
    } else {
      final noseColor =
          look.animal == AvatarAnimal.bunny || look.animal == AvatarAnimal.mouse
          ? const Color(0xFFE88A9C)
          : _ink;
      canvas.drawOval(
        Rect.fromCenter(
          center: p(0.5, 0.655),
          width: s * 0.06,
          height: s * 0.04,
        ),
        Paint()..color = noseColor,
      );
      final mouth = Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, s * 0.018)
        ..strokeCap = StrokeCap.round;
      final smile = Path()
        ..moveTo(0.455 * s, 0.69 * s)
        ..quadraticBezierTo(0.4775 * s, 0.715 * s, 0.5 * s, 0.69 * s)
        ..quadraticBezierTo(0.5225 * s, 0.715 * s, 0.545 * s, 0.69 * s);
      canvas.drawPath(smile, mouth);
    }
    canvas.restore();
  }

  static Color _shade(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(CuteAvatarPainter oldDelegate) => oldDelegate.look != look;
}
