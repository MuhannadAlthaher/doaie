import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    color: Colors.white,
  ),
  child: Column(
    children: [
      ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Image.asset(
          'assets/cc.png',
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        '✨ مرحباً بك في تطبيق دواءك ✨',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Color(0xff33484d)),
      ),
      const SizedBox(height: 10),
      const Text(
        'واجهة بسيطة تعرض صورة الدواء ووقته بوضوح',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18,color: Color(0xff33484d)),
      ),
    ],
  ),
);

  }
}
