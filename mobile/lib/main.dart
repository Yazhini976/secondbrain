import 'package:flutter/material.dart';
import 'package:second_brain/app.dart';
import 'package:second_brain/features/reminders/services/automatic_reminder_service.dart';
import 'package:second_brain/features/reminders/services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize(navigatorKey: navigatorKey);
  await AutomaticReminderService.instance.syncAutomaticReminders();
  runApp(SecondBrainApp(navigatorKey: navigatorKey));
}
