import 'package:flutter/material.dart';
import 'package:final_project_doa/src/footer.dart';

const Color background = Colors.blue;

class onboarding extends StatelessWidget {
  const onboarding({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
     body:CircleFooterIndicator()
    );
  }
}
