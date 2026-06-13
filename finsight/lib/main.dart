import 'package:finsight/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'constants/app_colors.dart';

void main() {
  runApp(const FinSightApp());
}

class FinSightApp extends StatelessWidget {
  const FinSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinSight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}
