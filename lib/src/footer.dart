import 'package:flutter/material.dart';

class CircleFooterIndicator extends StatefulWidget {
  const CircleFooterIndicator({super.key});

  @override
  State<CircleFooterIndicator> createState() => _CircleFooterIndicatorState();
}

class _CircleFooterIndicatorState extends State<CircleFooterIndicator> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<String> pages = [
    "Welcome to the App",
    "Pay with Apple Pay",
    "Get Instant Notifications",
    "Ready to Start!"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Circle Footer Onboarding")),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (_, index) => Center(
                child: Text(
                  pages[index],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // Footer indicators (circles)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (index) => Container(
                margin: const EdgeInsets.all(4),
                width: _currentIndex == index ? 14 : 10,
                height: _currentIndex == index ? 14 : 10,
                decoration: BoxDecoration(
                  color: _currentIndex == index ? Colors.blue : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
