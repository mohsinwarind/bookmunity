import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/social_providers.dart';
import 'cute_avatar.dart';

/// A user's uploaded photo if they have one, otherwise their generated
/// cute animal avatar (stable per [uid]).
///
/// Pass [hasPhoto] when the caller already has the profile; otherwise the
/// profile is looked up to find out.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    required this.uid,
    this.size = 40,
    this.hasPhoto,
    super.key,
  });

  final String uid;
  final double size;
  final bool? hasPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showPhoto =
        hasPhoto ??
        ref.watch(profileProvider(uid)).valueOrNull?.hasPhoto ??
        false;
    final Uint8List? photo = showPhoto
        ? ref.watch(profilePhotoProvider(uid)).valueOrNull
        : null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: size >= 64 ? 2 : 1,
        ),
      ),
      child: ClipOval(
        child: photo != null
            ? Image.memory(
                photo,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => CuteAvatar(seed: uid, size: size),
              )
            : CuteAvatar(seed: uid, size: size),
      ),
    );
  }
}
