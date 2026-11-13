import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/db/app_database.dart';
import '../../../core/reader/reader_platform.dart';
import '../../../core/reader/reader_server.dart';
import '../../../design/brutal_widgets.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../achievements/data/achievement_service.dart';
import '../../dictionary/dictionary_view.dart';
import '../../social/data/social_providers.dart';
import '../data/reader_bridge.dart';
import '../domain/reader_palette.dart';
import '../domain/reading_session_tracker.dart';
import 'widgets/reader_navigator_sheet.dart';
import 'widgets/reader_search_sheet.dart';
import 'widgets/reader_settings_sheet.dart';
import 'widgets/selection_panels.dart';

/// Must match the #viewer insets in assets/reader/reader.css / reader.js.
const _topStrip = 40.0;
const _bottomStrip = 36.0;

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({required this.book, this.initialCfi, super.key});

  final Book book;

  /// Opens at this position instead of the saved one (e.g. a highlight).
  final String? initialCfi;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  ReaderServer? _server;
  InAppWebViewController? _controller;
  AppDatabase? _database;
  AchievementService? _achievements;
  List<BadgeUnlockListener> _badgeListeners = const [];
  late Book _book = widget.book;

  bool _started = false;
  bool _ready = false;
  bool _locationsReady = false;
  String? _fatalError;

  ReaderLocation? _location;
  List<TocItem> _toc = const [];
  ReaderSelection? _selection;
  bool _chromeVisible = false;
  double? _scrubValue;

  final Map<int, Highlight> _highlights = {};
  StreamSubscription<List<Bookmark>>? _bookmarkSubscription;
  List<Bookmark> _bookmarks = const [];

  final _tracker = ReadingSessionTracker();
  final _search = ReaderSearchController();
  Timer? _saveTimer;
  bool _finishedAnnounced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _finishedAnnounced = widget.book.isFinished;
    _prepare();
  }

  bool get _supported =>
      readerSupported && !widget.book.filePath.startsWith('web://');

  Future<void> _prepare() async {
    if (!_supported) return;
    try {
      final database = await ref.read(databaseProvider.future);
      _database = database;
      _achievements = await ref.read(achievementServiceProvider.future);
      _badgeListeners = ref.read(badgeUnlockListenersProvider);
      // The Book passed in may be a stale snapshot from the previous screen;
      // reopen from the database so the saved position is current.
      final fresh = await (database.select(
        database.books,
      )..where((book) => book.id.equals(widget.book.id))).getSingleOrNull();
      if (fresh != null) _book = fresh;
      if (_book.lastOpenedAt == null && _book.progressPercent == 0) {
        unawaited(ref.read(socialActivityProvider).bookStarted(_book));
      }
      for (final highlight in await database.getHighlights(_book.id)) {
        _highlights[highlight.id] = highlight;
      }
      _bookmarkSubscription = database.watchBookmarks(_book.id).listen((
        items,
      ) {
        _bookmarks = items;
        _send('setBookmarks', {
          'cfis': [for (final bookmark in items) bookmark.cfi],
        });
      });

      final assets = <String, (String, String)>{
        '/reader.html': ('assets/reader/reader.html', 'text/html'),
        '/reader.js': ('assets/reader/reader.js', 'text/javascript'),
        '/reader.css': ('assets/reader/reader.css', 'text/css'),
        '/epub.min.js': ('assets/reader/epub.min.js', 'text/javascript'),
        '/jszip.min.js': ('assets/reader/jszip.min.js', 'text/javascript'),
      };
      final loaded = <String, ReaderAsset>{};
      for (final entry in assets.entries) {
        final data = await rootBundle.load(entry.value.$1);
        loaded[entry.key] = ReaderAsset(
          bytes: data.buffer.asUint8List(),
          contentType: entry.value.$2,
        );
      }
      _server = await ReaderServer.start(_book.filePath, assets: loaded);
      _applyDeviceSettings(ref.read(settingsProvider));
      if (mounted) setState(() {});
    } catch (exception) {
      if (mounted) {
        setState(() => _fatalError = 'The reader could not start: $exception');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _bookmarkSubscription?.cancel();
    _persistPosition();
    _persistSession();
    final achievements = _achievements;
    if (achievements != null) {
      unawaited(checkAchievementsWith(achievements, _badgeListeners));
    }
    _search.dispose();
    unawaited(WakelockPlus.disable());
    SystemChrome.setPreferredOrientations(const []);
    _server?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_ready) {
          _tracker.resume(DateTime.now(), percent: _percent);
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Save eagerly: the OS may kill a backgrounded app without warning.
        _persistPosition();
        _persistSession();
    }
  }

  // ------------------------------------------------------------- bridge

  Future<void> _send(String name, [Map<String, Object?> args = const {}]) async {
    final controller = _controller;
    if (controller == null || !_started) return;
    try {
      await controller.evaluateJavascript(
        source: ReaderCommands.command(name, args),
      );
    } catch (error) {
      debugPrint('Reader command $name failed: $error');
    }
  }

  Map<String, Object?> _highlightArgs(Highlight highlight) => {
    'id': highlight.id,
    'cfiRange': highlight.cfiRange,
    'color': highlight.color,
  };

  Future<void> _start(InAppWebViewController controller) async {
    if (_started || _server == null) return;
    _started = true;
    await controller.evaluateJavascript(
      source: ReaderCommands.start(
        url: _server!.url.toString(),
        cfi: widget.initialCfi ?? _book.lastCfi,
        settings: ref.read(settingsProvider).toReaderJson(),
        highlights: [for (final item in _highlights.values) _highlightArgs(item)],
        bookmarks: [for (final bookmark in _bookmarks) bookmark.cfi],
        locations: _book.locationsJson,
      ),
    );
  }

  void _handleEvent(Object? raw) {
    if (!mounted) return;
    final event = ReaderEvent.fromRaw(raw);
    final payload = event.payload;
    switch (event.name) {
      case 'ready':
        setState(() => _ready = true);
        _tracker.resume(DateTime.now(), percent: _percent);
      case 'relocated':
        final location = ReaderLocation.fromJson(payload);
        setState(() {
          _location = location;
          if (location.percentage != null) _locationsReady = true;
        });
        _tracker.signal(DateTime.now(), percent: _percent);
        _schedulePositionSave();
        if (location.reachedEnd && !_finishedAnnounced) {
          _finishedAnnounced = true;
          _persistPosition();
          _onFinished();
        }
      case 'locationsReady':
        setState(() => _locationsReady = true);
        final locations = payload['locations'];
        if (locations is String && locations.isNotEmpty) {
          _database?.saveLocations(_book.id, locations);
        }
      case 'toc':
        setState(() => _toc = TocItem.listFrom(payload));
      case 'selected':
        final selection = ReaderSelection.fromJson(payload);
        if (selection.text.isEmpty) return;
        setState(() {
          _selection = selection;
          _chromeVisible = false;
        });
      case 'selectionCleared':
        if (_selection != null) setState(() => _selection = null);
      case 'highlightTapped':
        final id = (payload['id'] as num?)?.toInt();
        final highlight = id == null ? null : _highlights[id];
        if (highlight != null) _openHighlight(highlight);
      case 'tap':
        if (_selection != null) {
          _clearSelection();
        } else {
          setState(() => _chromeVisible = !_chromeVisible);
        }
      case 'activity':
        _tracker.signal(DateTime.now());
      case 'edgeReached':
        if (payload['end'] == true) _showEndOfBook();
      case 'searchProgress':
        _search.progress(payload);
      case 'searchResults':
        _search.finished(payload);
      case 'error':
        setState(
          () => _fatalError =
              (payload['message'] as String?) ?? 'This book could not be opened.',
        );
      case 'jsError':
        debugPrint('Reader script: ${payload['message']}');
    }
  }

  // ----------------------------------------------------------- progress

  double get _percent {
    final percentage = _location?.percentage;
    return percentage == null ? _book.progressPercent : percentage * 100;
  }

  void _schedulePositionSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _persistPosition);
  }

  void _persistPosition() {
    _saveTimer?.cancel();
    final location = _location;
    final database = _database;
    if (location == null || database == null || location.cfi.isEmpty) return;
    unawaited(
      database.saveReadingPosition(
        bookId: _book.id,
        cfi: location.cfi,
        percent: _percent,
        reachedEnd: location.reachedEnd,
      ),
    );
  }

  void _persistSession() {
    final session = _tracker.finish(DateTime.now());
    final database = _database;
    if (session == null || database == null) return;
    unawaited(
      database.addReadingSession(
        ReadingSessionsCompanion.insert(
          bookId: _book.id,
          startedAt: session.startedAt,
          endedAt: session.endedAt,
          durationSeconds: session.duration.inSeconds,
          startPercent: Value(session.startPercent),
          endPercent: Value(session.endPercent),
        ),
      ),
    );
  }

  Future<void> _onFinished() async {
    // Let the save land before badges are evaluated.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await checkAchievements(ref);
    if (!mounted) return;
    await ref.read(socialActivityProvider).bookFinished(_book);
  }

  void _showEndOfBook() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _book.isFinished || _finishedAnnounced
                ? 'You finished “${_book.title}”.'
                : 'End of book.',
          ),
        ),
      );
  }

  // --------------------------------------------------------- settings

  void _applyDeviceSettings(ReaderSettings settings) {
    unawaited(
      settings.keepScreenAwake ? WakelockPlus.enable() : WakelockPlus.disable(),
    );
    SystemChrome.setPreferredOrientations(switch (settings.orientation) {
      ReaderOrientation.auto => const [],
      ReaderOrientation.portrait => const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      ReaderOrientation.landscape => const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    });
  }

  // -------------------------------------------------------- selection

  void _clearSelection() {
    setState(() => _selection = null);
    _send('clearSelection');
  }

  Future<Highlight?> _createHighlight(
    ReaderSelection selection, {
    int color = 0,
    String? note,
  }) async {
    final database = _database;
    if (database == null) return null;
    final now = DateTime.now();
    final id = await database.addHighlight(
      HighlightsCompanion.insert(
        bookId: _book.id,
        cfiRange: selection.cfiRange,
        selectedText: selection.text,
        color: Value(color),
        note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
        chapterTitle: Value(
          selection.chapterTitle.isEmpty ? null : selection.chapterTitle,
        ),
        createdAt: now,
        updatedAt: now,
      ),
    );
    final highlight = Highlight(
      id: id,
      bookId: _book.id,
      cfiRange: selection.cfiRange,
      selectedText: selection.text,
      color: color,
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      chapterTitle: selection.chapterTitle,
      createdAt: now,
      updatedAt: now,
    );
    _highlights[id] = highlight;
    await _send('addHighlight', _highlightArgs(highlight));
    if (mounted) unawaited(checkAchievements(ref));
    return highlight;
  }

  Future<void> _highlightSelection(int color) async {
    final selection = _selection;
    if (selection == null) return;
    _clearSelection();
    await _createHighlight(selection, color: color);
  }

  Future<void> _noteOnSelection() async {
    final selection = _selection;
    if (selection == null) return;
    final note = await showNoteDialog(context, quote: selection.text);
    _clearSelection();
    if (note == null) return;
    await _createHighlight(selection, note: note);
  }

  void _copySelection() {
    final selection = _selection;
    if (selection == null) return;
    Clipboard.setData(ClipboardData(text: selection.text));
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Copied to clipboard.'),
      ),
    );
  }

  Future<void> _openHighlight(Highlight highlight) async {
    final database = _database;
    if (database == null) return;
    await showHighlightSheet(
      context,
      highlight: highlight,
      onColor: (color) async {
        await database.updateHighlightColor(highlight.id, color);
        final updated = highlight.copyWith(color: color);
        _highlights[highlight.id] = updated;
        await _send('addHighlight', _highlightArgs(updated));
      },
      onEditNote: () async {
        final note = await showNoteDialog(
          context,
          initial: highlight.note ?? '',
          quote: highlight.selectedText,
        );
        if (note == null) return;
        await database.updateHighlightNote(highlight.id, note);
        _highlights[highlight.id] = highlight.copyWith(
          note: Value(note.trim().isEmpty ? null : note.trim()),
        );
      },
      onDelete: () async {
        await database.deleteHighlight(highlight.id);
        _highlights.remove(highlight.id);
        await _send('removeHighlight', {'cfiRange': highlight.cfiRange});
      },
      onDefine: (word) => showDictionarySheet(context, word),
    );
  }

  // ------------------------------------------------------- navigation

  Future<void> _toggleBookmark() async {
    final database = _database;
    final location = _location;
    if (database == null || location == null || location.cfi.isEmpty) return;
    if (location.bookmarked) {
      for (final bookmark in _bookmarks) {
        if (location.bookmarkCfis.contains(bookmark.cfi)) {
          await database.deleteBookmark(bookmark.id);
        }
      }
    } else {
      await database.addBookmark(
        BookmarksCompanion.insert(
          bookId: _book.id,
          cfi: location.cfi,
          label: Value(
            location.chapterTitle.isEmpty ? null : location.chapterTitle,
          ),
          percent: Value(_percent),
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _openNavigator({int tab = 0}) async {
    final database = _database;
    if (database == null) return;
    final target = await showReaderNavigator(
      context,
      toc: _toc,
      currentHref: _location?.href ?? '',
      bookmarks: database.watchBookmarks(_book.id),
      highlights: database.watchHighlights(_book.id),
      onDeleteBookmark: (bookmark) => database.deleteBookmark(bookmark.id),
      initialTab: tab,
    );
    switch (target) {
      case HrefTarget(:final href):
        await _send('display', {'href': href});
      case CfiTarget(:final cfi):
        await _send('display', {'cfi': cfi});
      case null:
        break;
    }
    if (mounted && target != null) setState(() => _chromeVisible = false);
  }

  Future<void> _openSearch([String? query]) async {
    final cfi = await showReaderSearch(
      context,
      controller: _search,
      initialQuery: query,
      onSearch: (value) => _send('search', {'query': value}),
    );
    if (cfi != null) {
      await _send('display', {'cfi': cfi, 'mark': true});
      if (mounted) setState(() => _chromeVisible = false);
    }
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    ref.listen<ReaderSettings>(settingsProvider, (previous, next) {
      if (previous == next) return;
      _applyDeviceSettings(next);
      _send('updateSettings', {'settings': next.toReaderJson()});
    });

    if (!_supported) return _unsupported(context);
    final settings = ref.watch(settingsProvider);
    final palette = ReaderPalette.of(settings.theme);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: PopScope(
        canPop: _selection == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _selection != null) _clearSelection();
        },
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surfaceContainerLow: palette.panel,
              onSurface: palette.foreground,
              onSurfaceVariant: palette.muted,
              brightness: palette.isDark ? Brightness.dark : Brightness.light,
            ),
            iconTheme: IconThemeData(color: palette.foreground),
          ),
          child: Scaffold(
            backgroundColor: palette.background,
            body: SafeArea(
              child: _fatalError != null
                  ? _errorView(palette)
                  : _server == null
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // A platform view laid out at zero size is what threw
                        // "Cannot hit test a render box with no size".
                        if (constraints.biggest.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Stack(
                          children: [
                            Positioned.fill(child: _webView()),
                            ..._statusStrips(palette),
                            if (!_ready)
                              Positioned.fill(
                                child: ColoredBox(
                                  color: palette.background,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                            ..._chrome(palette),
                            if (_selection != null)
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: SelectionToolbar(
                                  selection: _selection!,
                                  onHighlight: _highlightSelection,
                                  onNote: _noteOnSelection,
                                  onCopy: _copySelection,
                                  onSearch: () {
                                    final text = _selection!.text;
                                    _clearSelection();
                                    _openSearch(text);
                                  },
                                  onDefine: (word) =>
                                      showDictionarySheet(context, word),
                                  onClose: _clearSelection,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(_server!.url.replace(path: '/reader.html').toString()),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: true,
        supportZoom: false,
        builtInZoomControls: false,
        displayZoomControls: false,
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,
        overScrollMode: OverScrollMode.NEVER,
        disableHorizontalScroll: false,
        disableVerticalScroll: false,
        useHybridComposition: true,
        allowFileAccess: false,
        allowContentAccess: false,
        mediaPlaybackRequiresUserGesture: true,
        // Selection actions are drawn in Flutter instead.
        disableContextMenu: true,
      ),
      contextMenu: ContextMenu(
        settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
      ),
      shouldOverrideUrlLoading: (controller, action) async {
        final url = action.request.url;
        final local = url != null && url.host == '127.0.0.1';
        // External links in books must not navigate the reader away.
        return local
            ? NavigationActionPolicy.ALLOW
            : NavigationActionPolicy.CANCEL;
      },
      onWebViewCreated: (controller) {
        _controller = controller;
        controller.addJavaScriptHandler(
          handlerName: 'readerEvent',
          callback: (args) {
            if (args.isNotEmpty) _handleEvent(args.first);
            return null;
          },
        );
      },
      onLoadStop: (controller, _) => _start(controller),
      onConsoleMessage: (controller, message) {
        // Book stylesheets and scripts routinely log errors; they must never
        // take the reader down. Fatal problems arrive as an `error` event.
        if (message.messageLevel == ConsoleMessageLevel.ERROR) {
          debugPrint('Reader console: ${message.message}');
        }
      },
      onReceivedError: (controller, request, error) {
        if (request.isForMainFrame == true && mounted) {
          setState(
            () => _fatalError = 'The reader failed to load: ${error.description}',
          );
        }
      },
    );
  }

  List<Widget> _statusStrips(ReaderPalette palette) {
    final location = _location;
    final style = TextStyle(
      color: palette.muted,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final chapter = location?.chapterTitle.isNotEmpty == true
        ? location!.chapterTitle
        : _book.title;
    final pagesLeft = location?.pagesLeftInChapter;
    final percent = location?.percentage;
    final left = pagesLeft == null
        ? ''
        : pagesLeft == 0
        ? 'Last page in chapter'
        : '$pagesLeft ${pagesLeft == 1 ? 'page' : 'pages'} left in chapter';
    final right = percent == null
        ? (_ready ? 'Calculating…' : '')
        : '${(percent * 100).floor()}%';
    return [
      Positioned(
        left: 56,
        right: 56,
        top: 0,
        height: _topStrip,
        child: IgnorePointer(
          child: Center(
            child: Text(
              chapter,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      ),
      if (location?.bookmarked == true)
        Positioned(
          right: 16,
          top: 0,
          child: IgnorePointer(
            child: Icon(
              Icons.bookmark,
              color: const Color(0xFFD46A5F),
              size: 28,
              semanticLabel: 'Bookmarked page',
            ),
          ),
        ),
      Positioned(
        left: 20,
        right: 20,
        bottom: 0,
        height: _bottomStrip,
        child: IgnorePointer(
          child: Row(
            children: [
              Expanded(child: Text(left, style: style)),
              Text(right, style: style),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _chrome(ReaderPalette palette) {
    final visible = _chromeVisible && _selection == null;
    final location = _location;
    final percent = _scrubValue ?? location?.percentage ?? 0;
    return [
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 180),
            offset: visible ? Offset.zero : const Offset(0, -1),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: visible ? 1 : 0,
              child: Material(
                color: palette.panel,
                elevation: 2,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const BackButton(),
                      Expanded(
                        child: Text(
                          _book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: palette.foreground),
                        ),
                      ),
                      IconButton(
                        tooltip: location?.bookmarked == true
                            ? 'Remove bookmark'
                            : 'Bookmark this page',
                        onPressed: _ready ? _toggleBookmark : null,
                        icon: Icon(
                          location?.bookmarked == true
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Search in book',
                        onPressed: _ready ? () => _openSearch() : null,
                        icon: const Icon(Icons.search),
                      ),
                      IconButton(
                        tooltip: 'Contents, bookmarks and highlights',
                        onPressed: _ready ? () => _openNavigator() : null,
                        icon: const Icon(Icons.toc),
                      ),
                      IconButton(
                        tooltip: 'Reading settings',
                        onPressed: () => showReaderSettingsSheet(context),
                        icon: const Icon(Icons.text_fields),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 180),
            offset: visible ? Offset.zero : const Offset(0, 1),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: visible ? 1 : 0,
              child: Material(
                color: palette.panel,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                location?.chapterTitle.isNotEmpty == true
                                    ? location!.chapterTitle
                                    : ' ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: palette.muted),
                              ),
                            ),
                            Text(
                              _locationsReady
                                  ? location?.location != null &&
                                            location?.totalLocations != null
                                        ? '${(percent * 100).floor()}% · Location ${location!.location! + 1} of ${location.totalLocations}'
                                        : '${(percent * 100).floor()}%'
                                  : 'Calculating pages…',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.muted),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Previous chapter',
                            onPressed: _ready
                                ? () => _send('prevChapter')
                                : null,
                            icon: const Icon(Icons.skip_previous_outlined),
                          ),
                          Expanded(
                            child: Slider(
                              value: percent.clamp(0.0, 1.0),
                              onChanged: _locationsReady
                                  ? (value) =>
                                        setState(() => _scrubValue = value)
                                  : null,
                              onChangeEnd: (value) {
                                setState(() => _scrubValue = null);
                                _send('display', {'percentage': value});
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Next chapter',
                            onPressed: _ready
                                ? () => _send('nextChapter')
                                : null,
                            icon: const Icon(Icons.skip_next_outlined),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: _ready ? () => _send('prev') : null,
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Previous'),
                          ),
                          TextButton.icon(
                            onPressed: _ready
                                ? () => _openNavigator(tab: 2)
                                : null,
                            icon: const Icon(Icons.format_quote_outlined),
                            label: const Text('Notes'),
                          ),
                          TextButton.icon(
                            onPressed: _ready ? () => _send('next') : null,
                            icon: const Icon(Icons.chevron_right),
                            iconAlignment: IconAlignment.end,
                            label: const Text('Next'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _errorView(ReaderPalette palette) {
    return Column(
      children: [
        Align(alignment: Alignment.centerLeft, child: const BackButton()),
        Expanded(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'This book could not be opened',
            message: _fatalError,
          ),
        ),
      ],
    );
  }

  Widget _unsupported(BuildContext context) {
    return Scaffold(
      appBar: BrutalAppBar(title: widget.book.title),
      body: const EmptyState(
        icon: Icons.phone_android,
        title: 'Reading needs the mobile app',
        message: 'Open Bookmunity on Android or iOS to read this book.',
      ),
    );
  }
}
