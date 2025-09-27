import 'package:flutter/material.dart';
import 'package:final_project_doa/src/onboarding/first_screan.dart';
import 'package:final_project_doa/src/onboarding/second_screen.dart';
import 'package:final_project_doa/src/onboarding/third_screan.dart';
import 'package:final_project_doa/src/login_screen.dart';

class CircleFooterIndicator extends StatefulWidget {
  const CircleFooterIndicator({super.key});

  @override
  State<CircleFooterIndicator> createState() => _CircleFooterIndicatorState();
}

class _CircleFooterIndicatorState extends State<CircleFooterIndicator> {
  final PageController _controller = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;

  final List<Widget> pages = const [
    FirstScrean(),
    SecondScreen(),
    ThirdScrean(),
  ];

  void _goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) =>  LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentIndex == pages.length - 1;

    return Scaffold(
      backgroundColor: Color(0xfffffbf2),
      appBar: AppBar(
        backgroundColor:  Color(0xfffffbf2),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'دوائك',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xff33484d),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _goToLogin(context),
            child: const Text(
              'تخطي',
              style: TextStyle(color: Color(0xff33484d), fontSize: 16),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 550,
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (_, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                    decoration: BoxDecoration(
                      color: Color(0xffa1dcc0),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: pages[index],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.all(4),
                  width: _currentIndex == index ? 14 : 10,
                  height: _currentIndex == index ? 14 : 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Color(0xffa1dcc0)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xffa1dcc0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                if (isLastPage) {
                  _goToLogin(context);
                } else {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Text(isLastPage ? 'اذهب لتسجيل الدخول' : 'التالي',style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.bold),),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
