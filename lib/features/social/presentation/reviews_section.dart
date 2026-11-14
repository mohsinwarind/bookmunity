import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../../../design/formatters.dart';
import '../data/social_models.dart';
import '../data/social_providers.dart';
import 'friends_screen.dart';
import 'friend_profile_screen.dart';
import 'user_avatar.dart';

/// Ratings and reviews for a book, shared across Bookmunity readers by the
/// book's identity key (ISBN or title|author).
class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({required this.book, super.key});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repository = ref.watch(socialRepositoryProvider);
    if (repository == null || book.bookKey.isEmpty) {
      return const SizedBox.shrink();
    }
    final reviews = ref.watch(reviewsProvider(book.bookKey));
    final me = ref.watch(myProfileProvider).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          'Ratings and reviews',
          trailing: reviews.valueOrNull?.isNotEmpty == true
              ? _Average(reviews: reviews.requireValue)
              : null,
        ),
        reviews.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) =>
              Text(socialErrorMessage(error), style: theme.textTheme.bodySmall),
          data: (items) {
            final mine = items
                .where((review) => review.uid == repository.uid)
                .firstOrNull;
            final others = items
                .where((review) => review.uid != repository.uid)
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (me == null)
                  BrutalCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FriendsScreen()),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.rate_review_outlined),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Choose a username to rate and review books.',
                          ),
                        ),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                  )
                else if (mine == null)
                  BrutalPressable(
                    onPressed: () => _edit(context, ref, me, null),
                    backgroundColor: BrutalColors.yellow,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_outline),
                        SizedBox(width: 8),
                        Text('Rate this book'),
                      ],
                    ),
                  )
                else
                  _ReviewCard(
                    review: mine,
                    mine: true,
                    onEdit: () => _edit(context, ref, me, mine),
                  ),
                const SizedBox(height: 12),
                if (others.isEmpty && mine == null)
                  Text(
                    'No reviews yet. Be the first.',
                    style: theme.textTheme.bodySmall,
                  ),
                for (final review in others)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReviewCard(review: review),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Profile me,
    Review? existing,
  ) async {
    final result = await showModalBottomSheet<_ReviewDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ReviewEditor(existing: existing),
    );
    if (result == null || !context.mounted) return;
    final repository = ref.read(socialRepositoryProvider);
    if (repository == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (result.delete) {
        await repository.deleteReview(book.bookKey);
        return;
      }
      await repository.saveReview(
        me: me,
        bookKey: book.bookKey,
        title: book.title,
        author: book.author,
        rating: result.rating,
        text: result.text,
      );
      if (existing == null) {
        await ref.read(socialActivityProvider).reviewed(book, result.rating);
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(socialErrorMessage(error))),
      );
    }
  }
}

class _Average extends StatelessWidget {
  const _Average({required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    final average =
        reviews.fold<int>(0, (sum, review) => sum + review.rating) /
        reviews.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFE0A526)),
        const SizedBox(width: 2),
        Text(
          '${average.toStringAsFixed(1)} (${reviews.length})',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rating out of 5 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 16,
              color: const Color(0xFFE0A526),
            ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, this.mine = false, this.onEdit});

  final Review review;
  final bool mine;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BrutalCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: mine
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FriendProfileScreen(uid: review.uid),
                        ),
                      ),
                child: UserAvatar(uid: review.uid, size: 34),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mine ? 'Your review' : review.displayName,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              _Stars(rating: review.rating),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Edit review',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                )
              else
                const SizedBox(width: 8),
            ],
          ),
          if (review.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Text(review.text),
            ),
          if (review.updatedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                [
                  if (!mine) '@${review.username}',
                  formatDate(review.updatedAt!),
                ].join(' · '),
                style: theme.textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewDraft {
  const _ReviewDraft({this.rating = 0, this.text = '', this.delete = false});

  final int rating;
  final String text;
  final bool delete;
}

class _ReviewEditor extends StatefulWidget {
  const _ReviewEditor({this.existing});

  final Review? existing;

  @override
  State<_ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<_ReviewEditor> {
  late int _rating = widget.existing?.rating ?? 0;
  late final _text = TextEditingController(text: widget.existing?.text ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'Rate this book' : 'Edit your review',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i star${i == 1 ? '' : 's'}',
                  iconSize: 36,
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFE0A526),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            maxLines: 5,
            minLines: 3,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'What did you think? (optional)',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.existing != null)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: BrutalColors.red,
                  ),
                  onPressed: () =>
                      Navigator.pop(context, const _ReviewDraft(delete: true)),
                  child: const Text('Delete'),
                ),
              const Spacer(),
              BrutalPressable(
                onPressed: _rating == 0
                    ? null
                    : () => Navigator.pop(
                        context,
                        _ReviewDraft(rating: _rating, text: _text.text),
                      ),
                backgroundColor: BrutalColors.blue,
                foregroundColor: Colors.white,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
