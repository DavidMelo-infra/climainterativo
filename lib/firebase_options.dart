// ARQUIVO: lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  // CHAVES GERAIS EXTRAÍDAS DO SEU JSON ANTIGO
  static const String API_KEY = 'AIzaSyAuif8MO5Hol5Q92NzBaVSHDuH5LzycIl4';
  static const String PROJECT_ID = 'clima-interativo-d91af';
  static const String MESSAGING_SENDER_ID = '368017908513';
  static const String ANDROID_APP_ID =
      '1:368017908513:android:3ea1fe84dda54876fc1460';
  static const String IOS_BUNDLE_ID = 'com.climainterativo.app';
  static const String STORAGE_BUCKET = '$PROJECT_ID.firebasestorage.app';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // --- CONFIGURAÇÕES POR PLATAFORMA ---

  // Configurações para Web (Usando as chaves do projeto d91af)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: API_KEY,
    // Placeholder ou App ID Web antigo
    appId: '1:368017908513:web:placeholder_web',
    messagingSenderId: MESSAGING_SENDER_ID,
    projectId: PROJECT_ID,
    authDomain: '$PROJECT_ID.firebaseapp.com',
    storageBucket: STORAGE_BUCKET,
    // measurementId: 'G-3WGH8D01FC', // Use o seu ID de Analytics se tiver
  );

  // Configurações para Android (USANDO OS VALORES EXATOS DO SEU JSON ANTIGO)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: API_KEY,
    appId: ANDROID_APP_ID,
    messagingSenderId: MESSAGING_SENDER_ID,
    projectId: PROJECT_ID,
    storageBucket: STORAGE_BUCKET,
  );

  // Configurações para iOS (Usando chaves gerais e inferindo o Bundle ID)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: API_KEY,
    // Placeholder ou App ID iOS antigo
    appId: '1:368017908513:ios:placeholder_ios',
    messagingSenderId: MESSAGING_SENDER_ID,
    projectId: PROJECT_ID,
    storageBucket: STORAGE_BUCKET,
    iosBundleId: IOS_BUNDLE_ID,
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = web;
}
