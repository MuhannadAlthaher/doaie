import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project_doa/src/services/notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../src/models/medicine.dart';

class DoseInstance {
  final Medicine med;
  final int doseIndex;
  final DateTime dateTime;
  final String keyId;
  final String? note;
  const DoseInstance({
    required this.med,
    required this.doseIndex,
    required this.dateTime,
    required this.keyId,
    required this.note,
  });
}

class HomeState {
  final List<Medicine> meds;
  final List<DoseInstance> today;
  final Map<String, bool> taken;
  final Map<String, DateTime> snoozed;
  final DoseInstance? next;
  final Duration? untilNext;

  const HomeState({
    required this.meds,
    required this.today,
    required this.taken,
    required this.snoozed,
    required this.next,
    required this.untilNext,
  });

  HomeState copyWith({
    List<Medicine>? meds,
    List<DoseInstance>? today,
    Map<String, bool>? taken,
    Map<String, DateTime>? snoozed,
    DoseInstance? next,
    Duration? untilNext,
  }) => HomeState(
    meds: meds ?? this.meds,
    today: today ?? this.today,
    taken: taken ?? this.taken,
    snoozed: snoozed ?? this.snoozed,
    next: next,
    untilNext: untilNext,
  );

  static HomeState initial(List<Medicine> seed) => HomeState(
    meds: seed,
    today: const [],
    taken: const {},
    snoozed: const {},
    next: null,
    untilNext: null,
  );
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(List<Medicine> seed) : super(HomeState.initial(seed)) {
    _init();
  }

  late Timer _ticker;
  late String _todayKey;

  Future<void> _init() async {
    _todayKey = _dateKey(DateTime.now());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    // تحميل البيانات من SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('meds') ?? [];
    final meds = saved.map((j) => Medicine.fromJson(jsonDecode(j))).toList();

    emit(state.copyWith(meds: meds));
    _rebuild();
    _scheduleAllNotifications();
  }

  @override
  Future<void> close() {
    _ticker.cancel();
    return super.close();
  }

  // -------- Utils --------

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
  String _doseKey(String medId, DateTime dt) =>
      '$medId@${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  int _stableHash(String s) {
    int h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  int _notificationIdWeekly(String medId, int doseIndex, int weekday1to7) {
    final base = _stableHash(medId);
    return base ^ (doseIndex << 8) ^ weekday1to7;
  }

  int _notificationIdFor(DoseInstance d) {
    final wd = d.dateTime.weekday;
    return _notificationIdWeekly(d.med.id, d.doseIndex, wd);
  }

  int _snoozeNotificationIdFor(DoseInstance d) =>
      _notificationIdFor(d) + 999999;

  // -------- Persistence --------

  Future<void> _saveMeds(List<Medicine> meds) async {
    final prefs = await SharedPreferences.getInstance();
    final list = meds.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList('meds', list);
  }

  // -------- Actions --------

  void addMedicine(Medicine m) {
    final list = [...state.meds, m];
    emit(state.copyWith(meds: list));
    _saveMeds(list);
    _rebuild();
    _scheduleNotificationsFor(m);
  }

  Future<void> removeMedicine(String medId) async {
    final list = state.meds.where((m) => m.id != medId).toList();
    emit(state.copyWith(meds: list));
    await _saveMeds(list);
    _rebuild();
  }

  Future<void> toggleTaken(String keyId, bool value) async {
    if (value) {
      final inst = _findInstance(keyId);
      if (inst != null) {
        final nid = _snoozeNotificationIdFor(inst);
        await NotificationService.instance.cancel(nid);
      }
    }

    final taken = {...state.taken}..[keyId] = value;
    final snoozed = {...state.snoozed};
    if (value) snoozed.remove(keyId);

    emit(state.copyWith(taken: taken, snoozed: snoozed));
    _recomputeNext();
  }

