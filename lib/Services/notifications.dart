import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Services/api_path.dart';
import 'database.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _fcm = FirebaseMessaging.instance;
  final FirestoreDatabase database;

  NotificationService(this.database);

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'yoga_house_channel', 'yoga_house_channel', 'yoga_house_channel',
      importance: Importance.high, playSound: true);

  static showNotification(RemoteMessage message) {
    const androidDetails = AndroidNotificationDetails(
        'yoga_house_channel', 'yoga_house_channel', 'yoga_house_channel',
        icon: '@mipmap/launcher_icon',
        importance: Importance.max,
        priority: Priority.high);
    const ios = IOSNotificationDetails();
    final notification = message.notification;
    FlutterLocalNotificationsPlugin().show(
        notification.hashCode,
        notification?.title,
        notification?.body,
        const NotificationDetails(android: androidDetails, iOS: ios));
  }

  Future init() async {
    tz.initializeTimeZones();
    _fcm.requestPermission();
    _fcm.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = IOSInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await plugin.initialize(initSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  listenForMessages(BuildContext context) {
    const androidDetails = AndroidNotificationDetails(
        'yoga_house_channel', 'yoga_house_channel', 'yoga_house_channel',
        icon: '@mipmap/launcher_icon',
        importance: Importance.max,
        priority: Priority.high);
    const ios = IOSNotificationDetails();
    FirebaseMessaging.onMessage.listen(
      (message) {
        final notification = message.notification;
        // final android = message.notification?.android;
        if (notification != null) {
          debugPrint('onMessage');
          _plugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              const NotificationDetails(android: androidDetails, iOS: ios));
        }
      },
    );
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      final notification = message.notification;
      // final android = message.notification?.android;
      if (notification != null) {
        debugPrint('onMessageOpenedApp');
        await showOkAlertDialog(
            context: context,
            message: notification.body,
            okLabel: 'אישור',
            title: notification.title);
      }
    });
  }

  void subscribeToUserNotifications(String uid) {
    _subscribeToTopic(APIPath.clientNotificationsTopic(uid));
  }

  Future<void> sendUserNotification(NotificationData notification) async {
    await database.addNotificationToUser(notification);
  }

  sendAdminNotification(String title, String msg) async {
    await database.addAdminNotification(title, msg);
  }

  void _subscribeToTopic(String topic) {
    debugPrint('Subscribing to $topic');
    _fcm.subscribeToTopic(topic);
  }

  void _unsubscribeFromTopic(String topic) {
    debugPrint('Unsubscribing from $topic');
    _fcm.unsubscribeFromTopic(topic);
  }

  int idFromStartTime(DateTime startTime) {
    final dayOfMonth = startTime.day;
    final month = startTime.month;
    final minuteInHour = startTime.minute;
    final hourInDay = startTime.hour;
    final year = startTime.year % 100;
    final yearWithMonth = concatTwoDigits(year, month);
    final yearWithMonthWithDay = concatTwoDigits(yearWithMonth, dayOfMonth);
    final yearWithMonthWithDayWithHour =
        concatTwoDigits(yearWithMonthWithDay, hourInDay);
    final yearWithMonthWithDayWithHourWithMinute =
        concatTwoDigits(yearWithMonthWithDayWithHour, minuteInHour);
    return yearWithMonthWithDayWithHourWithMinute;
  }

  int concatTwoDigits(int original, int toConcat) {
    final withHunnid = original * 100;
    return withHunnid + toConcat;
  }

  Future<void> setPracticeLocalNotification(
      Practice practice, int hoursBeforeToAlert) async {
    if (!practice.startTime
        .isAfter(DateTime.now().add(Duration(hours: hoursBeforeToAlert)))) {
      return;
    } //dont alert if appointment time is close
    const android = AndroidNotificationDetails(
        'yoga_house_channel', 'yoga_house_channel', 'yoga_house_channel',
        icon: '@mipmap/launcher_icon',
        importance: Importance.max,
        priority: Priority.high);
    const ios = IOSNotificationDetails();
    const platform = NotificationDetails(android: android, iOS: ios);
    final date = tz.TZDateTime.from(practice.startTime, tz.local)
        .subtract(Duration(hours: hoursBeforeToAlert));
    final title = practice.name;
    final hour = DateFormat.Hm().format(practice.startTime);
    final body =
        'תזכורת ל${practice.name} מחר ב$hour, במידה ואינך מתכוון להגיע אנא לבטל לפחות 12 שעות לפני. נתראה :)';
    await _plugin.zonedSchedule(
        idFromStartTime(practice.startTime), title, body, date, platform,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true);
  }

  cancelPracticeLocalNotification(Practice practice) {
    final id = idFromStartTime(practice.startTime);
    _plugin.cancel(id);
  }

  void initUserNotifications(String uid) {
    subscribeToHomepageTextTopic();
    subscribeToUserNotificationsTopic(uid);
  }

  void subscribeToHomepageTextTopic() {
    _subscribeToTopic(APIPath.homepageTextTopic());
  }

  void subscribeToUserNotificationsTopic(String uid) {
    _subscribeToTopic(APIPath.userNotificationsTopic(uid));
  }

  void subscribeToAdminNotificationsTopic() {
    _subscribeToTopic(APIPath.adminNotificationsTopic());
  }

  void adminRegisterToUserRegisteredNotifications() {
    _subscribeToTopic(APIPath.adminTopicUserRegistered());
  }

  void adminUnregisterFromUserRegisteredNotifications() {
    _unsubscribeFromTopic(APIPath.adminTopicUserRegistered());
  }

  void adminRegisterToUserCancelledNotifications() {
    _subscribeToTopic(APIPath.adminTopicUserRegistered());
  }

  void adminUnregisterFromUserCancelledNotifications() {
    _unsubscribeFromTopic(APIPath.adminTopicUserRegistered());
  }
}

class NotificationData {
  final String targetUID;
  final String targetUserNotificationTopic;
  final String title;
  final String msg;

  NotificationData(
      {required this.targetUID,
      required this.targetUserNotificationTopic,
      required this.title,
      required this.msg});

  Map<String, dynamic> toMap() {
    return {
      'targetUID': targetUID,
      'targetUserNotificationTopic': targetUserNotificationTopic,
      'title': title,
      'msg': msg,
    };
  }
}
