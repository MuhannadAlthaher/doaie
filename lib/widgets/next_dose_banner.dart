import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xfffffbf2);
  static const primary = Color(0xffa1dcc0);
  static const dark = Color(0xff33484d);
  static const accent = Color(0xff7a71e5);
}

class NextDoseBanner extends StatelessWidget {
  final String? title;
  final DateTime? nextTime;
  final Duration? until;

  const NextDoseBanner({super.key, this.title, this.nextTime, this.until});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medication, color: AppColors.dark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: nextTime == null
                ? const Text(
                    'لا توجد جرعات قادمة اليوم — استرح 🙌',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'أقرب جرعة',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _timeString(nextTime!) +
                            (until != null
                                ? ' (بعد ${_fmtDuration(until!)})'
                                : ''),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

String _timeString(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
String _fmtDuration(Duration d) => d.inHours > 0
    ? '${d.inHours}س ${d.inMinutes % 60}د'
    : '${d.inMinutes} دقيقة';
