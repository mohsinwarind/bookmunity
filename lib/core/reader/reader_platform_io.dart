import 'dart:io';

bool get readerSupported =>
    Platform.isAndroid ||
    Platform.isIOS ||
    Platform.isMacOS ||
    Platform.isWindows;
