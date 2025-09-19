import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onAddPressed;
  const EmptyState({super.key, required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_alert, size: 64, color: const Color(0xff33484d).withOpacity(.5)),
          const SizedBox(height: 12),
          const Text('ما أضفت أي دواء حتى الآن', style: TextStyle(color: Color(0xff33484d), fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('اضغط على "إضافة دواء" وحدد الوقت والأيام', style: TextStyle(color: const Color(0xff33484d).withOpacity(.7))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAddPressed,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffa1dcc0), foregroundColor: Colors.white),
            child: const Text('إضافة أول دواء'),
          ),
        ],
      ),
    );
  }
}