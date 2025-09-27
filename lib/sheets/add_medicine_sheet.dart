import 'dart:typed_data';
import 'dart:io' show File; // ✅ جديد: للكتابة على الملف
import 'package:final_project_doa/src/models/medicine.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ جديد: تفرع للويب
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // ✅ جديد: مجلد التطبيق

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
  bool _saving = false;

  // الصورة
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  Uint8List? _imageBytes; // للمعاينة بشكل متوافق (iOS/Android/Web لاحقًا)

  final Set<Weekday> _days = {
    Weekday.sun,
    Weekday.mon,
    Weekday.tue,
    Weekday.wed,
    Weekday.thu,
    Weekday.fri,
    Weekday.sat,
  };

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      helpText: 'اختر وقت الجرعة',
    );
    if (t != null) setState(() => _time = t);
  }

  // ==== صورة الدواء ====
  Future<void> _chooseImageSource() async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                runSpacing: 6,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('التقاط من الكاميرا'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('اختيار من الألبوم'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_imageFile != null)
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'إزالة الصورة',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _removeImage();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        imageQuality: 75, // تقليل الحجم قليلاً
        maxWidth: 2000, // حد حجم معقول للهواتف
      );
      if (x != null) {
        final bytes = await x.readAsBytes();
        if (mounted) {
          setState(() {
            _imageFile = x;
            _imageBytes = bytes;
          });
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر اختيار الصورة')));
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageBytes = null;
    });
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
        _days
          ..clear()
          ..addAll({
            Weekday.sun,
            Weekday.mon,
            Weekday.tue,
            Weekday.wed,
            Weekday.thu,
            Weekday.fri,
            Weekday.sat,
          });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const Text(
                        'إضافة دواء',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff33484d),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // اسم الدواء
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 60,
                        buildCounter:
                            (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => const SizedBox.shrink(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'اكتب اسم الدواء'
                            : null,
                        decoration: _fieldDecoration(
                          'اسم الدواء',
                          Icons.medication,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // الجرعة
                      TextFormField(
                        controller: _dosage,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        inputFormatters: [LengthLimitingTextInputFormatter(30)],
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'اكتب الجرعة (مثال: 500mg)'
                            : null,
                        decoration: _fieldDecoration('الجرعة', Icons.scale),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _note,
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                        decoration: _fieldDecoration(
                          'وصف الجرعة (اختياري)',
                          Icons.sticky_note_2,
                        ),
                      ),

                      const SizedBox(height: 12),

                      FormField<TimeOfDay>(
                        validator: (_) =>
                            _time == null ? 'اختر وقت الجرعة' : null,
                        builder: (state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GestureDetector(
                                onTap: _pickTime,
                                child: InputDecorator(
                                  decoration: _fieldDecoration(
                                    'وقت الجرعة',
                                    Icons.access_time,
                                  ).copyWith(errorText: state.errorText),
                                  child: Text(
                                    _time == null
                                        ? 'اختر الوقت'
                                        : _time!.format(context),
                                    style: const TextStyle(
                                      color: Color(0xff33484d),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // ==== صورة الدواء ====
                      const Text(
                        'صورة الدواء (اختياري)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xff33484d),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _imageBytes == null
                              ? Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xfffffbf2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: Colors.black38,
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _imageBytes!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _chooseImageSource,
                                  icon: const Icon(Icons.add_a_photo_outlined),
                                  label: Text(
                                    _imageFile == null
                                        ? 'إضافة صورة'
                                        : 'تغيير الصورة',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xff33484d),
                                  ),
                                ),
                                if (_imageFile != null)
                                  OutlinedButton.icon(
                                    onPressed: _removeImage,
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('إزالة'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 12),

                      SwitchListTile(
                        value: _everyday,
                        onChanged: _toggleEveryday,
                        title: const Text('كل الأيام'),
                        activeColor: const Color(0xffa1dcc0),
                        contentPadding: EdgeInsets.zero,
                      ),

                      // اختيار الأيام
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _everyday
                            ? const SizedBox.shrink()
                            : Wrap(
                                spacing: 8,
                                children: Weekday.values.map((d) {
                                  final selected = _days.contains(d);
                                  return FilterChip(
                                    label: Text(weekdayName(d)),
                                    selected: selected,
                                    onSelected: (v) => _toggleDay(d, v),
                                    selectedColor: const Color(
                                      0xffa1dcc0,
                                    ).withOpacity(.8),
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xff33484d),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),

                      const SizedBox(height: 20),

                      // زر الحفظ
                      ElevatedButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                HapticFeedback.selectionClick();
                                FocusScope.of(context).unfocus();
                                final valid = _formKey.currentState!.validate();
                                if (!valid) return;

                                setState(() => _saving = true);
                                try {
                                  // ✅ نحاول حفظ الصورة في مجلد التطبيق بمسار ثابت
                                  String? savedPath;
                                  if (_imageBytes != null && !kIsWeb) {
                                    try {
                                      final dir =
                                          await getApplicationDocumentsDirectory();
                                      final file = File(
                                        '${dir.path}/med_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                      );
                                      await file.writeAsBytes(
                                        _imageBytes!,
                                        flush: true,
                                      );
                                      savedPath = file.path;
                                    } catch (_) {
                                      // لو فشل الحفظ لأي سبب: نحتفظ بمسار الـ picker كحل احتياطي
                                      savedPath = _imageFile?.path;
                                    }
                                  } else {
                                    // ويب أو ما فيه Bytes: استخدم مسار الـ picker إن وجد
                                    savedPath = _imageFile?.path;
                                  }

                                  final med = Medicine(
                                    id: DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                    name: _name.text.trim(),
                                    dosage: _dosage.text.trim(),
                                    times: [
                                      DoseTime(
                                        time: _time!,
                                        note: _note.text.trim().isEmpty
                                            ? null
                                            : _note.text.trim(),
                                      ),
                                    ],
                                    days: _everyday
                                        ? {
                                            Weekday.sun,
                                            Weekday.mon,
                                            Weekday.tue,
                                            Weekday.wed,
                                            Weekday.thu,
                                            Weekday.fri,
                                            Weekday.sat,
                                          }
                                        : _days,

                                    // ✅ مهم: مرّر مسار الصورة (المحفوظ محليًا إن أمكن)
                                    imagePath: savedPath,
                                  );
                                  Navigator.pop(context, med);
                                  return; // ✅ عشان ما يصير Pop مرتين (أبقينا السطر الآخر كما هو)

                                  // إن موديلك ما فيه imagePath:
                                  // ممكن ترجع Map فيها الدواء والمسار:
                                  // Navigator.pop(context, {'medicine': med, 'imagePath': _imageFile?.path});

                                  Navigator.pop(context, med);
                                } finally {
                                  if (mounted) setState(() => _saving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffa1dcc0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_saving ? '...يحفظ' : 'حفظ الدواء'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xfffffbf2),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}

/// في حال ما عندك دالة أسماء الأيام عربية
String weekdayName(Weekday d) {
  switch (d) {
    case Weekday.sun:
      return 'الأحد';
    case Weekday.mon:
      return 'الإثنين';
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
