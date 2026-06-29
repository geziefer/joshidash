import 'package:flame/game.dart' hide Route;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/joshi_dash_game.dart';

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
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
            Navigator.of(context).push(_gameRoute());
          }
        },
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Joshi Dash',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00FFFF),
                shadows: [
                  Shadow(color: const Color(0xFF00FFFF), blurRadius: 20),
                  Shadow(color: const Color(0xFFFF00FF), blurRadius: 40),
                ],
              ),
            ),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () => Navigator.of(context).push(_gameRoute()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00FFFF), width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00FFFF), blurRadius: 15, spreadRadius: 1),
                    BoxShadow(color: const Color(0xFFFF00FF), blurRadius: 30, spreadRadius: -2),
                  ],
                ),
                child: Text(
                  'START',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00FFFF),
                    letterSpacing: 4,
                    shadows: [Shadow(color: const Color(0xFF00FFFF), blurRadius: 10)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Route _gameRoute() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) => const GameScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late JoshiDashGame _game;
  bool _showOverlay = false;
  String _overlayText = '';

  @override
  void initState() {
    super.initState();
    _game = JoshiDashGame();
    _game.onGameOver = () {
      setState(() {
        _showOverlay = true;
        _overlayText = 'GAME OVER\nTap to restart';
      });
    };
    _game.onLevelComplete = () {
      setState(() {
        _showOverlay = true;
        _overlayText = 'LEVEL COMPLETE!';
      });
    };
  }

  void _handleOverlayTap() {
    setState(() => _showOverlay = false);
    _game.restart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          if (_showOverlay)
            GestureDetector(
              onTap: _handleOverlayTap,
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Text(
                  _overlayText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF00FFFF),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
