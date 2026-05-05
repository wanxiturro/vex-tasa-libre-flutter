import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _requestPermissions();

    await _initializeLocalNotifications();

    await _setupMessageHandlers();

    // final token = await _firebaseMessaging.getToken();
    // print('FCM Token: $token');
  }

  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    //print('Mensaje recibido en primer plano: ${message.notification?.title}');

    // Mostrar notificación local
    _showLocalNotification(message);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    //print('Mensaje recibido en segundo plano: ${message.notification?.title}');

    // Aquí puedes navegar a una pantalla específica o manejar la lógica
    // Por ejemplo, si es una notificación sobre tasas de cambio, podrías
    // refrescar los datos o navegar a la pantalla principal
  }

  void _onNotificationTapped(NotificationResponse response) {
    // print('Notificación tocada: ${response.payload}');

    // Manejar cuando el usuario toca la notificación
    // Puedes navegar a diferentes pantallas basado en el payload
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vex_channel_id',
      'Vex Notificaciones',
      channelDescription: 'Notificaciones de Vex - Tasas de Cambio',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Vex',
      message.notification?.body ?? 'Nueva actualización disponible',
      details,
      payload: message.data.toString(),
    );
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vex_channel_id',
      'Vex Notificaciones',
      channelDescription: 'Notificaciones de Vex - Tasas de Cambio',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      0,
      '¡Hola desde Vex!',
      'Esta es una notificación de prueba. Las notificaciones push están funcionando correctamente.',
      details,
    );
  }
}