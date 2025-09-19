import 'package:flutter/material.dart';

enum Weekday { sun, mon, tue, wed, thu, fri, sat }

String weekdayName(Weekday d) {
  switch (d) {
    case Weekday.sun:
      return 'الأحد';
    case Weekday.mon:
      return 'الاثنين';
    case Weekday.tue:
      return 'الثلاثاء';
    case Weekday.wed:
      return 'الأربعاء';
    case Weekday.thu:
      return 'الخميس';
    case Weekday.fri:
      return 'الجمعة';
    case Weekday.sat:
      return 'السبت';
  }
}

Weekday weekdayFromDate(DateTime d) {
  switch (d.weekday) {
    case DateTime.monday:
      return Weekday.mon;
    case DateTime.tuesday:
      return Weekday.tue;
    case DateTime.wednesday:
      return Weekday.wed;
    case DateTime.thursday:
      return Weekday.thu;
    case DateTime.friday:
      return Weekday.fri;
    case DateTime.saturday:
      return Weekday.sat;
    case DateTime.sunday:
    default:
      return Weekday.sun;
  }
}

/// وقت/وصف جرعة محددة للدواء
class DoseTime {
  final TimeOfDay time;
  final String? note; // وصف لكل جرعة
  const DoseTime({required this.time, this.note});
}

class Medicine {
  final String id;
  final String name;
  final String dosage; // مثال: 500mg
  final List<DoseTime> times; // أوقات الجرعات في اليوم (مع ملاحظات)
  final Set<Weekday> days; // الأيام الفعالة

  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.days,
  });

  bool isForDay(Weekday day) => days.contains(day);
}