  Future<void> removeDose(String keyId) async {
    final inst = _findInstance(keyId);

    if (inst != null) {
      final snoozeId = _snoozeNotificationIdFor(inst);
      await NotificationService.instance.cancel(snoozeId);
    }

    final updatedToday = state.today.where((e) => e.keyId != keyId).toList();
    final newTaken = Map<String, bool>.from(state.taken)..[keyId] = true;
    final newSnoozed = Map<String, DateTime>.from(state.snoozed)..remove(keyId);

    emit(
      state.copyWith(today: updatedToday, taken: newTaken, snoozed: newSnoozed),
    );
    _recomputeNext();
  }

  Future<void> snooze(String keyId, Duration by) async {
    final inst = state.today.firstWhere((e) => e.keyId == keyId);
    final newTime = inst.dateTime.add(by);

    final oldNid = _snoozeNotificationIdFor(inst);
    await NotificationService.instance.cancel(oldNid);

    final snoozed = {...state.snoozed}..[keyId] = newTime;
    emit(state.copyWith(snoozed: snoozed));

    _rebuild();

    final newNid = _snoozeNotificationIdFor(inst);
    NotificationService.instance.scheduleOneShot(
      id: newNid,
      title: 'غفوة — ${inst.med.name}',
      body: '${inst.med.dosage}${inst.note != null ? " — ${inst.note}" : ''}',
      when: newTime,
    );
  }

  // -------- Ticker & rebuild --------

  void _tick() {
    final nowKey = _dateKey(DateTime.now());
    if (nowKey != _todayKey) {
      _todayKey = nowKey;
      emit(HomeState.initial(state.meds));
      _rebuild();
    } else {
      _recomputeNext();
    }
  }

  void _rebuild() {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final wd = weekdayFromDate(now);

    final List<DoseInstance> list = [];
    for (final m in state.meds) {
      if (!m.isForDay(wd)) continue;
      for (int i = 0; i < m.times.length; i++) {
        final dose = m.times[i];
        DateTime dt = DateTime(
          todayDate.year,
          todayDate.month,
          todayDate.day,
          dose.time.hour,
          dose.time.minute,
        );

        final baseKey = _doseKey(m.id, dt);
        final snoozedTime = state.snoozed[baseKey];
        if (snoozedTime != null) dt = snoozedTime;

        list.add(
          DoseInstance(
            med: m,
            doseIndex: i,
            dateTime: dt,
            keyId: baseKey,
            note: dose.note,
          ),
        );
      }
    }

    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    emit(state.copyWith(today: list));
    _recomputeNext();
  }

  void _recomputeNext() {
    final now = DateTime.now();
    DoseInstance? next;
    for (final d in state.today) {
      if (d.dateTime.isAfter(now) && !(state.taken[d.keyId] ?? false)) {
        next = d;
        break;
      }
    }
    final until = next == null ? null : next.dateTime.difference(now);
    emit(state.copyWith(next: next, untilNext: until));
  }

  // -------- Notifications scheduling --------

  Future<void> _scheduleNotificationsFor(Medicine m) async {
    await NotificationService.instance.ensureAndroidChannel();
    for (final wd in m.days) {
      final w = _weekdayToInt(wd);
      for (int i = 0; i < m.times.length; i++) {
        final t = m.times[i];
        final id = _notificationIdWeekly(m.id, i, w);
        await NotificationService.instance.scheduleWeekly(
          id: id,
          title: m.name,
          body: '${m.dosage}${t.note != null ? " — ${t.note}" : ''}',
          weekday: w,
          time: t.time,
        );
      }
    }
  }

  Future<void> _scheduleAllNotifications() async {
    for (final m in state.meds) {
      await _scheduleNotificationsFor(m);
    }
  }

  int _weekdayToInt(Weekday d) {
    switch (d) {
      case Weekday.mon:
        return 1;
      case Weekday.tue:
        return 2;
      case Weekday.wed:
        return 3;
      case Weekday.thu:
        return 4;
      case Weekday.fri:
        return 5;
      case Weekday.sat:
        return 6;
      case Weekday.sun:
        return 7;
    }
  }

  DoseInstance? _findInstance(String keyId) {
    try {
      return state.today.firstWhere((e) => e.keyId == keyId);
    } catch (_) {
      return null;
    }
  }
}
