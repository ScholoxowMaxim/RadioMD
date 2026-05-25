import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Запрос разрешений
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Получение токена
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Настройка локальных уведомлений для шторки
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Слушаем сообщения когда приложение открыто
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработка нажатия на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Фоновые сообщения
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Обработка сообщений в foreground (приложение открыто)
  void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Сообщение: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'RadioMD',
        body: notification.body ?? '',
      );
    }
  }

  // Обработка нажатия на уведомление
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Нажали на уведомление: ${message.notification?.title}');
  }

  // Показать локальное уведомление в шторке
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'radiomd_channel',
      'RadioMD',
      channelDescription: 'Уведомления RadioMD',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}

// Фоновая обработка (когда приложение закрыто или в фоне)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Фоновое сообщение: ${message.notification?.title}');
}