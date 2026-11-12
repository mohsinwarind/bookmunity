import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/reader/reader_platform.dart';
import '../../../core/reader/reader_server.dart';
import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../../../providers/app_providers.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({required this.book, super.key});

  final Book book;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  ReaderServer? _server;
  InAppWebViewController? _controller;
  String chapter = 'OPENING';
  double progress = 0;
  bool chromeVisible = true;
  String readerTheme = 'light';
  String error = '';
  bool _readerStarted = false;

  @override
  void initState() {
    super.initState();
    _prepareReader();
  }

  Future<void> _prepareReader() async {
    if (!readerSupported || widget.book.filePath.startsWith('web://')) {
      return;
    }
    try {
      final html = await rootBundle.load('assets/reader/reader.html');
      final js = await rootBundle.load('assets/reader/reader.js');
      final css = await rootBundle.load('assets/reader/reader.css');
      final epub = await rootBundle.load('assets/reader/epub.min.js');
      final jszip = await rootBundle.load('assets/reader/jszip.min.js');
      _server = await ReaderServer.start(
        widget.book.filePath,
        assets: {
          '/reader.html': ReaderAsset(
            bytes: html.buffer.asUint8List(),
            contentType: 'text/html',
          ),
          '/reader.js': ReaderAsset(
            bytes: js.buffer.asUint8List(),
            contentType: 'text/javascript',
          ),
          '/reader.css': ReaderAsset(
            bytes: css.buffer.asUint8List(),
            contentType: 'text/css',
          ),
          '/epub.min.js': ReaderAsset(
            bytes: epub.buffer.asUint8List(),
            contentType: 'text/javascript',
          ),
          '/jszip.min.js': ReaderAsset(
            bytes: jszip.buffer.asUint8List(),
            contentType: 'text/javascript',
          ),
        },
      );
      if (!mounted) return;
      setState(() {});
    } catch (exception) {
      if (mounted) setState(() => error = 'READER FAILED TO START: $exception');
    }
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }

  Future<void> _send(String name, [Map<String, dynamic> args = const {}]) {
    return _controller
            ?.evaluateJavascript(
              source:
                  'window.readerCommand(${jsonEncode({'name': name, 'args': args})});',
            )
            .then((_) {}) ??
        Future<void>.value();
  }

  Future<void> _handleEvent(dynamic event) async {
    final map = Map<String, dynamic>.from(event as Map);
    final name = map['event'] as String?;
    final payload = Map<String, dynamic>.from(map['payload'] as Map? ?? {});
    if (!mounted) return;
    switch (name) {
      case 'relocated':
        final nextProgress = (payload['percentage'] as num?)?.toDouble() ?? 0;
        setState(() {
          progress = nextProgress * 100;
          chapter = (payload['chapterTitle'] as String?)?.isNotEmpty == true
              ? payload['chapterTitle'] as String
              : 'SECTION';
        });
        final database = await ref.read(databaseProvider.future);
        await (database.update(
          database.books,
        )..where((book) => book.id.equals(widget.book.id))).write(
          BooksCompanion(
            lastCfi: Value(payload['cfi'] as String?),
            progressPercent: Value(progress.clamp(0, 100)),
            lastOpenedAt: Value(DateTime.now()),
            shelf: const Value('currentlyReading'),
          ),
        );
      case 'selected':
        _showSelectionActions(payload);
      case 'error':
        setState(() => error = 'READER ERROR: ${payload['message']}');
    }
  }

  void _showSelectionActions(Map<String, dynamic> payload) {
    final text = payload['text'] as String? ?? '';
    if (text.trim().isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: [
              Text(text, maxLines: 3, overflow: TextOverflow.ellipsis),
              TextButton(
                onPressed: () async {
                  final database = await ref.read(databaseProvider.future);
                  await database.addHighlight(
                    HighlightsCompanion.insert(
                      bookId: widget.book.id,
                      cfiRange: payload['cfiRange'] as String? ?? '',
                      selectedText: text,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('HIGHLIGHT'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!readerSupported || widget.book.filePath.startsWith('web://')) {
      return _unsupportedScreen();
    }
    if (error.isNotEmpty) {
      return Scaffold(
        appBar: BrutalAppBar(title: widget.book.title),
        body: Center(
          child: BrutalCard(
            backgroundColor: BrutalColors.red,
            child: Text(error),
          ),
        ),
      );
    }
    if (_server == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: readerTheme == 'dark'
          ? BrutalColors.ink
          : BrutalColors.paper,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(
                    _server!.url.replace(path: '/reader.html').toString(),
                  ),
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  disableContextMenu: true,
                  verticalScrollBarEnabled: true,
                  horizontalScrollBarEnabled: false,
                  disableVerticalScroll: false,
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;
                  controller.addJavaScriptHandler(
                    handlerName: 'readerEvent',
                    callback: (args) => _handleEvent(args.first),
                  );
                },
                onLoadStop: (controller, _) async {
                  if (_readerStarted) return;
                  _readerStarted = true;
                  await controller.evaluateJavascript(
                    source:
                        'window.startReader(${jsonEncode(_server!.url.toString())}, ${jsonEncode(widget.book.lastCfi)});',
                  );
                },
                onConsoleMessage: (controller, message) {
                  if (message.messageLevel == ConsoleMessageLevel.ERROR &&
                      mounted) {
                    setState(() => error = 'READER ERROR: ${message.message}');
                  }
                },
                onReceivedError: (controller, request, receivedError) {
                  if (mounted) {
                    setState(
                      () => error =
                          'READER LOAD FAILED: ${receivedError.description}',
                    );
                  }
                },
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: GestureDetector(
                onTap: () => setState(() => chromeVisible = !chromeVisible),
                child: Text(
                  '$chapter  ${progress.round()}%',
                  style: const TextStyle(
                    color: BrutalColors.ink,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (chromeVisible)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: BrutalAppBar(
                  title: widget.book.title,
                  actions: [
                    IconButton(
                      tooltip: 'PREVIOUS PAGE',
                      onPressed: () => _send('prev'),
                      icon: const Text('<'),
                    ),
                    IconButton(
                      tooltip: 'NEXT PAGE',
                      onPressed: () => _send('next'),
                      icon: const Text('>'),
                    ),
                    IconButton(
                      tooltip: 'TOGGLE READER THEME',
                      onPressed: () {
                        final next = readerTheme == 'light' ? 'dark' : 'light';
                        setState(() => readerTheme = next);
                        _send('setTheme', {'theme': next});
                      },
                      icon: const Text('THEME'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _unsupportedScreen() {
    return Scaffold(
      appBar: BrutalAppBar(title: widget.book.title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BrutalCard(
            backgroundColor: BrutalColors.yellow,
            child: Text(
              'READER NEEDS ANDROID OR IOS.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
