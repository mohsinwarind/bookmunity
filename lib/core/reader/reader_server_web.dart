import 'reader_asset.dart';

class ReaderServer {
  ReaderServer._();

  Uri get url => Uri();

  static Future<ReaderServer> start(
    String bookPath, {
    required Map<String, ReaderAsset> assets,
  }) {
    throw UnsupportedError('EPUB reader server is unavailable on web.');
  }

  Future<void> close() async {}
}
