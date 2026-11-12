# Bookmunity

Bookmunity is a local-first EPUB reader with Firebase email/password
authentication, a Drift library, highlights, notes, reading statistics, and a
neo-brutalist interface.

## Run the app

```bash
flutter pub get
dart run build_runner build
flutter run
```

The full EPUB reader uses `flutter_inappwebview` and is intended for Android,
iOS, macOS, or Windows. Linux and web builds deliberately show
`READER NEEDS ANDROID OR IOS.` instead of pretending that the native reader is
available.

For Android:

1. Install Android Studio and an Android SDK.
2. Create an emulator with an API level supported by the installed Flutter SDK.
3. Start the emulator.
4. Run `flutter devices`, then `flutter run -d <android-device-id>`.

The native reader serves the imported EPUB through a loopback HTTP server on
`127.0.0.1` with byte-range support. Android cleartext access is restricted to
that loopback host in `android/app/src/main/res/xml/network_security_config.xml`.

## Firebase

Firebase Auth configuration is generated in `lib/firebase_options.dart`.
Enable Email/Password in the Firebase Console before testing login and
signup. Firestore social features require a Firestore database to be selected
and configured before the social repository is enabled.

## Validation

```bash
flutter analyze
flutter test
```

Metadata tests generate valid EPUB archives in memory and cover EPUB2, EPUB3,
namespaced metadata, title fallbacks, author fallbacks, and cover resolution.
