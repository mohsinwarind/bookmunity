import 'package:flutter/material.dart';

import '../../data/reader_bridge.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.searching = false,
    this.scanned = 0,
    this.total = 0,
    this.truncated = false,
  });

  final String query;
  final List<SearchResult> results;
  final bool searching;
  final int scanned;
  final int total;
  final bool truncated;
}

/// Bridges search events from the reader into the sheet. Kept on the reader
/// screen so results survive closing and reopening the sheet.
class ReaderSearchController extends ValueNotifier<SearchState> {
  ReaderSearchController() : super(const SearchState());

  void started(String query) =>
      value = SearchState(query: query, searching: true);

  void progress(Map<String, dynamic> payload) {
    if (payload['query'] != value.query) return;
    value = SearchState(
      query: value.query,
      results: value.results,
      searching: true,
      scanned: (payload['scanned'] as num?)?.toInt() ?? 0,
      total: (payload['total'] as num?)?.toInt() ?? 0,
    );
  }

  void finished(Map<String, dynamic> payload) {
    if (payload['query'] != value.query) return;
    value = SearchState(
      query: value.query,
      results: SearchResult.listFrom(payload),
      truncated: payload['truncated'] == true,
    );
  }
}

/// Returns the CFI of the chosen result.
Future<String?> showReaderSearch(
  BuildContext context, {
  required ReaderSearchController controller,
  required ValueChanged<String> onSearch,
  String? initialQuery,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: _SearchSheet(
          controller: controller,
          onSearch: onSearch,
          initialQuery: initialQuery,
        ),
      ),
    ),
  );
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({
    required this.controller,
    required this.onSearch,
    this.initialQuery,
  });

  final ReaderSearchController controller;
  final ValueChanged<String> onSearch;
  final String? initialQuery;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: widget.initialQuery ?? widget.controller.value.query,
    );
    final initial = widget.initialQuery;
    if (initial != null &&
        initial.trim().length >= 2 &&
        initial.trim() != widget.controller.value.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _submit(initial));
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final query = value.trim();
    if (query.length < 2) return;
    widget.controller.started(query);
    widget.onSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _text,
            autofocus: widget.initialQuery == null,
            textInputAction: TextInputAction.search,
            onSubmitted: _submit,
            decoration: InputDecoration(
              hintText: 'Search in this book',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _submit(_text.text),
              ),
            ),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<SearchState>(
            valueListenable: widget.controller,
            builder: (context, state, _) {
              if (state.query.isEmpty) {
                return Center(
                  child: Text(
                    'Type at least two characters.',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }
              return Column(
                children: [
                  if (state.searching)
                    LinearProgressIndicator(
                      value: state.total == 0
                          ? null
                          : state.scanned / state.total,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        state.searching
                            ? 'Searching…'
                            : state.results.isEmpty
                            ? 'No matches for “${state.query}”.'
                            : '${state.results.length}${state.truncated ? '+' : ''} matches',
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: state.results.length,
                      separatorBuilder: (_, _) =>
                          const Divider(indent: 20, endIndent: 20),
                      itemBuilder: (context, index) {
                        final result = state.results[index];
                        return ListTile(
                          title: _Excerpt(
                            excerpt: result.excerpt,
                            query: state.query,
                          ),
                          subtitle: result.chapterTitle.isEmpty
                              ? null
                              : Text(result.chapterTitle),
                          onTap: () => Navigator.pop(context, result.cfi),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Excerpt extends StatelessWidget {
  const _Excerpt({required this.excerpt, required this.query});

  final String excerpt;
  final String query;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!;
    final lower = excerpt.toLowerCase();
    final needle = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = lower.indexOf(needle, start);
      if (index < 0 || needle.isEmpty) {
        spans.add(TextSpan(text: excerpt.substring(start)));
        break;
      }
      spans
        ..add(TextSpan(text: excerpt.substring(start, index)))
        ..add(
          TextSpan(
            text: excerpt.substring(index, index + needle.length),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              backgroundColor: Color(0x55F2D16B),
            ),
          ),
        );
      start = index + needle.length;
    }
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
