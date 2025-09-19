import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await _configureLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await ensureAndroidChannel();
    _initialized = true;
  }

  static const _channel = AndroidNotificationChannel(
    'meds_reminders',
    'تذكير الدواء',
    description: 'تنبيهات أوقات جرعات الدواء',
    importance: Importance.max,
  );

  Future<void> ensureAndroidChannel() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// جدول تنبيه لمرة واحدة في وقت محدد (تُستخدم للغفوة)
  Future<int> scheduleOneShot({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    final tzTime = tz.TZDateTime.from(when, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          priority: Priority.max,
          importance: Importance.max,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // أزيلت uiLocalNotificationDateInterpretation في الإصدارات الحديثة
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'dose',
    );
    return id;
  }

  /// جدول أسبوعي بحسب اليوم/الوقت
  Future<int> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday, // Monday=1 .. Sunday=7
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // حرّك التاريخ للأمام حتى يطابق اليوم/ويكون مستقبلي
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final tzTime = tz.TZDateTime.from(scheduled, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          priority: Priority.max,
          importance: Importance.max,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // أزيلت uiLocalNotificationDateInterpretation
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'dose',
    );
    return id;
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  // ---------------------- Helpers ----------------------

  Future<void> _configureLocalTimezone() async {
    tz.initializeTimeZones();

    String iana;
    try {
      // يعطيك IANA الصحيح مثل: Asia/Riyadh
      iana = await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      // fallback ذكي بناءً على الاسم المختصر أو الويندوز
      iana = _fallbackIanaFrom(DateTime.now().timeZoneName);
    }

    // لو رجع اسم غير موجود في قاعدة tz، نفترض Asia/Riyadh ثم UTC كحل أخير
    try {
      tz.setLocalLocation(tz.getLocation(iana));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
      } catch (__) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }
  }

  String _fallbackIanaFrom(String rawName) {
    final n = rawName.trim();
    // أشهر الاحتمالات للأجهزة اللي تعطي اسم غير IANA:
    switch (n) {
      case 'Arabian Standard Time':
      case 'AST': // قد تُستخدم عربياً (ليست Atlantic هنا)
      case 'GMT+03:00':
      case 'UTC+03:00':
        return 'Asia/Riyadh';
      default:
        // كحل عام
        return 'UTC';
    }
  }
}
