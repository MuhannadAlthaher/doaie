import 'package:final_project_doa/src/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social_button/flutter_social_button.dart';
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfffffbf2),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.jpeg', height: 200,width: 200,),
            const SizedBox(height: 40),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xffa1dcc0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text('تسجيل الدخول',style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold,color: Colors.white),),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "اسم المستخدم",
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "كلمة المرور",
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff33484d),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
              
                      },
                      child:  Text(
                        "تسجيل الدخول",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                 GestureDetector(
  onTap: () {
    Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const RegisterScreen()),
);
  },
  child: RichText(
    text: const TextSpan(
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white, 
      ),
      children: [
        TextSpan(text: "ليس لديك حساب؟ "),
        TextSpan(
          text: "سجل الآن",
          style: TextStyle(
            color: Color(0xff7a71e5), 
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
),

                  SizedBox(height: 20,),
                  Row(
                    children: [
                      FlutterSocialButton(
                       iconSize: 20,
                        onTap: () {},
                        mini: true,   
                        buttonType: ButtonType.github,  
                      ),
                      SizedBox(width: 20,),
                       FlutterSocialButton(
                        iconSize: 20,
                        onTap: () {},
                        mini: true,   
                        buttonType: ButtonType.apple,  
                      ),
                      SizedBox(width: 20,),
                       FlutterSocialButton(
                        iconSize: 20,
                        onTap: () {},
                        mini: true,   
                        buttonType: ButtonType.google,  
                      ),
                        SizedBox(width: 20,),

                      FlutterSocialButton(
                        iconSize: 20,
                        onTap: () {},
                        mini: true,   
                        buttonType: ButtonType.twitter,  
                      ),
                    ],
                  ),

                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
