import 'package:flutter/material.dart';
import 'package:flutter_foreground_service/flutter_foreground_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:air_watch/Screens/aqi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getBool("Notification_Allowed") == null) {
    prefs.setBool("Notification_Allowed", true);
  }

  PermissionStatus status = await Permission.notification.status;
  if (!status.isGranted) {
    status = await Permission.notification.request();
  }
  ForegroundService().start();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirWatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Aqi(
        prefs: prefs,
      ),
    );
  }
}
