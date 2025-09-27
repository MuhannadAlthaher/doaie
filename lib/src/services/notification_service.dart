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
  late tz.Location _localLocation;

  // قناة أندرويد
  static const _channel = AndroidNotificationChannel(
    'meds_reminders_v3',
    'تذكير الدواء (V3)',
    description: 'تنبيهات أوقات جرعات الدواء',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> init() async {
    if (_initialized) return;

    await _configureLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // عرض التنبيه في foreground على iOS (اختياري)
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // إنشاء القناة
    await ensureAndroidChannel();

    _initialized = true;
  }

  /// إتاحة تأكيد القناة من الخارج عند الحاجة
  Future<void> ensureAndroidChannel() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  NotificationDetails _buildDetails() {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      priority: Priority.max,
      importance: Importance.max,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: false,
    );
    return NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );
  }

  /// إشعار فوري
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await _ensureInited();
    await ensureAndroidChannel();
    await _plugin.show(id, title, body, _buildDetails());
  }

  Future<int> scheduleOneShot({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    bool exact = false,
  }) async {
    await _ensureInited();

    var tzTime = tz.TZDateTime.from(when, _localLocation);

    // وقت آمن للمقارنة (now + 1s)
    final safeFutureTz = tz.TZDateTime.now(
      _localLocation,
    ).add(const Duration(seconds: 1));

    // إن لم يكن بعد الوقت الآمن، ندفعه 5 ثواني
    if (!tzTime.isAfter(safeFutureTz)) {
      tzTime = tz.TZDateTime.now(
        _localLocation,
      ).add(const Duration(seconds: 5));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      _buildDetails(),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      // ملاحظة: أزلنا uiLocalNotificationDateInterpretation لأن إصدارك لا يدعمه
      payload: 'one-shot',
    );
    return id;
  }

  Future<int> scheduleIn({
    required int id,
    required String title,
    required String body,
    required Duration delta,
    bool exact = false,
  }) async {
    final nowTz = tz.TZDateTime.now(_localLocation);
    return scheduleOneShot(
      id: id,
      title: title,
      body: body,
      when: nowTz.add(delta),
      exact: exact,
    );
  }

  Future<int> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required TimeOfDay time,
  }) async {
    await _ensureInited();

    final now = tz.TZDateTime.now(_localLocation);
    var first = tz.TZDateTime(
      _localLocation,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    // اليوم الصحيح + في المستقبل
    while (first.weekday != weekday || !first.isAfter(now)) {
      first = first.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      first,
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      // أزلنا uiLocalNotificationDateInterpretation
      payload: 'weekly',
    );
    return id;
  }

  /// تذكير يومي
  Future<int> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await _ensureInited();

    final now = tz.TZDateTime.now(_localLocation);
    var first = tz.TZDateTime(
      _localLocation,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      first,
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily',
    );
    return id;
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
  Future<List<PendingNotificationRequest>> pluginPending() =>
      _plugin.pendingNotificationRequests();

  // ---------------------------------

  Future<void> _ensureInited() async {
    if (!_initialized) {
      await init();
    }
  }

  Future<void> _configureLocalTimezone() async {
    tz.initializeTimeZones();

    String iana;
    try {
      iana = await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      iana = 'Asia/Riyadh';
    }

    try {
      _localLocation = tz.getLocation(iana);
    } catch (_) {
      _localLocation = tz.getLocation('Asia/Riyadh');
    }
    tz.setLocalLocation(_localLocation);
  }
}
