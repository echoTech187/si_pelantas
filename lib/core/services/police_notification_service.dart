import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Filter Background Notification:
  // 1. Cek target aplikasi
  if (message.data['targetApp'] != null && message.data['targetApp'] != 'POLRI_COMMAND_APP') {
    return;
  }
  // 2. Cek apakah user sedang login dan role-nya UNIT_KAMSEL
  const storage = FlutterSecureStorage();
  final userJson = await storage.read(key: 'polri_user_data');
  if (userJson == null) {
    return;
  }
  try {
    final Map<String, dynamic> user = jsonDecode(userJson);
    if (user['role'] != 'UNIT_KAMSEL') {
      return;
    }
  } catch (_) {
    return;
  }

  final localNotifications = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await localNotifications.initialize(const InitializationSettings(android: androidSettings));

  final title = message.data['title'] ?? 'Peringatan Unit Kamsel';
  final body = message.data['body'] ?? '';

  await localNotifications.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'polantas_kamsel_high_alert',
        'Siaga & Peringatan Ambang Batas Kamsel',
        channelDescription: 'Notifikasi darurat ambang batas pelanggaran pelajar dan penyuluhan Satlantas Mojokerto',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

class PoliceNotificationService {
  static final PoliceNotificationService instance = PoliceNotificationService._internal();
  PoliceNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'polantas_kamsel_high_alert',
    'Siaga & Peringatan Ambang Batas Kamsel',
    description: 'Notifikasi darurat ambang batas pelanggaran pelajar dan penyuluhan Satlantas Mojokerto',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Local notifications setup
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      // Create high-priority channel
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_channel);
      }

      // Request permission
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Foreground handler dengan verifikasi targetApp dan targetRole
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final data = message.data;
        final String? targetApp = data['targetApp'];
        final String? targetRole = data['targetRole'];

        // 1. Abaikan jika notifikasi ini BUKAN untuk aplikasi Polri
        if (targetApp != null && targetApp != 'POLRI_COMMAND_APP') {
          return;
        }

        // 2. Cek apakah ada user Polri yang sedang login dan periksa role-nya
        final userJson = await _storage.read(key: 'polri_user_data');
        if (userJson == null) {
          // Tidak ada user login di aplikasi polri, jangan tampilkan banner
          return;
        }

        try {
          final Map<String, dynamic> officerMap = jsonDecode(userJson);
          final String roleRaw = (officerMap['role'] ?? officerMap['roleRaw'] ?? '').toString().toUpperCase();

          // 3. Jika notifikasi dikhususkan untuk UNIT_KAMSEL, tolak jika user saat ini adalah POLANTAS
          if (targetRole == 'UNIT_KAMSEL' && !roleRaw.contains('KAMSEL')) {
            return;
          }
        } catch (_) {
          return;
        }

        final notification = message.notification;
        final title = notification?.title ?? data['title'] ?? 'Peringatan Satlantas';
        final body = notification?.body ?? data['body'] ?? '';

        _localNotifications.show(
          message.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      });

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('FCM Polri initialization warning: $e');
      }
    }
  }

  Future<String?> getFcmToken() async {
    try {
      if (!_initialized) {
        await initialize();
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get FCM token for Polri: $e');
      }
      return null;
    }
  }
}

