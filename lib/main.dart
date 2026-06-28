import 'package:flutter/material.dart';

void main() {
  runApp(const JoshiDashApp());
}

class JoshiDashApp extends StatelessWidget {
  const JoshiDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JoshiDash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const StartPage(),
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Joshi Dash',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00FFFF),
            shadows: [
              Shadow(
                color: const Color(0xFF00FFFF),
                blurRadius: 20,
              ),
              Shadow(
                color: const Color(0xFFFF00FF),
                blurRadius: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
