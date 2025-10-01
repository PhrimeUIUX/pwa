// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pwa/views/splash.view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pwa/services/storage.service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBp6_fzqtLoGmIeSyg3vtrHyJJfxVg902c",
      authDomain: "ppc-toda.firebaseapp.com",
      databaseURL:
          "https://ppc-toda-default-rtdb.asia-southeast1.firebasedatabase.app",
      projectId: "ppc-toda",
      storageBucket: "ppc-toda.firebasestorage.app",
      messagingSenderId: "462080229186",
      appId: "1:462080229186:web:be7b5e37e13c33e09392db",
      measurementId: "G-30S1M2THQW",
    ),
  );
  await StorageService.getPrefs();
  await setupWebPush();
  GestureBinding.instance.pointerRouter.addGlobalRoute((event) {});
  runApp(
    const MyApp(),
  );
}

Future<void> setupWebPush() async {
  try {
    final permission = await html.Notification.requestPermission();
    if (permission == "granted") {
      final messaging = FirebaseMessaging.instance;
      const vapidKey =
          "BHlyzsbKUKY7dLGucP2TBDD9jXJWCKnE4c5ZCsFXhfZXEnmcCK9A-kF5vSAIN4DpsKvccRy468XW7qzE_DMfjMk";
      final token = await messaging.getToken(vapidKey: vapidKey);
      debugPrint("Web FCM Token: $token");
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          "Foreground title: ${message.data["title"] ?? message.notification?.title}",
        );
        debugPrint(
          "Foreground body: ${message.data["body"] ?? message.notification?.body}",
        );
        if (message.notification != null) {
          html.Notification(
            message.data["title"] ?? message.notification?.title ?? '',
            body: message.data["body"] ?? message.notification?.body ?? '',
            icon: "/icons/webiconsmall.png",
          );
        }
      });
    } else {
      debugPrint("Notification permission denied");
    }
  } catch (e) {
    debugPrint("Web Push setup failed: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PPC TODA (Beta)',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        var mediaQuery = MediaQuery.of(
          context,
        );
        var textScaleFactor = 1.0;
        return MediaQuery(
          data: mediaQuery.copyWith(
            padding: EdgeInsets.zero,
            viewInsets: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
            textScaler: TextScaler.linear(
              textScaleFactor,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashView(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          secondary: Colors.blueAccent,
        ),
      ),
    );
  }
}
