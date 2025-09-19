import 'package:final_project_doa/src/onboarding.dart';
import 'package:final_project_doa/src/services/notification_service.dart';
import 'package:flutter/material.dart';

void main() async{
   WidgetsFlutterBinding.ensureInitialized();
   await NotificationService.instance.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: onboarding()
    );
  }
}
