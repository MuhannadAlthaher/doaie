import 'package:flutter/material.dart';
import 'dart:convert';

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

/// مجموعة سريعة لكل الأيام
const Set<Weekday> allWeekdays = {
  Weekday.sun,
  Weekday.mon,
  Weekday.tue,
  Weekday.wed,
  Weekday.thu,
  Weekday.fri,
  Weekday.sat,
};

/// وقت/وصف جرعة محددة للدواء
class DoseTime {
  final TimeOfDay time;
  final String? note; // وصف لكل جرعة
  const DoseTime({required this.time, this.note});

  Map<String, dynamic> toJson() => {
    'hour': time.hour,
    'minute': time.minute,
    'note': note,
  };

  factory DoseTime.fromJson(Map<String, dynamic> j) => DoseTime(
    time: TimeOfDay(
      hour: (j['hour'] as num?)?.toInt() ?? 0,
      minute: (j['minute'] as num?)?.toInt() ?? 0,
    ),
    note: j['note'] as String?,
  );

  @override
  String toString() => 'DoseTime(${time.hour}:${time.minute}, note=$note)';

  @override
  bool operator ==(Object other) {
    return other is DoseTime &&
        other.time.hour == time.hour &&
        other.time.minute == time.minute &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(time.hour, time.minute, note);
}

class Medicine {
  final String id;
  final String name;
  final String dosage; // مثال: 500mg
  final List<DoseTime> times; // أوقات الجرعات في اليوم (مع ملاحظات)
  final Set<Weekday> days; // الأيام الفعالة

  /// جديد (اختياري): مسار صورة محلي للدواء
  final String? imagePath;

  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.days,
    this.imagePath,
  });

  bool isForDay(Weekday day) => days.contains(day);

  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    List<DoseTime>? times,
    Set<Weekday>? days,
    String? imagePath,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      times: times ?? this.times,
      days: days ?? this.days,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'times': times.map((e) => e.toJson()).toList(),
    // نخزّن الأيام كـ أسماء Enum (sun/mon/..)، بترتيب ثابت
    'days': _sortedDays(days).map((e) => e.name).toList(),
    'imagePath': imagePath,
  };

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    dosage: j['dosage'] as String? ?? '',
    times: ((j['times'] as List?) ?? const [])
        .map((e) => DoseTime.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    days: _parseDays(j['days']),
    imagePath: j['imagePath'] as String?,
  );

  static Set<Weekday> _parseDays(dynamic raw) {
    if (raw is List) {
      // يدعم إما أسماء (sun, mon, ..) أو أرقام index
      final Set<Weekday> out = {};
      for (final item in raw) {
        if (item is String) {
          final match = Weekday.values
              .where((w) => w.name == item)
              .cast<Weekday?>()
              .firstWhere((w) => w != null, orElse: () => null);
          if (match != null) out.add(match);
        } else if (item is num) {
          final i = item.toInt();
          if (i >= 0 && i < Weekday.values.length) {
            out.add(Weekday.values[i]);
          }
        }
      }
      if (out.isNotEmpty) return out;
    }
    // افتراضي: كل الأيام
    return {...allWeekdays};
  }

  static List<Weekday> _sortedDays(Set<Weekday> d) {
    // لترتيب ثابت: sun..sat
    const order = [
      Weekday.sun,
      Weekday.mon,
      Weekday.tue,
      Weekday.wed,
      Weekday.thu,
      Weekday.fri,
      Weekday.sat,
    ];
    return order.where(d.contains).toList(growable: false);
  }

  @override
  String toString() =>
      'Medicine(id=$id, name=$name, dosage=$dosage, times=$times, days=$days, imagePath=$imagePath)';

  @override
  bool operator ==(Object other) {
    return other is Medicine &&
        other.id == id &&
        other.name == name &&
        other.dosage == dosage &&
        _listEquals(other.times, times) &&
        _setEquals(other.days, days) &&
        other.imagePath == imagePath;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    dosage,
    Object.hashAll(times),
    Object.hashAll(days),
    imagePath,
  );
}

/// ====== أدوات مساعدة للتخزين مع SharedPreferences ======

/// حوّل قائمة أدوية إلى List<String> JSON (مناسب لـ setStringList)
List<String> medicinesToPrefs(List<Medicine> meds) =>
    meds.map((m) => jsonEncode(m.toJson())).toList(growable: false);

/// حوّل List<String> JSON إلى قائمة أدوية (مناسب لـ getStringList)
List<Medicine> medicinesFromPrefs(List<String>? data) {
  if (data == null) return const [];
  final out = <Medicine>[];
  for (final s in data) {
    try {
      final map = jsonDecode(s);
      if (map is Map<String, dynamic>) {
        out.add(Medicine.fromJson(map));
      }
    } catch (_) {
      // تجاهل العناصر الفاسدة
    }
  }
  return out;
}

/// ====== مساعدين داخليين ======
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final v in a) {
    if (!b.contains(v)) return false;
  }
  return true;
}
