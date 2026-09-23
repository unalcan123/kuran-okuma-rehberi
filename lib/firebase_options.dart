// Firebase yapılandırması — `firebase apps:sdkconfig` çıktılarından üretildi
// (proje: kuran-okuma-rehberi). FlutterFire CLI'nin ürettiği dosyayla aynı biçim;
// yeniden üretmek için: flutterfire configure --project=kuran-okuma-rehberi
// Bu değerler gizli değildir; erişimi firestore.rules denetler.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions bu platform için yapılandırılmadı.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBX2tEfNM52YMKkHbrxikz-FMc4AmYGZog',
    appId: '1:773237096966:web:1bc2a2938f48de84f8b987',
    messagingSenderId: '773237096966',
    projectId: 'kuran-okuma-rehberi',
    authDomain: 'kuran-okuma-rehberi.firebaseapp.com',
    storageBucket: 'kuran-okuma-rehberi.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAk_Az_PyDo9yaYrrW_OGMzPA2OJc6KqoY',
    appId: '1:773237096966:android:16f0ff283e7c0c2bf8b987',
    messagingSenderId: '773237096966',
    projectId: 'kuran-okuma-rehberi',
    storageBucket: 'kuran-okuma-rehberi.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDqt5nkHCj9NLDnCzpG-ClaxDLS38GTM8Y',
    appId: '1:773237096966:ios:373c68ee6b3d2fe6f8b987',
    messagingSenderId: '773237096966',
    projectId: 'kuran-okuma-rehberi',
    storageBucket: 'kuran-okuma-rehberi.firebasestorage.app',
    iosBundleId: 'com.kuranokumarehberi.kuranOkumaRehberi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBX2tEfNM52YMKkHbrxikz-FMc4AmYGZog',
    appId: '1:773237096966:web:47ca0e7dd6f19b3ef8b987',
    messagingSenderId: '773237096966',
    projectId: 'kuran-okuma-rehberi',
    authDomain: 'kuran-okuma-rehberi.firebaseapp.com',
    storageBucket: 'kuran-okuma-rehberi.firebasestorage.app',
  );
}
