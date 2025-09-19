import 'package:flutter/material.dart';

class DoseCard extends StatelessWidget {
  final String medName;
  final String dosage;
  final String? note;
  final DateTime time;
  final bool taken;
  final bool isPast;
  final VoidCallback onSnooze;
  final VoidCallback onToggle;

  const DoseCard({
    super.key,
    required this.medName,
    required this.dosage,
    required this.time,
    this.note,
    required this.taken,
    required this.isPast,
    required this.onSnooze,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = taken ? Colors.green : (isPast ? Colors.orange : const Color(0xff33484d));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        border: Border.all(color: const Color(0xffa1dcc0).withOpacity(.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(width: 4, height: 56, decoration: BoxDecoration(color: const Color(0xffa1dcc0), borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            const Icon(Icons.medication_liquid, color: Color(0xff33484d)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(medName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xff33484d)), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  const Icon(Icons.access_time, size: 16, color: Color(0xff33484d)),
                  const SizedBox(width: 4),
                  Text(_timeString(time), style: TextStyle(color: const Color(0xff33484d).withOpacity(.8))),
                ]),
                const SizedBox(height: 4),
                Text(dosage + (note != null && note!.trim().isNotEmpty ? ' — ${note!}' : ''), style: TextStyle(color: const Color(0xff33484d).withOpacity(.7))),
                const SizedBox(height: 8),
                Row(children: [
                  if (!taken)
                    OutlinedButton.icon(
                      onPressed: isPast ? null : onSnooze,
                      icon: const Icon(Icons.snooze),
                      label: const Text('غفوة 10د'),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onToggle,
                      icon: Icon(taken ? Icons.undo : Icons.check),
                      label: Text(taken ? 'تراجع' : 'تم'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: taken ? Colors.grey[400] : const Color(0xffa1dcc0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ])
              ]),
            ),
            const SizedBox(width: 8),
            Icon(taken ? Icons.check_circle : Icons.alarm, color: statusColor),
          ],
        ),
      ),
    );
  }
}

String _timeString(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
