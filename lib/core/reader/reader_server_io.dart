import 'dart:io';

import 'reader_asset.dart';

class ReaderServer {
  ReaderServer._(this._server, this.url);

  final HttpServer _server;
  final Uri url;

  static Future<ReaderServer> start(
    String bookPath, {
    required Map<String, ReaderAsset> assets,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.method == 'OPTIONS') {
        request.response.headers
          ..set('Access-Control-Allow-Origin', '*')
          ..set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS')
          ..set('Access-Control-Allow-Headers', 'Range, Content-Type');
        await request.response.close();
        return;
      }
      final asset = assets[request.uri.path];
      if (asset != null) {
        request.response.headers
          ..contentType = ContentType.parse(asset.contentType)
          ..contentLength = asset.bytes.length
          ..set('Access-Control-Allow-Origin', '*');
        if (request.method != 'HEAD') {
          request.response.add(asset.bytes);
        }
        await request.response.close();
        return;
      }

      if (request.uri.path != '/book.epub') {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
        return;
      }

      final file = File(bookPath);
      if (!await file.exists()) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
        return;
      }

      final length = await file.length();
      request.response.headers
        ..contentType = ContentType('application', 'epub+zip')
        ..contentLength = length
        ..set('Access-Control-Allow-Origin', '*')
        ..set('Access-Control-Allow-Headers', 'Range, Content-Type')
        ..set('Accept-Ranges', 'bytes');

      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range == null) {
        if (request.method == 'HEAD') {
          await request.response.close();
          return;
        }
        await request.response.addStream(file.openRead());
        await request.response.close();
        return;
      }

      final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(range);
      if (match == null) {
        request.response
          ..statusCode = HttpStatus.requestedRangeNotSatisfiable
          ..close();
        return;
      }
      final start = int.parse(match.group(1)!);
      final requestedEnd = match.group(2);
      final end = requestedEnd == null || requestedEnd.isEmpty
          ? length - 1
          : int.parse(requestedEnd);
      if (start >= length || end < start) {
        request.response
          ..statusCode = HttpStatus.requestedRangeNotSatisfiable
          ..close();
        return;
      }
      final boundedEnd = end.clamp(start, length - 1);
      request.response
        ..statusCode = HttpStatus.partialContent
        ..contentLength = boundedEnd - start + 1
        ..headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-$boundedEnd/$length',
        );
      await request.response.addStream(file.openRead(start, boundedEnd + 1));
      await request.response.close();
    });
    return ReaderServer._(
      server,
      Uri.parse('http://127.0.0.1:${server.port}/book.epub'),
    );
  }

  Future<void> close() => _server.close(force: true);
}
