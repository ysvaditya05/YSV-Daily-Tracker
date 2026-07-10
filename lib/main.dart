import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const YsvDailyApp());
}

class YsvDailyApp extends StatelessWidget {
  const YsvDailyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YSV Daily',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
