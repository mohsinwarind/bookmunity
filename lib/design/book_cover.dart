import 'package:flutter/material.dart';

import 'brutal_theme.dart';
import 'cover_image.dart';

/// A book cover: the extracted cover image when there is one, otherwise a
/// calm colour block with the title.
class BookCover extends StatelessWidget {
  const BookCover({
    required this.title,
    required this.coverPath,
    this.width,
    this.height,
    this.shadow = true,
    super.key,
  });

  final String title;
  final String? coverPath;
  final double? width;
  final double? height;
  final bool shadow;

  static Color colorFor(String title) {
    var hash = 0;
    for (final unit in title.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return BrutalColors.accents[hash % BrutalColors.accents.length];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = coverImageProvider(coverPath);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorFor(title),
        borderRadius: BrutalTokens.smallBorderRadius,
        border: Border.all(color: scheme.outline, width: BrutalTokens.borderWidth),
        boxShadow: shadow
            ? [BoxShadow(color: scheme.outline, offset: BrutalTokens.shadowOffset)]
            : null,
        image: image == null
            ? null
            : DecorationImage(image: image, fit: BoxFit.cover),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      padding: image == null ? const EdgeInsets.all(10) : EdgeInsets.zero,
      child: image != null
          ? null
          : Text(
              title,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BrutalColors.ink,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
    );
  }
}
