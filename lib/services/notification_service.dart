import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap or action button tap
        if (response.payload == 'cancel_sos') {
          // Logic to cancel SOS will be handled by a broadcast receiver or stream
        }
      },
    );
  }

  Future<void> showCountdownNotification(int secondsLeft) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sos_countdown_channel',
      'SOS Alerts',
      channelDescription: 'Countdown for automatic SOS triggering',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'cancel_sos',
          'CANCEL SOS',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      100,
      'Scream Detected!',
      'Sending SOS in $secondsLeft seconds...',
      platformChannelSpecifics,
      payload: 'cancel_sos',
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}