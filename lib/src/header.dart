import 'package:flutter/material.dart';

class LineHeaderIndicator extends StatefulWidget {
  const LineHeaderIndicator({super.key});

  @override
  State<LineHeaderIndicator> createState() => _LineHeaderIndicatorState();
}

class _LineHeaderIndicatorState extends State<LineHeaderIndicator> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<String> pages = [
    "Welcome to the App",
    "Secure Banking Made Easy",
    "Track your Finances",
    "Start your Journey Today"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Line Header Onboarding")),
      body: Column(
        children: [
          // Header indicator (line)
          LinearProgressIndicator(
            value: (_currentIndex + 1) / pages.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
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
        ],
      ),
    );
  }
}
