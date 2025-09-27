import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class DoseCard extends StatefulWidget {
  final String medName;
  final String dosage;
  final String? note;
  final DateTime time;
  final bool taken;
  final bool isPast;

  /// مرّر واحدة فقط:
  final String? imagePath; // مسار ملف محلي
  final Uint8List? imageBytes; // Bytes

  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const DoseCard({
    super.key,
    required this.medName,
    required this.dosage,
    required this.time,
    this.note,
    required this.taken,
    required this.isPast,
    required this.onToggle,
    required this.onRemove,
    this.imagePath,
    this.imageBytes,
  });

  @override
  State<DoseCard> createState() => _DoseCardState();
}

class _DoseCardState extends State<DoseCard> {
  bool _expanded = false;

  ImageProvider? get _thumbImage {
    // أولوية للـ bytes
    if (widget.imageBytes != null && widget.imageBytes!.isNotEmpty) {
      return MemoryImage(widget.imageBytes!);
    }

    // بعدها مسار الملف (Android/iOS فقط)
    if (widget.imagePath != null &&
        widget.imagePath!.trim().isNotEmpty &&
        !kIsWeb) {
      final f = File(widget.imagePath!.trim());
      if (f.existsSync()) {
        return FileImage(f);
      }
    }
    // لو ما توفر شيء -> null (يستخدم الأيقونة)
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.taken
        ? Colors.green
        : (widget.isPast ? Colors.orange : const Color(0xff33484d));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: const Color(0xffa1dcc0).withOpacity(.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // ====== الصف الأساسي ======
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xffa1dcc0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // صورة مصغرة أو أيقونة عند الفشل
                  _ThumbBox(image: _thumbImage),

                  const SizedBox(width: 12),

                  // نصوص العنوان
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.medName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xff33484d),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Color(0xff33484d),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _timeString(widget.time),
                              style: TextStyle(
                                color: const Color(0xff33484d).withOpacity(.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.dosage +
                              ((widget.note != null &&
                                      widget.note!.trim().isNotEmpty)
                                  ? ' — ${widget.note!}'
                                  : ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xff33484d).withOpacity(.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  Icon(
                    widget.taken ? Icons.check_circle : Icons.alarm,
                    color: statusColor,
                  ),
                ],
              ),

              // ====== التفاصيل عند التوسيع ======
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _DetailsSection(
                    time: widget.time,
                    dosage: widget.dosage,
                    note: widget.note,
                    image: _thumbImage,
                    taken: widget.taken,
                    statusColor: statusColor,
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),

              const SizedBox(height: 12),

              // ====== الأزرار ======
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('إزالة'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onToggle,
                      icon: Icon(widget.taken ? Icons.undo : Icons.check),
                      label: Text(widget.taken ? 'تراجع' : 'تم'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.taken
                            ? Colors.grey[400]
                            : const Color(0xffa1dcc0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صندوق الصورة المصغرة مع fallback أيقونة عند الفشل
class _ThumbBox extends StatelessWidget {
  final ImageProvider? image;
  const _ThumbBox({required this.image});

  @override
  Widget build(BuildContext context) {
    final border = BoxDecoration(
      color: const Color(0xfffffbf2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black12),
    );

    if (image == null) {
      return Container(
        width: 64,
        height: 64,
        decoration: border,
        child: const Icon(Icons.medication_liquid, color: Color(0xff33484d)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image(
        image: image!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        // لو حصل خطأ بالتحميل/القراءة، رجّع الأيقونة:
        errorBuilder: (_, __, ___) => Container(
          width: 64,
          height: 64,
          decoration: border,
          child: const Icon(Icons.medication_liquid, color: Color(0xff33484d)),
        ),
        // تأثير دخول لطيف
        frameBuilder: (ctx, child, frame, wasSyncLoaded) {
          if (wasSyncLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final DateTime time;
  final String dosage;
  final String? note;
  final ImageProvider? image;
  final bool taken;
  final Color statusColor;

  const _DetailsSection({
    required this.time,
    required this.dosage,
    required this.note,
    required this.image,
    required this.taken,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (image != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image: image!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xfffffbf2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Icon(
                  Icons.medication_liquid,
                  color: Color(0xff33484d),
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Icon(
              taken ? Icons.check_circle : Icons.schedule,
              size: 18,
              color: statusColor,
            ),
            const SizedBox(width: 6),
            Text(
              'الوقت: ${_timeString(time)}',
              style: const TextStyle(
                color: Color(0xff33484d),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'الجرعة: $dosage',
          style: TextStyle(color: const Color(0xff33484d).withOpacity(.9)),
        ),
        if (note != null && note!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'الوصف: ${note!}',
            style: TextStyle(color: const Color(0xff33484d).withOpacity(.9)),
          ),
        ],
      ],
    );
  }
}

String _timeString(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
