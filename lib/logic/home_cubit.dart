import 'dart:async';
import 'package:final_project_doa/src/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../src/models/medicine.dart';

class DoseInstance {
  final Medicine med;
  final int doseIndex; // index داخل med.times
  final DateTime dateTime; // وقت الجرعة لليوم الحالي (قد يتغير بالغفوة)
  final String keyId; // مفتاح فريد لليوم
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
  final Map<String, bool> taken; // keyId -> taken
  final Map<String, DateTime> snoozed; // keyId -> new time
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
        taken: {},
        snoozed: {},
        next: null,
        untilNext: null,
      );
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(List<Medicine> seed) : super(HomeState.initial(seed)) {
    _todayKey = _dateKey(DateTime.now());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _rebuild();
    _scheduleAllNotifications();
  }

  late Timer _ticker;
  late String _todayKey;

  @override
  Future<void> close() {
    _ticker.cancel();
    return super.close();
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
  String _doseKey(String medId, DateTime dt) => '$medId@${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void addMedicine(Medicine m) {
    final list = [...state.meds, m];
    emit(state.copyWith(meds: list));
    _rebuild();
    _scheduleNotificationsFor(m);
  }

  void toggleTaken(String keyId, bool value) {
    final taken = {...state.taken};
    taken[keyId] = value;
    emit(state.copyWith(taken: taken));
    _recomputeNext();
  }

  void snooze(String keyId, Duration by) {
    final snoozed = {...state.snoozed};
    final inst = state.today.firstWhere((e) => e.keyId == keyId);
    final newTime = inst.dateTime.add(by);
    snoozed[keyId] = newTime;
    emit(state.copyWith(snoozed: snoozed));
    _rebuild();
    final nid = _notificationIdFor(inst);
    NotificationService.instance.scheduleOneShot(
      id: nid + 999999,
      title: 'غفوة — ${inst.med.name}',
      body: '${inst.med.dosage}${inst.note != null ? " — ${inst.note}" : ''}',
      when: newTime,
    );
  }

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
        DateTime dt = DateTime(todayDate.year, todayDate.month, todayDate.day, dose.time.hour, dose.time.minute);
        final baseKey = _doseKey(m.id, dt);
        final snoozedTime = state.snoozed[baseKey];
        if (snoozedTime != null) dt = snoozedTime;
        list.add(DoseInstance(
          med: m,
          doseIndex: i,
          dateTime: dt,
          keyId: baseKey,
          note: dose.note,
        ));
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
        next = d; break;
      }
    }
    final until = next == null ? null : next.dateTime.difference(now);
    emit(state.copyWith(next: next, untilNext: until));
  }

  int _notificationIdFor(DoseInstance d) {
    final wd = DateTime.now().weekday; 
    return d.med.id.hashCode ^ (d.doseIndex << 8) ^ wd;
  }

  Future<void> _scheduleNotificationsFor(Medicine m) async {
    await NotificationService.instance.ensureAndroidChannel();
    for (final wd in m.days) {
      for (int i = 0; i < m.times.length; i++) {
        final t = m.times[i];
        final id = m.id.hashCode ^ (i << 8) ^ _weekdayToInt(wd);
        await NotificationService.instance.scheduleWeekly(
          id: id,
          title: m.name,
          body: '${m.dosage}${t.note != null ? " — ${t.note}" : ''}',
          weekday: _weekdayToInt(wd),
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
      case Weekday.mon: return 1;
      case Weekday.tue: return 2;
      case Weekday.wed: return 3;
      case Weekday.thu: return 4;
      case Weekday.fri: return 5;
      case Weekday.sat: return 6;
      case Weekday.sun: return 7;
    }
  }
}