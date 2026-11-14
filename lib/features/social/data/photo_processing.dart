import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Edge length of stored profile photos.
const profilePhotoSize = 256;

/// Centre-crops [input] to a square, scales it to [size] and re-encodes it
/// as a JPEG small enough for a Firestore document (~20-40 KB).
/// Returns null when the bytes are not a decodable image.
Uint8List? squareProfileJpeg(Uint8List input, {int size = profilePhotoSize}) {
  final decoded = img.decodeImage(input);
  if (decoded == null) return null;
  final upright = img.bakeOrientation(decoded);
  final square = img.copyResizeCropSquare(
    upright,
    size: size,
    interpolation: img.Interpolation.average,
  );
  return img.encodeJpg(square, quality: 80);
}

/// [squareProfileJpeg] off the UI thread.
Future<Uint8List?> prepareProfilePhoto(Uint8List input) =>
    compute(squareProfileJpeg, input);
