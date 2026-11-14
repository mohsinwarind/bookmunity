import 'package:flutter/material.dart';

import '../../../../core/db/app_database.dart';
import '../../data/reader_bridge.dart';
import '../../domain/reader_palette.dart';
import '../../../../design/formatters.dart';

/// Where the navigator should jump to.
sealed class NavigatorTarget {
  const NavigatorTarget();
}

class HrefTarget extends NavigatorTarget {
  const HrefTarget(this.href);
  final String href;
}

class CfiTarget extends NavigatorTarget {
  const CfiTarget(this.cfi);
  final String cfi;
}

String _base(String href) {
  final clean = href.split('#').first;
  return clean.substring(clean.lastIndexOf('/') + 1);
}

/// Contents / bookmarks / highlights in one sheet, like most e-readers.
Future<NavigatorTarget?> showReaderNavigator(
  BuildContext context, {
  required List<TocItem> toc,
  required String currentHref,
  required Stream<List<Bookmark>> bookmarks,
  required Stream<List<Highlight>> highlights,
  required ValueChanged<Bookmark> onDeleteBookmark,
  int initialTab = 0,
}) {
  return showModalBottomSheet<NavigatorTarget>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => DefaultTabController(
        length: 3,
        initialIndex: initialTab,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Contents'),
                Tab(text: 'Bookmarks'),
                Tab(text: 'Highlights'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ContentsList(
                    toc: toc,
                    currentHref: currentHref,
                    controller: controller,
                  ),
                  StreamBuilder<List<Bookmark>>(
                    stream: bookmarks,
                    builder: (context, snapshot) => _BookmarksList(
                      bookmarks: snapshot.data,
                      onDelete: onDeleteBookmark,
                    ),
                  ),
                  StreamBuilder<List<Highlight>>(
                    stream: highlights,
                    builder: (context, snapshot) =>
                        _HighlightsList(highlights: snapshot.data),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ContentsList extends StatelessWidget {
  const _ContentsList({
    required this.toc,
    required this.currentHref,
    required this.controller,
  });

  final List<TocItem> toc;
  final String currentHref;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (toc.isEmpty) {
      return const _Empty(
        icon: Icons.list_alt,
        text: 'This book has no table of contents.',
      );
    }
    final theme = Theme.of(context);
    final current = _base(currentHref);
    // The current chapter is the last TOC entry pointing at the current file.
    final currentIndex = toc.lastIndexWhere(
      (item) => _base(item.href) == current,
    );
    return ListView.builder(
      controller: controller,
      itemCount: toc.length,
      itemBuilder: (context, index) {
        final item = toc[index];
        final selected = index == currentIndex;
        return ListTile(
          dense: true,
          selected: selected,
          selectedColor: theme.colorScheme.primary,
          contentPadding: EdgeInsets.only(
            left: 20.0 + item.depth * 16,
            right: 20,
          ),
          title: Text(
            item.label,
            style: TextStyle(
              fontWeight: selected || item.depth == 0
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
          trailing: selected ? const Icon(Icons.chevron_left, size: 18) : null,
          onTap: () => Navigator.pop(context, HrefTarget(item.href)),
        );
      },
    );
  }
}

class _BookmarksList extends StatelessWidget {
  const _BookmarksList({required this.bookmarks, required this.onDelete});

  final List<Bookmark>? bookmarks;
  final ValueChanged<Bookmark> onDelete;

  @override
  Widget build(BuildContext context) {
    final items = bookmarks;
    if (items == null) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return const _Empty(
        icon: Icons.bookmark_border,
        text:
            'No bookmarks yet. Tap the bookmark icon while reading to add one.',
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(indent: 20, endIndent: 20),
      itemBuilder: (context, index) {
        final bookmark = items[index];
        return ListTile(
          leading: const Icon(Icons.bookmark, color: Color(0xFFD46A5F)),
          title: Text(
            bookmark.label?.isNotEmpty == true ? bookmark.label! : 'Bookmark',
          ),
          subtitle: Text(
            '${bookmark.percent.round()}% · ${formatDate(bookmark.createdAt)}',
          ),
          trailing: IconButton(
            tooltip: 'Remove bookmark',
            icon: const Icon(Icons.close),
            onPressed: () => onDelete(bookmark),
          ),
          onTap: () => Navigator.pop(context, CfiTarget(bookmark.cfi)),
        );
      },
    );
  }
}

class _HighlightsList extends StatelessWidget {
  const _HighlightsList({required this.highlights});

  final List<Highlight>? highlights;

  @override
  Widget build(BuildContext context) {
    final items = highlights;
    if (items == null) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return const _Empty(
        icon: Icons.format_quote_outlined,
        text: 'No highlights yet. Press and hold on text to highlight it.',
      );
    }
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(indent: 20, endIndent: 20),
      itemBuilder: (context, index) {
        final highlight = items[index];
        return InkWell(
          onTap: () => Navigator.pop(context, CfiTarget(highlight.cfiRange)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    color: highlightSwatch(highlight.color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        highlight.selectedText,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'serif',
                        ),
                      ),
                      if (highlight.note?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            highlight.note!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (highlight.chapterTitle?.isNotEmpty == true)
                            highlight.chapterTitle!,
                          formatDate(highlight.createdAt),
                        ].join(' · '),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
