import 'package:final_project_doa/src/models/medicine.dart';
import 'package:flutter/material.dart';

class AddMedicineSheet extends StatefulWidget {
  const AddMedicineSheet({super.key});

  @override
  State<AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<AddMedicineSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _dosage = TextEditingController();
  final TextEditingController _note = TextEditingController();
  TimeOfDay? _time;
  bool _everyday = true;
  final Set<Weekday> _days = {Weekday.sun, Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu, Weekday.fri, Weekday.sat};

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _time = t);
  }

  void _toggleDay(Weekday d, bool selected) {
    setState(() {
      if (selected) {
        _days.add(d);
      } else {
        _days.remove(d);
      }
      _everyday = _days.length == 7;
    });
  }

  void _toggleEveryday(bool v) {
    setState(() {
      _everyday = v;
      if (v) {
        _days..clear()..addAll({Weekday.sun, Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu, Weekday.fri, Weekday.sat});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(
                    child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))),
                  ),
                  const Text('إضافة دواء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xff33484d))),
                  const SizedBox(height: 16),
                  TextFormField(controller: _name, validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب اسم الدواء' : null, decoration: _fieldDecoration('اسم الدواء', Icons.medication)),
                  const SizedBox(height: 12),
                  TextFormField(controller: _dosage, validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب الجرعة (مثال: 500mg)' : null, decoration: _fieldDecoration('الجرعة', Icons.scale)),
                  const SizedBox(height: 12),
                  TextFormField(controller: _note, decoration: _fieldDecoration('وصف الجرعة (اختياري)', Icons.sticky_note_2)),
                  const SizedBox(height: 12),
                  GestureDetector(onTap: _pickTime, child: InputDecorator(decoration: _fieldDecoration('وقت الجرعة', Icons.access_time), child: Text(_time == null ? 'اختر الوقت' : _time!.format(context), style: const TextStyle(color: Color(0xff33484d))))),
                  const SizedBox(height: 12),
                  SwitchListTile(value: _everyday, onChanged: _toggleEveryday, title: const Text('كل الأيام'), activeColor: const Color(0xffa1dcc0), contentPadding: EdgeInsets.zero),
                  if (!_everyday)
                    Wrap(spacing: 8, children: Weekday.values.map((d) { final selected = _days.contains(d); return FilterChip(label: Text(weekdayName(d)), selected: selected, onSelected: (v) => _toggleDay(d, v), selectedColor: const Color(0xffa1dcc0).withOpacity(.8), labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xff33484d))); }).toList()),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final valid = _formKey.currentState!.validate();
                      if (!valid) return;
                      if (_time == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختَر وقت الجرعة')));
                        return;
                      }
                      final med = Medicine(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _name.text.trim(),
                        dosage: _dosage.text.trim(),
                        times: [DoseTime(time: _time!, note: _note.text.trim().isEmpty ? null : _note.text.trim())],
                        days: _everyday ? {Weekday.sun, Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu, Weekday.fri, Weekday.sat} : _days,
                      );
                      Navigator.pop(context, med);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffa1dcc0), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('حفظ الدواء'),
                  )
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xfffffbf2),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}
