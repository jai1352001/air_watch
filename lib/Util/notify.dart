import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Noti {
  static Future initialize(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    var androidInitialize =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationsSettings = InitializationSettings(
      android: androidInitialize,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationsSettings);
  }

  static Future showBigTextNotification(
      {var id = 0,
      required String title,
      required String body,
      var payload,
      required FlutterLocalNotificationsPlugin fln}) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics;
    if (title == "Wear Mask") {
      androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'channelid_wm_164',
        'channel_name',
        playSound: true,
        sound: RawResourceAndroidNotificationSound('wear_mask'),
        importance: Importance.max,
        priority: Priority.high,
      );
    } else {
      androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'channelid_rm_164',
        'channel_name',
        playSound: true,
        sound: RawResourceAndroidNotificationSound('remove_mask'),
        importance: Importance.max,
        priority: Priority.high,
      );
    }

    var not = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await fln.show(
      0,
      title,
      body,
      not,
    );
  }
}
