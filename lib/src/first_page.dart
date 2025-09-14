import 'package:flutter/material.dart';
import 'package:final_project_doa/src/footer.dart';
import 'package:final_project_doa/src/header.dart';

const Color background = Colors.blue;

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
     body:CircleFooterIndicator()
    );
  }
}
