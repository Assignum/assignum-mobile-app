import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:assignum/core/infrastructure/firebase_options.dart';

// Handler para mensajes cuando la app está cerrada/background.
// Necesita inicializar Firebase porque corre en un isolate separado.
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage _) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;

  // Keys globales: se pasan a MaterialApp para navegar/mostrar sin BuildContext
  static final navigatorKey       = GlobalKey<NavigatorState>();
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // Pedir permiso (Android 13+, iOS siempre)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Notificación recibida con app en primer plano → SnackBar
    FirebaseMessaging.onMessage.listen(_showSnackBar);

    // Tap en notificación con app en background
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _goToNotifications());

    // Tap en notificación con app cerrada
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToNotifications());
    }
  }

  /// Guarda el token FCM + email en Firestore bajo users/{uid}.
  /// El backend busca por email para encontrar el token al invitar.
  static Future<void> saveToken(String uid, String email) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await _storeToken(uid, email, token);
      _fcm.onTokenRefresh.listen((t) => _storeToken(uid, email, t));
    } catch (_) {}
  }

  /// Elimina el token al cerrar sesión.
  static Future<void> deleteToken(String uid) async {
    try {
      await _fcm.deleteToken();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': FieldValue.delete()}, SetOptions(merge: true));
    } catch (_) {}
  }

  // ── Privados ─────────────────────────────────────────────────────────

  static Future<void> _storeToken(String uid, String email, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'email': email, 'fcmToken': token}, SetOptions(merge: true));
  }

  static void _showSnackBar(RemoteMessage message) {
    final title = message.notification?.title ?? 'Assignum';
    final body  = message.notification?.body  ?? '';
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            if (body.isNotEmpty)
              Text(body,
                  style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF2A2723),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Ver',
          textColor: const Color(0xFFDC2F26),
          onPressed: _goToNotifications,
        ),
      ),
    );
  }

  static void _goToNotifications() {
    navigatorKey.currentState?.pushNamed('/notifications');
  }
}
