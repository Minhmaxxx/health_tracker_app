import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    } else if (kIsWeb) {
      return web;
    }
    throw UnsupportedError('Platform not supported.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    appId:
        '1:623589170351:android:692477bbef967bf023085a', // từ mobilesdk_app_id
    apiKey: 'AIzaSyB-wGl2wX5W_y5Vi3Gwh2_jSLG_7C8i274', // từ current_key
    projectId: 'health-tracker-minh-1762-f786f', // từ project_id
    messagingSenderId: '623589170351', // từ project_number
    storageBucket:
        'health-tracker-minh-1762-f786f.firebasestorage.app', // từ storage_bucket
  );

  static const FirebaseOptions web = FirebaseOptions(
    appId:
        '1:623589170351:android:692477bbef967bf023085a', // từ mobilesdk_app_id
    apiKey: 'AIzaSyB-wGl2wX5W_y5Vi3Gwh2_jSLG_7C8i274', // từ current_key
    projectId: 'health-tracker-minh-1762-f786f', // từ project_id
    messagingSenderId: '623589170351', // từ project_number
    storageBucket:
        'health-tracker-minh-1762-f786f.firebasestorage.app', // từ storage_bucket
  );
}
